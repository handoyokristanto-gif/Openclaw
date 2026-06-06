#!/usr/bin/env sh
set -eu

PROMPT="${1:-$(cat -)}"
MODEL="${MODEL:-google/gemini-3-pro-preview}"
API_URL="${API_URL:-https://generativelanguage.googleapis.com/v1/models/$MODEL:generateText}" 
MAX_TOKENS="${MAX_TOKENS:-512}"

if [ -n "${GEMINI_ACCESS_TOKEN:-}" ]; then
  TOKEN="$GEMINI_ACCESS_TOKEN"
elif command -v gcloud >/dev/null 2>&1; then
  TOKEN="$(gcloud auth print-access-token)"
else
  echo "ERROR: No access token. Set GEMINI_ACCESS_TOKEN or install/configure gcloud." >&2
  exit 2
fi

curl -sS -X POST "$API_URL" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json; charset=utf-8" \
  -d "{
    \"prompt\": { \"text\": \"${PROMPT//\"/\\\"}\" },
    \"maxOutputTokens\": ${MAX_TOKENS}
  }"
