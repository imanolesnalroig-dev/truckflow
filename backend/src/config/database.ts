import postgres from 'postgres';
import { config } from './index.js';

let sql: ReturnType<typeof postgres>;

export async function setupDatabase() {
  sql = postgres(config.databaseUrl, {
    max: 20,
    idle_timeout: 20,
    connect_timeout: 10,
    types: {
      // Handle PostGIS geography type
      geography: {
        to: 4326,
        from: [4326],
        serialize: (x: { lat: number; lng: number }) => `POINT(${x.lng} ${x.lat})`,
        parse: (x: string) => {
          const match = x.match(/POINT\(([-\d.]+) ([-\d.]+)\)/);
          if (match) {
            return { lng: parseFloat(match[1]), lat: parseFloat(match[2]) };
          }
          return null;
        }
      }
    }
  });

  // Test connection
  try {
    await sql`SELECT 1`;
    console.log('✅ Database connected');
  } catch (error) {
    console.error('❌ Database connection failed:', error);
    throw error;
  }

  return sql;
}

export function getDb() {
  if (!sql) {
    throw new Error('Database not initialized. Call setupDatabase() first.');
  }
  return sql;
}

export { sql };
