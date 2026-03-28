## Question
What do you think a "connection pool" is, and why would you need one instead of just opening a new database connection for every request?

## Answer
A connection pool is like a stack/queue of requests that lines up according to the order in which the requests came in.

## Full Explanation
Good thinking — the queue part is right, but there's more to it.

A connection pool is a **set of database connections that are created once at startup and reused**.

Think of it like a taxi rank:
- **No pool** — every request hires a new taxi, waits for it to be built from scratch, uses it, then destroys it. 100 requests = 100 taxis built and destroyed. Very slow and expensive.
- **With a pool** — there are 10 taxis always waiting. A request grabs one, uses it, returns it. If all 10 are busy, the next request waits in the queue.

Opening a database connection is expensive — it involves:
- TCP handshake
- Authentication
- SSL negotiation

That can take **50-200ms** per connection. For an API that needs to respond in under 100ms total, you can't afford that on every request.

With sqlx's `PgPool`:
- Connections are opened **once** at startup
- Every request **borrows** a connection from the pool
- When done, it's **returned** to the pool — not closed
- You set a max (e.g. 10 connections) — extra requests wait in the queue
