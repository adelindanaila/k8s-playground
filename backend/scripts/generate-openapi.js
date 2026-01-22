import { writeFileSync } from 'fs';
import { fileURLToPath } from 'url';
import { dirname, join } from 'path';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

// This script will be run after the backend is built
// It starts a temporary server, fetches the OpenAPI spec, and saves it
// For now, we'll create a placeholder that can be extended

const openapiSpec = {
  openapi: '3.0.0',
  info: {
    title: 'K8s Playground API',
    version: '1.0.0',
    description: 'Counter API with PostgreSQL backend',
  },
  servers: [
    { url: 'http://localhost:3000', description: 'API Server' },
  ],
  paths: {},
};

// Write the spec to a file that can be used by the frontend
const outputPath = join(__dirname, '../../openapi.json');
writeFileSync(outputPath, JSON.stringify(openapiSpec, null, 2));
console.log(`OpenAPI spec written to ${outputPath}`);
