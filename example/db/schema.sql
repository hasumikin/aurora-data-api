/*
 * This file was automatically genarated by the command:
 *   aurora-data-api export --models app/models --output db/schema.sql
 *
 * Genarated at 2022-05-31 10:24:29 +0900
 *
 * https://github.com/hasumikin/aurora-data-api
 */

CREATE TABLE "users" (
  "id" bigint NOT NULL GENERATED ALWAYS AS IDENTITY,
  "name" text,
  "internet_account" text,
  "created_at" timestamp with time zone NOT NULL,
  "updated_at" timestamp with time zone NOT NULL,
  PRIMARY KEY ("id")
);

CREATE TABLE "comments" (
  "id" bigint NOT NULL GENERATED ALWAYS AS IDENTITY,
  "user_id" bigint NOT NULL,
  "entry_id" bigint NOT NULL,
  "body" text,
  "created_at" timestamp with time zone NOT NULL,
  "updated_at" timestamp with time zone NOT NULL,
  PRIMARY KEY ("id")
);

CREATE TABLE "entries" (
  "id" bigint NOT NULL GENERATED ALWAYS AS IDENTITY,
  "user_id" bigint NOT NULL,
  "title" text,
  "body" text,
  "created_at" timestamp with time zone NOT NULL,
  "updated_at" timestamp with time zone NOT NULL,
  PRIMARY KEY ("id")
);

ALTER TABLE ONLY "comments" ADD CONSTRAINT "comments_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users" ("id");
ALTER TABLE ONLY "comments" ADD CONSTRAINT "comments_entry_id_fkey" FOREIGN KEY ("entry_id") REFERENCES "entries" ("id");
ALTER TABLE ONLY "entries" ADD CONSTRAINT "entries_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users" ("id");