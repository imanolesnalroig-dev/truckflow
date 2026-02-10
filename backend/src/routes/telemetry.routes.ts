import { FastifyInstance, FastifyRequest, FastifyReply } from 'fastify';
import { z } from 'zod';
import { sendGpsPings } from '../config/kafka.js';
import { authenticate } from '../middleware/auth.middleware.js';

const gpsPingSchema = z.object({
  timestamp: z.string().datetime(),
  lat: z.number().min(-90).max(90),
  lng: z.number().min(-180).max(180),
  speed_kmh: z.number().min(0).max(300),
  heading: z.number().min(0).max(360),
  accuracy_m: z.number().min(0).max(1000)
});

const batchTelemetrySchema = z.object({
  pings: z.array(gpsPingSchema).min(1).max(100)
});

export default async function telemetryRoutes(app: FastifyInstance) {
  // Batch upload GPS pings - THE MOST CRITICAL ENDPOINT
  // This receives the highest traffic. Must be blazing fast.
  // Validate, push to Kafka, return 202. No DB writes in request path.
  app.post('/batch', {
    preHandler: [authenticate],
    handler: async (request: FastifyRequest, reply: FastifyReply) => {
      const { userId } = request.user as { userId: string };
      const body = batchTelemetrySchema.parse(request.body);

      // Push to Kafka for async processing
      await sendGpsPings(userId, body.pings);

      // Return 202 Accepted immediately
      return reply.status(202).send({
        accepted: true,
        count: body.pings.length,
        timestamp: new Date().toISOString()
      });
    }
  });
}
