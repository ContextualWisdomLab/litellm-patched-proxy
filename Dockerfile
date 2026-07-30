# syntax=docker/dockerfile:1.7

FROM ghcr.io/berriai/litellm:v1.84.10@sha256:3f59ec3f54e095c18abdc4142ea0afd2f3961d91133c6677ae378a36bf212029

ENV PIP_ROOT_USER_ACTION=ignore \
    PATH="/app/.venv/bin:${PATH}"

ARG LITELLM_REDIS_CACHE_SHA256=89b6cfde221da34d62ffce8c836356d0b1fba67275cc88171fed087d7815109a
ARG LITELLM_LOWEST_LATENCY_SHA256=ae110430f0eba972cdfa5cb6e66875f0d586c646c34a2520815da12c8e46d448
ARG LITELLM_ROUTER_PATCH_SHA256=25c3cf60ed6e32d9243ec864950827e29f122dcf84389d051bb44deff68016b3
ARG LITELLM_CONSTANTS_SHA256=771612640a5d4857ed5548abed8f4f4fd0b7d5ff710cb9e9a29dd7e22020aab1
ARG LITELLM_HEALTH_CHECK_SHA256=3ebc961d09f087f3b0b507dcb529db65abbcf0f17f849fe24bcb78d3607fed67
ARG LITELLM_PROXY_SERVER_SHA256=dfa8495a62758b9b1269a2d2a902b44d51ed764ac008a30480ee5eb4a1a53657
ARG LITELLM_PROXY_UTILS_SHA256=9e07c5a4df29cfc7d2fe0a6e896df027323095cf9f074879f62ffb2540b1d4af
ARG LITELLM_SCHEMA_SHA256=4929d5d49e09aa6946e167c1bf7afce1408e924aca00b63ec4109e389e1f59df
ARG LITELLM_HEALTH_PATCH_SHA256=0817bf4a35500c8b0a41625d35c7ebae6b467a58cf5d3c7fbb699d0077f706af
ARG LITELLM_HTTP_HANDLER_SHA256=fe0fba2252310bb27364f955d4ece8604eb6bc4a2452fc7a0c3abe4847dd5109
ARG LITELLM_ASYNC_CLEANUP_PATCH_SHA256=5e2d870b236bc99cacc23678a840711c417b1355687f55a74606218fa6f78fa9
ARG PICOMATCH_SHA256=515b5ab666558ed9a117483a310892aede54a68dd78f2d8db6604513e578571c
ARG SIGSTORE_SHA256=4d7ecc73cd9559457209adab0d9a64c50145e5cb1286de92abc75f0a140928a0

# Install OS packages, keep pinned functional deps, and upgrade Python packages
# that carry HIGH vulnerabilities shipped in the base image:
#   orjson>=3.11.6            fixes CVE-2025-67221
#   Pillow>=12.2.0            fixes CVE-2026-40192, CVE-2026-42311
#   python-multipart>=0.0.30  fixes CVE-2026-24486, CVE-2026-42561, CVE-2026-53539
#   urllib3>=2.7.0            fixes CVE-2026-44431, CVE-2026-44432
#   litellm==1.84.10          fixes CVE-2026-40217, CVE-2026-49468 and bounds version drift
RUN apk_retry() { \
        attempt=1; \
        while ! apk "$@"; do \
          [ "$attempt" -ge 3 ] && return 1; \
          sleep $((attempt * 5)); \
          attempt=$((attempt + 1)); \
        done; \
      } \
    && apk_retry add --no-cache curl jq python3 py3-pip ffmpeg patch \
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
    && rm -rf /root/.cache

# Overlay reviewed fixes from immutable fork commits onto the pinned package.
RUN --mount=type=bind,source=scripts/verify_litellm_health_overlay.py,target=/usr/local/bin/verify-litellm-health-overlay,ro \
    --mount=type=bind,source=scripts/verify_litellm_runtime_overlay.py,target=/usr/local/bin/verify-litellm-runtime-overlay,ro \
    --mount=type=bind,source=patches/router-timedelta-661948eb.patch,target=/tmp/router-overlay.patch,ro \
    --mount=type=bind,source=patches/health-history-fce13be0.patch,target=/tmp/health-overlay.patch,ro \
    --mount=type=bind,source=patches/async-client-cleanup-91a5f2f4.patch,target=/tmp/async-cleanup-overlay.patch,ro \
    cd /tmp \
    && pkg_root="$(/app/.venv/bin/python3 -c 'import litellm, pathlib; print(pathlib.Path(litellm.__file__).resolve().parent)')" \
    && pkg_parent="$(dirname "$pkg_root")" \
    && printf '%s  %s\n' "$LITELLM_ROUTER_PATCH_SHA256" "/tmp/router-overlay.patch" | sha256sum -c - \
    && printf '%s  %s\n' "$LITELLM_HEALTH_PATCH_SHA256" "/tmp/health-overlay.patch" | sha256sum -c - \
    && printf '%s  %s\n' "$LITELLM_ASYNC_CLEANUP_PATCH_SHA256" "/tmp/async-cleanup-overlay.patch" | sha256sum -c - \
    && patch --batch --forward --strip=1 --directory="$pkg_parent" < /tmp/router-overlay.patch \
    && patch --batch --forward --strip=1 --directory="$pkg_parent" < /tmp/health-overlay.patch \
    && patch --batch --forward --strip=1 --directory="$pkg_parent" < /tmp/async-cleanup-overlay.patch \
    && printf '%s  %s\n' "$LITELLM_REDIS_CACHE_SHA256" "$pkg_root/caching/redis_cache.py" | sha256sum -c - \
    && printf '%s  %s\n' "$LITELLM_LOWEST_LATENCY_SHA256" "$pkg_root/router_strategy/lowest_latency.py" | sha256sum -c - \
    && printf '%s  %s\n' "$LITELLM_CONSTANTS_SHA256" "$pkg_root/constants.py" | sha256sum -c - \
    && printf '%s  %s\n' "$LITELLM_HEALTH_CHECK_SHA256" "$pkg_root/proxy/health_check.py" | sha256sum -c - \
    && printf '%s  %s\n' "$LITELLM_PROXY_SERVER_SHA256" "$pkg_root/proxy/proxy_server.py" | sha256sum -c - \
    && printf '%s  %s\n' "$LITELLM_PROXY_UTILS_SHA256" "$pkg_root/proxy/utils.py" | sha256sum -c - \
    && printf '%s  %s\n' "$LITELLM_SCHEMA_SHA256" "$pkg_root/proxy/schema.prisma" | sha256sum -c - \
    && printf '%s  %s\n' "$LITELLM_HTTP_HANDLER_SHA256" "$pkg_root/llms/custom_httpx/http_handler.py" | sha256sum -c - \
    && find "$pkg_root" -type d -name __pycache__ -prune -exec rm -rf {} + \
    && /app/.venv/bin/python3 -c 'from importlib.metadata import version; assert version("litellm") == "1.84.10"' \
    && grep -Fq 'DEFAULT_HEALTH_CHECK_CONCURRENCY' "$pkg_root/constants.py" \
    && grep -Fq 'background_health_check_cycle_start' "$pkg_root/proxy/proxy_server.py" \
    && /app/.venv/bin/python3 /usr/local/bin/verify-litellm-health-overlay \
         "$pkg_root/proxy/utils.py" "$pkg_root/proxy/schema.prisma" \
    && /app/.venv/bin/python3 /usr/local/bin/verify-litellm-runtime-overlay

# Upgrade every picomatch and sigstore installation found in the base image.
# Download each verified tarball once to avoid O(N) network requests in loops.
RUN curl -fsSL --retry 4 --retry-all-errors --retry-delay 2 "https://registry.npmjs.org/picomatch/-/picomatch-4.0.4.tgz" -o /tmp/picomatch.tgz \
    && echo "$PICOMATCH_SHA256  /tmp/picomatch.tgz" | sha256sum -c - || { rm -f /tmp/picomatch.tgz; exit 1; } \
    && curl -fsSL --retry 4 --retry-all-errors --retry-delay 2 "https://registry.npmjs.org/sigstore/-/sigstore-4.1.1.tgz" -o /tmp/sigstore.tgz \
    && echo "$SIGSTORE_SHA256  /tmp/sigstore.tgz" | sha256sum -c - || { rm -f /tmp/picomatch.tgz /tmp/sigstore.tgz; exit 1; } \
    && find /usr /opt /app /root -maxdepth 15 -path "*/node_modules/picomatch" -type d 2>/dev/null \
    | while IFS= read -r d; do \
        rm -rf "$d" && mkdir -p "$d" && tar -xz -f /tmp/picomatch.tgz --strip-components=1 -C "$d" || exit 1; \
      done \
    && find /usr /opt /app /root -maxdepth 15 -path "*/node_modules/sigstore" -type d 2>/dev/null \
    | while IFS= read -r d; do \
        rm -rf "$d" && mkdir -p "$d" && tar -xz -f /tmp/sigstore.tgz --strip-components=1 -C "$d" || exit 1; \
      done \
    && rm -f /tmp/picomatch.tgz /tmp/sigstore.tgz
