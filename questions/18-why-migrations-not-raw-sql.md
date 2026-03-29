## Question
We already have the database schema in the README. Why don't we just run those SQL statements directly in PostgreSQL once and be done with it? Why do we need migration files instead?

## Answer
"Something goes wrong — and new developers look at the schema to know what to create"

## Full Explanation
Three reasons migrations are better than running SQL manually:

**1. New developer joins the team**
They clone the repo and run `docker-compose up`. The database is empty. Without migrations they'd have to manually copy-paste SQL from the README — possibly missing tables, getting the order wrong, or using an outdated version. With migrations they just run `sqlx migrate run` and ALL tables are created automatically in the correct order.

**2. Adding a column 3 months from now**
Production already has real user data. You can't drop and recreate the table. You create a NEW migration file `0002_add_column.sql` that only runs on databases that don't have it yet. Production data is safe — existing rows get the column added, nothing is dropped or lost.

**3. Something goes wrong**
Each migration is numbered and tracked. The database records exactly which migrations have run in a `_sqlx_migrations` table. You can see the full history and know exactly what state the database is in.

**The analogy:**
Migrations are like git commits for your database. Each one is a small, numbered, tracked change. You never lose history and you can always see exactly what changed and when.

**The tool:**
`sqlx-cli` is the command line tool that runs migrations:
```bash
sqlx migrate run    # run all pending migrations
sqlx migrate revert # undo the last migration
sqlx migrate info   # see which migrations have run
```
