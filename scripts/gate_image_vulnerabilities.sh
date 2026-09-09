#!/bin/sh
# Fail on HIGH/CRITICAL image findings except python-3.13 HIGH on this digest.
# 3.13.14-r3 needs GLIBC_2.44, which ghcr.io/berriai/litellm:v1.84.10
# @sha256:3f59ec3f54e095c18abdc4142ea0afd2f3961d91133c6677ae378a36bf212029
# does not ship (validate job 101963192386). Interpreter CRITICAL still blocks.
set -eu

json="${1:-}"
if [ -z "$json" ] || [ ! -f "$json" ]; then
  echo "usage: gate_image_vulnerabilities.sh TRIVY_JSON" >&2
  exit 2
fi

blocking_filter='
  [.Results[]?.Vulnerabilities[]?
   | select(.Severity == "CRITICAL" or .Severity == "HIGH")
   | select(
       (.PkgName != "python-3.13" and .PkgName != "python-3.13-base")
       or .Severity == "CRITICAL"
     )]
  | sort_by(.PkgName, .VulnerabilityID)
'

allowed_filter='
  [.Results[]?.Vulnerabilities[]?
   | select(.Severity == "HIGH")
   | select(.PkgName == "python-3.13" or .PkgName == "python-3.13-base")]
  | sort_by(.PkgName, .VulnerabilityID)
'

line_format='.[] | "- \(.PkgName) \(.InstalledVersion): \(.VulnerabilityID) (\(.Severity), fixed: \(.FixedVersion // "unavailable"))"'

blocking_count="$(jq "$blocking_filter | length" "$json")"
allowed_count="$(jq "$allowed_filter | length" "$json")"

printf '%s\n' \
  "## Vulnerability gate" \
  "- Blocking CRITICAL/HIGH count: **$blocking_count**" \
  "- Allowed interpreter HIGH count: **$allowed_count** (python-3.13 / python-3.13-base on this digest)"
if [ -n "${GITHUB_STEP_SUMMARY:-}" ]; then
  {
    echo "## Vulnerability gate"
    echo "- Blocking CRITICAL/HIGH count: **$blocking_count**"
    echo "- Allowed interpreter HIGH count: **$allowed_count** (python-3.13 / python-3.13-base on this digest)"
  } >>"$GITHUB_STEP_SUMMARY"
fi

echo "blocking_count=$blocking_count"
echo "allowed_interpreter_high_count=$allowed_count"

if [ "$allowed_count" -gt 0 ]; then
  echo "Allowed interpreter HIGH (this digest lacks GLIBC_2.44):"
  jq -r "$allowed_filter | $line_format" "$json"
fi

if [ "$blocking_count" -gt 0 ]; then
  echo "Blocking CRITICAL/HIGH:"
  jq -r "$blocking_filter | $line_format" "$json"
  exit 1
fi
