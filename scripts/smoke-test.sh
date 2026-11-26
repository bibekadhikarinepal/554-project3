#!/bin/sh
# Checks the API responds and the Redis counter increases by 1 per request.
# Usage: scripts/smoke-test.sh [URL] [REQUESTS]   (URL defaults to terraform output api_url)
set -eu

URL="${1:-$(terraform output -raw api_url)}"
REQUESTS="${2:-3}"

field() {
  printf '%s\n' "$2" | sed -n "s/.*\"$1\": *\"\{0,1\}\([^\",]*\)\"\{0,1\},\{0,1\}\$/\1/p" | head -n 1
}

echo "Smoke test: $REQUESTS request(s) to $URL/"
previous=""
i=1
while [ "$i" -le "$REQUESTS" ]; do
  if ! body=$(curl -fsS --max-time 5 "$URL/"); then
    echo "FAIL: request $i got no HTTP 200 response from $URL/"
    exit 1
  fi

  count=$(field redisCount "$body")
  error=$(field redisError "$body")
  echo "  request $i: HTTP 200 service=$(field service "$body") hostname=$(field hostname "$body") localCount=$(field localCount "$body") redisCount=$count redisError=$error"

  if [ "$error" != "null" ]; then
    echo "FAIL: API is up but could not reach Redis (redisError=$error)"
    exit 1
  fi
  if [ -n "$previous" ] && [ "$count" -ne $((previous + 1)) ]; then
    echo "FAIL: redisCount went from $previous to $count (expected $((previous + 1)))"
    exit 1
  fi
  previous="$count"
  i=$((i + 1))
done

echo "PASS: API responded and the Redis-backed counter incremented on every request."
