#!/bin/sh
set -eu

dockerfile="${1:-Dockerfile}"

if grep -Eq '(^|[^[:alnum:]_])apk(_retry)?[[:space:]]+upgrade([^[:alnum:]_]|$)' "$dockerfile"; then
  echo "Dockerfile must not upgrade the pinned base image package set in place." >&2
  exit 1
fi

joined="$(awk '{
  if (sub(/\\[[:space:]]*$/, " ")) {
    printf "%s", $0
  } else {
    print
  }
}' "$dockerfile")"
if printf '%s\n' "$joined" | grep -Eq 'apk(_retry)?[[:space:]]+add.*--upgrade.*python-3\.13'; then
  echo "Dockerfile must not replace python-3.13 in place; this digest lacks GLIBC_2.44." >&2
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

script_dir="$(CDPATH= cd -- "$(dirname "$0")" && pwd)"
repo_root="$(CDPATH= cd -- "$script_dir/.." && pwd)"
workflows="$repo_root/.github/workflows"
if [ -d "$workflows" ]; then
  if grep -R -F -q 'ghcr.io/seongho-bae/pre-secured-llm-proxy' \
    "$workflows" "$repo_root/README.md" "$repo_root/docs/index.md"; then
    echo "published image must not use the personal pre-secured-llm-proxy GHCR path." >&2
    exit 1
  fi
  if ! grep -R -F -q 'IMAGE_NAME: ghcr.io/contextualwisdomlab/litellm-patched-proxy' "$workflows"; then
    echo "workflows must publish ghcr.io/contextualwisdomlab/litellm-patched-proxy." >&2
    exit 1
  fi
  if grep -R -F -q 'local/pre-secured-llm-proxy:' "$workflows"; then
    echo "local scan tags must use litellm-patched-proxy." >&2
    exit 1
  fi
fi
