import { Hono } from 'hono';
import health from './health.js';
import api from './api.js';

const routes = new Hono();

// Root endpoint
routes.get('/', (c) => {
  return c.json({
    message: 'Hono Backend API',
    endpoints: {
      health: '/health',
      hello: '/api/hello',
      dbTest: '/api/db/test',
    },
  });
});

// Mount route handlers
routes.route('/health', health);
routes.route('/api', api);

export default routes;
