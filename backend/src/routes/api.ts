import { Hono } from 'hono';
import { getPool } from '../db.js';

const api = new Hono();

// Simple hello endpoint
api.get('/hello', (c) => {
  return c.json({ message: 'Hello from Hono backend!' });
});

// Test database connection endpoint
api.get('/db/test', async (c) => {
  try {
    const pool = getPool();
    const result = await pool.query('SELECT NOW() as current_time, version() as pg_version');
    
    return c.json({
      success: true,
      data: {
        currentTime: result.rows[0].current_time,
        postgresVersion: result.rows[0].pg_version.split(' ')[0] + ' ' + result.rows[0].pg_version.split(' ')[1],
      },
    });
  } catch (error) {
    console.error('Database query failed:', error);
    return c.json(
      {
        success: false,
        error: error instanceof Error ? error.message : 'Unknown error',
      },
      500
    );
  }
});

export default api;
