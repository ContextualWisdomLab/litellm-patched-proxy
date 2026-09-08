#!/bin/sh
set -eu

check="${1:-scripts/check_container_runtime_contract.sh}"
workdir="$(mktemp -d)"
trap 'rm -rf "$workdir"' EXIT HUP INT TERM

write_fixture() {
  name="$1"
  body="$2"
  user="${3:-10001:10001}"
  {
    printf '%s\n' 'ARG LITELLM_PATCH_COMMIT=patch'
    printf '%s\n' 'ARG LITELLM_HEALTH_PATCH_COMMIT=health'
    printf '%s\n' 'RUN curl https://raw.githubusercontent.com/BerriAI/litellm/${LITELLM_PATCH_COMMIT}/one'
    printf '%s\n' 'RUN curl https://raw.githubusercontent.com/BerriAI/litellm/${LITELLM_HEALTH_PATCH_COMMIT}/two'
    printf '%s\n' "$body"
    printf 'USER %s\n' "$user"
  } >"$workdir/$name"
}

expect_rejected() {
  name="$1"
  if sh "$check" "$workdir/$name" >/dev/null 2>&1; then
    echo "expected $name to be rejected" >&2
    exit 1
  fi
}

write_fixture valid 'RUN apk add --no-cache curl
RUN rm -rf /root/.cache/uv'
sh "$check" "$workdir/valid"

write_fixture missing_uv 'RUN apk add --no-cache curl'
expect_rejected missing_uv

write_fixture direct_apk 'RUN apk upgrade --no-cache'
expect_rejected direct_apk

write_fixture helper_apk 'RUN apk_retry upgrade --no-cache'
expect_rejected helper_apk

write_fixture separator_apk 'RUN true; apk upgrade'
expect_rejected separator_apk

write_fixture continued_apk '    && apk_retry upgrade --no-cache'
expect_rejected continued_apk

write_fixture named_root 'RUN true' 'root:litellm'
expect_rejected named_root

write_fixture numeric_root 'RUN true' '0:10001'
expect_rejected numeric_root
