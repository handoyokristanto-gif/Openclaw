#!/usr/bin/env sh
set -eu

# OpenClaw LLM Call Script
# Supports: Google AI Studio (Direct) and OpenRouter (OpenAI-compatible)

PROMPT="${1:-$(cat -)}"
# Default to OpenRouter Gemini Flash 1.5 if not specified
MODEL="${MODEL:-google/gemini-flash-1.5}"
MAX_TOKENS="${MAX_TOKENS:-1024}"

# Detect Provider based on API_URL or Model Name
# If MODEL starts with 'google/' and no API_URL is set, we check for OPENROUTER_API_KEY
if [ -z "${API_URL:-}" ]; then
  if [ -n "${OPENROUTER_API_KEY:-}" ]; then
    API_URL="https://openrouter.ai/api/v1/chat/completions"
    PROVIDER="openrouter"
  else
    # Fallback to Google Direct if no OpenRouter key
    API_URL="https://generativelanguage.googleapis.com/v1/models/$MODEL:generateContent"
    PROVIDER="google"
  fi
else
  if echo "$API_URL" | grep -q "openrouter.ai"; then
    PROVIDER="openrouter"
  else
    PROVIDER="google"
  fi
fi

# Authentication
if [ "$PROVIDER" = "openrouter" ]; then
  if [ -z "${OPENROUTER_API_KEY:-}" ]; then
    echo "ERROR: OPENROUTER_API_KEY is not set." >&2
    exit 2
  fi
  TOKEN="$OPENROUTER_API_KEY"
  
  # OpenRouter / OpenAI Format
  PAYLOAD=$(cat <<EOF
{
  "model": "$MODEL",
  "messages": [
    {
      "role": "user",
      "content": "$(echo "$PROMPT" | sed 's/"/\\"/g' | tr -d '\n')"
    }
  ],
  "max_tokens": $MAX_TOKENS
}
EOF
)

  curl -sS -X POST "$API_URL" \
    -H "Authorization: Bearer $TOKEN" \
    -H "Content-Type: application/json" \
    -d "$PAYLOAD" | jq -r '.choices[0].message.content // .error.message'

elif [ "$PROVIDER" = "google" ]; then
  if [ -n "${GEMINI_ACCESS_TOKEN:-}" ]; then
    TOKEN="$GEMINI_ACCESS_TOKEN"
  elif command -v gcloud >/dev/null 2>&1; then
    TOKEN="$(gcloud auth print-access-token)"
  else
    echo "ERROR: No access token. Set GEMINI_ACCESS_TOKEN or OPENROUTER_API_KEY." >&2
    exit 2
  fi

  # Google Gemini Direct Format (generateContent)
  # Note: The old 'generateText' is deprecated for newer models
  curl -sS -X POST "$API_URL" \
    -H "Authorization: Bearer $TOKEN" \
    -H "Content-Type: application/json" \
    -d "{
      \"contents\": [{
        \"parts\":[{\"text\": \"$(echo "$PROMPT" | sed 's/"/\\"/g' | tr -d '\n')\"}]
      }],
      \"generationConfig\": {
        \"maxOutputTokens\": $MAX_TOKENS
      }
    }" | jq -r '.candidates[0].content.parts[0].text // .error.message'
fi
