import { Pool, PoolConfig } from 'pg';
import { drizzle } from 'drizzle-orm/node-postgres';
import * as schema from './db/schema.js';

let pool: Pool | null = null;
let dbInstance: ReturnType<typeof drizzle> | null = null;

export function getPool(): Pool {
  if (!pool) {
    const config: PoolConfig = {
      host: process.env.POSTGRES_HOST || 'postgresql',
      port: parseInt(process.env.POSTGRES_PORT || '5432', 10),
      database: process.env.POSTGRES_DB || 'postgres',
      user: process.env.POSTGRES_USER || 'postgres',
      password: process.env.POSTGRES_PASSWORD || '',
      max: 20, // Maximum number of clients in the pool
      idleTimeoutMillis: 30000,
      connectionTimeoutMillis: 5000, // Increased timeout for initial connection
    };

    console.log(`Connecting to PostgreSQL at ${config.host}:${config.port}/${config.database} as ${config.user}`);

    pool = new Pool(config);

    // Handle pool errors (don't crash on connection errors)
    pool.on('error', (err) => {
      console.error('Unexpected error on idle client', err);
    });
  }

  return pool;
}

export function getDb() {
  if (!dbInstance) {
    const pool = getPool();
    dbInstance = drizzle({ client: pool, schema });
  }
  return dbInstance;
}

export async function testConnection(): Promise<boolean> {
  try {
    const pool = getPool();
    const result = await pool.query('SELECT NOW()');
    return result.rows.length > 0;
  } catch (error) {
    console.error('Database connection test failed:', error);
    return false;
  }
}

export async function closePool(): Promise<void> {
  if (pool) {
    await pool.end();
    pool = null;
  }
}
