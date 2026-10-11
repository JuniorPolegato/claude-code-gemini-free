#!/usr/bin/env bash
[ -f ~/.config/litellm/env ] && source ~/.config/litellm/env
: "${OPENROUTER_API_KEY:?OPENROUTER_API_KEY not set}"

models=(
  cohere/north-mini-code:free
  poolside/laguna-s-2.1:free
  nvidia/nemotron-3-ultra-550b-a55b:free
)

failed=0
for m in "${models[@]}"; do
  resp=$(curl -s --max-time 60 -w '\n%{http_code}' https://openrouter.ai/api/v1/chat/completions \
    -H "Authorization: Bearer $OPENROUTER_API_KEY" -H 'Content-Type: application/json' \
    -d "{\"model\":\"$m\",\"messages\":[{\"role\":\"user\",\"content\":\"Hi!\"}]}")
  code=$(tail -n1 <<<"$resp"); body=$(sed '$d' <<<"$resp")
  if [ "$code" = 200 ]; then
    printf "✅ %-45s %s\n" "$m" "$(jq -r '.choices[0].message.content // empty' <<<"$body" | tr '\n' ' ' | head -c 60)"
  else
    printf "❌ %-45s %s %s\n" "$m" "$code" "$(jq -r '.error.message // empty' <<<"$body" | head -c 80)"
    failed=$((failed + 1))
  fi
done

exit "$failed"
