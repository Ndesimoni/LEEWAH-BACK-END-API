# Docker & Docker Compose

## The Problem Docker Solves

When building the Leewah API locally, you need:
- PostgreSQL running (for the database)
- Redis running (for the cache)

Without Docker, you would:
1. Install PostgreSQL on your Mac manually
2. Configure it (create users, databases)
3. Install Redis on your Mac manually
4. Make sure the right versions are running
5. Manage starting/stopping them yourself
6. Hope your colleague has the exact same versions installed

This is messy. Different machines end up with different versions. Config differs. "Works on my machine" becomes a constant problem.

Docker solves this completely.

---

## What is Docker?

Docker lets you run software in an isolated box called a **container**.

A container packages together:
- The software itself (e.g. PostgreSQL)
- Its operating system dependencies
- Its configuration
- Everything it needs to run

You don't install PostgreSQL on your Mac. You tell Docker "run a PostgreSQL container" and it handles everything. When you're done, you stop the container. Your Mac stays clean — nothing is permanently installed.

### A Helpful Analogy

Think of containers like **shipping containers** on a cargo ship:
- Each container is self-contained — everything inside is packed together
- You can move a container from ship to truck to train and it works the same way
- The contents don't care about the vehicle — they're isolated inside

Similarly, a Docker container runs the same way on your Mac, your colleague's Linux machine, or a production server.

---

## Key Docker Concepts

### Image
A Docker **image** is a blueprint — a snapshot of an operating system + software, frozen in time.

Examples:
- `postgres:16` — PostgreSQL version 16
- `redis:7-alpine` — Redis version 7 (alpine = lightweight version)

Images are downloaded from **Docker Hub** (like an app store for containers). They're maintained by the official software teams.

### Container
A **container** is a running instance of an image. The image is the blueprint, the container is the building.

You can run multiple containers from the same image. Each is isolated.

### Volume
A **volume** is persistent storage attached to a container.

By default, when a container stops, all data inside it is lost. For a database, this would mean losing all your data every time you restart — obviously not acceptable.

Volumes solve this by storing data outside the container, on your host machine. The container reads/writes to the volume. When the container stops and restarts, the data is still there.

### Port Mapping
Containers run in isolation — they have their own network. By default, you can't connect to them from your Mac.

Port mapping bridges this: `"5432:5432"` means:
- Your Mac's port 5432 → maps to → container's port 5432

So when your Rust server connects to `localhost:5432`, it's actually connecting to the PostgreSQL running inside the container.

---

## What is Docker Compose?

Docker Compose lets you define and run **multiple containers together** using a single file.

Instead of running two separate `docker run` commands for PostgreSQL and Redis, you define both in `docker-compose.yml` and start them together with one command.

---

## The docker-compose.yml Structure

```yaml
version: "3.8"

services:
  postgres:                          # Name of the service (you choose this)
    image: postgres:16               # Which image to use
    ports:
      - "5432:5432"                  # host-port:container-port
    environment:
      - POSTGRES_USER=leewah         # Variables the container needs
      - POSTGRES_PASSWORD=leewah
      - POSTGRES_DB=leewah
    volumes:
      - postgres_data:/var/lib/postgresql/data   # Where Postgres stores data

  redis:
    image: redis:7-alpine
    ports:
      - "6379:6379"
    volumes:
      - redis_data:/data             # Where Redis stores data

volumes:
  postgres_data:                     # Declare volumes here so Docker manages them
  redis_data:
```

### Breaking it down:

**`services:`** — Every container you want to run is listed here as a service.

**`image:`** — Which pre-built image to use. Docker downloads this from Docker Hub automatically.

**`ports:`** — Maps a port on your Mac to a port in the container. Format: `"mac-port:container-port"`

**`environment:`** — Environment variables passed into the container. PostgreSQL uses these to create the initial database user and database name.

**`volumes:`** — Attaches persistent storage. Format: `volume-name:path-inside-container`

**`volumes:` (at the bottom)** — Declares the named volumes so Docker knows to manage them. Without this declaration, the volume names in services would be invalid.

---

## Essential Docker Compose Commands

```bash
# Start all containers in the background
docker-compose up -d

# Stop all containers (data is preserved in volumes)
docker-compose down

# Stop containers AND delete volumes (all data lost — use with care)
docker-compose down -v

# Watch logs from all containers
docker-compose logs -f

# Watch logs from one container only
docker-compose logs -f postgres

# Check which containers are running
docker-compose ps

# Restart a single service
docker-compose restart redis
```

---

## How This Connects to Your .env

Once your containers are running, your `.env` database URL matches exactly:

```
DATABASE_URL=postgres://leewah:leewah@localhost:5432/leewah
```

- `leewah:leewah` — the user and password you set in `POSTGRES_USER` / `POSTGRES_PASSWORD`
- `localhost:5432` — localhost because port 5432 is mapped to your Mac
- `/leewah` — the database name you set in `POSTGRES_DB`

The Rust server connects to `localhost:5432` → Docker redirects it to the PostgreSQL container.

---

## What is `alpine`?

You'll notice Redis uses `redis:7-alpine`, not just `redis:7`.

Alpine is a very minimal Linux distribution — only ~5MB. Regular Linux images can be 200MB+.

For containers you just want the software, not a full-featured OS. Alpine gives you exactly that. The tradeoff is it has fewer built-in tools, but for running a database or cache that doesn't matter.

Rule: **Use alpine images when available** — faster to download, less disk space, smaller attack surface for security.

---

## Key Things to Remember

1. **Docker runs software in isolated containers** — no need to install PostgreSQL or Redis directly on your Mac
2. **Images are blueprints, containers are running instances**
3. **Without volumes, all data is lost when a container stops** — always use volumes for databases
4. **Port mapping `"5432:5432"` bridges your Mac to the container**
5. **`docker-compose up -d`** starts everything, **`docker-compose down`** stops everything
6. **alpine images are smaller and faster** — prefer them when available
7. **Your `.env` DATABASE_URL must match the credentials in docker-compose.yml**
