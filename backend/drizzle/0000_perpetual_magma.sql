CREATE TABLE "counters" (
	"id" serial PRIMARY KEY NOT NULL,
	"value" integer DEFAULT 0 NOT NULL,
	"created_at" timestamp DEFAULT now() NOT NULL,
	"updated_at" timestamp DEFAULT now() NOT NULL
);
