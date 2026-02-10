import { FastifyInstance, FastifyRequest, FastifyReply } from 'fastify';
import { z } from 'zod';
import { getDb } from '../config/database.js';
import { authenticate } from '../middleware/auth.middleware.js';

const updateOccupancySchema = z.object({
  occupancy_pct: z.number().min(0).max(100)
});

// Seed data for European truck parks
const seedParkingData = [
  { name: 'Rasthof Helmstedt Nord', address: 'A2 km 242, 38350 Helmstedt', country: 'DE', lat: 52.2167, lng: 11.0167, totalSpaces: 150, hasSecurity: true, hasCamera: true, hasFence: true, hasToilets: true, hasShowers: true, hasRestaurant: true, hasShop: true, hasAdblue: true, hasWifi: true, pricePerNightEur: 15, isFree: false },
  { name: 'Autohof Peine', address: 'Im Gewerbepark 15, 31228 Peine', country: 'DE', lat: 52.3167, lng: 10.2333, totalSpaces: 200, hasSecurity: true, hasCamera: true, hasFence: true, hasElectricity: true, hasWater: true, hasToilets: true, hasShowers: true, hasRestaurant: true, hasShop: true, hasAdblue: true, hasWifi: true, pricePerNightEur: 20, isFree: false },
  { name: 'Rasthof Münsterland West', address: 'A1 km 268, 48268 Greven', country: 'DE', lat: 52.0833, lng: 7.6500, totalSpaces: 120, hasCamera: true, hasToilets: true, hasRestaurant: true, hasShop: true, hasAdblue: true, isFree: true },
  { name: 'MOP Konin', address: 'A2 km 289, 62-510 Konin', country: 'PL', lat: 52.2167, lng: 18.2500, totalSpaces: 180, hasSecurity: true, hasCamera: true, hasFence: true, hasToilets: true, hasShowers: true, hasRestaurant: true, hasShop: true, hasAdblue: true, hasWifi: true, pricePerNightEur: 10, isFree: false },
  { name: 'Truck Stop Koło', address: 'ul. Toruńska 200, 62-600 Koło', country: 'PL', lat: 52.2000, lng: 18.6333, totalSpaces: 100, hasSecurity: true, hasCamera: true, hasFence: true, hasElectricity: true, hasWater: true, hasToilets: true, hasShowers: true, hasRestaurant: true, hasShop: true, hasAdblue: true, hasWifi: true, pricePerNightEur: 8, isFree: false },
  { name: 'Truckparking Veenendaal', address: 'De Smalle Zijde 40, 3903 LP Veenendaal', country: 'NL', lat: 52.0167, lng: 5.5333, totalSpaces: 250, hasSecurity: true, hasCamera: true, hasFence: true, hasElectricity: true, hasWater: true, hasToilets: true, hasShowers: true, hasWifi: true, pricePerNightEur: 25, isFree: false },
  { name: 'De Bolder Truck Parking', address: 'Energieweg 2, 3542 DZ Utrecht', country: 'NL', lat: 52.1000, lng: 5.0333, totalSpaces: 180, hasSecurity: true, hasCamera: true, hasFence: true, hasElectricity: true, hasWater: true, hasToilets: true, hasShowers: true, hasRestaurant: true, hasShop: true, hasAdblue: true, hasWifi: true, pricePerNightEur: 28, isFree: false },
  { name: 'Total Aire de Heverlee', address: 'E40 km 23, 3001 Heverlee', country: 'BE', lat: 50.8667, lng: 4.6833, totalSpaces: 80, hasCamera: true, hasToilets: true, hasRestaurant: true, hasShop: true, hasAdblue: true, isFree: true },
  { name: 'Aire de Ressons-Ouest', address: 'A1 km 90, 60490 Ressons-sur-Matz', country: 'FR', lat: 49.5500, lng: 2.7500, totalSpaces: 200, hasSecurity: true, hasCamera: true, hasFence: true, hasToilets: true, hasShowers: true, hasRestaurant: true, hasShop: true, hasAdblue: true, hasWifi: true, pricePerNightEur: 18, isFree: false },
  { name: 'Área de Servicio La Junquera', address: 'AP-7 km 2, 17700 La Jonquera', country: 'ES', lat: 42.4167, lng: 2.8667, totalSpaces: 300, hasSecurity: true, hasCamera: true, hasFence: true, hasElectricity: true, hasWater: true, hasToilets: true, hasShowers: true, hasRestaurant: true, hasShop: true, hasAdblue: true, hasWifi: true, pricePerNightEur: 22, isFree: false },
  { name: 'Área de Servicio Lleida', address: 'A-2 km 457, 25190 Lleida', country: 'ES', lat: 41.6167, lng: 0.6333, totalSpaces: 150, hasSecurity: true, hasCamera: true, hasFence: true, hasToilets: true, hasShowers: true, hasRestaurant: true, hasShop: true, hasAdblue: true, hasWifi: true, pricePerNightEur: 15, isFree: false },
  { name: 'Area di Servizio Secchia Ovest', address: 'A1 km 162, 41058 Vignola', country: 'IT', lat: 44.4500, lng: 11.0000, totalSpaces: 180, hasSecurity: true, hasCamera: true, hasFence: true, hasToilets: true, hasShowers: true, hasRestaurant: true, hasShop: true, hasAdblue: true, hasWifi: true, pricePerNightEur: 20, isFree: false },
  { name: 'Truckparkplatz Innsbruck', address: 'Grabenweg 68, 6020 Innsbruck', country: 'AT', lat: 47.2500, lng: 11.3833, totalSpaces: 120, hasSecurity: true, hasCamera: true, hasFence: true, hasElectricity: true, hasWater: true, hasToilets: true, hasShowers: true, hasWifi: true, pricePerNightEur: 30, isFree: false },
  { name: 'OMV Velká Bíteš', address: 'D1 km 153, 595 01 Velká Bíteš', country: 'CZ', lat: 49.2833, lng: 16.2167, totalSpaces: 100, hasCamera: true, hasToilets: true, hasShowers: true, hasRestaurant: true, hasShop: true, hasAdblue: true, isFree: true },
  { name: 'MOL Töltőállomás Győr', address: 'M1 km 108, 9024 Győr', country: 'HU', lat: 47.6833, lng: 17.6333, totalSpaces: 130, hasSecurity: true, hasCamera: true, hasFence: true, hasToilets: true, hasShowers: true, hasRestaurant: true, hasShop: true, hasAdblue: true, hasWifi: true, pricePerNightEur: 12, isFree: false },
  { name: 'Petrom Peco Pitești', address: 'A1 km 109, 110224 Pitești', country: 'RO', lat: 44.8500, lng: 24.8667, totalSpaces: 80, hasSecurity: true, hasCamera: true, hasFence: true, hasToilets: true, hasShowers: true, hasRestaurant: true, hasShop: true, hasAdblue: true, hasWifi: true, pricePerNightEur: 8, isFree: false },
  { name: 'OMV Plovdiv', address: 'A1 km 132, 4000 Plovdiv', country: 'BG', lat: 42.1500, lng: 24.7500, totalSpaces: 70, hasSecurity: true, hasCamera: true, hasFence: true, hasToilets: true, hasShowers: true, hasRestaurant: true, hasShop: true, hasAdblue: true, pricePerNightEur: 6, isFree: false },
  { name: 'Circle K Truck Stop Kaunas', address: 'A1 km 102, 54340 Kaunas', country: 'LT', lat: 54.9000, lng: 23.9000, totalSpaces: 100, hasSecurity: true, hasCamera: true, hasFence: true, hasToilets: true, hasShowers: true, hasRestaurant: true, hasShop: true, hasAdblue: true, hasWifi: true, pricePerNightEur: 10, isFree: false },
  { name: 'Opet Petrol Edirne', address: 'D100 km 5, 22030 Edirne', country: 'TR', lat: 41.6667, lng: 26.5500, totalSpaces: 200, hasSecurity: true, hasCamera: true, hasFence: true, hasToilets: true, hasShowers: true, hasRestaurant: true, hasShop: true, hasAdblue: true, hasWifi: true, pricePerNightEur: 5, isFree: false },
  { name: 'Truckhaven Lymm Services', address: 'M6 J20, Lymm WA13 0SP', country: 'GB', lat: 53.3833, lng: -2.4667, totalSpaces: 120, hasSecurity: true, hasCamera: true, hasFence: true, hasElectricity: true, hasWater: true, hasToilets: true, hasShowers: true, hasRestaurant: true, hasShop: true, hasAdblue: true, hasWifi: true, pricePerNightEur: 30, isFree: false },
  { name: 'Donington Park Services', address: 'A50/M1, Castle Donington DE74 2TN', country: 'GB', lat: 52.8333, lng: -1.3667, totalSpaces: 200, hasSecurity: true, hasCamera: true, hasFence: true, hasElectricity: true, hasWater: true, hasToilets: true, hasShowers: true, hasRestaurant: true, hasShop: true, hasAdblue: true, hasWifi: true, pricePerNightEur: 28, isFree: false },
];

export default async function parkingRoutes(app: FastifyInstance) {
  // Seed parking data (admin endpoint)
  app.post('/seed', async (_request: FastifyRequest, reply: FastifyReply) => {
    const sql = getDb();
    let inserted = 0;
    let skipped = 0;

    for (const park of seedParkingData) {
      try {
        const existing = await sql`SELECT id FROM truck_parks WHERE name = ${park.name} AND country = ${park.country}`;
        if (existing.length > 0) { skipped++; continue; }

        await sql`
          INSERT INTO truck_parks (name, address, country, location, total_spaces, has_security, has_camera, has_fence, has_electricity, has_water, has_toilets, has_showers, has_restaurant, has_shop, has_adblue, has_wifi, price_per_night_eur, is_free, created_at)
          VALUES (${park.name}, ${park.address}, ${park.country}, ST_MakePoint(${park.lng}, ${park.lat})::geography, ${park.totalSpaces || null}, ${park.hasSecurity || false}, ${park.hasCamera || false}, ${park.hasFence || false}, ${park.hasElectricity || false}, ${park.hasWater || false}, ${park.hasToilets || false}, ${park.hasShowers || false}, ${park.hasRestaurant || false}, ${park.hasShop || false}, ${park.hasAdblue || false}, ${park.hasWifi || false}, ${park.pricePerNightEur || null}, ${park.isFree || false}, NOW())
        `;
        inserted++;
      } catch (e) { skipped++; }
    }

    return reply.send({ success: true, inserted, skipped, total: seedParkingData.length });
  });

  // Find truck parking near point
  app.get('/', async (request: FastifyRequest, reply: FastifyReply) => {
    const { lat, lng, radius_km } = request.query as {
      lat: string;
      lng: string;
      radius_km?: string;
    };
    const sql = getDb();

    const radiusMeters = parseFloat(radius_km || '50') * 1000;

    const parkings = await sql`
      SELECT id, name, address, country, total_spaces,
             has_security, has_camera, has_fence, has_electricity,
             has_water, has_toilets, has_showers, has_restaurant,
             has_shop, has_adblue, has_wifi,
             current_occupancy_pct, last_occupancy_update,
             avg_rating, total_reviews, price_per_night_eur, is_free,
             ST_X(location::geometry) as lng, ST_Y(location::geometry) as lat,
             ST_Distance(
               location,
               ST_SetSRID(ST_MakePoint(${parseFloat(lng)}, ${parseFloat(lat)}), 4326)::geography
             ) / 1000 as distance_km
      FROM truck_parks
      WHERE ST_DWithin(
        location,
        ST_SetSRID(ST_MakePoint(${parseFloat(lng)}, ${parseFloat(lat)}), 4326)::geography,
        ${radiusMeters}
      )
      ORDER BY distance_km
      LIMIT 50
    `;

    return reply.send({ parkings });
  });

  // Get parking details
  app.get('/:id', async (request: FastifyRequest, reply: FastifyReply) => {
    const { id } = request.params as { id: string };
    const sql = getDb();

    const [parking] = await sql`
      SELECT id, name, address, country, total_spaces,
             has_security, has_camera, has_fence, has_electricity,
             has_water, has_toilets, has_showers, has_restaurant,
             has_shop, has_adblue, has_wifi,
             current_occupancy_pct, last_occupancy_update,
             avg_rating, total_reviews, price_per_night_eur, is_free,
             ST_X(location::geometry) as lng, ST_Y(location::geometry) as lat
      FROM truck_parks
      WHERE id = ${id}
    `;

    if (!parking) {
      return reply.status(404).send({ error: 'Parking not found' });
    }

    return reply.send({ parking });
  });

  // Report current occupancy (crowdsourced)
  app.put('/:id/occupancy', {
    preHandler: [authenticate],
    handler: async (request: FastifyRequest, reply: FastifyReply) => {
      const { id } = request.params as { id: string };
      const body = updateOccupancySchema.parse(request.body);
      const sql = getDb();

      const [parking] = await sql`
        UPDATE truck_parks
        SET current_occupancy_pct = ${body.occupancy_pct},
            last_occupancy_update = NOW()
        WHERE id = ${id}
        RETURNING id, current_occupancy_pct, last_occupancy_update
      `;

      if (!parking) {
        return reply.status(404).send({ error: 'Parking not found' });
      }

      return reply.send({ parking });
    }
  });
}
