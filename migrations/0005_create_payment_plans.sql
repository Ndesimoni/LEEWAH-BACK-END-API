--- Migration: Create payment_plans and fee_payments tables
-- This migration creates the 'payment_plans' table to manage payment plans for school fees and the 'fee_payments' table to track individual payments made towards those plans.
-- The 'payment_plans' table includes fields for the child and school references, total fee amount, installment details, academic year, and status of the plan.
-- The 'fee_payments' table includes a reference to the payment plan, payment amount, method, status, and timestamps for when payments were made and disbursed to schools.
-- To apply this migration, run: `sqlx migrate run`
-- To rollback this migration, run: `sqlx migrate revert`


CREATE TABLE payment_plans (
  id                   UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  child_id             UUID NOT NULL REFERENCES children(id),
  school_id            UUID REFERENCES schools(id),
  total_fee_amount     INTEGER NOT NULL,
  plan_type            TEXT NOT NULL CHECK (plan_type IN ('daily','weekly','monthly')),
  installment_amount   INTEGER NOT NULL,
  amount_paid          INTEGER DEFAULT 0,
  amount_remaining     INTEGER GENERATED ALWAYS AS (total_fee_amount - amount_paid) STORED,
  next_due_date        DATE NOT NULL,
  academic_year_start  DATE,
  academic_year_end    DATE,
  status               TEXT DEFAULT 'active' CHECK (status IN ('active','paused','completed','stopped')),
  created_at           TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE fee_payments (
  id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  plan_id             UUID NOT NULL REFERENCES payment_plans(id),
  amount              INTEGER NOT NULL,
  method              TEXT CHECK (method IN ('wallet','mtn_momo','orange_money')),
  status              TEXT DEFAULT 'pending' CHECK (status IN ('pending','confirmed','failed')),
  paid_at             TIMESTAMPTZ,
  momo_ref            TEXT,                      -- external MoMo reference
  receipt_ref         TEXT UNIQUE DEFAULT 'SF-' || substr(md5(random()::text), 1, 8),
  disbursed_to_school BOOLEAN DEFAULT FALSE,
  disbursed_at        TIMESTAMPTZ,
  created_at          TIMESTAMPTZ DEFAULT now()
);