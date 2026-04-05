## Question
The `payment_plans` table has `amount_remaining INTEGER GENERATED ALWAYS AS (total_fee_amount - amount_paid) STORED`. What does `GENERATED ALWAYS AS` mean and why is it useful?

## Answer
"to always show the amount paid and the amount remaining"

## Full Explanation
`GENERATED ALWAYS AS` means PostgreSQL automatically calculates the column's value from other columns. You never insert or update it manually — the database does it for you.

Every time `amount_paid` changes, PostgreSQL automatically recalculates:
```
amount_remaining = total_fee_amount - amount_paid
```

**Without it** — you'd have to:
1. Read `total_fee_amount` from the database
2. Read `amount_paid`
3. Calculate `amount_remaining` in Rust code
4. Store the result back

**With it** — you just update `amount_paid` and PostgreSQL handles everything else automatically.

**Why this matters:**
The calculation lives in the database — always correct regardless of which application or tool updates the data. No risk of your Rust code and the database getting out of sync. If someone updates `amount_paid` directly via a database client (during a bug fix for example), `amount_remaining` still updates correctly.

**`STORED` keyword:**
The value is physically saved to disk when written — not recalculated on every read. This makes reads fast at the cost of a tiny bit of extra storage.

The opposite would be a virtual/computed column that recalculates on every read — PostgreSQL supports both but `STORED` is better for frequently read fields like remaining balance.
