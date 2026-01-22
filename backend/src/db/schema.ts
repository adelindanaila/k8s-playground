import { pgTable, serial, integer, timestamp } from 'drizzle-orm/pg-core';

export const counters = pgTable('counters', {
  id: serial('id').primaryKey(),
  value: integer('value').notNull().default(0),
  createdAt: timestamp('created_at').defaultNow().notNull(),
  updatedAt: timestamp('updated_at').defaultNow().notNull(),
});

export type Counter = typeof counters.$inferSelect;
export type NewCounter = typeof counters.$inferInsert;
