#!/bin/bash
# Setup script to create the test user in GoTrue
# Run this after docker-compose services are up

set -e

AUTH_URL="${AUTH_URL:-http://localhost:9999}"
TEST_EMAIL="test@linguaflutter.dev"
TEST_PASSWORD="testpass123"

echo "Waiting for GoTrue to be ready..."
for i in {1..30}; do
  if curl -sf "$AUTH_URL/health" > /dev/null 2>&1; then
    echo "GoTrue is ready"
    break
  fi
  echo "Waiting... ($i/30)"
  sleep 2
done

echo "Creating test user: $TEST_EMAIL"
RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "$AUTH_URL/signup" \
  -H "Content-Type: application/json" \
  -d "{\"email\":\"$TEST_EMAIL\",\"password\":\"$TEST_PASSWORD\"}")

HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
BODY=$(echo "$RESPONSE" | sed '$d')

if [ "$HTTP_CODE" = "200" ] || [ "$HTTP_CODE" = "201" ]; then
  echo "Test user created successfully"
elif echo "$BODY" | grep -q "already registered"; then
  echo "Test user already exists"
else
  echo "Warning: User creation returned $HTTP_CODE"
  echo "$BODY"
fi

echo "Test user setup complete"
