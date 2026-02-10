import 'dotenv/config';

export const config = {
  // Server
  port: parseInt(process.env.PORT || '3000', 10),
  nodeEnv: process.env.NODE_ENV || 'development',

  // Database
  databaseUrl: process.env.DATABASE_URL || 'postgres://truckflow:dev_password@localhost:5432/truckflow',

  // Redis
  redisUrl: process.env.REDIS_URL || 'redis://localhost:6379',

  // Kafka
  kafkaBrokers: (process.env.KAFKA_BROKERS || 'localhost:9092').split(','),
  kafkaClientId: 'truckflow-api',
  kafkaGroupId: 'truckflow-consumers',

  // Valhalla routing engine
  valhallaUrl: process.env.VALHALLA_URL || 'http://localhost:8002',

  // Google AI (Gemini)
  geminiApiKey: process.env.GEMINI_API_KEY || '',

  // Google Places API
  googlePlacesApiKey: process.env.GOOGLE_PLACES_API_KEY || '',

  // JWT
  jwtSecret: process.env.JWT_SECRET || 'dev_jwt_secret_change_in_production',
  jwtExpiresIn: process.env.JWT_EXPIRES_IN || '7d',
  jwtRefreshExpiresIn: process.env.JWT_REFRESH_EXPIRES_IN || '30d',

  // Google OAuth
  googleClientId: process.env.GOOGLE_CLIENT_ID || '',
  googleClientSecret: process.env.GOOGLE_CLIENT_SECRET || '',
} as const;

// Validate required config in production
if (config.nodeEnv === 'production') {
  const required = ['jwtSecret', 'databaseUrl', 'geminiApiKey'] as const;
  for (const key of required) {
    if (!config[key]) {
      throw new Error(`Missing required environment variable for ${key}`);
    }
  }
}
