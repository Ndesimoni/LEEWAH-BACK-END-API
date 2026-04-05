## Question
The `children` table has a `deleted_at` column instead of actually deleting rows. Why do we use `deleted_at` (soft delete) instead of a real DELETE statement?

## Answer
"so that the delete will show the time it was deleted" / "it will be deleted too (payment history)"

## Full Explanation
Financial records must never be deleted. A child has payment plans, which have fee payments — real financial transactions where money was moved.

If you hard delete the child row with `DELETE FROM children WHERE id = $1`, PostgreSQL cascades and deletes all linked payment plans and fee payments too. That means:
- Payment history is gone forever
- No proof that fees were paid (disputes become impossible to resolve)
- School disbursement records are lost

**Soft delete** solves this:
- Set `deleted_at = now()` instead of deleting the row
- The row stays in the database forever with all its history intact
- Every query filters with `WHERE deleted_at IS NULL` so the app never shows it
- From the user's perspective the child is gone — but the data is safe

| | Hard Delete | Soft Delete |
|---|---|---|
| Row in DB | Gone forever | Still there |
| Payment history | Destroyed | Preserved |
| How to "delete" | `DELETE FROM children` | `UPDATE children SET deleted_at = now()` |
| How to query | `SELECT * FROM children` | `SELECT * FROM children WHERE deleted_at IS NULL` |

In Leewah, `children` uses soft delete. Financial tables (`fee_payments`, `wallet_transactions`) never get deleted at all — they are permanent ledger records.
