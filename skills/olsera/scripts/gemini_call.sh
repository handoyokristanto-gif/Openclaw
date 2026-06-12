#!/usr/bin/env sh
set -eu

# OpenClaw LLM Call Script
# Supports: Google AI Studio (Direct) and OpenRouter (OpenAI-compatible)

PROMPT="${1:-$(cat -)}"
# Default to OpenRouter Gemini Flash 1.5 if not specified
MODEL="${MODEL:-google/gemini-flash-1.5}"
MAX_TOKENS="${MAX_TOKENS:-1024}"
RETRY_COUNT=3
RETRY_DELAY=2

# Detect Provider based on API_URL or Model Name
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

# Function to perform the call with retries
call_llm() {
  local attempt=1
  local response=""
  local status=0

  while [ $attempt -le $RETRY_COUNT ]; do
    if [ "$PROVIDER" = "openrouter" ]; then
      # OpenRouter / OpenAI Format
      PAYLOAD=$(cat <<EOF
{
  "model": "$MODEL",
  "messages": [
    {
      "role": "user",
      "content": $(echo "$PROMPT" | jq -R .)
    }
  ],
  "max_tokens": $MAX_TOKENS
}
EOF
)
      response=$(curl -sS -X POST "$API_URL" \
        -H "Authorization: Bearer $OPENROUTER_API_KEY" \
        -H "Content-Type: application/json" \
        -H "HTTP-Referer: https://github.com/handoyokristanto-gif/Openclaw" \
        -H "X-Title: OpenClaw" \
        -d "$PAYLOAD")
      
      # Check if response has choices
      if echo "$response" | jq -e '.choices[0].message.content' >/dev/null 2>&1; then
        echo "$response" | jq -r '.choices[0].message.content'
        return 0
      else
        error_msg=$(echo "$response" | jq -r '.error.message // "Unknown error"')
        echo "Attempt $attempt failed: $error_msg" >&2
      fi

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
      response=$(curl -sS -X POST "$API_URL" \
        -H "Authorization: Bearer $TOKEN" \
        -H "Content-Type: application/json" \
        -d "{
          \"contents\": [{
            \"parts\":[{\"text\": $(echo "$PROMPT" | jq -R .)}]
          }],
          \"generationConfig\": {
            \"maxOutputTokens\": $MAX_TOKENS
          }
        }")
      
      if echo "$response" | jq -e '.candidates[0].content.parts[0].text' >/dev/null 2>&1; then
        echo "$response" | jq -r '.candidates[0].content.parts[0].text'
        return 0
      else
        error_msg=$(echo "$response" | jq -r '.error.message // "Unknown error"')
        echo "Attempt $attempt failed: $error_msg" >&2
      fi
    fi

    attempt=$((attempt + 1))
    [ $attempt -le $RETRY_COUNT ] && sleep $RETRY_DELAY
  done

  echo "ERROR: All $RETRY_COUNT attempts failed." >&2
  return 1
}

# Main Execution
if [ "$PROVIDER" = "openrouter" ] && [ -z "${OPENROUTER_API_KEY:-}" ]; then
  echo "ERROR: OPENROUTER_API_KEY is not set." >&2
  exit 2
fi

call_llm
