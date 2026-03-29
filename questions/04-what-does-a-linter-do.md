## Question
What do you think a "linter" does in programming?

## Answer
"catches errors and unused variables"

## Full Explanation
Exactly right. A linter analyses your code WITHOUT running it and catches problems like:

- Unused variables
- Unused imports
- Dead code that can never execute
- Code that could be written more safely
- Common mistakes and bad patterns

Rust has a built-in linter called **Clippy**. It is more powerful than most linters because it knows Rust deeply and catches things that are technically valid code but are considered bad practice.

There are two levels of code checking in Rust:
1. **The compiler (`rustc`)** — catches hard errors. Code won't compile without fixing these.
2. **Clippy** — catches warnings and suggestions. Code still compiles but you are doing something questionable.

By adding `[lints.clippy]` to `Cargo.toml`, you configure Clippy to enforce rules across your entire project. Without the lints section, many warnings are silenced by default. With it, the compiler shouts at you about anything questionable — which is exactly what you want while learning Rust.
