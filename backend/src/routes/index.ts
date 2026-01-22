import { Hono } from 'hono';
import { openAPIRouteHandler } from 'hono-openapi';
import { swaggerUI } from '@hono/swagger-ui';
import health from './health.js';
import api from './api.js';
import counter from './counter.js';

const routes = new Hono();

// Root endpoint
routes.get('/', (c) => {
  return c.json({
    message: 'Hono Backend API',
    endpoints: {
      health: '/health',
      hello: '/api/hello',
      dbTest: '/api/db/test',
      counter: '/api/counter',
      openapi: '/openapi',
      swaggerUI: '/ui',
    },
  });
});

// OpenAPI documentation endpoint
routes.get(
  '/openapi',
  openAPIRouteHandler(routes, {
    documentation: {
      info: {
        title: 'K8s Playground API',
        version: '1.0.0',
        description: 'Counter API with PostgreSQL backend',
      },
      servers: [
        { 
          url: process.env.API_BASE_URL || 'http://localhost:3000', 
          description: 'API Server' 
        },
      ],
    },
  })
);

// Swagger UI endpoint
routes.get('/ui', swaggerUI({ url: '/openapi' }));

// Mount route handlers
routes.route('/health', health);
routes.route('/api', api);
routes.route('/api/counter', counter);

export default routes;
