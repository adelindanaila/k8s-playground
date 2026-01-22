import { Hono } from 'hono';
import { serve } from '@hono/node-server';
import routes from './routes/index.js';

// Handle unhandled promise rejections
process.on('unhandledRejection', (reason, promise) => {
  console.error('Unhandled Rejection at:', promise, 'reason:', reason);
});

process.on('uncaughtException', (error) => {
  console.error('Uncaught Exception:', error);
  process.exit(1);
});

const app = new Hono();

// Mount all routes
app.route('/', routes);

const PORT = parseInt(process.env.PORT || '3000', 10);

// Start server
console.log(`Server starting on port ${PORT}...`);

const server = serve({
  fetch: app.fetch,
  port: PORT,
});

console.log(`Server running on port ${PORT}`);

// Handle graceful shutdown
process.on('SIGTERM', () => {
  console.log('SIGTERM received, shutting down gracefully...');
  server.close((err) => {
    if (err) {
      console.error(err);
      process.exit(1);
    }
    process.exit(0);
  });
});

process.on('SIGINT', () => {
  console.log('SIGINT received, shutting down gracefully...');
  server.close((err) => {
    if (err) {
      console.error(err);
      process.exit(1);
    }
    process.exit(0);
  });
});
