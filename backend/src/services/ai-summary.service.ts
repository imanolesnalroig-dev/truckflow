import { GoogleGenerativeAI } from '@google/generative-ai';
import { config } from '../config/index.js';
import { getDb } from '../config/database.js';

const genAI = config.geminiApiKey
  ? new GoogleGenerativeAI(config.geminiApiKey)
  : null;

const SUMMARY_PROMPT = `You are a truck driver assistant. Summarize the following driver reviews of the loading/unloading location.

Create a concise, practical briefing (max 150 words) covering:
1. Average and typical waiting time
2. How to access the location with a truck (entrance, approach road, tight turns)
3. Whether mega trailers / specific trailer types can access
4. Required PPE or documentation
5. Staff attitude and helpfulness
6. Available facilities (toilets, water, parking while waiting)
7. Any tips or warnings

Write in second person ('you'). Be direct and practical. This will be read by a truck driver approaching this location for the first time.

Location: {name}
Address: {address}

Reviews:
{reviews}

Respond ONLY with the summary text, no preamble.`;

const TRANSLATION_PROMPT = `Translate the following truck driver briefing to {language}. Keep the same practical, direct tone. Do not add or remove information.

{summary}`;

// Supported languages for translation
const LANGUAGES: Record<string, string> = {
  pl: 'Polish',
  ro: 'Romanian',
  de: 'German',
  es: 'Spanish',
  en: 'English',
  bg: 'Bulgarian',
  lt: 'Lithuanian',
  tr: 'Turkish',
  fr: 'French',
  it: 'Italian',
  hu: 'Hungarian',
  cs: 'Czech',
  pt: 'Portuguese',
  nl: 'Dutch'
};

export async function generateAISummary(locationId: string): Promise<string | null> {
  if (!genAI) {
    console.warn('Gemini API key not configured, skipping AI summary generation');
    return null;
  }

  const sql = getDb();

  // Get location details
  const [location] = await sql`
    SELECT id, name, address FROM locations WHERE id = ${locationId}
  `;

  if (!location) {
    throw new Error('Location not found');
  }

  // Get recent reviews
  const reviews = await sql`
    SELECT overall_rating, waiting_time_rating, access_rating, staff_rating,
           facilities_rating, actual_waiting_time_min, mega_trailer_ok,
           has_truck_parking, has_toilets, has_water, requires_ppe, ppe_details,
           comment, language
    FROM location_reviews
    WHERE location_id = ${locationId}
    ORDER BY created_at DESC
    LIMIT 50
  `;

  if (reviews.length < 3) {
    return null;
  }

  // Format reviews for the prompt
  const reviewsText = reviews.map((r, i) => {
    const parts = [`Review ${i + 1}:`];
    if (r.overall_rating) parts.push(`Rating: ${r.overall_rating}/5`);
    if (r.actual_waiting_time_min) parts.push(`Wait time: ${r.actual_waiting_time_min} min`);
    if (r.mega_trailer_ok !== null) parts.push(`Mega trailer: ${r.mega_trailer_ok ? 'OK' : 'NOT OK'}`);
    if (r.requires_ppe) parts.push(`PPE: ${r.ppe_details || 'Required'}`);
    if (r.comment) parts.push(`Comment: ${r.comment}`);
    return parts.join(' | ');
  }).join('\n');

  // Generate summary
  const prompt = SUMMARY_PROMPT
    .replace('{name}', location.name)
    .replace('{address}', location.address || 'Unknown')
    .replace('{reviews}', reviewsText);

  try {
    const model = genAI.getGenerativeModel({ model: 'gemini-1.5-flash' });
    const result = await model.generateContent(prompt);
    const summary = result.response.text().trim();

    // Store the summary
    await sql`
      UPDATE locations
      SET ai_summary = ${summary},
          ai_summary_updated_at = NOW()
      WHERE id = ${locationId}
    `;

    return summary;
  } catch (error) {
    console.error('Failed to generate AI summary:', error);
    return null;
  }
}

export async function translateSummary(summary: string, targetLanguage: string): Promise<string | null> {
  if (!genAI) {
    return null;
  }

  const languageName = LANGUAGES[targetLanguage];
  if (!languageName || targetLanguage === 'en') {
    return summary;
  }

  const prompt = TRANSLATION_PROMPT
    .replace('{language}', languageName)
    .replace('{summary}', summary);

  try {
    const model = genAI.getGenerativeModel({ model: 'gemini-1.5-flash' });
    const result = await model.generateContent(prompt);
    return result.response.text().trim();
  } catch (error) {
    console.error('Failed to translate summary:', error);
    return null;
  }
}
