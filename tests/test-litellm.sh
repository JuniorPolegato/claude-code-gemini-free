#!/usr/bin/env bash
[ -f ~/.config/litellm/env ] && source ~/.config/litellm/env
: "${LITELLM_MASTER_KEY:?LITELLM_MASTER_KEY not set}"

# Models supported by our LiteLLM setup
models=(g38 g37 g36 g35 g3fp g35l g31l g431 g426)

printf "Testing LiteLLM Proxy on http://127.0.0.1:4000/v1\n"
failed=0

for m in "${models[@]}"; do
  resp=$(curl -s --max-time 60 -w '\n%{http_code}' http://127.0.0.1:4000/v1/chat/completions \
    -H "Authorization: Bearer $LITELLM_MASTER_KEY" -H 'Content-Type: application/json' \
    -d "{\"model\":\"$m\",\"messages\":[{\"role\":\"user\",\"content\":\"Hi!\"}]}")

  code=$(tail -n1 <<<"$resp"); body=$(sed '$d' <<<"$resp")

  if [ "$code" = 200 ]; then
    printf "✅ %-10s %s\n" "$m" "$(jq -r '.choices[0].message.content // empty' <<<"$body" | tr '\n' ' ' | head -c 60)"
  else
    printf "❌ %-10s %s %s\n" "$m" "$code" "$(jq -r '.error.message // empty' <<<"$body" | head -c 80)"
    failed=$((failed + 1))
  fi
done

# Verification of fallback chain (g38 trigger)
printf "\nTesting Fallback Chain (g38 trigger)...\n"
resp=$(curl -s --max-time 60 -w '\n%{http_code}' http://127.0.0.1:4000/v1/chat/completions \
  -H "Authorization: Bearer $LITELLM_MASTER_KEY" -H 'Content-Type: application/json' \
  -d '{"model":"g38","messages":[{"role":"user","content":"Hi!"}]}')
code=$(tail -n1 <<<"$resp"); body=$(sed '$d' <<<"$resp")

if [ "$code" = 200 ]; then
  used_model=$(jq -r '.model' <<<"$body")
  printf "✅ Fallback trigger: Requesting g38, used model: %s\n" "$used_model"
else
  printf "❌ Fallback trigger failed: %s %s\n" "$code" "$(jq -r '.error.message // empty' <<<"$body")"
  failed=$((failed + 1))
fi

exit "$failed"
