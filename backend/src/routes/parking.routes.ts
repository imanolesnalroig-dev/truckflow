import { FastifyInstance, FastifyRequest, FastifyReply } from 'fastify';
import { z } from 'zod';
import { getDb } from '../config/database.js';
import { authenticate } from '../middleware/auth.middleware.js';

const updateOccupancySchema = z.object({
  occupancy_pct: z.number().min(0).max(100)
});

export default async function parkingRoutes(app: FastifyInstance) {
  // Find truck parking near point
  app.get('/', async (request: FastifyRequest, reply: FastifyReply) => {
    const { lat, lng, radius_km = 50 } = request.query as {
      lat: string;
      lng: string;
      radius_km?: string;
    };
    const sql = getDb();

    const radiusMeters = parseFloat(radius_km) * 1000;

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
