import { FastifyInstance, FastifyRequest, FastifyReply } from 'fastify';
import { z } from 'zod';
import { getDb } from '../config/database.js';
import { authenticate } from '../middleware/auth.middleware.js';

const updateProfileSchema = z.object({
  display_name: z.string().min(2).max(100).optional(),
  language: z.string().length(2).optional(),
  country: z.string().length(2).optional()
});

export default async function userRoutes(app: FastifyInstance) {
  // Get current user profile
  app.get('/me', {
    preHandler: [authenticate],
    handler: async (request: FastifyRequest, reply: FastifyReply) => {
      const { userId } = request.user as { userId: string };
      const sql = getDb();

      const [user] = await sql`
        SELECT id, email, display_name, language, country, created_at,
               reputation_score, total_km_driven, total_reports, total_reviews
        FROM users
        WHERE id = ${userId} AND is_active = true
      `;

      if (!user) {
        return reply.status(404).send({ error: 'User not found' });
      }

      return reply.send({ user });
    }
  });

  // Update profile
  app.put('/me', {
    preHandler: [authenticate],
    handler: async (request: FastifyRequest, reply: FastifyReply) => {
      const { userId } = request.user as { userId: string };
      const body = updateProfileSchema.parse(request.body);
      const sql = getDb();

      const [user] = await sql`
        UPDATE users
        SET display_name = COALESCE(${body.display_name}, display_name),
            language = COALESCE(${body.language}, language),
            country = COALESCE(${body.country}, country),
            updated_at = NOW()
        WHERE id = ${userId}
        RETURNING id, email, display_name, language, country, updated_at
      `;

      return reply.send({ user });
    }
  });

  // Get user stats
  app.get('/me/stats', {
    preHandler: [authenticate],
    handler: async (request: FastifyRequest, reply: FastifyReply) => {
      const { userId } = request.user as { userId: string };
      const sql = getDb();

      const [stats] = await sql`
        SELECT
          u.reputation_score,
          u.total_km_driven,
          u.total_reports,
          u.total_reviews,
          (SELECT COUNT(*) FROM driving_sessions WHERE user_id = ${userId}) as total_sessions,
          (SELECT COALESCE(SUM(distance_km), 0) FROM driving_sessions WHERE user_id = ${userId}) as total_distance,
          (SELECT COALESCE(SUM(total_driving_min), 0) FROM driving_sessions WHERE user_id = ${userId}) as total_driving_minutes
        FROM users u
        WHERE u.id = ${userId}
      `;

      return reply.send({ stats });
    }
  });
}
