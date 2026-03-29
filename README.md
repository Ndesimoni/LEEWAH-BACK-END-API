# LEEWAH Backend — Architecture & Implementation Plan

> Language: **Rust** | Framework: **Axum** | Database: **PostgreSQL** | Cache: **Redis**

---

## Table of Contents

1. [Tech Stack](#tech-stack)
2. [Project Structure](#project-structure)
3. [Database Schema](#database-schema)
4. [Feature Breakdown](#feature-breakdown)
   - [1. Authentication](#1-authentication)
   - [2. User Management](#2-user-management--profiles)
   - [3. Children Management](#3-children-management-parent-only)
   - [4. Schools](#4-schools)
   - [5. School Fee Payment](#5-school-fee-payment-core-feature)
   - [6. Wallet](#6-wallet)
   - [7. Donations](#7-donations)
   - [8. Past Exam Questions](#8-past-exam-questions)
   - [9. Peer Review](#9-peer-review)
   - [10. Push Notifications](#10-push-notifications)
   - [11. Support](#11-support-faq--live-chat--ai)
   - [12. Admin Panel](#12-admin-panel-api)
5. [Cross-Cutting Concerns](#cross-cutting-concerns)
6. [Crate List](#crate-list--what-each-does)
7. [Sprint Plan](#sprint-plan)
8. [Environment Variables](#environment-variables)

---

## Tech Stack

| Layer | Choice | Why |
|---|---|---|
| Language | **Rust** | Memory safe, blazing fast, tiny binary for cheap hosting |
| Framework | **Axum 0.7** | Modern, async-native, ergonomic, built on Tokio |
| Database | **PostgreSQL** | Relational data, strong consistency for payments |
| Query layer | **sqlx** | Async, compile-time checked queries — no ORM bloat |
| Auth | **JWT** (`jsonwebtoken`) | Stateless, mobile-friendly |
| Cache / OTP | **Redis** | OTP storage, rate limiting, response caching |
| File storage | **Cloudflare R2** | Cheap, S3-compatible (profile pics, PDFs, question docs) |
| Migrations | **sqlx-migrate** | Lives in the same ecosystem as sqlx |
| Background jobs | **tokio-cron-scheduler** | Recurring tasks (reminders, disbursements) |
| Deployment | **Fly.io or Railway** | Rust binaries are tiny — very cheap to run |
| SMS (OTP) | **Africa's Talking** | Regional, cheap, good Cameroon coverage |
| Push notifications | **Firebase FCM v1** | Single API covers Android + iOS |

---

## Project Structure

```
leewah-api/
├── src/
│   ├── main.rs                  # Server boot, router assembly
│   ├── config.rs                # Env vars (DB_URL, JWT_SECRET, etc.)
│   ├── error.rs                 # Unified AppError type → IntoResponse
│   ├── db.rs                    # PgPool setup
│   ├── middleware/
│   │   ├── auth.rs              # JWT extractor — injects AuthUser into extensions
│   │   └── rate_limit.rs        # Redis-based sliding window rate limiter
│   ├── routes/                  # HTTP handlers grouped by domain
│   │   ├── auth.rs
│   │   ├── users.rs
│   │   ├── children.rs
│   │   ├── schools.rs
│   │   ├── plans.rs             # Payment plans
│   │   ├── wallet.rs
│   │   ├── donations.rs
│   │   ├── papers.rs            # Past exam questions
│   │   ├── notifications.rs
│   │   ├── support.rs           # FAQ, live chat, AI assistant
│   │   └── admin.rs
│   ├── models/                  # Rust structs matching DB rows (sqlx FromRow)
│   │   ├── user.rs
│   │   ├── child.rs
│   │   ├── school.rs
│   │   ├── plan.rs
│   │   ├── wallet.rs
│   │   ├── donation.rs
│   │   ├── paper.rs
│   │   └── notification.rs
│   ├── services/                # Business logic — no HTTP concerns
│   │   ├── auth.rs              # OTP generation, token signing/verification
│   │   ├── payments.rs          # MTN MoMo + Orange Money integration
│   │   ├── wallet.rs            # Atomic balance operations
│   │   ├── push.rs              # FCM push notification sending
│   │   └── storage.rs           # R2 file upload/signed URL generation
│   └── types.rs                 # Shared enums, request/response DTOs
├── migrations/                  # SQL migration files (numbered, sequential)
│   ├── 0001_create_users.sql
│   ├── 0002_create_children.sql
│   ├── 0003_create_schools.sql
│   └── ...
├── Cargo.toml
├── Dockerfile
├── docker-compose.yml           # Local: Postgres + Redis
└── .env.example
```

---

## Database Schema

```sql
-- ─────────────────────────────────────────────────────────────────────────────
-- USERS
-- ─────────────────────────────────────────────────────────────────────────────
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

-- ─────────────────────────────────────────────────────────────────────────────
-- AUTH
-- ─────────────────────────────────────────────────────────────────────────────
CREATE TABLE refresh_tokens (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id     UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  token_hash  TEXT NOT NULL,
  expires_at  TIMESTAMPTZ NOT NULL,
  created_at  TIMESTAMPTZ DEFAULT now()
);

-- Redis key pattern: otp:{phone} → { hash, attempts }  TTL 300s

CREATE TABLE device_tokens (
  id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id    UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  token      TEXT UNIQUE NOT NULL,
  platform   TEXT CHECK (platform IN ('ios', 'android')),
  created_at TIMESTAMPTZ DEFAULT now()
);

-- ─────────────────────────────────────────────────────────────────────────────
-- CHILDREN
-- ─────────────────────────────────────────────────────────────────────────────
CREATE TABLE children (
  id             UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  parent_id      UUID NOT NULL REFERENCES users(id),
  full_name      TEXT NOT NULL,
  class_level    TEXT NOT NULL,
  school_id      UUID REFERENCES schools(id),
  school_name    TEXT,                           -- fallback if school not in DB
  active_plan_id UUID,                           -- FK added after payment_plans
  deleted_at     TIMESTAMPTZ,                    -- soft delete
  created_at     TIMESTAMPTZ DEFAULT now()
);

-- ─────────────────────────────────────────────────────────────────────────────
-- SCHOOLS
-- ─────────────────────────────────────────────────────────────────────────────
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

-- Full-text search index
CREATE INDEX schools_search_idx ON schools USING GIN (to_tsvector('english', name || ' ' || town));

-- ─────────────────────────────────────────────────────────────────────────────
-- SCHOOL FEE PAYMENT PLANS
-- ─────────────────────────────────────────────────────────────────────────────
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

-- ─────────────────────────────────────────────────────────────────────────────
-- WALLET
-- ─────────────────────────────────────────────────────────────────────────────
CREATE TABLE wallets (
  id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id    UUID UNIQUE NOT NULL REFERENCES users(id),
  balance    INTEGER DEFAULT 0 CHECK (balance >= 0),
  updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE wallet_transactions (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  wallet_id   UUID NOT NULL REFERENCES wallets(id),
  type        TEXT NOT NULL CHECK (type IN ('topup','payment','refund')),
  amount      INTEGER NOT NULL,                  -- always positive
  description TEXT NOT NULL,
  reference   TEXT,                              -- external ref or plan ref
  created_at  TIMESTAMPTZ DEFAULT now()
);

-- ─────────────────────────────────────────────────────────────────────────────
-- DONATIONS
-- ─────────────────────────────────────────────────────────────────────────────
CREATE TABLE campaigns (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  title         TEXT NOT NULL,
  description   TEXT,
  goal_amount   INTEGER,
  raised_amount INTEGER DEFAULT 0,
  category      TEXT CHECK (category IN ('urgent','school','project','student')),
  image_url     TEXT,
  beneficiary   TEXT,
  is_active     BOOLEAN DEFAULT TRUE,
  created_at    TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE donations (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  campaign_id UUID NOT NULL REFERENCES campaigns(id),
  user_id     UUID NOT NULL REFERENCES users(id),
  amount      INTEGER NOT NULL,
  method      TEXT CHECK (method IN ('mtn_momo','orange_money','card','wallet')),
  status      TEXT DEFAULT 'pending' CHECK (status IN ('pending','confirmed','failed')),
  momo_ref    TEXT,
  anonymous   BOOLEAN DEFAULT FALSE,
  created_at  TIMESTAMPTZ DEFAULT now()
);

-- Trigger: update campaigns.raised_amount on confirmed donation insert
CREATE OR REPLACE FUNCTION update_campaign_raised()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.status = 'confirmed' THEN
    UPDATE campaigns SET raised_amount = raised_amount + NEW.amount WHERE id = NEW.campaign_id;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_update_raised
AFTER INSERT OR UPDATE ON donations
FOR EACH ROW EXECUTE FUNCTION update_campaign_raised();

-- ─────────────────────────────────────────────────────────────────────────────
-- PAST EXAM QUESTIONS
-- ─────────────────────────────────────────────────────────────────────────────
CREATE TABLE papers (
  id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  subject    TEXT NOT NULL,
  year       INTEGER NOT NULL,
  exam_type  TEXT NOT NULL,           -- 'O-Level', 'A-Level', 'BEPC', etc.
  paper_type TEXT NOT NULL CHECK (paper_type IN ('MCQ','THEORY','PRACTICAL')),
  section    TEXT,                    -- 'General', 'Technical', 'Commercial'
  system     TEXT CHECK (system IN ('anglophone','francophone')),
  content    JSONB NOT NULL,          -- structured question data (see below)
  pdf_url    TEXT,                    -- R2 URL for scanned PDF
  is_active  BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX papers_filter_idx ON papers (subject, year, exam_type, paper_type);

-- content JSONB shape:
-- {
--   "mcq": [{ "id": "q1", "question": "...", "options": ["A","B","C","D"], "answer": "A" }],
--   "theory": [{ "id": "q1", "question": "...", "subQuestions": [...], "markingScheme": "..." }],
--   "practical": [{ "id": "q1", "question": "...", "criteria": [...] }]
-- }

-- ─────────────────────────────────────────────────────────────────────────────
-- PEER REVIEW
-- ─────────────────────────────────────────────────────────────────────────────
CREATE TABLE peer_reviews (
  id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  paper_id     UUID NOT NULL REFERENCES papers(id),
  submitter_id UUID NOT NULL REFERENCES users(id),
  reviewer_id  UUID REFERENCES users(id),
  review_code  TEXT UNIQUE NOT NULL,
  answers      JSONB NOT NULL,
  feedback     JSONB,
  scores       JSONB,
  status       TEXT DEFAULT 'pending' CHECK (status IN ('pending','reviewing','completed')),
  submitted_at TIMESTAMPTZ DEFAULT now(),
  claimed_at   TIMESTAMPTZ,
  completed_at TIMESTAMPTZ
);

CREATE INDEX peer_reviews_code_idx ON peer_reviews (review_code);

-- ─────────────────────────────────────────────────────────────────────────────
-- NOTIFICATIONS
-- ─────────────────────────────────────────────────────────────────────────────
CREATE TABLE notifications (
  id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id    UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  type       TEXT NOT NULL,
  title      TEXT NOT NULL,
  body       TEXT NOT NULL,
  data       JSONB,                   -- deep link params
  read       BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX notifications_user_idx ON notifications (user_id, created_at DESC);
```

---

## Feature Breakdown

---

### 1. Authentication

**Flow**

```
POST /auth/send-otp      { phone }
  → Normalize phone to +237XXXXXXXXX
  → Generate 6-digit OTP
  → Hash with SHA-256 → store in Redis  key=otp:{phone}  TTL=300s
  → Send raw OTP via Africa's Talking SMS API
  → Return { expires_in: 300 }

POST /auth/verify-otp    { phone, code }
  → Pull hash from Redis, compare
  → Enforce max 5 wrong attempts (counter in Redis)
  → On match: upsert user → generate access_token (15min JWT) + refresh_token (30 days)
  → Store refresh_token hash in DB
  → Delete OTP from Redis
  → Return { access_token, refresh_token, user }

POST /auth/refresh       { refresh_token }
  → Validate token hash in DB → issue new access_token

POST /auth/logout
  → Delete refresh_token from DB
```

**Key rules**
- Rate limit: max 3 OTP sends per phone per 10 minutes (Redis counter)
- OTP attempt limit: 5 wrong guesses → invalidate OTP entirely
- JWT payload: `{ sub: user_id, account_type, exp }`
- Refresh tokens: 64-byte random (base64url), hash stored in DB — allows selective revocation
- `AuthUser` Axum extractor validates JWT on every protected route and injects `user_id` + `account_type`

---

### 2. User Management & Profiles

**Endpoints**
```
GET    /users/me            Full profile
PATCH  /users/me            Update name, email, language
POST   /users/me/avatar     Multipart upload → R2
GET    /users/me/kyc        KYC status
POST   /users/me/kyc        Submit KYC document (multipart)
```

**Key rules**
- PATCH uses partial updates — only update fields that are `Some` in the request body
- Avatar: validate MIME type server-side (not just extension), enforce 5MB max
- File goes directly to R2 via `aws-sdk-s3` (S3-compatible). Only the URL is stored in Postgres
- KYC Phase 1 = manual admin review. Phase 2 = Smile Identity (covers Cameroon)
- Phone number always normalized to international format before storage

---

### 3. Children Management (Parent Only)

**Endpoints**
```
GET    /children            List parent's children (includes active plan summary)
POST   /children            Add child
GET    /children/:id        Single child detail
PATCH  /children/:id        Update child info
DELETE /children/:id        Soft delete
```

**Key rules**
- All routes guarded: `account_type == 'guardian_or_parent'` → 403 if student hits these
- Soft delete only: payment history must stay intact. Set `deleted_at = now()`, filter with `WHERE deleted_at IS NULL`
- School linking: if school is in our DB → link by `school_id`; if not → store free-text `school_name`
- Students cannot add siblings — enforced at the API level, not just the UI

---

### 4. Schools

**Endpoints**
```
GET  /schools               Search / list (params: name, region, town, system)
GET  /schools/:id           Detail with fees by grade and term
POST /admin/schools         Admin only — add school to directory
```

**Key rules**
- Full-text search via Postgres `tsvector` on `name + town` — no external search engine needed
- Always paginate results: `LIMIT 20 OFFSET ?` initially, upgrade to keyset pagination at scale
- Seed the DB with existing mock school data via migration on first deploy
- Return fees grouped by class_level → term for easy display in the fee setup flow

---

### 5. School Fee Payment (Core Feature)

**Endpoints**
```
GET  /plans                 All active plans for the authenticated user's children
POST /plans                 Create a new payment plan
GET  /plans/:id             Plan detail + payment history
POST /plans/:id/pay         Make an installment payment
POST /plans/:id/pause       Pause plan
POST /plans/:id/stop        Stop plan permanently
```

**Payment flow**
```
POST /plans/:id/pay   { method: 'wallet' | 'mtn_momo' | 'orange_money', idempotency_key }

if method == 'wallet':
  → Atomic DB operation: deduct balance + create fee_payment + create wallet_transaction
  → status = 'confirmed' immediately
  → send push notification

if method == 'mtn_momo' | 'orange_money':
  → Call MoMo Initiate API
  → Create fee_payment with status = 'pending', store momo_ref
  → Return { status: 'pending', message: 'Check your phone to approve' }
  → Webhook callback → POST /webhooks/mtn or /webhooks/orange
    → Verify signature → update fee_payment.status → update plan.amount_paid
    → Send push notification

Background job (daily 23:00 CAT):
  → Find confirmed, undisbursed fee_payments
  → Call MoMo Transfer API to school's momo_number
  → Set disbursed_to_school = true, disbursed_at = now()
```

**Key rules**
- Server always calculates installment amount — never trust client-provided amounts
  - Formula: `ceil(total_fee / periods / 50) * 50` (rounds up to nearest 50 FCFA)
- Idempotency: every pay request takes `Idempotency-Key` header. Cache result in Redis (TTL 24h) — prevents double-charges on client retry
- Wallet deduction is atomic: use `UPDATE wallets SET balance = balance - $amount WHERE id = $id AND balance >= $amount RETURNING balance` — if 0 rows returned → insufficient balance
- Payment state machine: `pending → confirmed → disbursed` (or `failed`). No skipping states
- No refund endpoint — money always goes to school. This is by design

---

### 6. Wallet

**Endpoints**
```
GET  /wallet                Balance + last 10 transactions
POST /wallet/topup          Initiate top-up via MoMo/card
GET  /wallet/transactions   Full paginated transaction history
```

**Top-up flow**
```
POST /wallet/topup   { amount, method: 'mtn_momo' | 'orange_money' | 'card' }
  → Call MoMo Initiate / card processor
  → Store pending topup record
  → Webhook confirms → credit wallet atomically
  → Create wallet_transaction { type: 'topup' }
  → Send push notification: "Wallet funded with FCFA X"
```

**Key rules**
- Balance is always updated atomically via SQL — never in application code
- `balance >= 0` constraint enforced at DB level (CHECK constraint)
- `wallet_transactions` is the ledger (source of truth). `wallets.balance` is a cache
- Reconciliation job: weekly job that recomputes balance from transactions and alerts if mismatch
- Every wallet is auto-created when a user account is created (one wallet per user, always)

---

### 7. Donations

**Endpoints**
```
GET  /campaigns                   List (filter: category, is_active)
GET  /campaigns/:id               Detail + paginated donor list
POST /campaigns/:id/donate        Make a donation
GET  /users/me/donations          My donation history
```

**Key rules**
- Minimum donation: 500 FCFA — enforced server-side
- Enforce `anonymous = false` by default. If `true`, donor name not shown in public list
- `campaigns.raised_amount` updated via DB trigger on confirmed donation — consistent even if app code crashes
- Same MoMo webhook pattern as school fee payments drives `donations.status` transitions

---

### 8. Past Exam Questions

**Endpoints**
```
GET  /papers                    List (filter: subject, year, exam_type, paper_type, section, system)
GET  /papers/:id                Full paper content (JSONB)
GET  /papers/:id/pdf            Redirect to signed R2 URL (1-hour expiry)
POST /admin/papers              Upload paper (admin only)
```

**Key rules**
- List endpoint returns metadata only — no `content` JSONB in list response (too heavy)
- Detail endpoint returns full `content` JSONB
- PDF files stored in R2. Generate a pre-signed URL per request (1-hour expiry) — never expose raw R2 URL
- Index on `(subject, year, exam_type, paper_type)` — every query filters on these columns
- Cache list responses in Redis TTL 1 hour — this data rarely changes, read constantly
- Phase 1: seed from existing mock data via SQL migration. Phase 2: admin upload flow

---

### 9. Peer Review

**Endpoints**
```
POST /reviews/submit              Submit answers → get review_code
POST /reviews/claim               Claim a review with review_code
GET  /reviews/:id                 Review detail (for reviewer: see submitter's answers)
POST /reviews/:id/submit-feedback Submit marks + feedback
GET  /reviews/:id/result          Submitter views completed review result
```

**Flow**
```
Student A:
  POST /reviews/submit  { paper_id, answers[] }
  → Create peer_review, status = 'pending'
  → Generate unique 8-char alphanumeric review_code
  → Return { review_code }

Student B:
  POST /reviews/claim  { review_code }
  → Verify reviewer_id != submitter_id (prevent self-review)
  → Set reviewer_id, status = 'reviewing', claimed_at = now()
  → Return { answers[], questions[] }

  POST /reviews/:id/submit-feedback  { feedback[], scores[] }
  → Set feedback, scores, status = 'completed', completed_at = now()
  → Send push notification to Student A

Student A:
  GET /reviews/:id/result
  → Return { questions, answers, feedback, scores, marking_guide }
```

**Key rules**
- Review code: 8-char nanoid (no ambiguous chars 0/O/l/I). Unique index in DB
- Reviewer identity never exposed to submitter (and vice versa)
- 48-hour timeout: cron job resets `reviewing → pending` if reviewer doesn't submit within 48h
- Marking guide only visible to submitter after review is `completed` — not before

---

### 10. Push Notifications

**Endpoints**
```
POST   /device-tokens            Register FCM/APNs token
DELETE /device-tokens/:token     Unregister (on logout)
GET    /notifications            In-app notification list (paginated, newest first)
PATCH  /notifications/:id/read   Mark single notification read
PATCH  /notifications/read-all   Mark all read
```

**Send pattern**
```
Event fires (payment confirmed, review ready, etc.)
  → Write notification row to DB      (in-app always works)
  → Fetch device_tokens for user
  → Call FCM v1 HTTP API              (push, may fail silently)
  → If FCM returns UNREGISTERED       → delete token from DB
```

**Background jobs**
```
Daily 09:00 CAT:
  → Find plans where next_due_date = today + 3 days
  → Send push: "Your FCFA X payment is due in 3 days"
  → Write notification to DB

Weekly:
  → Reconcile wallet balances
  → Alert admin Slack channel if any mismatch found
```

**Key rules**
- Always write to `notifications` table before attempting FCM push — in-app is the ground truth
- FCM is fire-and-forget. App polls `/notifications` on open as the reliable fallback
- For broadcast pushes (new feature announcement): use FCM topic subscriptions, not individual sends

---

### 11. Support (FAQ + Live Chat + AI)

**Endpoints**
```
GET  /faqs                        Categorized FAQ list (cached)
GET  /faqs/search                 Search FAQs (query param)

POST /support/sessions            Create live chat session
GET  /support/sessions/:id/messages   Message history
POST /support/sessions/:id/messages   Send message
WS   /support/sessions/:id       WebSocket — real-time bidirectional

POST /ai/chat                     Send message to AI assistant (SSE streaming)
```

**Live chat approach**
- WebSocket via Axum's native `ws` feature + `tokio-tungstenite`
- Each message stored in DB — history survives disconnects and reconnects
- Agent side: admin web panel (separate frontend, same WebSocket endpoint)
- If no agent is online: auto-reply saved to DB + admin notification triggered
- Session statuses: `open → active → resolved → closed`

**AI assistant approach**
- Mobile app sends message to `POST /ai/chat { message, context? }`
- Rust server holds `ANTHROPIC_API_KEY` — never in the mobile app
- Server proxies to Anthropic API with a system prompt (Cameroon curriculum, exam context)
- Response streamed back to mobile via **SSE (Server-Sent Events)** — user sees text appear in real time
- Rate limit: 20 AI messages per user per hour (Redis counter)

**FAQ approach**
- Stored in DB for admin management. Cached in Redis TTL 6 hours
- No auth required — public endpoint
- Search: Postgres `ILIKE` for simple search (or `tsvector` if volume grows)

---

### 12. Admin Panel API

**Endpoints**
```
GET  /admin/users                  User list + filters
GET  /admin/plans                  All payment plans
POST /admin/plans/:id/disburse     Mark payment as disbursed to school
POST /admin/schools                Add school to directory
POST /admin/papers                 Upload exam paper
GET  /admin/analytics              Revenue, active users, payment volume
GET  /admin/kyc/pending            KYC queue
PATCH /admin/kyc/:id               Approve or reject KYC submission
GET  /admin/reviews                Peer review oversight
```

**Key rules**
- Separate `AdminUser` Axum extractor — checks `users.is_admin = true`
- Add IP allowlist middleware for admin routes (only accessible from known IPs in production)
- Analytics: use Postgres materialized views for expensive aggregations (refresh hourly)
- KYC approval: sets `kyc_status = 'verified'` or `'failed'` + optional `kyc_note` for rejection reason

---

## Cross-Cutting Concerns

### Error Handling

One unified `AppError` enum that implements `IntoResponse`. All handlers return `Result<Json<T>, AppError>`. Zero panics in request handlers.

```rust
pub enum AppError {
    Unauthorized,
    Forbidden,
    NotFound(String),
    ValidationError(String),
    InsufficientBalance,
    PaymentFailed(String),
    RateLimitExceeded,
    Internal(anyhow::Error),
}
```

### Request Validation
- `validator` crate on all request DTOs
- Phone numbers normalized to `+237XXXXXXXXX` before storage
- Amount fields always validated as positive integers
- Enum fields validated against allowed values before hitting the DB

### Logging & Tracing
- `tracing` + `tracing-subscriber` with JSON output in production
- Every request gets a `request_id` (UUID) injected by middleware — logged on entry and exit with duration
- Structured log fields: `request_id`, `user_id`, `method`, `path`, `status`, `duration_ms`

### Rate Limiting (Redis sliding window)
| Endpoint | Limit |
|---|---|
| POST /auth/send-otp | 3 per phone per 10 min |
| POST /auth/verify-otp | 5 attempts per OTP |
| POST /ai/chat | 20 per user per hour |
| POST /wallet/topup | 10 per user per day |
| General API | 200 per user per minute |

### Security
- All DB queries use sqlx parameterized statements — zero SQL injection surface
- File uploads: validate MIME type server-side, enforce size limits
- HTTPS only — SSL termination at load balancer (Fly.io / Railway handles this)
- CORS: allowlist only mobile app origins
- Webhook endpoints: verify HMAC signature before processing any payment callback
- Secrets: never in code or logs — loaded from environment variables only

---

## Crate List & What Each Does

### Server

| Crate | Purpose |
|---|---|
| `axum` | Web framework. Handles HTTP routing, middleware, WebSockets (`ws` feature), and multipart file uploads (`multipart` feature). Built on Tokio and Tower. |
| `tokio` | Async runtime. Every async task, timer, and I/O operation runs on it. The `full` feature enables all sub-runtimes (net, fs, time, etc.). |
| `tower` | Middleware abstraction layer that axum is built on. Used for composing service layers (auth, rate limiting, etc.). |
| `tower-http` | Ready-made HTTP middleware: `cors` adds CORS headers, `trace` logs every request with method, path, status, and duration. |

### Database

| Crate | Purpose |
|---|---|
| `sqlx` | Async PostgreSQL driver. Compile-time checked queries — if your SQL is wrong, it won't compile. No ORM bloat. The `uuid`, `time`, and `postgres` features map Rust types directly to Postgres column types. |

### Cache

| Crate | Purpose |
|---|---|
| `redis` | Async Redis client. Used for OTP storage (TTL 5min), rate limiting counters, idempotency key caching, and response caching for read-heavy endpoints (FAQs, exam papers). |

### Auth

| Crate | Purpose |
|---|---|
| `jsonwebtoken` | Signs and verifies JWTs. Used to issue short-lived access tokens (15 min) and validate them on every protected route. |
| `sha2` | SHA-256 hashing. OTP codes and refresh tokens are stored as hashes — never in plain text. |
| `bcrypt` | Password hashing. Used if admin accounts ever need password-based login in addition to OTP. |

### IDs

| Crate | Purpose |
|---|---|
| `uuid` | Generates UUID v4 primary keys for all database rows. |
| `nanoid` | Generates short, URL-safe unique IDs. Used for the 8-character peer review codes (no ambiguous chars like `0/O/l/I`). |

### Serialization

| Crate | Purpose |
|---|---|
| `serde` | Serialization/deserialization framework. The `derive` feature lets you add `#[derive(Serialize, Deserialize)]` to any struct. |
| `serde_json` | JSON support for serde. Axum uses this internally to parse request bodies and build JSON responses. |

### HTTP Client

| Crate | Purpose |
|---|---|
| `reqwest` | Makes outbound HTTP requests to external APIs: MTN MoMo, Orange Money, Firebase FCM, Africa's Talking (SMS), and the Anthropic API. The `stream` feature enables SSE streaming for the AI assistant proxy. |

### Validation

| Crate | Purpose |
|---|---|
| `validator` | Validates request DTOs at the handler boundary using derive macros. Catches bad input (invalid phone format, amount below minimum, empty required fields) before it reaches business logic or the database. |

### File Storage

| Crate | Purpose |
|---|---|
| `aws-sdk-s3` | S3-compatible client used to upload files to Cloudflare R2 (profile pictures, KYC documents, exam PDFs) and generate pre-signed download URLs. |
| `aws-config` | Loads AWS/R2 credentials from environment variables and builds the S3 client config. |

### Background Jobs

| Crate | Purpose |
|---|---|
| `tokio-cron-scheduler` | Runs scheduled tasks inside the same Tokio runtime. Powers daily payment reminders (09:00 CAT), nightly disbursement jobs (23:00 CAT), the weekly wallet reconciliation, and the 48-hour peer review timeout reset. |

### Error Handling

| Crate | Purpose |
|---|---|
| `thiserror` | Derive macros for the `AppError` enum. Keeps error definitions clean and generates `Display` + `Error` implementations automatically. |
| `anyhow` | Wraps arbitrary third-party errors into `AppError::Internal(anyhow::Error)`. Used in service-layer code where you just need to propagate an unexpected error up to the handler. |

### Logging

| Crate | Purpose |
|---|---|
| `tracing` | Structured, async-aware logging. Emits spans and events that carry fields like `request_id`, `user_id`, `method`, `path`, `status`, `duration_ms`. |
| `tracing-subscriber` | Configures how tracing output is formatted and where it goes. The `json` feature enables structured JSON logs in production (easy to ingest into Datadog, Loki, etc.). |

### Config

| Crate | Purpose |
|---|---|
| `dotenvy` | Loads `.env` file into environment variables at startup. All secrets (DB URL, JWT secret, API keys) are read from env — never hardcoded. |

---

### Full Cargo.toml Reference

```toml
[dependencies]
# Server
axum = { version = "0.8", features = ["ws", "multipart"] }
tokio = { version = "1", features = ["full"] }
tower = "0.5"
tower-http = { version = "0.6", features = ["cors", "trace"] }

# Database
sqlx = { version = "0.8", features = ["postgres", "uuid", "time", "runtime-tokio"] }

# Cache
redis = { version = "0.27", features = ["aio", "tokio-comp"] }

# Auth
jsonwebtoken = "9"
sha2 = "0.10"
bcrypt = "0.15"

# IDs
uuid = { version = "1", features = ["v4"] }
nanoid = "0.4"

# Serialization
serde = { version = "1", features = ["derive"] }
serde_json = "1"

# HTTP client (MoMo, FCM, Anthropic, Africa's Talking)
reqwest = { version = "0.12", features = ["json", "stream"] }

# Validation
validator = { version = "0.19", features = ["derive"] }

# File storage (Cloudflare R2 — S3 compatible)
aws-sdk-s3 = "1"
aws-config = "1"

# Background jobs
tokio-cron-scheduler = "0.13"

# Error handling
anyhow = "1"
thiserror = "2"

# Logging
tracing = "0.1"
tracing-subscriber = { version = "0.3", features = ["json"] }

# Config
dotenvy = "0.15"
```

---

## Sprint Plan

| Sprint | Deliverable |
|---|---|
| **1** | Project setup — Axum server, sqlx pool, Redis, Docker Compose (Postgres + Redis locally), migrations scaffolding |
| **2** | Auth — OTP via Africa's Talking, JWT access + refresh tokens, rate limiting |
| **3** | Users + Children — CRUD, soft delete, avatar upload to R2 |
| **4** | Schools — directory, full-text search, seed data migration |
| **5** | Payment Plans — setup flow, installment calculation, plan CRUD |
| **6** | Wallet — balance, top-up (mock MoMo), atomic deduction, transactions |
| **7** | School fee payment via wallet — atomic pay + transaction + plan update |
| **8** | Donations — campaigns CRUD, donate endpoint, raised_amount trigger |
| **9** | Past Exam Questions — browse API, filters, cached list, signed PDF URLs |
| **10** | Push Notifications — FCM integration, device tokens, in-app notifications, reminder cron |
| **11** | Peer Review — submit/claim/feedback/result flow, 48h timeout job |
| **12** | Real MoMo / Orange Money integration — initiate + webhook handlers + signature verification |
| **13** | AI assistant proxy (SSE streaming) + live chat WebSocket |
| **14** | Admin panel API — KYC queue, disbursement trigger, analytics |
| **15** | Load testing (k6), security audit, production deploy on Fly.io |

---

## Environment Variables

```bash
# .env.example

# Server
PORT=8080
RUST_LOG=info

# Database
DATABASE_URL=postgres://user:password@localhost:5432/leewah

# Redis
REDIS_URL=redis://localhost:6379

# JWT
JWT_SECRET=your-256-bit-secret-here
JWT_ACCESS_EXPIRY_MINUTES=15
JWT_REFRESH_EXPIRY_DAYS=30

# SMS — Africa's Talking
AT_API_KEY=your-api-key
AT_USERNAME=your-username
AT_SENDER_ID=LEEWAH

# Firebase FCM
FCM_PROJECT_ID=your-project-id
FCM_SERVICE_ACCOUNT_JSON=path/to/serviceAccount.json

# Cloudflare R2
R2_ACCOUNT_ID=your-account-id
R2_ACCESS_KEY_ID=your-access-key
R2_SECRET_ACCESS_KEY=your-secret-key
R2_BUCKET_NAME=leewah-assets
R2_PUBLIC_URL=https://assets.leewah.com

# Anthropic (AI assistant)
ANTHROPIC_API_KEY=sk-ant-...

# MTN MoMo
MTN_MOMO_SUBSCRIPTION_KEY=your-key
MTN_MOMO_API_USER=your-user-id
MTN_MOMO_API_KEY=your-api-key
MTN_MOMO_ENV=sandbox   # or production

# Orange Money
ORANGE_MONEY_CLIENT_ID=your-client-id
ORANGE_MONEY_CLIENT_SECRET=your-secret
ORANGE_MONEY_ENV=sandbox

# Admin
ADMIN_IP_ALLOWLIST=127.0.0.1,YOUR_OFFICE_IP
```

---

## Open Decisions

Before Sprint 1 begins, these need to be locked in:

| Decision | Options | Status |
|---|---|---|
| Hosting | Fly.io / Railway / VPS | ❓ TBD |
| SMS provider | Africa's Talking / Twilio | ❓ TBD |
| File storage | Cloudflare R2 / AWS S3 | ❓ TBD |
| MTN MoMo account | Developer portal registration | ❓ TBD |
| Orange Money account | Developer portal registration | ❓ TBD |
| Admin panel frontend | Separate web app / Tauri desktop | ❓ TBD |
