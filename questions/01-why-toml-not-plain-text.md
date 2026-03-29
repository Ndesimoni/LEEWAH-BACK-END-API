## Question
Why do you think we use `.toml` format for `rust-toolchain.toml` instead of just a plain text file?

## Answer
"don't know tell me"

## Full Explanation
TOML stands for "Tom's Obvious, Minimal Language". It is the standard configuration format across the entire Rust ecosystem. You see it in `Cargo.toml`, `rust-toolchain.toml`, `sqlx.toml`, and more.

The reason it is used instead of plain text is that configuration files often have structure — sections, key-value pairs, arrays, nested data. Plain text has no structure. TOML gives you:

- `[section]` headers to group related settings
- `key = "value"` pairs that are typed (strings, integers, booleans)
- Arrays: `features = ["ws", "multipart"]`
- Human-readable and writable — cleaner than JSON, less fragile than YAML

Compared to JSON:
```json
{ "toolchain": { "channel": "stable" } }
```

TOML is just:
```toml
[toolchain]
channel = "stable"
```

Same data. Much easier to read and write by hand.
