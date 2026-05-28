#!/bin/bash

# Start ArangoDB 3.12 for testing
# Usage: ./reset_docker.sh
#
# Sets root password to "test" and exposes on localhost:8529
# Run tests with: ARANGO_HOST=localhost ARANGO_USER=root ARANGO_PASSWORD=test mix test

set -e

docker compose down -v 2>/dev/null || true
docker compose up -d

echo "Waiting for ArangoDB to start..."
until curl -s http://localhost:8529/_api/version > /dev/null 2>&1; do
  sleep 1
done

echo "ArangoDB ready at http://localhost:8529"
echo "  User: root"
echo "  Password: test"
echo ""
echo "Run tests:"
echo "  ARANGO_HOST=localhost ARANGO_USER=root ARANGO_PASSWORD=test mix test"
