# Stage 1: Build the backend
FROM node:20-alpine AS builder

WORKDIR /app

# Copy package files
COPY backend/package.json backend/pnpm-lock.yaml* ./

# Install pnpm if needed, then dependencies
RUN corepack enable && corepack prepare pnpm@latest --activate
RUN pnpm install --frozen-lockfile

# Copy source code and config files
COPY backend/src ./src
COPY backend/tsconfig.json ./
COPY backend/drizzle.config.ts ./
# Ensure routes directory structure is preserved

# Build TypeScript
RUN pnpm run build

# Stage 2: Runtime
FROM node:20-alpine

WORKDIR /app

# Copy package files
COPY backend/package.json backend/pnpm-lock.yaml* ./

# Install pnpm if needed, then production dependencies
RUN corepack enable && corepack prepare pnpm@latest --activate
RUN pnpm install --frozen-lockfile --prod

# Copy built files from builder
COPY --from=builder /app/dist ./dist
# Copy drizzle config and schema files for drizzle-kit push at runtime
COPY backend/drizzle.config.ts ./
COPY backend/src/db ./src/db
# Copy migration script
COPY backend/scripts/migrate.sh ./scripts/migrate.sh
RUN chmod +x ./scripts/migrate.sh

# Expose port
EXPOSE 3000

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD node -e "require('http').get('http://localhost:3000/health', (r) => {process.exit(r.statusCode === 200 ? 0 : 1)})"

# Start the server
CMD ["node", "dist/index.js"]
