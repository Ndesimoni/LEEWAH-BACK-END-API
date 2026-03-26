Create a new numbered SQL migration file for the Leewah API.

The user will describe what the migration should do.

Follow these steps:

1. Run `ls migrations/` to find the highest existing migration number.
2. Create `migrations/<next_number>_<snake_case_description>.sql` with the migration SQL.
3. If the migration adds a table, include:
   - `CREATE TABLE IF NOT EXISTS`
   - Primary key as `UUID PRIMARY KEY DEFAULT gen_random_uuid()`
   - `created_at TIMESTAMPTZ DEFAULT now()` on every table
   - `updated_at TIMESTAMPTZ DEFAULT now()` on tables that will be updated
   - All CHECK constraints for enum-like TEXT columns
   - All foreign key constraints with `ON DELETE CASCADE` or `ON DELETE RESTRICT` as appropriate
4. If the migration adds an index, use `CREATE INDEX IF NOT EXISTS`.
5. If the migration alters an existing table, use `ALTER TABLE ... ADD COLUMN IF NOT EXISTS`.
6. Always add a comment block at the top of the file explaining what the migration does and why.

Rules to follow:
- Never modify an existing migration file — always create a new one.
- Never use `DROP TABLE` or `DROP COLUMN` without explicit user confirmation.
- Never use `TRUNCATE` in a migration.
- All text enum columns must have a `CHECK` constraint listing allowed values.
- Monetary amounts are always `INTEGER NOT NULL` (FCFA, no decimals, no nulls).
- Use `GENERATED ALWAYS AS (...) STORED` for computed columns (e.g. `amount_remaining`).
- Add a GIN index for any column used in full-text search.
- Add a partial index (`WHERE deleted_at IS NULL`) for soft-deletable tables.

Show the full migration file content after creating it.
