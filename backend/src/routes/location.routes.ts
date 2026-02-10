import { FastifyInstance, FastifyRequest, FastifyReply } from 'fastify';
import { z } from 'zod';
import { v4 as uuid } from 'uuid';
import { getDb } from '../config/database.js';
import { authenticate } from '../middleware/auth.middleware.js';
import { generateAISummary } from '../services/ai-summary.service.js';

const createReviewSchema = z.object({
  overall_rating: z.number().int().min(1).max(5),
  waiting_time_rating: z.number().int().min(1).max(5).optional(),
  access_rating: z.number().int().min(1).max(5).optional(),
  staff_rating: z.number().int().min(1).max(5).optional(),
  facilities_rating: z.number().int().min(1).max(5).optional(),
  actual_waiting_time_min: z.number().int().min(0).optional(),
  mega_trailer_ok: z.boolean().optional(),
  has_truck_parking: z.boolean().optional(),
  has_toilets: z.boolean().optional(),
  has_water: z.boolean().optional(),
  requires_ppe: z.boolean().optional(),
  ppe_details: z.string().max(255).optional(),
  comment: z.string().max(2000).optional(),
  visit_date: z.string().optional()
});

export default async function locationRoutes(app: FastifyInstance) {
  // Search locations near point
  app.get('/', async (request: FastifyRequest, reply: FastifyReply) => {
    const { lat, lng, radius_km, type } = request.query as {
      lat: string;
      lng: string;
      radius_km?: string;
      type?: string;
    };
    const sql = getDb();

    const radiusMeters = parseFloat(radius_km || '10') * 1000;

    const locationsResult = await sql`
      SELECT id, name, address, location_type,
             ST_X(location::geometry) as lng, ST_Y(location::geometry) as lat,
             avg_waiting_time_min, avg_rating, total_reviews, ai_summary
      FROM locations
      WHERE ST_DWithin(
        location,
        ST_SetSRID(ST_MakePoint(${parseFloat(lng)}, ${parseFloat(lat)}), 4326)::geography,
        ${radiusMeters}
      )
      ORDER BY ST_Distance(
        location,
        ST_SetSRID(ST_MakePoint(${parseFloat(lng)}, ${parseFloat(lat)}), 4326)::geography
      )
      LIMIT 50
    `;

    const locations = type
      ? (locationsResult as Array<Record<string, unknown>>).filter((l) => l.location_type === type)
      : locationsResult;

    return reply.send({ locations });
  });

  // Get location details
  app.get('/:id', async (request: FastifyRequest, reply: FastifyReply) => {
    const { id } = request.params as { id: string };
    const sql = getDb();

    const [location] = await sql`
      SELECT id, name, address, location_type, google_place_id,
             ST_X(location::geometry) as lng, ST_Y(location::geometry) as lat,
             avg_waiting_time_min, avg_rating, total_reviews,
             ai_summary, ai_summary_updated_at
      FROM locations
      WHERE id = ${id}
    `;

    if (!location) {
      return reply.status(404).send({ error: 'Location not found' });
    }

    return reply.send({ location });
  });

  // Get reviews for location
  app.get('/:id/reviews', async (request: FastifyRequest, reply: FastifyReply) => {
    const { id } = request.params as { id: string };
    const { limit, offset } = request.query as { limit?: string; offset?: string };
    const limitNum = limit ? parseInt(limit) : 20;
    const offsetNum = offset ? parseInt(offset) : 0;
    const sql = getDb();

    const reviews = await sql`
      SELECT r.id, r.overall_rating, r.waiting_time_rating, r.access_rating,
             r.staff_rating, r.facilities_rating, r.actual_waiting_time_min,
             r.mega_trailer_ok, r.has_truck_parking, r.has_toilets, r.has_water,
             r.requires_ppe, r.ppe_details, r.comment, r.created_at, r.visit_date,
             u.display_name as reviewer_name, u.country as reviewer_country
      FROM location_reviews r
      JOIN users u ON r.user_id = u.id
      WHERE r.location_id = ${id}
      ORDER BY r.created_at DESC
      LIMIT ${limitNum} OFFSET ${offsetNum}
    `;

    return reply.send({ reviews });
  });

  // Submit review
  app.post('/:id/reviews', {
    preHandler: [authenticate],
    handler: async (request: FastifyRequest, reply: FastifyReply) => {
      const { userId } = request.user as { userId: string };
      const { id: locationId } = request.params as { id: string };
      const body = createReviewSchema.parse(request.body);
      const sql = getDb();

      // Check location exists
      const [location] = await sql`SELECT id, name FROM locations WHERE id = ${locationId}`;
      if (!location) {
        return reply.status(404).send({ error: 'Location not found' });
      }

      // Get user's language
      const [user] = await sql`SELECT language FROM users WHERE id = ${userId}`;

      // Create review
      const [review] = await sql`
        INSERT INTO location_reviews (
          id, location_id, user_id, overall_rating, waiting_time_rating,
          access_rating, staff_rating, facilities_rating, actual_waiting_time_min,
          mega_trailer_ok, has_truck_parking, has_toilets, has_water,
          requires_ppe, ppe_details, comment, language, visit_date
        )
        VALUES (
          ${uuid()}, ${locationId}, ${userId}, ${body.overall_rating},
          ${body.waiting_time_rating || null}, ${body.access_rating || null},
          ${body.staff_rating || null}, ${body.facilities_rating || null},
          ${body.actual_waiting_time_min || null}, ${body.mega_trailer_ok || null},
          ${body.has_truck_parking || null}, ${body.has_toilets || null},
          ${body.has_water || null}, ${body.requires_ppe || null},
          ${body.ppe_details || null}, ${body.comment || null},
          ${user?.language || 'en'}, ${body.visit_date || null}
        )
        RETURNING id, overall_rating, created_at
      `;

      // Update location stats
      await sql`
        UPDATE locations
        SET total_reviews = total_reviews + 1,
            avg_rating = (
              SELECT AVG(overall_rating) FROM location_reviews WHERE location_id = ${locationId}
            ),
            avg_waiting_time_min = (
              SELECT AVG(actual_waiting_time_min) FROM location_reviews
              WHERE location_id = ${locationId} AND actual_waiting_time_min IS NOT NULL
            )
        WHERE id = ${locationId}
      `;

      // Update user's review count
      await sql`
        UPDATE users SET total_reviews = total_reviews + 1 WHERE id = ${userId}
      `;

      // Trigger AI summary regeneration if enough new reviews
      const [stats] = await sql`
        SELECT total_reviews, ai_summary_updated_at FROM locations WHERE id = ${locationId}
      `;

      const daysSinceUpdate = stats.ai_summary_updated_at
        ? (Date.now() - new Date(stats.ai_summary_updated_at).getTime()) / (1000 * 60 * 60 * 24)
        : Infinity;

      if (stats.total_reviews >= 3 && (stats.total_reviews % 3 === 0 || daysSinceUpdate > 7)) {
        // Generate new AI summary asynchronously
        generateAISummary(locationId).catch(err => {
          app.log.error(`Failed to generate AI summary for location ${locationId}:`, err);
        });
      }

      return reply.status(201).send({ review });
    }
  });

  // Get AI summary (regenerate if needed)
  app.get('/:id/summary', async (request: FastifyRequest, reply: FastifyReply) => {
    const { id } = request.params as { id: string };
    const sql = getDb();

    const [location] = await sql`
      SELECT id, name, ai_summary, ai_summary_updated_at, total_reviews
      FROM locations WHERE id = ${id}
    `;

    if (!location) {
      return reply.status(404).send({ error: 'Location not found' });
    }

    // If no summary and we have reviews, generate one
    if (!location.ai_summary && location.total_reviews >= 3) {
      const summary = await generateAISummary(id);
      return reply.send({ summary, generated: true });
    }

    return reply.send({
      summary: location.ai_summary,
      updated_at: location.ai_summary_updated_at,
      generated: false
    });
  });
}
