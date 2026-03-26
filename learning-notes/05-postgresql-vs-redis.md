# PostgreSQL vs Redis — When to Use Each

## The Core Difference

| | PostgreSQL | Redis |
|---|---|---|
| Storage | Disk | RAM (memory) |
| Speed | Fast | Extremely fast |
| Data | Permanent | Temporary |
| Structure | Tables, rows, columns | Keys and values |
| Query language | SQL | Simple commands |
| Best for | Business data | Caching, temporary state |

---

## PostgreSQL — Your Permanent Database

PostgreSQL is a **relational database**. Data is stored in tables with rows and columns, just like a spreadsheet — but with powerful querying, relationships between tables, and strong consistency guarantees.

Data in PostgreSQL is written to disk. When the server restarts, all your data is still there. This is where you store anything that matters long-term.

### What Leewah stores in PostgreSQL:
- Users and their profiles
- Children records
- Schools and fee structures
- Payment plans and payment history
- Wallet balances and transaction ledger
- Donation campaigns and donations
- Past exam papers
- Peer reviews
- Notifications
- Device tokens for push notifications

Everything that would be a disaster to lose goes in PostgreSQL.

### How you query PostgreSQL (SQL):
```sql
SELECT id, name, phone FROM users WHERE account_type = 'parent';

INSERT INTO wallets (user_id, balance) VALUES ($1, 0);

UPDATE wallets SET balance = balance - $1 WHERE id = $2 AND balance >= $1;
```

In this project you use **sqlx** to run these queries from Rust code safely.

---

## Redis — Your Fast Temporary Store

Redis is an **in-memory key-value store**. Data is stored in RAM, not on disk. This makes it extremely fast — reading a value from Redis takes microseconds, vs milliseconds for a database query.

The tradeoff: RAM is limited and expensive. You only store small, temporary things in Redis.

Think of it like this:
- PostgreSQL is your **filing cabinet** — everything is organized and permanent
- Redis is your **desk** — only what you're actively working with, cleared regularly

### What Leewah stores in Redis:

**OTP codes**
```
Key:   otp:+237612345678
Value: { hash: "abc123...", attempts: 0 }
TTL:   300 seconds (5 minutes, then auto-deleted)
```
When a user requests an OTP, you store the hashed code in Redis with a 5-minute expiry. Redis automatically deletes it after 5 minutes — you don't have to clean it up yourself.

**Rate limiting counters**
```
Key:   rate:otp:+237612345678
Value: 3  (number of OTP requests made)
TTL:   600 seconds (10 minutes window)
```
Every time a user requests an OTP, you increment this counter. If it hits 3, you block them. After 10 minutes, Redis deletes the key and they can try again.

**Idempotency keys (payment safety)**
```
Key:   idempotency:a1b2c3d4-...
Value: { status: "confirmed", payment_id: "uuid..." }
TTL:   86400 seconds (24 hours)
```
When a user makes a payment, they send a unique `Idempotency-Key` header. Before processing, you check Redis: "have I seen this key before?" If yes, return the cached result. If no, process the payment and cache the result. This prevents double-charges if the mobile app retries a request.

**Response caching**
```
Key:   cache:papers:list:subject=maths&year=2023
Value: [{ id: "...", subject: "Maths", ... }, ...]
TTL:   3600 seconds (1 hour)
```
The exam papers list is read constantly but rarely changes. Instead of hitting PostgreSQL on every request, you cache the result in Redis. First request: query PostgreSQL, store in Redis. All subsequent requests within 1 hour: return from Redis instantly.

**Session/token blacklist**
When a user logs out, you add their token to a Redis blacklist so it can't be reused even if it hasn't expired yet.

---

## TTL — Time To Live

TTL is one of Redis's most powerful features. Every key can have an expiry time set in seconds. When the time runs out, Redis automatically deletes the key.

This is perfect for:
- OTP codes (expire in 5 minutes)
- Rate limit windows (expire in 10 minutes)
- Cached responses (expire in 1 hour)
- Idempotency keys (expire in 24 hours)

You never need to write cleanup code — Redis handles it automatically.

---

## How They Work Together in Leewah

Here's the OTP flow to see both databases working together:

```
User requests OTP:
  1. Normalize phone to +237XXXXXXXXX
  2. Check Redis: has this phone sent 3 OTPs in the last 10 min? (rate limit)
  3. If yes → reject with "Too many attempts"
  4. If no → generate 6-digit OTP code
  5. Hash the OTP with SHA-256
  6. Store hash in Redis: key=otp:{phone}, TTL=300s
  7. Increment rate limit counter in Redis
  8. Send raw OTP via Africa's Talking SMS
  9. Return { expires_in: 300 }

User verifies OTP:
  1. Read OTP hash from Redis
  2. Hash the provided code and compare
  3. Check attempt counter — if 5 wrong guesses, delete OTP from Redis
  4. If match:
     a. Upsert user in PostgreSQL (permanent storage)
     b. Create wallet in PostgreSQL if new user
     c. Generate JWT tokens
     d. Store refresh token hash in PostgreSQL
     e. Delete OTP from Redis (used, no longer needed)
  5. Return { access_token, refresh_token, user }
```

Notice how Redis handles the fast, temporary, expiring data — and PostgreSQL handles everything that needs to persist.

---

## Key Things to Remember

1. **PostgreSQL = permanent data on disk** — users, payments, schools, everything that matters
2. **Redis = temporary data in memory** — OTPs, rate limits, caches, idempotency keys
3. **Redis is much faster than PostgreSQL** — use it to avoid hitting the database for repeated reads
4. **TTL automatically expires Redis keys** — you never need to manually clean up temporary data
5. **Both are needed** — they solve different problems and work together
6. **Never store permanent data in Redis** — it can be evicted from memory under pressure
7. **Never store high-volume temporary data in PostgreSQL** — you'll slow it down with unnecessary rows
