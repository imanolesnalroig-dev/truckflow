import { FastifyInstance, FastifyRequest, FastifyReply } from 'fastify';
import { z } from 'zod';
import { v4 as uuid } from 'uuid';
import { getDb } from '../config/database.js';
import { authenticate } from '../middleware/auth.middleware.js';

const truckProfileSchema = z.object({
  name: z.string().min(1).max(100),
  height_cm: z.number().int().min(100).max(500),
  weight_kg: z.number().int().min(1000).max(60000),
  length_cm: z.number().int().min(200).max(2500),
  width_cm: z.number().int().min(150).max(300).optional(),
  axle_count: z.number().int().min(2).max(10).optional(),
  axle_weight_kg: z.number().int().min(1000).max(15000).optional(),
  has_trailer: z.boolean().default(true),
  trailer_type: z.enum(['tilt', 'reefer', 'mega', 'tank', 'flatbed', 'container', 'other']).optional(),
  hazmat_class: z.string().max(20).optional(),
  emission_class: z.enum(['euro3', 'euro4', 'euro5', 'euro6', 'euro6d']).optional()
});

export default async function truckRoutes(app: FastifyInstance) {
  // List user's truck profiles
  app.get('/', {
    preHandler: [authenticate],
    handler: async (request: FastifyRequest, reply: FastifyReply) => {
      const { userId } = request.user as { userId: string };
      const sql = getDb();

      const trucks = await sql`
        SELECT * FROM truck_profiles
        WHERE user_id = ${userId}
        ORDER BY is_default DESC, created_at DESC
      `;

      return reply.send({ trucks });
    }
  });

  // Create truck profile
  app.post('/', {
    preHandler: [authenticate],
    handler: async (request: FastifyRequest, reply: FastifyReply) => {
      const { userId } = request.user as { userId: string };
      const body = truckProfileSchema.parse(request.body);
      const sql = getDb();

      // Check if this is the first truck (make it default)
      const existing = await sql`SELECT id FROM truck_profiles WHERE user_id = ${userId}`;
      const isDefault = existing.length === 0;

      const [truck] = await sql`
        INSERT INTO truck_profiles (
          id, user_id, name, height_cm, weight_kg, length_cm, width_cm,
          axle_count, axle_weight_kg, has_trailer, trailer_type,
          hazmat_class, emission_class, is_default
        )
        VALUES (
          ${uuid()}, ${userId}, ${body.name}, ${body.height_cm}, ${body.weight_kg},
          ${body.length_cm}, ${body.width_cm || 260}, ${body.axle_count || 5},
          ${body.axle_weight_kg || 10000}, ${body.has_trailer},
          ${body.trailer_type || null}, ${body.hazmat_class || null},
          ${body.emission_class || null}, ${isDefault}
        )
        RETURNING *
      `;

      return reply.status(201).send({ truck });
    }
  });

  // Update truck profile
  app.put('/:id', {
    preHandler: [authenticate],
    handler: async (request: FastifyRequest, reply: FastifyReply) => {
      const { userId } = request.user as { userId: string };
      const { id } = request.params as { id: string };
      const body = truckProfileSchema.partial().parse(request.body);
      const sql = getDb();

      const [truck] = await sql`
        UPDATE truck_profiles
        SET name = COALESCE(${body.name ?? null}, name),
            height_cm = COALESCE(${body.height_cm ?? null}, height_cm),
            weight_kg = COALESCE(${body.weight_kg ?? null}, weight_kg),
            length_cm = COALESCE(${body.length_cm ?? null}, length_cm),
            width_cm = COALESCE(${body.width_cm ?? null}, width_cm),
            axle_count = COALESCE(${body.axle_count ?? null}, axle_count),
            axle_weight_kg = COALESCE(${body.axle_weight_kg ?? null}, axle_weight_kg),
            has_trailer = COALESCE(${body.has_trailer ?? null}, has_trailer),
            trailer_type = COALESCE(${body.trailer_type ?? null}, trailer_type),
            hazmat_class = COALESCE(${body.hazmat_class ?? null}, hazmat_class),
            emission_class = COALESCE(${body.emission_class ?? null}, emission_class)
        WHERE id = ${id} AND user_id = ${userId}
        RETURNING *
      `;

      if (!truck) {
        return reply.status(404).send({ error: 'Truck profile not found' });
      }

      return reply.send({ truck });
    }
  });

  // Delete truck profile
  app.delete('/:id', {
    preHandler: [authenticate],
    handler: async (request: FastifyRequest, reply: FastifyReply) => {
      const { userId } = request.user as { userId: string };
      const { id } = request.params as { id: string };
      const sql = getDb();

      const result = await sql`
        DELETE FROM truck_profiles
        WHERE id = ${id} AND user_id = ${userId}
        RETURNING id
      `;

      if (result.length === 0) {
        return reply.status(404).send({ error: 'Truck profile not found' });
      }

      return reply.status(204).send();
    }
  });

  // Set as default
  app.put('/:id/default', {
    preHandler: [authenticate],
    handler: async (request: FastifyRequest, reply: FastifyReply) => {
      const { userId } = request.user as { userId: string };
      const { id } = request.params as { id: string };
      const sql = getDb();

      // Unset current default
      await sql`
        UPDATE truck_profiles SET is_default = false WHERE user_id = ${userId}
      `;

      // Set new default
      const [truck] = await sql`
        UPDATE truck_profiles
        SET is_default = true
        WHERE id = ${id} AND user_id = ${userId}
        RETURNING *
      `;

      if (!truck) {
        return reply.status(404).send({ error: 'Truck profile not found' });
      }

      return reply.send({ truck });
    }
  });
}
