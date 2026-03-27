# CLAUDE.md — Leewah API Rules & Best Practices

This file is read automatically by Claude Code on every session.
Follow every rule here without being asked.

---

## What is Leewah?

Leewah is a Cameroonian fintech mobile app built with React Native. It helps parents save and pay school fees in installments instead of one lump sum — solving a major financial pain point for families in Cameroon.

**Core features:**
- Phone-based OTP authentication (no passwords)
- School fee payment plans (daily / weekly / monthly installments)
- Wallet system (top up via MTN MoMo or Orange Money, pay from wallet)
- School directory with fee structures
- Donation campaigns for students and schools
- Past exam questions (O-Level, A-Level, BEPC, etc.)
- Peer review system for exam practice
- Push notifications (Firebase FCM)
- AI assistant (proxied Anthropic API, SSE streaming)
- Live chat support (WebSocket)
- Admin panel API

**Target market:** Parents and students in Cameroon (Anglophone and Francophone)

**Payment providers:** MTN Mobile Money + Orange Money (local Cameroon providers)

**Currency:** FCFA (Central African Franc) — always integers, never decimals

---

## Collaboration Context

- The developer is **learning Rust and Axum for the first time** through this project
- This is a **paired programming** setup — explain the why behind every decision, not just the what
- Always ask the developer a question when introducing a new concept to make them think first
- After completing each major step, update `learning-notes/` with a detailed explanation of what was built and why
- Keep explanations grounded in the Leewah project — avoid generic examples when a project-specific one works better

---

## Current Progress (update this as sprints complete)

- [x] Dependencies added to Cargo.toml
- [x] README.md with full architecture, schema, and sprint plan
- [x] CLAUDE.md (this file) with rules and project context
- [x] Custom skills: `/new-route`, `/new-model`, `/new-migration`, `/check`, `/review`
- [x] .gitignore
- [x] rust-toolchain.toml
- [x] .env.example
- [x] docker-compose.yml
- [ ] Cargo.toml lints section
- [ ] .github/workflows/ci.yml
- [ ] src/main.rs (async Axum server boot)
- [ ] src/config.rs
- [ ] src/error.rs
- [ ] src/db.rs
- [ ] src/middleware/ (auth, rate_limit)
- [ ] src/routes/ (all route modules)
- [ ] src/models/ (all model structs)
- [ ] src/services/ (all service modules)
- [ ] src/types.rs
- [ ] migrations/ (all SQL migration files)

---

## Key Decisions Made

| Decision | Choice | Reason |
|---|---|---|
| Language | Rust | Memory safe, fast binary, cheap to host |
| Framework | Axum 0.8 | Modern, async-native, built on Tokio |
| DB driver | sqlx (no ORM) | Compile-time checked SQL, no ORM bloat |
| Auth | OTP via SMS, not passwords | Phone-first UX for Cameroonian market |
| File storage | Cloudflare R2 | S3-compatible, cheaper than AWS S3 |
| IDs | UUID v4 | Standard, no sequential ID enumeration attacks |
| Amounts | Integer FCFA only | No float rounding errors on money |
| Soft deletes | `deleted_at` timestamp | Payment history must stay intact |

---

## Project Overview

- **Language**: Rust (edition 2024)
- **Framework**: Axum 0.8
- **Database**: PostgreSQL via sqlx 0.8 (compile-time checked queries)
- **Cache**: Redis (OTP, rate limiting, idempotency, response caching)
- **Auth**: JWT (access tokens 15min) + refresh tokens (30 days, hash stored in DB)
- **File storage**: Cloudflare R2 via aws-sdk-s3
- **Background jobs**: tokio-cron-scheduler
- **Deployment target**: Fly.io or Railway

---

## Project Structure

```
src/
├── main.rs           # Server boot, router assembly only
├── config.rs         # All env vars loaded once at startup
├── error.rs          # Unified AppError enum → IntoResponse
├── db.rs             # PgPool setup
├── middleware/       # auth.rs, rate_limit.rs
├── routes/           # One file per domain (auth, users, children, ...)
├── models/           # sqlx FromRow structs matching DB rows
├── services/         # Business logic — zero HTTP types here
└── types.rs          # Shared enums, request/response DTOs
migrations/           # Numbered SQL files only — no Rust migrations
```

---

## Code Rules

### General

- Never use `unwrap()` or `expect()` in request handlers or service code. Use `?` with `AppError`.
- Never use `panic!` in request path code.
- Never hardcode secrets, URLs, or credentials. All config comes from environment variables via `config.rs`.
- Never log sensitive data: passwords, OTP codes, JWT tokens, MoMo references, phone numbers in full.
- All handler functions must return `Result<Json<T>, AppError>` or `Result<impl IntoResponse, AppError>`.
- Keep handlers thin — validate input, call a service function, return the result. No business logic in route files.
- Services must have zero Axum/HTTP imports. They receive plain Rust types and return `Result<T, AppError>`.

### Error Handling

- All errors flow through `AppError` defined in `src/error.rs`.
- Map external errors to `AppError::Internal(anyhow::Error)` using `.map_err(AppError::internal)` or `?` with `From` impl.
- Never return raw sqlx or redis errors to the client.
- HTTP status codes are set once in `AppError`'s `IntoResponse` impl — not scattered across handlers.
- Always return structured JSON errors: `{ "error": "message" }`.

```rust
// Correct
pub enum AppError {
    Unauthorized,
    Forbidden,
    NotFound(String),
    ValidationError(String),
    InsufficientBalance,
    RateLimitExceeded,
    Internal(anyhow::Error),
}
```

### Database (sqlx)

- Always use parameterized queries — never string-format SQL.
- Use `sqlx::query_as!` for queries that return structs (compile-time checked).
- Use `sqlx::query!` for mutations (INSERT, UPDATE, DELETE).
- Soft-delete only — never `DELETE FROM` user data tables. Use `deleted_at = now()` and filter with `WHERE deleted_at IS NULL`.
- Wallet balance mutations must be atomic SQL: `UPDATE wallets SET balance = balance - $1 WHERE id = $2 AND balance >= $1 RETURNING balance`. Never read-then-write in application code.
- All migrations are numbered sequentially: `0001_`, `0002_`, etc. Never modify an existing migration file — always add a new one.
- Always add indexes for columns used in `WHERE`, `ORDER BY`, or `JOIN` clauses.

### Auth & Security

- Every protected route must use the `AuthUser` Axum extractor — never manually parse the Authorization header in handlers.
- Admin routes must use a separate `AdminUser` extractor that additionally checks `users.is_admin = true`.
- Rate limiting is Redis-based sliding window — always use the middleware, never roll per-handler limits.
- Validate MIME type server-side on every file upload — never trust the file extension alone.
- Enforce file size limits before reading the body (5MB for avatars, 20MB for PDFs).
- Webhook endpoints (MoMo, Orange Money) must verify HMAC signatures before any processing.
- Idempotency keys for payment endpoints are stored in Redis (TTL 24h) — always check before processing.
- CORS allowlist only known mobile app origins — never use wildcard `*` in production.

### Validation

- Every request DTO must derive `validator::Validate`.
- Validate at the handler boundary before calling any service function.
- Phone numbers are always normalized to `+237XXXXXXXXX` format before storage or Redis key use.
- Amount fields are always positive integers (FCFA, no decimals). Enforce with `#[validate(range(min = 1))]`.
- Enum fields (account_type, plan_type, method, etc.) are validated before hitting the DB.

### Serialization

- Response structs must derive `serde::Serialize`.
- Request structs must derive `serde::Deserialize` and `validator::Validate`.
- DB model structs (`models/`) derive `sqlx::FromRow` and `serde::Serialize` — no `Deserialize` on DB types.
- Never expose internal DB fields in API responses (e.g. `is_admin`, `token_hash`, raw UUIDs of internal join tables).
- Use `#[serde(skip_serializing_if = "Option::is_none")]` on optional response fields.

### Async & Concurrency

- Never use `std::thread::sleep` — use `tokio::time::sleep`.
- Never block the async executor — use `tokio::task::spawn_blocking` for CPU-heavy or blocking operations.
- Background jobs are registered at startup in `main.rs` via `tokio-cron-scheduler` — never spawn ad-hoc long-running tasks in handlers.

### Logging & Tracing

- Use `tracing::info!`, `tracing::warn!`, `tracing::error!` — never `println!` or `eprintln!` in production code.
- Every request gets a `request_id` UUID injected by middleware and included in all log fields.
- Structured log fields: `request_id`, `user_id`, `method`, `path`, `status`, `duration_ms`.
- Log at `warn` for rate limit hits, at `error` for payment failures, at `info` for successful payment events.

### Testing

- Unit test service functions in isolation with mock inputs — no HTTP layer needed.
- Integration tests hit a real test database (never mock sqlx). Use a separate `TEST_DATABASE_URL`.
- Each integration test runs in a transaction that is rolled back at the end — no test data cleanup needed.
- Test file naming: `src/services/auth.rs` tests live in `src/services/auth_test.rs` or inline in a `#[cfg(test)]` module.
- Never write tests that depend on execution order.

---

## Git Rules

- Branch naming: `feat/`, `fix/`, `chore/`, `refactor/` prefixes. Example: `feat/wallet-topup`.
- Commit message format: `type(scope): short description`. Example: `feat(auth): add OTP rate limiting`.
- Never commit `.env` files — only `.env.example` with placeholder values.
- Never commit `target/` or any build artifacts.
- Every PR must have a description linking to the sprint task it belongs to.
- Squash commits on merge to keep main history clean.

---

## API Design Rules

- All routes are versioned: `/api/v1/...`
- All responses are JSON with consistent shape:
  - Success: `{ "data": { ... } }` or `{ "data": [...], "meta": { "total": N, "page": N } }`
  - Error: `{ "error": "human-readable message" }`
- Pagination: use `?page=1&per_page=20`. Default `per_page=20`, max `per_page=100`.
- Always return `404` for resources that exist but belong to another user (not `403`) — don't leak existence.
- Timestamps are always UTC ISO 8601: `2025-03-26T12:00:00Z`.
- Amounts are always integers in FCFA — never floats.
- Never accept or return `null` for required fields — use `Option<T>` only for genuinely optional data.

---

## What to Avoid

- No ORMs (diesel, sea-orm) — sqlx raw queries only.
- No `async-std` — Tokio only.
- No `serde_yaml` or `serde_toml` for runtime config — environment variables only.
- No `rocket`, `actix-web`, or other web frameworks — Axum only.
- No `unsafe` blocks without a detailed comment explaining why it is sound.
- No `clone()` on large structs in hot paths — pass references.
- No `.to_string()` in tight loops — use `format!` only where necessary.
- No commented-out code committed to main.
- No `TODO` comments committed without an accompanying issue number.
