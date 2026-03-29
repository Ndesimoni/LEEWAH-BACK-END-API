## Question
What do you think is the difference between `"warn"` and `"deny"` in Rust lints?

## Answer
"deny like refuse to compile while warn is still going to compile but give warning"

## Full Explanation
Exactly right. There are three lint levels in Rust:

- `"allow"` — completely silences the lint. Used when you intentionally want to break a rule in one specific place.
- `"warn"` — compiles but prints a warning. You see the problem but the build succeeds.
- `"deny"` — refuses to compile. The warning becomes a hard error. Build fails until you fix it.

For the Leewah API we use `"warn"` while learning because `"deny"` would make the compiler very aggressive for a beginner. Once the codebase is mature you can upgrade critical lints to `"deny"` to enforce stricter standards.

Example in `Cargo.toml`:
```toml
[lints.rust]
unused_imports = "warn"     # warns but still compiles
dead_code = "warn"

[lints.clippy]
all = "warn"                # standard clippy rules
pedantic = "warn"           # extra strict rules
```
