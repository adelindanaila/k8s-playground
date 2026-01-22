# Stage 1: Build the backend
FROM node:20-alpine AS builder

WORKDIR /app

# Copy package files
COPY backend/package.json ./

# Install dependencies
RUN npm install

# Copy source code (excluding node_modules)
COPY backend/src ./src
COPY backend/tsconfig.json ./
# Ensure routes directory structure is preserved

# Build TypeScript
RUN npm run build

# Stage 2: Runtime
FROM node:20-alpine

WORKDIR /app

# Copy package files
COPY backend/package.json ./

# Install only production dependencies
RUN npm install --omit=dev

# Copy built files from builder
COPY --from=builder /app/dist ./dist

# Expose port
EXPOSE 3000

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD node -e "require('http').get('http://localhost:3000/health', (r) => {process.exit(r.statusCode === 200 ? 0 : 1)})"

# Start the server
CMD ["node", "dist/index.js"]
