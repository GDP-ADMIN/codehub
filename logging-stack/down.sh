#!/bin/bash
set -e

echo "Stopping all Docker Compose services..."

# Find all docker-compose.* files and execute `docker compose down` with the specific file
find . -name 'docker-compose.*' | while read -r file; do
    echo "Running 'docker compose down' for $file"
    docker compose -f "$file" down
done

echo "All Docker Compose services have been stopped."
