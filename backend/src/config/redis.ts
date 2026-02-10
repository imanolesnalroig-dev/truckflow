import Redis from 'ioredis';
import { config } from './index.js';

let redis: Redis;

export async function setupRedis() {
  redis = new Redis(config.redisUrl, {
    maxRetriesPerRequest: 3,
    retryStrategy(times) {
      const delay = Math.min(times * 50, 2000);
      return delay;
    }
  });

  redis.on('connect', () => {
    console.log('✅ Redis connected');
  });

  redis.on('error', (error) => {
    console.error('❌ Redis error:', error);
  });

  // Test connection
  await redis.ping();

  return redis;
}

export function getRedis() {
  if (!redis) {
    throw new Error('Redis not initialized. Call setupRedis() first.');
  }
  return redis;
}

// Cache helpers
export const cache = {
  async get<T>(key: string): Promise<T | null> {
    const data = await redis.get(key);
    return data ? JSON.parse(data) : null;
  },

  async set(key: string, value: unknown, ttlSeconds?: number): Promise<void> {
    const json = JSON.stringify(value);
    if (ttlSeconds) {
      await redis.setex(key, ttlSeconds, json);
    } else {
      await redis.set(key, json);
    }
  },

  async del(key: string): Promise<void> {
    await redis.del(key);
  },

  async exists(key: string): Promise<boolean> {
    return (await redis.exists(key)) === 1;
  }
};

export { redis };
