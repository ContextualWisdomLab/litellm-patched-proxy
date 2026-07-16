FROM ghcr.io/berriai/litellm:v1.83.7-stable@sha256:af0152ca6dfb6703b35c0d4899effa9ac132bce9a4fbcbe1dc6ef145c100db26

ENV PIP_ROOT_USER_ACTION=ignore

ARG LITELLM_PATCH_COMMIT=661948eb340aa7661a4203205154cf22106077df
ARG LITELLM_REDIS_CACHE_URL=https://raw.githubusercontent.com/Seongho-Bae/litellm/661948eb340aa7661a4203205154cf22106077df/litellm/caching/redis_cache.py
ARG LITELLM_REDIS_CACHE_SHA256=0fabfb741e3a482b002d70cbf59c0627239b59d0ba08a0300c06f9d049f09c81
ARG LITELLM_LOWEST_LATENCY_URL=https://raw.githubusercontent.com/Seongho-Bae/litellm/661948eb340aa7661a4203205154cf22106077df/litellm/router_strategy/lowest_latency.py
ARG LITELLM_LOWEST_LATENCY_SHA256=ae110430f0eba972cdfa5cb6e66875f0d586c646c34a2520815da12c8e46d448
ARG LITELLM_HEALTH_PATCH_COMMIT=1bf89fc4649402e1f5c67a189db725adbaf3f515
ARG LITELLM_CONSTANTS_URL=https://raw.githubusercontent.com/Seongho-Bae/litellm/1bf89fc4649402e1f5c67a189db725adbaf3f515/litellm/constants.py
ARG LITELLM_CONSTANTS_SHA256=771612640a5d4857ed5548abed8f4f4fd0b7d5ff710cb9e9a29dd7e22020aab1
ARG LITELLM_HEALTH_CHECK_URL=https://raw.githubusercontent.com/Seongho-Bae/litellm/1bf89fc4649402e1f5c67a189db725adbaf3f515/litellm/proxy/health_check.py
ARG LITELLM_HEALTH_CHECK_SHA256=3ebc961d09f087f3b0b507dcb529db65abbcf0f17f849fe24bcb78d3607fed67
ARG LITELLM_PROXY_SERVER_URL=https://raw.githubusercontent.com/Seongho-Bae/litellm/1bf89fc4649402e1f5c67a189db725adbaf3f515/litellm/proxy/proxy_server.py
ARG LITELLM_PROXY_SERVER_SHA256=dfa8495a62758b9b1269a2d2a902b44d51ed764ac008a30480ee5eb4a1a53657
ARG PICOMATCH_SHA256=515b5ab666558ed9a117483a310892aede54a68dd78f2d8db6604513e578571c
ARG SIGSTORE_SHA256=4d7ecc73cd9559457209adab0d9a64c50145e5cb1286de92abc75f0a140928a0

# Install OS packages, keep pinned functional deps, and upgrade Python packages
# that carry HIGH vulnerabilities shipped in the base image:
#   orjson>=3.11.6            fixes CVE-2025-67221
#   Pillow>=12.2.0            fixes CVE-2026-40192, CVE-2026-42311
#   python-multipart>=0.0.27  fixes CVE-2026-24486, CVE-2026-42561
#   urllib3>=2.7.0            fixes CVE-2026-44431, CVE-2026-44432
#   litellm==1.84.10          fixes CVE-2026-40217, CVE-2026-49468 and bounds version drift
RUN apk update \
    && apk add --no-cache curl jq python3 py3-pip ffmpeg \
    && apk upgrade --no-cache \
    && python3 -m pip install --no-cache-dir "uv==0.11.29" "hypercorn==0.18.0" \
    && python3 -m pip install --no-cache-dir \
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
         "python-multipart>=0.0.27" \
         "urllib3>=2.7.0"

# Overlay reviewed fixes from immutable fork commits onto the pinned package.
RUN tmpdir="$(mktemp -d)" \
    && pkg_root="$(python3 -c 'import litellm, pathlib; print(pathlib.Path(litellm.__file__).resolve().parent)')" \
    && curl -fsSL "$LITELLM_REDIS_CACHE_URL" -o "$tmpdir/redis_cache.py" \
    && curl -fsSL "$LITELLM_LOWEST_LATENCY_URL" -o "$tmpdir/lowest_latency.py" \
    && curl -fsSL "$LITELLM_CONSTANTS_URL" -o "$tmpdir/constants.py" \
    && curl -fsSL "$LITELLM_HEALTH_CHECK_URL" -o "$tmpdir/health_check.py" \
    && curl -fsSL "$LITELLM_PROXY_SERVER_URL" -o "$tmpdir/proxy_server.py" \
    && printf '%s  %s\n' "$LITELLM_REDIS_CACHE_SHA256" "$tmpdir/redis_cache.py" | sha256sum -c - \
    && printf '%s  %s\n' "$LITELLM_LOWEST_LATENCY_SHA256" "$tmpdir/lowest_latency.py" | sha256sum -c - \
    && printf '%s  %s\n' "$LITELLM_CONSTANTS_SHA256" "$tmpdir/constants.py" | sha256sum -c - \
    && printf '%s  %s\n' "$LITELLM_HEALTH_CHECK_SHA256" "$tmpdir/health_check.py" | sha256sum -c - \
    && printf '%s  %s\n' "$LITELLM_PROXY_SERVER_SHA256" "$tmpdir/proxy_server.py" | sha256sum -c - \
    && install -m 0644 "$tmpdir/redis_cache.py" "$pkg_root/caching/redis_cache.py" \
    && install -m 0644 "$tmpdir/lowest_latency.py" "$pkg_root/router_strategy/lowest_latency.py" \
    && install -m 0644 "$tmpdir/constants.py" "$pkg_root/constants.py" \
    && install -m 0644 "$tmpdir/health_check.py" "$pkg_root/proxy/health_check.py" \
    && install -m 0644 "$tmpdir/proxy_server.py" "$pkg_root/proxy/proxy_server.py" \
    && python3 -c 'from importlib.metadata import version; assert version("litellm") == "1.84.10"' \
    && grep -Fq 'DEFAULT_HEALTH_CHECK_CONCURRENCY' "$pkg_root/constants.py" \
    && grep -Fq 'background_health_check_cycle_start' "$pkg_root/proxy/proxy_server.py" \
    && rm -rf "$tmpdir"

# Upgrade every picomatch and sigstore installation found in the base image.
# Download each verified tarball once to avoid O(N) network requests in loops.
RUN curl -fsSL "https://registry.npmjs.org/picomatch/-/picomatch-4.0.4.tgz" -o /tmp/picomatch.tgz \
    && echo "$PICOMATCH_SHA256  /tmp/picomatch.tgz" | sha256sum -c - || { rm -f /tmp/picomatch.tgz; exit 1; } \
    && curl -fsSL "https://registry.npmjs.org/sigstore/-/sigstore-4.1.1.tgz" -o /tmp/sigstore.tgz \
    && echo "$SIGSTORE_SHA256  /tmp/sigstore.tgz" | sha256sum -c - || { rm -f /tmp/picomatch.tgz /tmp/sigstore.tgz; exit 1; } \
    && find /usr /opt /app /root -path "*/node_modules/picomatch" -maxdepth 15 -type d 2>/dev/null \
    | while read -r d; do \
        tar -xz -f /tmp/picomatch.tgz --strip-components=1 -C "$d"; \
      done \
    && find /usr /opt /app /root -path "*/node_modules/sigstore" -maxdepth 15 -type d 2>/dev/null \
    | while read -r d; do \
        tar -xz -f /tmp/sigstore.tgz --strip-components=1 -C "$d"; \
      done \
    && rm -f /tmp/picomatch.tgz /tmp/sigstore.tgz
