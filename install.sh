#!/usr/bin/env bash
set -e

is_expired() {
  local jwt="$1"

  local payload_base64="${jwt#*.}"
  payload_base64="${payload_base64%%.*}"

  local remainder=$(( ${#payload_base64} % 4 ))
  if [ $remainder -eq 2 ]; then
    payload_base64="${payload_base64}=="
  elif [ $remainder -eq 3 ]; then
    payload_base64="${payload_base64}="
  fi

  # Decode and get exp
  local payload_json
  payload_json="$(echo "$payload_base64" | tr '_-' '/+' | base64 -d 2>/dev/null)"
  local exp
  exp="$(echo "$payload_json" | sed -n 's/.*"exp":[[:space:]]*\([0-9]*\).*/\1/p')"

  [ -z "$exp" ] && return 0

  local now
  now="$(date +%s)"

  if [ "$now" -ge "$exp" ]; then
    return 0
  else
    return 1
  fi
}

# Prepare clean build dir
rm -rf build
mkdir build
cd build

COMMAND="npx --yes croct@latest --stateless --no-interaction --dnd use $CROCT_PROJECT_TEMPLATE"

if is_expired "${CROCT_CLI_TOKEN:-}"; then
  env -u CROCT_TOKEN \
    CROCT_API_KEY="$CROCT_API_KEY" \
    CROCT_SKIP_API_KEY_SETUP=true \
    bash -c "$COMMAND"
else
  env -u CROCT_API_KEY \
    CROCT_TOKEN="$CROCT_CLI_TOKEN" \
    CROCT_SKIP_API_KEY_SETUP=true \
    bash -c "$COMMAND"
fi

cd ..
cp -rf build/*/* .
rm -rf build
