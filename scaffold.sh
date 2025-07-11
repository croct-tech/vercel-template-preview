#!/usr/bin/env bash
set -e
set -a

for envfile in $(find . -type f \( -name ".env.local" -o -name ".env.development.local" \)); do
  while IFS= read -r line; do
    if [[ -z "$line" || "$line" == \#* ]]; then
      continue
    fi

    line="${line%%#*}"

    key="${line%%=*}"
    val="${line#*=}"

    val="${val%\"}"
    val="${val#\"}"

    export "$key=$val"

  done < "$envfile"
done

set +a

# Check required env vars
required_vars=(
  "CROCT_PROJECT_TEMPLATE"
  "CROCT_WORKSPACE"
  "CROCT_ORGANIZATION"
  "CROCT_DEV_APP"
  "CROCT_PROD_APP"
)

for var in "${required_vars[@]}"; do
  if [ -z "${!var}" ]; then
    echo "Environment variable '$var' is missing."
    exit 1
  fi
done

is_token_expired() {
  local jwt="$1"

  local payload_base64="${jwt#*.}"
  payload_base64="${payload_base64%%.*}"

  local remainder=$(( ${#payload_base64} % 4 ))
  if [ $remainder -eq 2 ]; then
    payload_base64="${payload_base64}=="
  elif [ $remainder -eq 3 ]; then
    payload_base64="${payload_base64}="
  fi

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

find_page_folder() {
  local path="$1"

  local found=""
  for dir in "$path"/*/; do
    [[ ! -d "$dir" ]] && continue

    dir="${dir%/}"
    folder="${dir##*/}"

    if [[ "$folder" != "api" && -n "$folder" ]]; then
      found="$folder"
      break
    fi
  done

  if [[ -n "$found" ]]; then
    echo "$found"
    return 0
  else
    return 1
  fi
}

create_next_config() {
 local path="$1"
  local folder
  local config_name

  if folder=$(find_page_folder "$path"); then
    if [[ -f next.config.ts ]]; then
      config_name="next.config.ts"
    else
      config_name="next.config.js"
    fi

    cat > "$config_name" <<EOF
export default {
  redirects: () => Promise.resolve([
    {
      source: '/',
      destination: '/$folder',
      permanent: true,
    },
  ]),
};
EOF
  fi
}

rm -rf build
mkdir build
cd build

COMMAND="npx --yes croct@latest --stateless --no-interaction --dnd use $CROCT_PROJECT_TEMPLATE"

if is_token_expired "${CROCT_CLI_TOKEN:-}"; then
  if [ -n "${CROCT_API_KEY:-}" ]; then
     env -u CROCT_TOKEN \
        CROCT_API_KEY="$CROCT_API_KEY" \
        CROCT_SKIP_API_KEY_SETUP=true \
        bash -c "$COMMAND"
  else
     bash -c "npx --yes croct@latest --dnd use $CROCT_PROJECT_TEMPLATE"
  fi
else
  env -u CROCT_API_KEY \
    CROCT_TOKEN="$CROCT_CLI_TOKEN" \
    CROCT_SKIP_API_KEY_SETUP=true \
    bash -c "$COMMAND"
fi

cd ..
cp -rf build/*/* .
rm -rf build

create_next_config "./app"
