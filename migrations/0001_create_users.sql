 -- 2024-06-01: Initial migration to create users table
 -- This migration creates the "users" table with fields for user information, account type, KYC status, and timestamps.
 -- The "id" field is a UUID that serves as the primary key, and the "phone" and "email" fields are unique to prevent duplicates.
 -- The "account_type" field is constrained to either 'guardian_or_parent' or 'student', and the "kyc_status" field is constrained to 'none', 'pending', 'verified', or 'failed'.
 -- The "profile_pic" field is intended to store the URL of the user's profile picture, which will be hosted on Cloudflare R2.
 --- To apply this migration, run: `sqlx migrate run`
 -- To rollback this migration, run: `sqlx migrate revert`
 
 CREATE TABLE users (
  id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  phone            TEXT UNIQUE NOT NULL,
  name             TEXT,
  email            TEXT UNIQUE,
  account_type     TEXT NOT NULL CHECK (account_type IN ('guardian_or_parent', 'student')),
  profile_pic      TEXT,                         -- Cloudflare R2 URL
  language         TEXT DEFAULT 'english',
  is_admin         BOOLEAN DEFAULT FALSE,
  kyc_status       TEXT DEFAULT 'none' CHECK (kyc_status IN ('none','pending','verified','failed')),
  kyc_doc_type     TEXT,
  kyc_doc_url      TEXT,
  kyc_note         TEXT,
  created_at       TIMESTAMPTZ DEFAULT now(),
  updated_at       TIMESTAMPTZ DEFAULT now()
);