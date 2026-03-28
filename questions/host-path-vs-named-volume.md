## Question
What is the difference between a host path volume and a named volume in Docker?

## Answer
User asked Claude to explain — did not know the answer yet.

## Full Explanation
**Host Path Volume** (`./postgres-data:/var/lib/postgresql/data`):
- The `./` means a folder on your actual computer, right next to your docker-compose.yml
- You can open it in Finder and see the raw database files
- Pro: easy to inspect. Con: litters your project folder with data directories

**Named Volume** (`postgres-data:/var/lib/postgresql/data`):
- No `./` — just a name. Docker manages the storage location internally
- You don't see it in your project folder
- Pro: clean project folder, Docker handles it properly. Con: harder to manually inspect

**Which Leewah uses:** Named volumes — declared at the bottom of docker-compose.yml under `volumes:` and referenced by name inside each service.

Think of it like:
- The bottom `volumes:` block = **defining** the volume
- The `volumes:` inside each service = **using** the volume
