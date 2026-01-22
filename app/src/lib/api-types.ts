// This file will be generated from the OpenAPI spec
// Run: pnpm generate-api-types (after backend is running)
// Or manually: openapi-typescript http://localhost:3000/openapi -o src/lib/api-types.ts

// Placeholder types - will be replaced by generated types
export interface paths {
  '/api/counter': {
    get: {
      responses: {
        200: {
          content: {
            'application/json': {
              id: number;
              value: number;
              createdAt: string;
              updatedAt: string;
            };
          };
        };
      };
    };
    put: {
      requestBody: {
        content: {
          'application/json': {
            value: number;
          };
        };
      };
      responses: {
        200: {
          content: {
            'application/json': {
              id: number;
              value: number;
              createdAt: string;
              updatedAt: string;
            };
          };
        };
      };
    };
  };
  '/api/counter/increment': {
    post: {
      responses: {
        200: {
          content: {
            'application/json': {
              id: number;
              value: number;
              createdAt: string;
              updatedAt: string;
            };
          };
        };
      };
    };
  };
  '/api/counter/reset': {
    post: {
      responses: {
        200: {
          content: {
            'application/json': {
              id: number;
              value: number;
              createdAt: string;
              updatedAt: string;
            };
          };
        };
      };
    };
  };
}
