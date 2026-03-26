Scaffold a new sqlx model struct for the Leewah API.

The user will provide a table name and the columns (or say "check the README for the schema").

Follow these steps:

1. If the schema is not provided, read `README.md` and find the relevant `CREATE TABLE` statement.
2. Read `src/models/` to understand the existing model structure before writing anything.
3. Create `src/models/<name>.rs` with:
   - A primary struct that maps 1:1 to the DB table (derive `sqlx::FromRow`, `serde::Serialize`, `Debug`)
   - A `Create<Name>` struct for insert operations (derive `serde::Deserialize`, `validator::Validate`)
   - An `Update<Name>` struct for partial updates where all fields are `Option<T>` (derive `serde::Deserialize`, `validator::Validate`)
   - A `<Name>Row` type alias if joins will return extra columns not in the base struct
4. Add the module to `src/models/mod.rs`.

Type mapping rules (Postgres → Rust):
- `UUID` → `uuid::Uuid`
- `TEXT` → `String`
- `INTEGER` → `i64`
- `BOOLEAN` → `bool`
- `TIMESTAMPTZ` → `time::OffsetDateTime`
- `DATE` → `time::Date`
- `JSONB` → `serde_json::Value`
- `TEXT NOT NULL` → `String` (never `Option`)
- `TEXT` (nullable) → `Option<String>`

Rules to follow:
- Never derive `Deserialize` on a DB model struct — use separate request DTOs in `src/types.rs`.
- Never expose `is_admin`, `token_hash`, or internal foreign keys directly in `Serialize` output — use `#[serde(skip)]` if needed.
- Use `#[serde(rename_all = "camelCase")]` on all serialized structs.
- Soft-deletable models must include `deleted_at: Option<time::OffsetDateTime>` and must never be returned in list queries without `WHERE deleted_at IS NULL`.

Show the complete file contents for each file created or modified.
