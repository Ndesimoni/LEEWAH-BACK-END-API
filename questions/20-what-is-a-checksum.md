## Question
What is a checksum?

## Answer
(Asked during migration discussion)

## Full Explanation
A checksum is a unique fingerprint of a file's contents.

When sqlx runs a migration it calculates a checksum of the SQL file and stores it in the `_sqlx_migrations` table. Next time you run `sqlx migrate run`, it recalculates the checksum of every previously applied migration and compares it to what's stored. If they don't match — the file was modified — sqlx refuses to run:

```
error: migration 1 was previously applied but has been modified
```

**The analogy:** A checksum is like a wax seal on a letter. If anyone opens and reseals it, the seal looks different and you know it was tampered with.

**Why it matters for migrations:**
- Protects you from accidentally running different SQL than what ran on production
- Guarantees every environment (dev, staging, production) ran exactly the same SQL
- Makes migrations tamper-proof

**The lesson learned:** Never modify a migration file after it has been applied. The checksum will catch it and block you. Always create a new migration file for changes.
