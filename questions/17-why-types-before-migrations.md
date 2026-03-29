## Question
Looking at the checklist, what should come before migrations — `src/types.rs` or the migrations themselves? Why?

## Answer
"I think types, cause we need to know the data types before sending it to the db"

## Full Explanation
Exactly right. `types.rs` defines the shared enums and DTOs (Data Transfer Objects) that models, requests, and responses all use.

If you wrote migrations first and then realized you needed a custom enum type, you'd have to go back and change things. Defining types first means your migrations can reference them confidently.

The correct order is:
1. `types.rs` — define shared enums and types first
2. `migrations/` — create database tables using those types
3. `models/` — Rust structs that map to the DB tables

This is the same principle as building a house — you design the blueprint (types) before pouring the foundation (migrations) before building the walls (models).

## Key concept — What is a DTO?
DTO stands for Data Transfer Object. It is a struct used to carry data between layers of your app:
- Request DTOs — what the mobile app sends to the API
- Response DTOs — what the API sends back to the mobile app

DTOs live in `types.rs` because they are shared across multiple route files. They are different from DB models — models map to database rows, DTOs map to JSON request/response bodies.
