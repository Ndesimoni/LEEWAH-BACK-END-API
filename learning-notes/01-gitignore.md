# .gitignore

## What is Git?

Before understanding `.gitignore`, you need to understand what Git is tracking.

Git is a version control system. Every time you make a commit, Git takes a snapshot of all the files in your project and saves that snapshot. This means:
- You can go back to any previous version of your code
- Multiple developers can work on the same project without overwriting each other
- Your entire code history is saved

The problem is — Git tracks EVERYTHING in your project folder by default. And not everything should be tracked.

---

## What is .gitignore?

`.gitignore` is a file that tells Git: "ignore these files and folders — never track them, never commit them, never show them in `git status`."

It lives in the root of your project and Git reads it automatically.

---

## Why Some Files Should Never Be Committed

### 1. Build artifacts — `target/`

When you run `cargo build`, Rust compiles your code and puts the output in a folder called `target/`. This folder contains:
- Compiled binaries
- Compiled dependencies
- Temporary build files

**Why ignore it?**
- It can be gigabytes in size
- It is generated automatically from your source code — anyone can recreate it by running `cargo build`
- Committing it would make your repo huge and slow to clone
- It changes constantly, creating noise in your git history

Rule: **Never commit generated files. Only commit source files.**

### 2. Secret files — `.env`

Your `.env` file contains real secrets:
- Database passwords
- API keys for MTN MoMo, Africa's Talking, Anthropic
- JWT secret key
- Cloudflare R2 credentials

**Why ignore it?**
- If you push `.env` to GitHub, anyone who can see your repo can steal your keys
- With your MoMo API key someone could initiate payments on your account
- With your Anthropic key someone could run up a huge AI bill on your credit card
- This is one of the most common security mistakes developers make

This is so serious that companies have entire automated systems scanning GitHub for accidentally committed API keys.

### 3. OS junk files — `.DS_Store`

`.DS_Store` is a hidden file that macOS creates automatically in every folder. It stores folder display settings (icon positions, view preferences). It has nothing to do with your code.

**Why ignore it?**
- It is Mac-specific — Linux and Windows developers don't have it
- It adds noise to your git history
- It can accidentally expose folder structure information

### 4. Certificate and key files — `*.pem`, `*.key`

These are cryptographic files:
- `.pem` — certificate files (used for SSL/TLS, FCM service accounts)
- `.key` — private key files

**Why ignore it?**
- A private key is like a master password — whoever has it can impersonate your server
- These should NEVER be in version control — use environment variables or secret managers instead

### 5. Log files — `*.log`

Log files record what your server is doing. They can contain:
- Phone numbers of users
- User IDs
- Request details
- Error messages with sensitive context

**Why ignore it?**
- Log files can grow very large
- They can contain personal user data (privacy concern)
- They change constantly, making them useless in version control

---

## How .gitignore Syntax Works

```
# This is a comment

/target          # The leading / means only the target folder at the ROOT of the project
.env             # Any file named .env anywhere in the project
.DS_Store        # Any file named .DS_Store anywhere in the project
*.pem            # Any file ending in .pem (the * is a wildcard)
*.key            # Any file ending in .key
*.log            # Any file ending in .log
```

### Key syntax rules:
- `#` starts a comment
- `*` is a wildcard (matches anything)
- Leading `/` anchors to the project root only
- No leading `/` matches the pattern anywhere in the project

---

## The Leewah .gitignore

```
/target
.env
.DS_Store
*.pem
*.key
*.log
```

---

## Key Things to Remember

1. **Commit code, not build output** — `target/` is always ignored in Rust projects
2. **Never commit secrets** — `.env` always goes in `.gitignore`
3. **`.env.example` is the exception** — it's safe to commit because it has fake placeholder values, not real secrets
4. **Wildcards (`*`) match any filename with that extension** — `*.log` catches `server.log`, `error.log`, `debug.log` etc.
5. **Once a file is committed, `.gitignore` won't hide it** — if you accidentally commit `.env`, you need to remove it from Git history, not just add it to `.gitignore`
