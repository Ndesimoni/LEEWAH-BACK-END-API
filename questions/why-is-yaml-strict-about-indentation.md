## Question
Why is YAML so strict about indentation?

## Answer
YAML is so strict because it uses indentation/spaces to define structure.

## Full Explanation
Exactly right. YAML has no brackets or braces like JSON does — indentation **is** the structure. Two spaces in means "this belongs to the thing above it." That's why moving `redis:` two spaces to the right completely changes its meaning from a root-level key to a service nested under `services:`.
