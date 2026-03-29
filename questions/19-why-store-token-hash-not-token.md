## Question
`refresh_tokens` has a `token_hash` field instead of storing the actual token. Why do we store a hash of the token instead of the token itself?

## Answer
"so that in case our db is breached hackers cannot get access to it"

## Full Explanation
Exactly right. If someone steals your database:

- **Without hashing** — they get the actual refresh tokens and can log in as any user immediately
- **With hashing** — they get a list of SHA-256 hashes. A hash cannot be reversed back to the original token. Useless to the attacker.

Same reason passwords are never stored in plain text. The token is like a password — you only ever store the hash, never the real value.

**How it works at runtime:**
1. Server generates a 64-byte random refresh token
2. Server hashes it with SHA-256
3. Server stores ONLY the hash in the database
4. Server sends the REAL token to the mobile app
5. Next time the app sends the token, the server hashes it again and compares to the stored hash
6. If they match — valid session

The real token never touches the database. Even if the database is completely stolen, the attacker cannot use the hashes to log in as users.

This is the same principle as password hashing — never store sensitive values, only store a one-way hash of them.
