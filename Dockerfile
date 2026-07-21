# syntax=docker/dockerfile:1.7

FROM ghcr.io/berriai/litellm:v1.84.10@sha256:3f59ec3f54e095c18abdc4142ea0afd2f3961d91133c6677ae378a36bf212029

ENV PIP_ROOT_USER_ACTION=ignore

ARG LITELLM_PATCH_COMMIT=661948eb340aa7661a4203205154cf22106077df
ARG LITELLM_REDIS_CACHE_SHA256=0fabfb741e3a482b002d70cbf59c0627239b59d0ba08a0300c06f9d049f09c81
ARG LITELLM_LOWEST_LATENCY_SHA256=ae110430f0eba972cdfa5cb6e66875f0d586c646c34a2520815da12c8e46d448
ARG LITELLM_HEALTH_PATCH_COMMIT=fce13be05e620bea3e4ba38139c0e878b0842cbe
ARG LITELLM_CONSTANTS_SHA256=771612640a5d4857ed5548abed8f4f4fd0b7d5ff710cb9e9a29dd7e22020aab1
ARG LITELLM_HEALTH_CHECK_SHA256=3ebc961d09f087f3b0b507dcb529db65abbcf0f17f849fe24bcb78d3607fed67
ARG LITELLM_PROXY_SERVER_SHA256=dfa8495a62758b9b1269a2d2a902b44d51ed764ac008a30480ee5eb4a1a53657
ARG LITELLM_PROXY_UTILS_SHA256=9e07c5a4df29cfc7d2fe0a6e896df027323095cf9f074879f62ffb2540b1d4af
ARG LITELLM_SCHEMA_SHA256=4929d5d49e09aa6946e167c1bf7afce1408e924aca00b63ec4109e389e1f59df
ARG PICOMATCH_SHA256=515b5ab666558ed9a117483a310892aede54a68dd78f2d8db6604513e578571c
ARG SIGSTORE_SHA256=4d7ecc73cd9559457209adab0d9a64c50145e5cb1286de92abc75f0a140928a0
ARG TAR_SHA256=191644f88c7dbd61121f913231ab328d1fc621f058e8ca334451b17cad85dfae
ARG BRACE_EXPANSION_SHA256=e6f29666db5a9503146d8fd93a2a492a64694bc819ce158b18c584610f240fba

# Install OS packages, keep pinned functional deps, and upgrade Python packages
# that carry HIGH vulnerabilities shipped in the base image:
#   orjson>=3.11.6            fixes CVE-2025-67221
#   Pillow>=12.2.0            fixes CVE-2026-40192, CVE-2026-42311
#   python-multipart>=0.0.30  fixes CVE-2026-24486, CVE-2026-42561, CVE-2026-53539
#   urllib3>=2.7.0            fixes CVE-2026-44431, CVE-2026-44432
#   mcp==1.28.1               fixes CVE-2026-52869, CVE-2026-52870, CVE-2026-59950
#   litellm==1.84.10          fixes CVE-2026-40217, CVE-2026-49468 and bounds version drift
RUN apk_retry() { \
        attempt=1; \
        while ! apk "$@"; do \
          [ "$attempt" -ge 3 ] && return 1; \
          sleep $((attempt * 5)); \
          attempt=$((attempt + 1)); \
        done; \
      } \
    && apk_retry add --no-cache curl jq python3 py3-pip ffmpeg \
    && apk_retry upgrade --no-cache \
    && /usr/bin/python3 -m pip --python /app/.venv/bin/python3 install --no-cache-dir "uv==0.11.29" "hypercorn==0.18.0" \
    && /usr/bin/python3 -m pip --python /app/.venv/bin/python3 install --no-cache-dir \
         "litellm==1.84.10" \
         "fastapi==0.139.2" \
         "starlette==1.3.1" \
         "PyJWT==2.13.0" \
         "cryptography==48.0.1" \
         "ddtrace==4.8.2" \
         "semantic-router==0.1.15" \
         "tornado==6.5.6" \
         "orjson>=3.11.6" \
         "Pillow>=12.2.0" \
         "python-multipart>=0.0.30" \
         "urllib3>=2.7.0" \
         "mcp==1.28.1" \
    && /app/.venv/bin/python3 -c 'from importlib.metadata import version; import sys; actual = version("mcp"); sys.exit(0 if actual == "1.28.1" else f"unexpected mcp version: {actual}")' \
    && rm -rf /root/.cache

# Overlay reviewed fixes from immutable fork commits onto the pinned package.
RUN --mount=type=bind,source=scripts/verify_litellm_health_overlay.py,target=/usr/local/bin/verify-litellm-health-overlay,ro \
    tmpdir="$(mktemp -d)" \
    && pkg_root="$(/app/.venv/bin/python3 -c 'import litellm, pathlib; print(pathlib.Path(litellm.__file__).resolve().parent)')" \
    && curl -fsSL --retry 4 --retry-all-errors --retry-delay 2 "https://raw.githubusercontent.com/Seongho-Bae/litellm/${LITELLM_PATCH_COMMIT}/litellm/caching/redis_cache.py" -o "$tmpdir/redis_cache.py" \
    && curl -fsSL --retry 4 --retry-all-errors --retry-delay 2 "https://raw.githubusercontent.com/Seongho-Bae/litellm/${LITELLM_PATCH_COMMIT}/litellm/router_strategy/lowest_latency.py" -o "$tmpdir/lowest_latency.py" \
    && curl -fsSL --retry 4 --retry-all-errors --retry-delay 2 "https://raw.githubusercontent.com/Seongho-Bae/litellm/${LITELLM_HEALTH_PATCH_COMMIT}/litellm/constants.py" -o "$tmpdir/constants.py" \
    && curl -fsSL --retry 4 --retry-all-errors --retry-delay 2 "https://raw.githubusercontent.com/Seongho-Bae/litellm/${LITELLM_HEALTH_PATCH_COMMIT}/litellm/proxy/health_check.py" -o "$tmpdir/health_check.py" \
    && curl -fsSL --retry 4 --retry-all-errors --retry-delay 2 "https://raw.githubusercontent.com/Seongho-Bae/litellm/${LITELLM_HEALTH_PATCH_COMMIT}/litellm/proxy/proxy_server.py" -o "$tmpdir/proxy_server.py" \
    && curl -fsSL --retry 4 --retry-all-errors --retry-delay 2 "https://raw.githubusercontent.com/Seongho-Bae/litellm/${LITELLM_HEALTH_PATCH_COMMIT}/litellm/proxy/utils.py" -o "$tmpdir/utils.py" \
    && curl -fsSL --retry 4 --retry-all-errors --retry-delay 2 "https://raw.githubusercontent.com/Seongho-Bae/litellm/${LITELLM_HEALTH_PATCH_COMMIT}/litellm/proxy/schema.prisma" -o "$tmpdir/schema.prisma" \
    && printf '%s  %s\n' "$LITELLM_REDIS_CACHE_SHA256" "$tmpdir/redis_cache.py" | sha256sum -c - \
    && printf '%s  %s\n' "$LITELLM_LOWEST_LATENCY_SHA256" "$tmpdir/lowest_latency.py" | sha256sum -c - \
    && printf '%s  %s\n' "$LITELLM_CONSTANTS_SHA256" "$tmpdir/constants.py" | sha256sum -c - \
    && printf '%s  %s\n' "$LITELLM_HEALTH_CHECK_SHA256" "$tmpdir/health_check.py" | sha256sum -c - \
    && printf '%s  %s\n' "$LITELLM_PROXY_SERVER_SHA256" "$tmpdir/proxy_server.py" | sha256sum -c - \
    && printf '%s  %s\n' "$LITELLM_PROXY_UTILS_SHA256" "$tmpdir/utils.py" | sha256sum -c - \
    && printf '%s  %s\n' "$LITELLM_SCHEMA_SHA256" "$tmpdir/schema.prisma" | sha256sum -c - \
    && install -m 0644 "$tmpdir/redis_cache.py" "$pkg_root/caching/redis_cache.py" \
    && install -m 0644 "$tmpdir/lowest_latency.py" "$pkg_root/router_strategy/lowest_latency.py" \
    && install -m 0644 "$tmpdir/constants.py" "$pkg_root/constants.py" \
    && install -m 0644 "$tmpdir/health_check.py" "$pkg_root/proxy/health_check.py" \
    && install -m 0644 "$tmpdir/proxy_server.py" "$pkg_root/proxy/proxy_server.py" \
    && install -m 0644 "$tmpdir/utils.py" "$pkg_root/proxy/utils.py" \
    && install -m 0644 "$tmpdir/schema.prisma" "$pkg_root/proxy/schema.prisma" \
    && /app/.venv/bin/python3 -c 'from importlib.metadata import version; assert version("litellm") == "1.84.10"' \
    && grep -Fq 'DEFAULT_HEALTH_CHECK_CONCURRENCY' "$pkg_root/constants.py" \
    && grep -Fq 'background_health_check_cycle_start' "$pkg_root/proxy/proxy_server.py" \
    && /app/.venv/bin/python3 /usr/local/bin/verify-litellm-health-overlay \
         "$pkg_root/proxy/utils.py" "$pkg_root/proxy/schema.prisma" \
    && rm -rf "$tmpdir"

# Upgrade vulnerable Node.js packages in every installation found in the base image.
# Download each verified tarball once to avoid O(N) network requests in loops.
RUN curl -fsSL --retry 4 --retry-all-errors --retry-delay 2 "https://registry.npmjs.org/picomatch/-/picomatch-4.0.4.tgz" -o /tmp/picomatch.tgz \
    && echo "$PICOMATCH_SHA256  /tmp/picomatch.tgz" | sha256sum -c - || { rm -f /tmp/picomatch.tgz; exit 1; } \
    && curl -fsSL --retry 4 --retry-all-errors --retry-delay 2 "https://registry.npmjs.org/sigstore/-/sigstore-4.1.1.tgz" -o /tmp/sigstore.tgz \
    && echo "$SIGSTORE_SHA256  /tmp/sigstore.tgz" | sha256sum -c - || { rm -f /tmp/picomatch.tgz /tmp/sigstore.tgz; exit 1; } \
    && curl -fsSL --retry 4 --retry-all-errors --retry-delay 2 "https://registry.npmjs.org/tar/-/tar-7.5.19.tgz" -o /tmp/tar.tgz \
    && echo "$TAR_SHA256  /tmp/tar.tgz" | sha256sum -c - || { rm -f /tmp/picomatch.tgz /tmp/sigstore.tgz /tmp/tar.tgz; exit 1; } \
    && curl -fsSL --retry 4 --retry-all-errors --retry-delay 2 "https://registry.npmjs.org/brace-expansion/-/brace-expansion-5.0.7.tgz" -o /tmp/brace-expansion.tgz \
    && echo "$BRACE_EXPANSION_SHA256  /tmp/brace-expansion.tgz" | sha256sum -c - || { rm -f /tmp/picomatch.tgz /tmp/sigstore.tgz /tmp/tar.tgz /tmp/brace-expansion.tgz; exit 1; } \
    && find /usr /opt /app /root -maxdepth 15 -path "*/node_modules/picomatch" -type d 2>/dev/null \
    | while IFS= read -r d; do \
        rm -rf "$d" && mkdir -p "$d" && tar -xz -f /tmp/picomatch.tgz --strip-components=1 -C "$d" || exit 1; \
      done \
    && find /usr /opt /app /root -maxdepth 15 -path "*/node_modules/sigstore" -type d 2>/dev/null \
    | while IFS= read -r d; do \
        rm -rf "$d" && mkdir -p "$d" && tar -xz -f /tmp/sigstore.tgz --strip-components=1 -C "$d" || exit 1; \
      done \
    && find /usr /opt /app /root -maxdepth 15 -path "*/node_modules/tar" -type d 2>/dev/null \
    | while IFS= read -r d; do \
        rm -rf "$d" && mkdir -p "$d" && tar -xz -f /tmp/tar.tgz --strip-components=1 -C "$d" || exit 1; \
      done \
    && find /usr /opt /app /root -maxdepth 15 -path "*/node_modules/brace-expansion" -type d 2>/dev/null \
    | while IFS= read -r d; do \
        rm -rf "$d" && mkdir -p "$d" && tar -xz -f /tmp/brace-expansion.tgz --strip-components=1 -C "$d" || exit 1; \
      done \
    && find /usr /opt /app /root -maxdepth 15 -path "*/node_modules/tar" -type d -print0 2>/dev/null > /tmp/tar-paths \
    && [ -s /tmp/tar-paths ] \
    && xargs -0 -n 1 node -e 'const path=process.argv[1]+"/package.json"; const actual=require(path).version; if (actual !== "7.5.19") throw new Error("unexpected version: "+path+" ("+actual+")");' < /tmp/tar-paths \
    && find /usr /opt /app /root -maxdepth 15 -path "*/node_modules/brace-expansion" -type d -print0 2>/dev/null > /tmp/brace-paths \
    && [ -s /tmp/brace-paths ] \
    && xargs -0 -n 1 node -e 'const path=process.argv[1]+"/package.json"; const actual=require(path).version; if (actual !== "5.0.7") throw new Error("unexpected version: "+path+" ("+actual+")");' < /tmp/brace-paths \
    && rm -f /tmp/picomatch.tgz /tmp/sigstore.tgz /tmp/tar.tgz /tmp/brace-expansion.tgz /tmp/tar-paths /tmp/brace-paths
