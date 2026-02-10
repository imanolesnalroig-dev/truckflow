import { FastifyInstance, FastifyRequest, FastifyReply } from 'fastify';
import { z } from 'zod';
import { v4 as uuid } from 'uuid';
import { getDb } from '../config/database.js';
import { getRedis } from '../config/redis.js';
import { authenticate } from '../middleware/auth.middleware.js';

const hazardTypes = ['police', 'accident', 'road_closure', 'construction', 'road_hazard', 'weather', 'border_delay'] as const;
const severities = ['low', 'medium', 'high', 'critical'] as const;

// Default TTL in hours per hazard type
const HAZARD_TTL: Record<string, number> = {
  police: 2,
  accident: 4,
  road_closure: 24,
  construction: 168, // 7 days
  road_hazard: 12,
  weather: 6,
  border_delay: 4
};

const createHazardSchema = z.object({
  lat: z.number().min(-90).max(90),
  lng: z.number().min(-180).max(180),
  hazard_type: z.enum(hazardTypes),
  subtype: z.string().max(50).optional(),
  description: z.string().max(500).optional(),
  severity: z.enum(severities).default('medium'),
  direction: z.number().min(0).max(360).optional()
});

export default async function hazardRoutes(app: FastifyInstance) {
  // Get active hazards in bounding box
  app.get('/', async (request: FastifyRequest, reply: FastifyReply) => {
    const { bbox, types } = request.query as { bbox?: string; types?: string };
    const sql = getDb();

    let query = sql`
      SELECT id, hazard_type, subtype, description, severity, direction,
             ST_X(location::geometry) as lng, ST_Y(location::geometry) as lat,
             created_at, expires_at, confirmed_count, denied_count
      FROM hazard_reports
      WHERE is_active = true AND expires_at > NOW()
    `;

    if (bbox) {
      const [lat1, lng1, lat2, lng2] = bbox.split(',').map(Number);
      query = sql`
        SELECT id, hazard_type, subtype, description, severity, direction,
               ST_X(location::geometry) as lng, ST_Y(location::geometry) as lat,
               created_at, expires_at, confirmed_count, denied_count
        FROM hazard_reports
        WHERE is_active = true
          AND expires_at > NOW()
          AND ST_Within(
            location::geometry,
            ST_MakeEnvelope(${lng1}, ${lat1}, ${lng2}, ${lat2}, 4326)
          )
      `;
    }

    const hazards = await query;

    // Filter by types if specified
    let filtered = hazards;
    if (types) {
      const typeList = types.split(',');
      filtered = hazards.filter((h: { hazard_type: string }) => typeList.includes(h.hazard_type));
    }

    return reply.send({ hazards: filtered });
  });

  // Report new hazard
  app.post('/', {
    preHandler: [authenticate],
    handler: async (request: FastifyRequest, reply: FastifyReply) => {
      const { userId } = request.user as { userId: string };
      const body = createHazardSchema.parse(request.body);
      const sql = getDb();

      const ttlHours = HAZARD_TTL[body.hazard_type] || 4;
      const expiresAt = new Date(Date.now() + ttlHours * 60 * 60 * 1000);

      const [hazard] = await sql`
        INSERT INTO hazard_reports (
          id, user_id, location, hazard_type, subtype, description,
          severity, direction, expires_at
        )
        VALUES (
          ${uuid()},
          ${userId},
          ST_SetSRID(ST_MakePoint(${body.lng}, ${body.lat}), 4326)::geography,
          ${body.hazard_type},
          ${body.subtype || null},
          ${body.description || null},
          ${body.severity},
          ${body.direction || null},
          ${expiresAt.toISOString()}
        )
        RETURNING id, hazard_type, subtype, severity, created_at, expires_at
      `;

      // Update user's report count
      await sql`
        UPDATE users SET total_reports = total_reports + 1 WHERE id = ${userId}
      `;

      // Invalidate nearby hazards cache
      const redis = getRedis();
      const cacheKey = `hazards:${Math.floor(body.lat)}:${Math.floor(body.lng)}`;
      await redis.del(cacheKey);

      return reply.status(201).send({ hazard });
    }
  });

  // Confirm hazard (still there)
  app.put('/:id/confirm', {
    preHandler: [authenticate],
    handler: async (request: FastifyRequest, reply: FastifyReply) => {
      const { id } = request.params as { id: string };
      const sql = getDb();

      // Increment confirmed count and extend expiry by 50%
      const [hazard] = await sql`
        UPDATE hazard_reports
        SET confirmed_count = confirmed_count + 1,
            expires_at = NOW() + (expires_at - created_at) * 0.5
        WHERE id = ${id} AND is_active = true
        RETURNING id, confirmed_count, denied_count, expires_at
      `;

      if (!hazard) {
        return reply.status(404).send({ error: 'Hazard not found' });
      }

      return reply.send({ hazard });
    }
  });

  // Deny hazard (not there anymore)
  app.put('/:id/deny', {
    preHandler: [authenticate],
    handler: async (request: FastifyRequest, reply: FastifyReply) => {
      const { id } = request.params as { id: string };
      const sql = getDb();

      // Increment denied count
      await sql`
        UPDATE hazard_reports
        SET denied_count = denied_count + 1
        WHERE id = ${id} AND is_active = true
      `;

      // Check if should deactivate (deny > confirm and total > 3)
      const [hazard] = await sql`
        UPDATE hazard_reports
        SET is_active = CASE
          WHEN denied_count > confirmed_count AND (denied_count + confirmed_count) > 3
          THEN false
          ELSE is_active
        END
        WHERE id = ${id}
        RETURNING id, is_active, confirmed_count, denied_count
      `;

      if (!hazard) {
        return reply.status(404).send({ error: 'Hazard not found' });
      }

      return reply.send({ hazard });
    }
  });
}
