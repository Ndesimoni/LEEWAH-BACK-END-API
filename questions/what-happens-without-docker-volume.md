## Question
Why do we use volumes in Docker Compose? What happens to your database data if you stop the container without a volume?

## Answer
"it destroys the data"

## Full Explanation
Correct. When a Docker container stops, its internal filesystem is thrown away. The container stores data in its own isolated environment — when it stops, that environment is gone. All data is lost.

Volumes solve this by storing data OUTSIDE the container on your actual Mac hard drive. The container reads and writes to the volume. When the container stops and restarts, the volume is still there with all the data intact.

Two types of volumes:
- **Bind mount** (`./postgres-data`) — creates a folder on your Mac at that exact path. Simple but messy.
- **Named volume** (`postgres_data`) — Docker manages the storage internally. This is the recommended approach.

Named volumes are declared at the bottom of `docker-compose.yml`:
```yaml
volumes:
  postgres_data:
  redis_data:
```

And referenced in each service:
```yaml
volumes:
  - postgres_data:/var/lib/postgresql/data
```

The analogy: a container is like a rented office. A volume is your personal filing cabinet. You can leave the office (stop the container), come back tomorrow (restart it), and your filing cabinet is exactly where you left it.
