--  Initial migration to create authentication tables
-- This migration creates the "refresh_tokens" table to store hashed refresh tokens for user authentication.
-- The "id" field is a UUID that serves as the primary key, and the "user_id" field is a foreign key referencing the "users" table, with cascading deletes to maintain referential integrity.
-- The "token_hash" field stores the hashed value of the refresh token, and the "expires_at" field indicates when the token will expire.
-- The "created_at" field automatically records when the token was created.
--- To apply this migration, run: `sqlx migrate run`
-- To rollback this migration, run: `sqlx migrate revert`


CREATE TABLE refresh_tokens (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id     UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  token_hash  TEXT NOT NULL,
  expires_at  TIMESTAMPTZ NOT NULL,
  created_at  TIMESTAMPTZ DEFAULT now()
);


--  Create device_tokens table
-- This migration creates the "device_tokens" table to store device tokens for push notifications.
-- The "id" field is a UUID that serves as the primary key, and the "user_id" field is a foreign key referencing the "users" table, with cascading deletes to maintain referential integrity.
-- The "token" field stores the unique device token, and the "platform" field indicates whether the device is running iOS or Android.
-- The "created_at" field automatically records when the device token was created.
--- To apply this migration, run: `sqlx migrate run`
-- To rollback this migration, run: `sqlx migrate revert`
CREATE TABLE device_tokens (
  id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id    UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  token      TEXT UNIQUE NOT NULL,
  platform   TEXT CHECK (platform IN ('ios', 'android')),
  created_at TIMESTAMPTZ DEFAULT now()
);