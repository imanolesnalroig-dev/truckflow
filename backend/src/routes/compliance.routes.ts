import { FastifyInstance, FastifyRequest, FastifyReply } from 'fastify';
import { v4 as uuid } from 'uuid';
import { getDb } from '../config/database.js';
import { authenticate } from '../middleware/auth.middleware.js';

// EC 561/2006 Driving Time Rules
const RULES = {
  MAX_CONTINUOUS_DRIVING_MIN: 270, // 4.5 hours
  BREAK_DURATION_MIN: 45,
  MAX_DAILY_DRIVING_MIN: 540, // 9 hours (can extend to 10h twice/week)
  MAX_EXTENDED_DAILY_MIN: 600, // 10 hours
  MIN_DAILY_REST_MIN: 660, // 11 hours
  MIN_REDUCED_DAILY_REST_MIN: 540, // 9 hours
  MAX_WEEKLY_DRIVING_MIN: 3360, // 56 hours
  MAX_BIWEEKLY_DRIVING_MIN: 5400, // 90 hours
};

export default async function complianceRoutes(app: FastifyInstance) {
  // Get current driving time status
  app.get('/status', {
    preHandler: [authenticate],
    handler: async (request: FastifyRequest, reply: FastifyReply) => {
      const { userId } = request.user as { userId: string };
      const sql = getDb();

      // Get active session
      const [activeSession] = await sql`
        SELECT * FROM driving_sessions
        WHERE user_id = ${userId} AND ended_at IS NULL
        ORDER BY started_at DESC
        LIMIT 1
      `;

      // Get today's total driving
      const [todayStats] = await sql`
        SELECT COALESCE(SUM(total_driving_min), 0) as today_driving
        FROM driving_sessions
        WHERE user_id = ${userId}
          AND DATE(started_at) = CURRENT_DATE
      `;

      // Get this week's total driving (Monday to Sunday)
      const [weekStats] = await sql`
        SELECT COALESCE(SUM(total_driving_min), 0) as week_driving
        FROM driving_sessions
        WHERE user_id = ${userId}
          AND started_at >= date_trunc('week', CURRENT_DATE)
      `;

      const currentContinuousDriving = activeSession?.total_driving_min || 0;
      const todayDriving = parseInt(todayStats.today_driving) + currentContinuousDriving;
      const weekDriving = parseInt(weekStats.week_driving) + currentContinuousDriving;

      // Find nearest parking if break needed soon
      let nearestParking = null;
      if (currentContinuousDriving >= RULES.MAX_CONTINUOUS_DRIVING_MIN - 30) {
        // TODO: Get driver's current location and find nearest parking
        // For now, return null
      }

      return reply.send({
        is_driving: !!activeSession && !activeSession.ended_at,
        session_started_at: activeSession?.started_at || null,
        current_driving_min: currentContinuousDriving,
        max_driving_before_break: RULES.MAX_CONTINUOUS_DRIVING_MIN,
        time_until_break_min: Math.max(0, RULES.MAX_CONTINUOUS_DRIVING_MIN - currentContinuousDriving),
        daily_driving_min: todayDriving,
        max_daily_driving_min: RULES.MAX_DAILY_DRIVING_MIN,
        weekly_driving_min: weekDriving,
        max_weekly_driving_min: RULES.MAX_WEEKLY_DRIVING_MIN,
        next_required_break_min: currentContinuousDriving >= RULES.MAX_CONTINUOUS_DRIVING_MIN
          ? RULES.BREAK_DURATION_MIN
          : 0,
        next_daily_rest_min: RULES.MIN_DAILY_REST_MIN,
        violations: detectViolations(currentContinuousDriving, todayDriving, weekDriving),
        nearest_parking: nearestParking
      });
    }
  });

  // Start driving session
  app.post('/start', {
    preHandler: [authenticate],
    handler: async (request: FastifyRequest, reply: FastifyReply) => {
      const { userId } = request.user as { userId: string };
      const sql = getDb();

      // Check if there's already an active session
      const [existing] = await sql`
        SELECT id FROM driving_sessions
        WHERE user_id = ${userId} AND ended_at IS NULL
      `;

      if (existing) {
        return reply.status(409).send({
          error: 'Active session already exists',
          session_id: existing.id
        });
      }

      const [session] = await sql`
        INSERT INTO driving_sessions (id, user_id, started_at)
        VALUES (${uuid()}, ${userId}, NOW())
        RETURNING id, started_at
      `;

      return reply.status(201).send({ session });
    }
  });

  // Stop driving session (break/rest)
  app.post('/stop', {
    preHandler: [authenticate],
    handler: async (request: FastifyRequest, reply: FastifyReply) => {
      const { userId } = request.user as { userId: string };
      const sql = getDb();

      const [session] = await sql`
        UPDATE driving_sessions
        SET ended_at = NOW(),
            total_driving_min = EXTRACT(EPOCH FROM (NOW() - started_at)) / 60
        WHERE user_id = ${userId} AND ended_at IS NULL
        RETURNING id, started_at, ended_at, total_driving_min
      `;

      if (!session) {
        return reply.status(404).send({ error: 'No active session found' });
      }

      return reply.send({ session });
    }
  });

  // Get driving history
  app.get('/history', {
    preHandler: [authenticate],
    handler: async (request: FastifyRequest, reply: FastifyReply) => {
      const { userId } = request.user as { userId: string };
      const { days } = request.query as { days?: string };
      const daysNum = days ? parseInt(days) : 7;
      const sql = getDb();

      const sessions = await sql`
        SELECT id, started_at, ended_at, total_driving_min, total_break_min,
               distance_km, is_compliant, violations
        FROM driving_sessions
        WHERE user_id = ${userId}
          AND started_at >= NOW() - INTERVAL '1 day' * ${daysNum}
        ORDER BY started_at DESC
      `;

      // Aggregate by day
      const dailySummary = await sql`
        SELECT DATE(started_at) as date,
               SUM(total_driving_min) as total_driving,
               SUM(total_break_min) as total_break,
               SUM(distance_km) as total_distance,
               COUNT(*) as session_count
        FROM driving_sessions
        WHERE user_id = ${userId}
          AND started_at >= NOW() - INTERVAL '1 day' * ${daysNum}
        GROUP BY DATE(started_at)
        ORDER BY date DESC
      `;

      return reply.send({ sessions, daily_summary: dailySummary });
    }
  });
}

function detectViolations(
  continuousDriving: number,
  dailyDriving: number,
  weeklyDriving: number
): string[] {
  const violations: string[] = [];

  if (continuousDriving > RULES.MAX_CONTINUOUS_DRIVING_MIN) {
    violations.push(`Exceeded max continuous driving (${continuousDriving}/${RULES.MAX_CONTINUOUS_DRIVING_MIN} min)`);
  }

  if (dailyDriving > RULES.MAX_EXTENDED_DAILY_MIN) {
    violations.push(`Exceeded max daily driving (${dailyDriving}/${RULES.MAX_EXTENDED_DAILY_MIN} min)`);
  }

  if (weeklyDriving > RULES.MAX_WEEKLY_DRIVING_MIN) {
    violations.push(`Exceeded max weekly driving (${weeklyDriving}/${RULES.MAX_WEEKLY_DRIVING_MIN} min)`);
  }

  return violations;
}
