# 09 — Database Migrations

## What are Migrations?

Migrations are numbered SQL files that create and modify your database schema over time. They are the professional way to manage database changes — instead of running SQL manually, you write migration files that run automatically and are tracked.

Think of migrations like **git commits for your database**. Each one is a small, numbered, tracked change. You never lose history.

---

## Why Not Just Run SQL Manually?

Three reasons:

**1. New developer joins the team**
They clone the repo and run `sqlx migrate run`. ALL tables are created automatically in the correct order. No manual copy-pasting, no missing tables, no guessing.

**2. Adding columns/tables later**
Production already has real user data. You can't drop and recreate tables. You create a NEW migration file that safely adds the change without touching existing data.

**3. Something goes wrong**
Each migration is numbered and tracked. The database knows exactly which migrations have run. You can see the full history anytime with `sqlx migrate info`.

---

## What is a Checksum?

A checksum is a unique fingerprint of a file's contents.

When sqlx runs a migration, it calculates a checksum of the SQL file and stores it in the `_sqlx_migrations` table alongside the migration record.

Next time you run `sqlx migrate run`, it recalculates the checksum of every previously applied migration and compares it to what's stored. If they don't match — the file was modified — sqlx refuses to run and throws an error:

```
error: migration 1 was previously applied but has been modified
```

This protects you from accidentally running different SQL than what ran on production.

**The analogy:** A checksum is like a wax seal on a letter. If anyone opens and reseals it, the seal looks different and you know it was tampered with.

---

## The Golden Rule

**Never modify a migration file after it has been applied to ANY database.**

| State | Can you edit? |
|---|---|
| Created but not yet run | ✅ Yes — edit freely |
| Already run with `sqlx migrate run` | ❌ Never — create a new migration instead |

---

## How to Make Changes After a Migration Has Run

Create a NEW migration file:

```sql
-- 0011_add_users_fcm_token.sql
-- Adding FCM token field for push notifications

ALTER TABLE users ADD COLUMN fcm_token TEXT;
```

Never touch the original `0001_create_users.sql` again.

---

## The `_sqlx_migrations` Table

sqlx automatically creates this table in your database. It records every migration that has been applied:

| version | description | installed_on | success | checksum |
|---|---|---|---|---|
| 1 | create users | 2026-03-29 | TRUE | abc123... |
| 2 | create auth tables | 2026-03-29 | TRUE | def456... |

This is how sqlx knows which migrations to skip and which are still pending.

---

## Essential Commands

```bash
# Run all pending migrations
sqlx migrate run --database-url postgres://leewah:leewah@localhost:5432/leewah

# Check which migrations have run and which are pending
sqlx migrate info --database-url postgres://leewah:leewah@localhost:5432/leewah

# Undo the last migration
sqlx migrate revert --database-url postgres://leewah:leewah@localhost:5432/leewah
```

---

## Leewah Migration Files

| File | Tables Created |
|---|---|
| `0001_create_users.sql` | users |
| `0002_create_auth_tables.sql` | refresh_tokens, device_tokens |
| `0003_create_children.sql` | children |
| `0004_create_schools.sql` | schools, school_fees |
| `0005_create_payment_plans.sql` | payment_plans, fee_payments |
| `0006_create_wallets.sql` | wallets, wallet_transactions |
| `0007_create_campaigns.sql` | campaigns, donations |
| `0008_create_papers.sql` | papers |
| `0009_create_peer_reviews.sql` | peer_reviews |
| `0010_create_notifications.sql` | notifications |

---

## Key Things to Remember

1. **Migrations are like git commits for your database** — numbered, tracked, permanent
2. **`sqlx migrate run`** applies all pending migrations in order
3. **A checksum is a fingerprint** — sqlx uses it to detect if a migration file was modified after being applied
4. **Never modify an applied migration** — always create a new one for changes
5. **`_sqlx_migrations` table** tracks every migration that has run
6. **Order matters** — `0002` can reference tables from `0001` because it runs after
