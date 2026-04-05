# NDE SIMONI CHE
**Backend Engineer — Rust | PostgreSQL | Systems Design**

ndesimoniche.io@gmail.com
&nbsp;|&nbsp; United Arab Emirates (Open to Remote)
&nbsp;|&nbsp; [github.com/Ndesimoni](https://github.com/Ndesimoni)
&nbsp;|&nbsp; [linkedin.com/in/nde-simoni-c-85b24a1a5](https://www.linkedin.com/in/nde-simoni-c-85b24a1a5/)

---

## Profile

Self-directed backend engineer building production-grade systems in Rust. Currently architecting a fintech API from the ground up — designing for correctness, concurrency, and scale rather than convenience. Obsessed with understanding *why* a system is built a certain way, not just how to copy it. Comfortable making real engineering trade-offs: memory safety over ORM convenience, atomic SQL over read-then-write, hard failures at startup over silent misconfiguration at runtime.

Actively seeking a role where hard problems are the norm and where the work demands growth.

---

## Technical Skills

| Category | Technologies |
|---|---|
| **Languages** | Rust (Edition 2024), SQL, TypeScript / JavaScript |
| **Backend Framework** | Axum 0.8, Tokio (async runtime), Tower, Tower-HTTP |
| **Database** | PostgreSQL 16, sqlx 0.8 (compile-time checked queries, no ORM) |
| **Cache / Messaging** | Redis 7 (sliding window rate limiting, OTP TTL, idempotency keys) |
| **Auth & Security** | JWT (jsonwebtoken), bcrypt, SHA-256 token hashing, HMAC webhook verification |
| **File Storage** | Cloudflare R2 via aws-sdk-s3 (S3-compatible) |
| **Background Jobs** | tokio-cron-scheduler |
| **Serialization** | serde, serde_json |
| **Validation** | validator (derive macros) |
| **Error Handling** | anyhow, thiserror, unified AppError → HTTP response mapping |
| **Observability** | tracing, tracing-subscriber (structured JSON logs) |
| **HTTP Client** | reqwest (external API integrations) |
| **DevOps / CI** | Docker, Docker Compose, GitHub Actions (fmt + clippy + test pipeline) |
| **Version Control** | Git, GitHub |
| **Frontend (separate)** | React Native, React, Next.js, Tailwind CSS, Shadcn UI |

---

## Project — Leewah API (In Active Development)

**Rust · Axum · PostgreSQL · Redis · Tokio · JWT · Cloudflare R2**

> Leewah is a fintech backend for a Cameroonian mobile app that lets parents pay school fees in daily, weekly, or monthly installments instead of one lump sum. Designed to handle real financial transactions, mobile OTP auth, and multi-provider payment processing at scale.

### Architecture Decisions & Why They Matter

**Async-first with Tokio + Axum**
Built on Tokio's async runtime so the server handles thousands of concurrent connections without blocking threads. Axum was chosen over Actix-Web for its composable, type-safe extractor model — incorrect handler signatures fail at compile time, not runtime.

**PostgreSQL + sqlx (no ORM)**
All queries are written in raw SQL and checked at compile time via `sqlx::query!` and `sqlx::query_as!` macros. If the database schema and the Rust code disagree, the build fails — not the production request. Eliminates an entire class of bugs that ORMs hide behind abstractions.

**Atomic wallet operations**
Wallet balance mutations are a single SQL statement:
```sql
UPDATE wallets SET balance = balance - $1
WHERE id = $2 AND balance >= $1
RETURNING balance
```
No read-then-write in application code. No race conditions. No possibility of overdraft from concurrent requests.

**Redis for everything ephemeral**
OTP codes stored with TTL (expires automatically), rate limiting via sliding window counters, idempotency keys for payment endpoints (24h TTL), response caching. Redis handles all state that does not belong in PostgreSQL.

**Soft deletes for financial compliance**
User data is never hard-deleted. A `deleted_at` timestamp marks records as inactive while preserving the full payment history required for auditing and dispute resolution.

**Unified error type — one place, not scattered**
A single `AppError` enum maps every possible failure (auth, validation, DB, rate limit, insufficient balance) to the correct HTTP status and structured JSON response. HTTP status codes are set exactly once — not scattered across 40 handlers.

**JWT + hashed refresh tokens**
Access tokens expire in 15 minutes. Refresh tokens are stored as SHA-256 hashes in PostgreSQL — the plaintext token only ever lives in memory and in the client. Compromising the database does not compromise live sessions.

**External integrations designed for**
- MTN Mobile Money + Orange Money (HMAC webhook verification before any processing)
- Africa's Talking SMS (OTP delivery)
- Firebase FCM (push notifications)
- Anthropic API (AI assistant, SSE streaming)
- Cloudflare R2 (avatar and PDF file storage, MIME-validated server-side)

### What's Built
- Full server bootstrap (config, error handling, DB pool, AppState, health check)
- Typed environment config that fails fast at startup if any required variable is missing
- PostgreSQL schema: users, refresh tokens, device tokens, children (via numbered SQL migrations)
- CI/CD pipeline: auto-format check, Clippy lint, and test suite on every push
- Docker Compose local dev environment (PostgreSQL 16 + Redis 7)
- Shared domain types: `AccountType`, `KycStatus`, `PlanType`, `PaymentMethod`, `PaymentStatus`

---

## Certifications

| Certificate | Platform | Date |
|---|---|---|
| Software Architecture & Design of Modern Large Scale Systems | Udemy | Feb 2025 |
| The Ultimate React Course 2025 (React, Next.js, Redux) — 84 hours | Udemy | Feb 2026 |
| Digital Skills Fundamentals | Google Garage | — |

---

## Education

High School Certificate — Cameroon

Self-directed continuing education in systems design, backend architecture, and low-level programming through project-based learning and structured coursework.

---

## What I Bring

- I build systems I can reason about — memory safety, compile-time guarantees, and explicit error paths are not constraints to work around, they are the design.
- I document what I build and why, not just how. Every architectural decision in this project has a written rationale.
- I am comfortable working in unfamiliar territory. I learned Rust by building a production system in it, not by following tutorials disconnected from real problems.
- Full-remote, async-first, timezone-flexible. Based in UAE, open to any geography.
