import { Hono } from 'hono';
import { testConnection } from '../db.js';

const health = new Hono();

// Health check endpoint (includes DB connection check)
health.get('/', async (c) => {
  try {
    const dbConnected = await testConnection();
    
    if (dbConnected) {
      return c.json({ status: 'healthy', database: 'connected' }, 200);
    } else {
      return c.json({ status: 'unhealthy', database: 'disconnected' }, 503);
    }
  } catch (error) {
    console.error('Health check error:', error);
    return c.json({ 
      status: 'unhealthy', 
      database: 'error',
      error: error instanceof Error ? error.message : 'Unknown error'
    }, 503);
  }
});

export default health;
