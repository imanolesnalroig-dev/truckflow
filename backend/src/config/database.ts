import postgres from 'postgres';
import { config } from './index.js';

let sql: ReturnType<typeof postgres>;

// Parse Cloud SQL connection string with Unix socket support
function parseConnectionString(url: string) {
  const parsed = new URL(url);
  const hostParam = parsed.searchParams.get('host');

  const options: Record<string, unknown> = {
    user: parsed.username,
    password: parsed.password,
    database: parsed.pathname.slice(1) || 'postgres',
    max: 20,
    idle_timeout: 20,
    connect_timeout: 10,
  };

  // If host query param starts with /, it's a Unix socket path
  if (hostParam && hostParam.startsWith('/')) {
    options.host = hostParam;
  } else if (parsed.hostname) {
    options.host = parsed.hostname;
    options.port = parseInt(parsed.port || '5432');
  }

  return options;
}

export async function setupDatabase() {
  const connectionOptions = parseConnectionString(config.databaseUrl);

  console.log('Connecting to database:', {
    host: connectionOptions.host,
    database: connectionOptions.database,
    user: connectionOptions.user
  });

  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  sql = postgres(connectionOptions as any);

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
