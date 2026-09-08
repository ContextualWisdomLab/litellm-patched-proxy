#!/bin/sh
set -eu

dockerfile="${1:-Dockerfile}"

if grep -Eq '(^|[^[:alnum:]_])apk(_retry)?[[:space:]]+upgrade([^[:alnum:]_]|$)' "$dockerfile"; then
  echo "Dockerfile must not upgrade the pinned base image package set in place." >&2
  exit 1
fi

if ! grep -Fq '/.cache/uv' "$dockerfile"; then
  echo "Dockerfile must drop inherited uv wheel archives before copying caches." >&2
  exit 1
fi

if grep -Fq 'raw.githubusercontent.com/Seongho-Bae/litellm/' "$dockerfile"; then
  echo "Dockerfile overlays must use the canonical public BerriAI/litellm supplier." >&2
  exit 1
fi

for commit_arg in LITELLM_PATCH_COMMIT LITELLM_HEALTH_PATCH_COMMIT; do
  if ! grep -Fq "raw.githubusercontent.com/BerriAI/litellm/\${$commit_arg}" "$dockerfile"; then
    echo "Dockerfile must fetch $commit_arg from canonical BerriAI/litellm." >&2
    exit 1
  fi
done

last_user="$(awk 'toupper($1) == "USER" { user = $2 } END { print user }' "$dockerfile")"
uid="${last_user%%:*}"
case "$uid" in
  ""|root|0)
    echo "Dockerfile must end with an explicit non-root USER." >&2
    exit 1
    ;;
esac
