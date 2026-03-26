# Environment Variables, .env, and .env.example

## What is an Environment Variable?

An environment variable is a value stored **outside your code** that your program reads at runtime.

Instead of writing this in your code:
```rust
let db_url = "postgres://admin:supersecret@localhost:5432/leewah";
```

You write this:
```rust
let db_url = std::env::var("DATABASE_URL").expect("DATABASE_URL must be set");
```

And you put the actual value in a separate file or in the system environment — never in the code itself.

---

## Why Not Just Put Config Values in Code?

There are three big reasons:

### 1. Security
Your code lives in a Git repository. If you hardcode a password or API key in your code and push it to GitHub, that secret is now public — even if you delete it later, it's in the git history.

Environment variables live outside the code, so they never get committed.

### 2. Different environments need different values
Your API runs in multiple places:
- Your laptop (development)
- A test server (staging)
- The real server (production)

Each environment needs different database URLs, different API keys, different log levels. With environment variables, the same code runs everywhere — you just change the values.

| Variable | Development | Production |
|---|---|---|
| `DATABASE_URL` | `postgres://localhost/leewah` | `postgres://prod-server/leewah` |
| `RUST_LOG` | `debug` | `info` |
| `MTN_MOMO_ENV` | `sandbox` | `production` |

### 3. Separation of concerns
Code is logic. Config is data. They should live separately. This is a core principle of professional software development (part of the "12-Factor App" methodology used by most production APIs).

---

## What is a .env File?

A `.env` file is a simple text file that stores environment variables for local development. It lives in the project root and looks like this:

```
PORT=8080
DATABASE_URL=postgres://leewah:leewah@localhost:5432/leewah
JWT_SECRET=my-real-secret-here
```

When your Rust server starts, the `dotenvy` crate reads this file and loads every variable into the process environment. Then `std::env::var("PORT")` finds them.

### Rules for .env files:
- One variable per line
- Format: `KEY=value` (no spaces around `=`)
- Comments start with `#`
- No quotes needed around values
- NEVER commit this file to Git

---

## What is .env.example?

Since `.env` is gitignored, a new developer who clones the project has no idea what variables they need to set up. They'd be lost.

`.env.example` solves this. It is:
- The same structure as `.env`
- BUT with fake placeholder values instead of real secrets
- Safe to commit to Git
- A template that developers copy and fill in

### The workflow every developer follows:
```bash
# 1. Clone the project
git clone https://github.com/your-org/leewah-api

# 2. Copy the example file
cp .env.example .env

# 3. Open .env and fill in real values
# (database URL, API keys, etc.)

# 4. Run the server
cargo run
```

---

## The Leewah .env.example

```bash
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
R2_PUBLIC_URL=your-r2-public-url

# Anthropic (AI assistant)
ANTHROPIC_API_KEY=sk-your-anthropic-api-key

# MTN MoMo
MTN_MOMO_SUBSCRIPTION_KEY=your-key
MTN_MOMO_API_USER=your-user-id
MTN_MOMO_API_KEY=your-api-key
MTN_MOMO_ENV=sandbox

# Orange Money
ORANGE_MONEY_CLIENT_ID=your-client-id
ORANGE_MONEY_CLIENT_SECRET=your-secret
ORANGE_MONEY_ENV=sandbox

# Admin
ADMIN_IP_ALLOWLIST=127.0.0.1,your-office-ip
```

---

## How dotenvy Works in Rust

In `src/main.rs`, the very first thing you do is:
```rust
dotenvy::dotenv().ok();
```

This tells dotenvy: "look for a `.env` file in the current directory, read it, and load every variable into the environment."

Then anywhere in your code you can read a variable:
```rust
let port = std::env::var("PORT").unwrap_or_else(|_| "8080".to_string());
let db_url = std::env::var("DATABASE_URL").expect("DATABASE_URL must be set");
```

In production (Fly.io / Railway), you don't have a `.env` file. Instead, the platform injects the environment variables directly. Your code doesn't care — `std::env::var` works the same way either way.

---

## Key Things to Remember

1. **Never hardcode secrets in code** — use environment variables
2. **`.env` holds real secrets — never commit it**
3. **`.env.example` is the safe template — always commit it**
4. **`dotenvy` loads the `.env` file at startup** in development
5. **In production, the platform provides the variables** — no `.env` file needed
6. **Same code, different config = runs in any environment** — this is the professional way
