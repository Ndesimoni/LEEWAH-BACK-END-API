-- 2024-06-01: Initial migration to create children table
-- This migration creates the "children" table to store information about children associated with parent users.
-- The "id" field is a UUID that serves as the primary key, and the "parent_id" field is a foreign key referencing the "users" table, indicating the parent-child relationship.
-- The "full_name" field stores the child's full name, and the "class_level" field indicates the child's current class level.
-- The "school_id" field is a foreign key referencing the "schools" table, while the "school_name" field serves as a fallback in case the school is not in the database.
-- The "active_plan_id" field will be added as a foreign key after the "payment_plans" table is created, to link the child to their active subscription plan.
-- The "deleted_at" field allows for soft deletion of child records, while the "created_at" field automatically records when the child record was created.
--- To apply this migration, run: `sqlx migrate run`
-- To rollback this migration, run: `sqlx migrate revert`


CREATE TABLE children (
  id             UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  parent_id      UUID NOT NULL REFERENCES users(id),
  full_name      TEXT NOT NULL,
  class_level    TEXT NOT NULL,
  school_id UUID,  -- FK to schools added in 0004_create_schools.sql
  school_name    TEXT,                           -- fallback if school not in DB
  active_plan_id UUID,                           -- FK added after payment_plans
  deleted_at     TIMESTAMPTZ,                    -- soft delete
  created_at     TIMESTAMPTZ DEFAULT now()
);