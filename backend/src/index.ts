import Fastify from 'fastify';
import cors from '@fastify/cors';
import helmet from '@fastify/helmet';
import jwt from '@fastify/jwt';
import rateLimit from '@fastify/rate-limit';
import websocket from '@fastify/websocket';
import { config } from './config/index.js';
import { setupDatabase } from './config/database.js';
import { setupRedis } from './config/redis.js';
import { setupKafka } from './config/kafka.js';

// Routes
import authRoutes from './routes/auth.routes.js';
import userRoutes from './routes/user.routes.js';
import truckRoutes from './routes/truck.routes.js';
import routeRoutes from './routes/route.routes.js';
import telemetryRoutes from './routes/telemetry.routes.js';
import hazardRoutes from './routes/hazard.routes.js';
import locationRoutes from './routes/location.routes.js';
import parkingRoutes from './routes/parking.routes.js';
import complianceRoutes from './routes/compliance.routes.js';

const app = Fastify({
  logger: {
    level: config.nodeEnv === 'production' ? 'info' : 'debug',
    transport: config.nodeEnv === 'development' ? {
      target: 'pino-pretty',
      options: { colorize: true }
    } : undefined
  }
});

async function bootstrap() {
  try {
    // Security plugins
    await app.register(helmet);
    await app.register(cors, {
      origin: config.nodeEnv === 'production'
        ? ['https://truckflow.app']
        : true,
      credentials: true
    });
    await app.register(rateLimit, {
      max: 100,
      timeWindow: '1 minute'
    });

    // JWT Authentication
    await app.register(jwt, {
      secret: config.jwtSecret,
      sign: { expiresIn: config.jwtExpiresIn }
    });

    // WebSocket for real-time hazard updates
    await app.register(websocket);

    // Initialize connections (graceful - don't crash if they fail)
    try {
      await setupDatabase();
      app.log.info('Database connected');
    } catch (err) {
      app.log.warn({ err }, 'Database connection failed - some features may not work');
    }

    try {
      await setupRedis();
      app.log.info('Redis connected');
    } catch (err) {
      app.log.warn({ err }, 'Redis connection failed - caching disabled');
    }

    try {
      await setupKafka();
      app.log.info('Kafka connected');
    } catch (err) {
      app.log.warn({ err }, 'Kafka connection failed - telemetry disabled');
    }

    // Health check
    app.get('/health', async () => ({ status: 'ok', timestamp: new Date().toISOString() }));

    // API Routes
    await app.register(authRoutes, { prefix: '/api/v1/auth' });
    await app.register(userRoutes, { prefix: '/api/v1/users' });
    await app.register(truckRoutes, { prefix: '/api/v1/trucks' });
    await app.register(routeRoutes, { prefix: '/api/v1/route' });
    await app.register(telemetryRoutes, { prefix: '/api/v1/telemetry' });
    await app.register(hazardRoutes, { prefix: '/api/v1/hazards' });
    await app.register(locationRoutes, { prefix: '/api/v1/locations' });
    await app.register(parkingRoutes, { prefix: '/api/v1/parking' });
    await app.register(complianceRoutes, { prefix: '/api/v1/compliance' });

    // Start server
    await app.listen({ port: config.port, host: '0.0.0.0' });
    app.log.info(`TruckFlow API running on http://localhost:${config.port}`);

  } catch (error) {
    app.log.error(error);
    process.exit(1);
  }
}

// Graceful shutdown
const signals: NodeJS.Signals[] = ['SIGINT', 'SIGTERM'];
signals.forEach(signal => {
  process.on(signal, async () => {
    app.log.info(`Received ${signal}, shutting down gracefully...`);
    await app.close();
    process.exit(0);
  });
});

bootstrap();

export default app;
