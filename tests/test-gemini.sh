#!/usr/bin/env bash
[ -f ~/.config/litellm/env ] && source ~/.config/litellm/env
: "${GEMINI_API_KEY:?GEMINI_API_KEY not set}"

models=(
  gemini-3.8-flash gemini-3.7-flash gemini-3.6-flash gemini-3.5-flash
  gemini-3-flash-preview gemini-3.5-flash-lite gemini-3.1-flash-lite
  gemini-2.5-flash gemini-2.5-flash-lite gemma-4-31b-it gemma-4-26b-a4b-it
)

for m in "${models[@]}"; do
  resp=$(curl -s --max-time 60 -w '\n%{http_code}' \
    "https://generativelanguage.googleapis.com/v1beta/models/$m:generateContent" \
    -H "x-goog-api-key: $GEMINI_API_KEY" -H 'Content-Type: application/json' \
    -d '{"contents":[{"parts":[{"text":"Hi!"}]}]}')
  code=$(tail -n1 <<<"$resp"); body=$(sed '$d' <<<"$resp")
  if [ "$code" = 200 ]; then
    printf "✅ %-26s %s\n" "$m" "$(jq -r '.candidates[0].content.parts[-1].text' <<<"$body" | tr '\n' ' ' | head -c 60)"
  else
    printf "❌ %-26s %s %s\n" "$m" "$code" "$(jq -r '.error.message // empty' <<<"$body" | head -c 80)"
  fi
done
