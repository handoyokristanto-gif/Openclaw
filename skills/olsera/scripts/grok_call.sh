#!/usr/bin/env sh
set -eu

# OpenClaw Grok (xAI) Call Script
# Optimized for xAI Direct API Integration

PROMPT="${1:-$(cat -)}"

# --- STRATEGIC CONFIGURATION ---
# Default to Grok 4.3 which is highly capable
DEFAULT_MODEL="grok-4.3"
MODEL="${MODEL:-$DEFAULT_MODEL}"

# TOKEN EFFICIENCY: 
MAX_TOKENS="${MAX_TOKENS:-1000}" 
RETRY_COUNT=3
RETRY_DELAY=5

# --- PROVIDER CONFIGURATION ---
API_URL="https://api.x.ai/v1/chat/completions"

# --- CORE FUNCTION ---
call_llm() {
  local attempt=1
  local response=""
  
  while [ $attempt -le $RETRY_COUNT ]; do
    # xAI Payload
    PAYLOAD=$(jq -n \
      --arg model "$MODEL" \
      --arg content "$PROMPT" \
      --argjson max_tokens "$MAX_TOKENS" \
      '{
        model: $model,
        messages: [{role: "user", content: $content}],
        max_tokens: $max_tokens,
        temperature: 0.7,
        stream: false
      }')

    response=$(curl -sS -X POST "$API_URL" \
      -H "Authorization: Bearer $XAI_API_KEY" \
      -H "Content-Type: application/json" \
      -d "$PAYLOAD")
    
    # VALIDATION & ERROR HANDLING
    if echo "$response" | jq -e '.choices[0].message.content' >/dev/null 2>&1; then
      echo "$response" | jq -r '.choices[0].message.content'
      return 0
    else
      error_msg=$(echo "$response" | jq -r '.error.message // "Unknown error"')
      echo "Attempt $attempt failed: $error_msg" >&2
      
      # Handle common errors (Rate Limit 429)
      if echo "$response" | grep -q "429"; then
        echo "Rate limit reached. Waiting longer..." >&2
        sleep 10
      fi
    fi

    attempt=$((attempt + 1))
    [ $attempt -le $RETRY_COUNT ] && sleep $RETRY_DELAY
  done

  echo "ERROR: xAI Grok connection failed after $RETRY_COUNT attempts." >&2
  return 1
}

# --- MAIN ---
if [ -z "${XAI_API_KEY:-}" ]; then
  echo "ERROR: XAI_API_KEY is not set." >&2
  exit 2
fi

call_llm
