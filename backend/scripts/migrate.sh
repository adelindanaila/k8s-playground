#!/bin/sh
set -e

echo "🔄 Running database migrations..."

# Run drizzle-kit push to sync schema
pnpm db:push

echo "✅ Database migrations completed successfully"
