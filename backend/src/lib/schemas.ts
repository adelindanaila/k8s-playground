import { z } from 'zod';

export const CounterUpdateSchema = z.object({
  value: z.number().int().min(0),
});

export type CounterUpdate = z.infer<typeof CounterUpdateSchema>;

// Response schema with date serialization
export const CounterResponseSchema = z.object({
  id: z.number(),
  value: z.number(),
  createdAt: z.string().datetime(), // Serialize as ISO string for JSON
  updatedAt: z.string().datetime(), // Serialize as ISO string for JSON
});

export type CounterResponse = z.infer<typeof CounterResponseSchema>;
