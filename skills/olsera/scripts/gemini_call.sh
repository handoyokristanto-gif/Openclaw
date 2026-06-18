#!/usr/bin/env sh
set -eu

# OpenClaw LLM Call Script - Strategic & Token Efficient Version
# Supports: Google AI Studio (Direct) and OpenRouter (OpenAI-compatible)

PROMPT="${1:-$(cat -)}"

# --- STRATEGIC CONFIGURATION ---
# Default to a robust free model if not specified. 
# 'openrouter/auto' can be unstable for free tier, so we prioritize specific free models.
# Preferred: google/gemini-2.0-flash-exp:free (Fast, large context, free)
DEFAULT_MODEL="meta-llama/llama-3.3-70b-instruct:free"
MODEL="${MODEL:-$DEFAULT_MODEL}"

# TOKEN EFFICIENCY: 
# 1. Limit max tokens to what's strictly necessary for Olsera responses.
# 2. OpenRouter free tier has tight rate limits; shorter prompts = faster processing.
MAX_TOKENS="${MAX_TOKENS:-800}" 
RETRY_COUNT=3
RETRY_DELAY=3

# --- PROVIDER DETECTION ---
if [ -z "${API_URL:-}" ]; then
  if [ -n "${OPENROUTER_API_KEY:-}" ]; then
    API_URL="https://openrouter.ai/api/v1/chat/completions"
    PROVIDER="openrouter"
  else
    # Fallback to Google Direct
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

# --- CORE FUNCTION ---
call_llm() {
  local attempt=1
  local response=""
  
  # STRATEGY: Handle 'openrouter/free' or 'openrouter/auto' by mapping to actual free models 
  # if the generic one fails or to ensure we stay in the free tier.
  # We also handle variations of the Llama 3.3 70B model ID to prevent "Unknown model" errors.
  case "$MODEL" in
    "openrouter/free"|"openrouter/auto"|"meta-llama/llama-3.3-70b-instruct:free"|"llama-3.3-70b-instruct:free"|"meta-llama/llama-3.3-70b-instruct"|"openrouter/meta-llama/llama-3.3-70b-instruct:free")
      CURRENT_MODEL="meta-llama/llama-3.3-70b-instruct:free"
      ;;
    "google/gemini-2.0-flash-exp:free"|"gemini-2.0-flash-exp:free"|"google/gemini-2.0-flash-exp"|"openrouter/google/gemini-2.0-flash-exp:free")
      CURRENT_MODEL="google/gemini-2.0-flash-exp:free"
      ;;
    *)
      # For any other model, if using OpenRouter, ensure it has the :free suffix if it's a known free model
      # and strip the 'openrouter/' prefix if present for the internal API call.
      if [ "$PROVIDER" = "openrouter" ]; then
        # Strip prefix for internal mapping if present
        TEMP_MODEL=$(echo "$MODEL" | sed 's|^openrouter/||')
        if echo "$TEMP_MODEL" | grep -qE "llama-3.2-3b-instruct|qwen3-coder|pixtral-12b|deepseek-chat" && ! echo "$TEMP_MODEL" | grep -q ":free"; then
          CURRENT_MODEL="$TEMP_MODEL:free"
        else
          CURRENT_MODEL="$TEMP_MODEL"
        fi
      else
        CURRENT_MODEL="$MODEL"
      fi
      ;;
  esac

  while [ $attempt -le $RETRY_COUNT ]; do
    if [ "$PROVIDER" = "openrouter" ]; then
      # OpenRouter Payload with optimized headers for free tier
      PAYLOAD=$(jq -n \
        --arg model "$CURRENT_MODEL" \
        --arg content "$PROMPT" \
        --argjson max_tokens "$MAX_TOKENS" \
        '{
          model: $model,
          messages: [{role: "user", content: $content}],
          max_tokens: $max_tokens,
          temperature: 0.7,
          top_p: 0.9
        }')

      response=$(curl -sS -X POST "$API_URL" \
        -H "Authorization: Bearer $OPENROUTER_API_KEY" \
        -H "Content-Type: application/json" \
        -H "HTTP-Referer: https://github.com/handoyokristanto-gif/Openclaw" \
        -H "X-Title: OpenClaw-Olsera" \
        -d "$PAYLOAD")
      
      # VALIDATION & ERROR HANDLING
      if echo "$response" | jq -e '.choices[0].message.content' >/dev/null 2>&1; then
        echo "$response" | jq -r '.choices[0].message.content'
        return 0
      else
        error_code=$(echo "$response" | jq -r '.error.code // "N/A"')
        error_msg=$(echo "$response" | jq -r '.error.message // "Unknown error"')
        
        echo "Attempt $attempt failed ($error_code): $error_msg" >&2
        
        # STRATEGIC FALLBACK: If 403 (Forbidden) or 401 (Unauthorized) on a specific model, 
        # try the most reliable free model on next attempt.
        if [ "$error_code" = "403" ] || [ "$error_code" = "401" ] || [ "$error_code" = "400" ] || [ "$error_code" = "404" ] || [ "$error_code" = "429" ]; then
           # Cycle through verified available free models
           case "$CURRENT_MODEL" in
             "meta-llama/llama-3.3-70b-instruct:free") CURRENT_MODEL="meta-llama/llama-3.2-3b-instruct:free" ;;
             "meta-llama/llama-3.2-3b-instruct:free") CURRENT_MODEL="qwen/qwen3-coder:free" ;;
             *) CURRENT_MODEL="meta-llama/llama-3.3-70b-instruct:free" ;;
           esac
           echo "Switching to fallback: $CURRENT_MODEL" >&2
        fi
      fi

    elif [ "$PROVIDER" = "google" ]; then
      # Google Gemini Direct
      if [ -z "${GEMINI_ACCESS_TOKEN:-}" ] && command -v gcloud >/dev/null 2>&1; then
        TOKEN="$(gcloud auth print-access-token)"
      else
        TOKEN="${GEMINI_ACCESS_TOKEN:-}"
      fi

      if [ -z "$TOKEN" ]; then
        echo "ERROR: No access token for Google Provider." >&2
        exit 2
      fi

      response=$(curl -sS -X POST "$API_URL" \
        -H "Authorization: Bearer $TOKEN" \
        -H "Content-Type: application/json" \
        -d "{
          \"contents\": [{\"parts\":[{\"text\": $(echo "$PROMPT" | jq -R .)}]}],
          \"generationConfig\": {\"maxOutputTokens\": $MAX_TOKENS}
        }")
      
      if echo "$response" | jq -e '.candidates[0].content.parts[0].text' >/dev/null 2>&1; then
        echo "$response" | jq -r '.candidates[0].content.parts[0].text'
        return 0
      else
        echo "Attempt $attempt failed: $(echo "$response" | jq -r '.error.message // "Unknown error"')" >&2
      fi
    fi

    attempt=$((attempt + 1))
    [ $attempt -le $RETRY_COUNT ] && sleep $RETRY_DELAY
  done

  echo "ERROR: OpenRouter/Gemini connection failed after $RETRY_COUNT attempts." >&2
  return 1
}

# --- MAIN ---
if [ "$PROVIDER" = "openrouter" ] && [ -z "${OPENROUTER_API_KEY:-}" ]; then
  echo "ERROR: OPENROUTER_API_KEY is not set." >&2
  exit 2
fi

call_llm
