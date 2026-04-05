--- Migration: Create schools and school_fees tables
-- This migration creates the 'schools' table to store information about schools and the 'school_fees' table to manage fee structures for different class levels and terms.
-- The 'schools' table includes fields for the school's name, location, system type, partnership status, mobile money number, and school type.
-- The 'school_fees' table includes a foreign key reference to the 'schools' table, as well as fields for class level, term, fee purpose, amount, and due date.
-- To apply this migration, run: `sqlx migrate run`
-- To rollback this migration, run: `sqlx migrate revert`

CREATE TABLE schools (
  id             UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name           TEXT NOT NULL,
  town           TEXT NOT NULL,
  region         TEXT NOT NULL,
  system         TEXT CHECK (system IN ('anglophone', 'francophone')),
  partner_status TEXT CHECK (partner_status IN ('partnered','reachable','unknown')),
  momo_number    TEXT,
  type           TEXT CHECK (type IN ('grammar','technical','commercial')),
  created_at     TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE school_fees (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  school_id   UUID NOT NULL REFERENCES schools(id),
  class_level TEXT NOT NULL,
  term        TEXT NOT NULL,
  purpose     TEXT NOT NULL,                     -- Tuition, PTA, Boarding, etc.
  amount      INTEGER NOT NULL,                  -- FCFA
  due_date    DATE
);


ALTER TABLE children ADD CONSTRAINT children_school_id_fkey 
    FOREIGN KEY (school_id) REFERENCES schools(id);


CREATE INDEX schools_search_idx ON schools 
    USING GIN (to_tsvector('english', name || ' ' || town));

