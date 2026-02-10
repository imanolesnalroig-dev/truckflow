import postgres from 'postgres';
import { config } from './index.js';

let sql: ReturnType<typeof postgres>;

// Parse Cloud SQL connection string with Unix socket support
// Handles URLs like: postgres://user:pass@/database?host=/cloudsql/...
function parseConnectionString(url: string) {
  const options: Record<string, unknown> = {
    max: 20,
    idle_timeout: 20,
    connect_timeout: 10,
  };

  // Extract query params first
  const queryStart = url.indexOf('?');
  let queryParams = new URLSearchParams();
  if (queryStart !== -1) {
    queryParams = new URLSearchParams(url.slice(queryStart + 1));
  }

  // Parse the main URL parts manually since URL class doesn't handle postgres://user:pass@/db
  const withoutProtocol = url.replace(/^postgres:\/\//, '');
  const pathStart = withoutProtocol.indexOf('/');
  const authAndHost = pathStart !== -1 ? withoutProtocol.slice(0, pathStart) : withoutProtocol;
  const pathAndQuery = pathStart !== -1 ? withoutProtocol.slice(pathStart) : '';

  // Extract auth (user:pass)
  const atIndex = authAndHost.indexOf('@');
  if (atIndex !== -1) {
    const auth = authAndHost.slice(0, atIndex);
    const colonIndex = auth.indexOf(':');
    if (colonIndex !== -1) {
      options.user = decodeURIComponent(auth.slice(0, colonIndex));
      options.password = decodeURIComponent(auth.slice(colonIndex + 1));
    } else {
      options.user = decodeURIComponent(auth);
    }

    // Host comes after @
    const hostPart = authAndHost.slice(atIndex + 1);
    if (hostPart) {
      const colonIdx = hostPart.lastIndexOf(':');
      if (colonIdx !== -1 && !hostPart.includes('[')) {
        options.host = hostPart.slice(0, colonIdx);
        options.port = parseInt(hostPart.slice(colonIdx + 1));
      } else {
        options.host = hostPart;
      }
    }
  }

  // Extract database from path
  const dbPath = pathAndQuery.split('?')[0];
  if (dbPath && dbPath !== '/') {
    options.database = dbPath.slice(1); // Remove leading /
  }

  // Check for Unix socket in host query param
  const hostParam = queryParams.get('host');
  if (hostParam && hostParam.startsWith('/')) {
    options.host = hostParam;
    delete options.port; // Unix sockets don't use port
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
