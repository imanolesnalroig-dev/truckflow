import { FastifyInstance, FastifyRequest, FastifyReply } from 'fastify';
import { z } from 'zod';
import bcrypt from 'bcryptjs';
import { v4 as uuid } from 'uuid';
import { getDb } from '../config/database.js';

const registerSchema = z.object({
  email: z.string().email(),
  password: z.string().min(8),
  display_name: z.string().min(2).max(100),
  language: z.string().length(2).default('en'),
  country: z.string().length(2).optional()
});

const loginSchema = z.object({
  email: z.string().email(),
  password: z.string()
});

export default async function authRoutes(app: FastifyInstance) {
  // Register
  app.post('/register', async (request: FastifyRequest, reply: FastifyReply) => {
    const body = registerSchema.parse(request.body);
    const sql = getDb();

    // Check if user exists
    const existing = await sql`SELECT id FROM users WHERE email = ${body.email}`;
    if (existing.length > 0) {
      return reply.status(409).send({ error: 'Email already registered' });
    }

    // Hash password
    const passwordHash = await bcrypt.hash(body.password, 12);

    // Create user
    const [user] = await sql`
      INSERT INTO users (id, email, password_hash, display_name, language, country)
      VALUES (${uuid()}, ${body.email}, ${passwordHash}, ${body.display_name}, ${body.language}, ${body.country || null})
      RETURNING id, email, display_name, language, country, created_at
    `;

    // Generate tokens
    const token = app.jwt.sign({ userId: user.id, email: user.email });
    const refreshToken = app.jwt.sign(
      { userId: user.id, type: 'refresh' },
      { expiresIn: '30d' }
    );

    return reply.status(201).send({
      user,
      token,
      refreshToken
    });
  });

  // Login
  app.post('/login', async (request: FastifyRequest, reply: FastifyReply) => {
    const body = loginSchema.parse(request.body);
    const sql = getDb();

    // Find user
    const [user] = await sql`
      SELECT id, email, password_hash, display_name, language, country
      FROM users WHERE email = ${body.email} AND is_active = true
    `;

    if (!user) {
      return reply.status(401).send({ error: 'Invalid credentials' });
    }

    // Verify password
    const valid = await bcrypt.compare(body.password, user.password_hash);
    if (!valid) {
      return reply.status(401).send({ error: 'Invalid credentials' });
    }

    // Generate tokens
    const token = app.jwt.sign({ userId: user.id, email: user.email });
    const refreshToken = app.jwt.sign(
      { userId: user.id, type: 'refresh' },
      { expiresIn: '30d' }
    );

    // Remove password hash from response
    const { password_hash, ...userWithoutPassword } = user;

    return reply.send({
      user: userWithoutPassword,
      token,
      refreshToken
    });
  });

  // Refresh token
  app.post('/refresh', async (request: FastifyRequest, reply: FastifyReply) => {
    const { refreshToken } = request.body as { refreshToken: string };

    try {
      const decoded = app.jwt.verify(refreshToken) as { userId: string; type: string };

      if (decoded.type !== 'refresh') {
        return reply.status(401).send({ error: 'Invalid refresh token' });
      }

      const sql = getDb();
      const [user] = await sql`
        SELECT id, email FROM users WHERE id = ${decoded.userId} AND is_active = true
      `;

      if (!user) {
        return reply.status(401).send({ error: 'User not found' });
      }

      const token = app.jwt.sign({ userId: user.id, email: user.email });
      const newRefreshToken = app.jwt.sign(
        { userId: user.id, type: 'refresh' },
        { expiresIn: '30d' }
      );

      return reply.send({ token, refreshToken: newRefreshToken });
    } catch {
      return reply.status(401).send({ error: 'Invalid refresh token' });
    }
  });
}
