import { Hono } from 'hono';
import { describeRoute, resolver } from 'hono-openapi';
import { zValidator } from '@hono/zod-validator';
import { eq } from 'drizzle-orm';
import { getDb } from '../db.js';
import { counters } from '../db/schema.js';
import { CounterUpdateSchema, CounterResponseSchema } from '../lib/schemas.js';

const counter = new Hono();

// Helper to serialize dates for JSON response
const serializeCounter = (c: typeof counters.$inferSelect) => ({
  id: c.id,
  value: c.value,
  createdAt: c.createdAt.toISOString(),
  updatedAt: c.updatedAt.toISOString(),
});

// Get current counter value
counter.get(
  '/',
  describeRoute({
    description: 'Get the current counter value',
    responses: {
      200: {
        description: 'Current counter value',
        content: {
          'application/json': {
            schema: resolver(CounterResponseSchema),
          },
        },
      },
      500: {
        description: 'Server error',
      },
    },
  }),
  async (c) => {
    try {
      const db = getDb();
      
      // Get or create counter (id=1)
      let counter = await db.select().from(counters).where(eq(counters.id, 1)).limit(1);
      
      if (counter.length === 0) {
        // Initialize counter if it doesn't exist
        const newCounter = await db.insert(counters).values({ value: 0 }).returning();
        return c.json(serializeCounter(newCounter[0]));
      }
      
      return c.json(serializeCounter(counter[0]));
    } catch (error) {
      console.error('Failed to get counter:', error);
      return c.json(
        {
          error: error instanceof Error ? error.message : 'Unknown error',
        },
        500
      );
    }
  }
);

// Increment counter by 1
counter.post(
  '/increment',
  describeRoute({
    description: 'Increment the counter by 1',
    responses: {
      200: {
        description: 'Counter incremented successfully',
        content: {
          'application/json': {
            schema: resolver(CounterResponseSchema),
          },
        },
      },
      500: {
        description: 'Server error',
      },
    },
  }),
  async (c) => {
    try {
      const db = getDb();
      
      // Get current counter or create if doesn't exist
      let counter = await db.select().from(counters).where(eq(counters.id, 1)).limit(1);
      
      if (counter.length === 0) {
        // Initialize counter
        const newCounter = await db.insert(counters).values({ value: 1 }).returning();
        return c.json(serializeCounter(newCounter[0]));
      }
      
      // Increment and update
      const updated = await db
        .update(counters)
        .set({ 
          value: counter[0].value + 1,
          updatedAt: new Date(),
        })
        .where(eq(counters.id, 1))
        .returning();
      
      return c.json(serializeCounter(updated[0]));
    } catch (error) {
      console.error('Failed to increment counter:', error);
      return c.json(
        {
          error: error instanceof Error ? error.message : 'Unknown error',
        },
        500
      );
    }
  }
);

// Reset counter to 0
counter.post(
  '/reset',
  describeRoute({
    description: 'Reset the counter to 0',
    responses: {
      200: {
        description: 'Counter reset successfully',
        content: {
          'application/json': {
            schema: resolver(CounterResponseSchema),
          },
        },
      },
      500: {
        description: 'Server error',
      },
    },
  }),
  async (c) => {
    try {
      const db = getDb();
      
      // Get current counter or create if doesn't exist
      let counter = await db.select().from(counters).where(eq(counters.id, 1)).limit(1);
      
      if (counter.length === 0) {
        // Initialize counter
        const newCounter = await db.insert(counters).values({ value: 0 }).returning();
        return c.json(serializeCounter(newCounter[0]));
      }
      
      // Reset to 0
      const updated = await db
        .update(counters)
        .set({ 
          value: 0,
          updatedAt: new Date(),
        })
        .where(eq(counters.id, 1))
        .returning();
      
      return c.json(serializeCounter(updated[0]));
    } catch (error) {
      console.error('Failed to reset counter:', error);
      return c.json(
        {
          error: error instanceof Error ? error.message : 'Unknown error',
        },
        500
      );
    }
  }
);

// Set counter to specific value (validated with Zod)
counter.put(
  '/',
  describeRoute({
    description: 'Set the counter to a specific value',
    responses: {
      200: {
        description: 'Counter updated successfully',
        content: {
          'application/json': {
            schema: resolver(CounterResponseSchema),
          },
        },
      },
      400: {
        description: 'Invalid request body',
      },
      500: {
        description: 'Server error',
      },
    },
  }),
  zValidator('json', CounterUpdateSchema),
  async (c) => {
    try {
      const { value } = c.req.valid('json');
      const db = getDb();
      
      // Get current counter or create if doesn't exist
      let counter = await db.select().from(counters).where(eq(counters.id, 1)).limit(1);
      
      if (counter.length === 0) {
        // Initialize counter with specified value
        const newCounter = await db.insert(counters).values({ value }).returning();
        return c.json(serializeCounter(newCounter[0]));
      }
      
      // Update to specified value
      const updated = await db
        .update(counters)
        .set({ 
          value,
          updatedAt: new Date(),
        })
        .where(eq(counters.id, 1))
        .returning();
      
      return c.json(serializeCounter(updated[0]));
    } catch (error) {
      console.error('Failed to set counter:', error);
      return c.json(
        {
          error: error instanceof Error ? error.message : 'Unknown error',
        },
        500
      );
    }
  }
);

export default counter;
