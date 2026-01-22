import createClient from 'openapi-fetch';
import type { paths } from './api-types';

const API_BASE_URL = import.meta.env.VITE_API_URL || '';

// Create OpenAPI client - fully type-safe based on generated OpenAPI spec
export const apiClient = createClient<paths>({
  baseUrl: API_BASE_URL,
});

// Export types for convenience
export type Counter = paths['/api/counter']['get']['responses']['200']['content']['application/json'];
