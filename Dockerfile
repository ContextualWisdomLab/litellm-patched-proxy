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
ARG TAR_SHA256=b792c2d1c7fc770910522ca1ffc29eee02ee38de4fa3a01e7832eb705879c6c6
ARG BRACE_EXPANSION_SHA256=5d06001fddd25cbee90c96db4dc5b7b57711b984c3141e28d10f143deb52dbaf
ARG PACOTE_SHA256=d671739e5e4b8d1f1042fe3f337c0b471b01a9abd7bb9afb764305d919118612
ARG IP_ADDRESS_SHA256=25a406ee4388fa3d47380ad57b816087fa82a681cc710cccbfe9162cffa8a57a

# Install OS packages, keep pinned functional deps, and upgrade Python packages
# that carry HIGH/CRITICAL vulnerabilities shipped in the base image.
# Already-installed Wolfi packages ignore a plain `apk add`; `--upgrade` on
# the named CVE packages pulls openssl 3.6.3-r5, busybox 1.38.0-r0, and
# python-3.13 3.13.14-r3. That is a 3.13 revision, not a whole-index refresh.
# The interpreter major.minor must stay 3.13 so this venv ABI holds.
RUN apk_retry() { \
        attempt=1; \
        while ! apk "$@"; do \
          [ "$attempt" -ge 3 ] && return 1; \
          sleep $((attempt * 5)); \
          attempt=$((attempt + 1)); \
        done; \
      } \
    && apk_retry add --no-cache curl jq python3 py3-pip ffmpeg \
    && apk_retry add --no-cache --upgrade \
         openssl libcrypto3 libssl3 busybox python-3.13 python-3.13-base \
    && /usr/bin/python3 -c 'import sys; assert sys.version_info[:2] == (3, 13), sys.version' \
    && pip_secure() { \
         /usr/bin/python3 -m pip --python /app/.venv/bin/python3 install --no-cache-dir "$@"; \
         /usr/bin/python3 -m pip install --no-cache-dir --break-system-packages "$@"; \
       } \
    && pip_secure "uv==0.11.29" "hypercorn==0.18.0" \
    && /usr/bin/python3 -m pip --python /app/.venv/bin/python3 install --no-cache-dir \
         "litellm==1.84.10" \
         "fastapi==0.139.2" \
         "semantic-router==0.1.15" \
    && pip_secure \
         "starlette==1.3.1" \
         "PyJWT==2.13.0" \
         "cryptography==50.0.1" \
         "ddtrace==4.8.2" \
         "tornado==6.5.8" \
         "orjson>=3.11.6" \
         "Pillow>=12.2.0" \
         "python-multipart==0.0.32" \
         "urllib3==2.7.0" \
         "RestrictedPython==8.5" \
         "aiohttp==3.14.3" \
         "mcp==1.30.0" \
         "pyasn1==0.6.4" \
         "pypdf==6.18.0" \
         "setuptools==84.0.0" \
    && /app/.venv/bin/python3 -c 'from importlib.metadata import version as v; assert v("starlette")=="1.3.1" and v("PyJWT")=="2.13.0" and v("cryptography")=="50.0.1" and v("tornado")=="6.5.8" and v("mcp")=="1.30.0" and v("urllib3")=="2.7.0"'

# Overlay reviewed fixes from immutable canonical upstream commits.
RUN --mount=type=bind,source=scripts/verify_litellm_health_overlay.py,target=/usr/local/bin/verify-litellm-health-overlay,ro \
    tmpdir="$(mktemp -d)" \
    && pkg_root="$(/app/.venv/bin/python3 -c 'import litellm, pathlib; print(pathlib.Path(litellm.__file__).resolve().parent)')" \
    && curl -fsSL --retry 4 --retry-all-errors --retry-delay 2 "https://raw.githubusercontent.com/BerriAI/litellm/${LITELLM_PATCH_COMMIT}/litellm/caching/redis_cache.py" -o "$tmpdir/redis_cache.py" \
    && curl -fsSL --retry 4 --retry-all-errors --retry-delay 2 "https://raw.githubusercontent.com/BerriAI/litellm/${LITELLM_PATCH_COMMIT}/litellm/router_strategy/lowest_latency.py" -o "$tmpdir/lowest_latency.py" \
    && curl -fsSL --retry 4 --retry-all-errors --retry-delay 2 "https://raw.githubusercontent.com/BerriAI/litellm/${LITELLM_HEALTH_PATCH_COMMIT}/litellm/constants.py" -o "$tmpdir/constants.py" \
    && curl -fsSL --retry 4 --retry-all-errors --retry-delay 2 "https://raw.githubusercontent.com/BerriAI/litellm/${LITELLM_HEALTH_PATCH_COMMIT}/litellm/proxy/health_check.py" -o "$tmpdir/health_check.py" \
    && curl -fsSL --retry 4 --retry-all-errors --retry-delay 2 "https://raw.githubusercontent.com/BerriAI/litellm/${LITELLM_HEALTH_PATCH_COMMIT}/litellm/proxy/proxy_server.py" -o "$tmpdir/proxy_server.py" \
    && curl -fsSL --retry 4 --retry-all-errors --retry-delay 2 "https://raw.githubusercontent.com/BerriAI/litellm/${LITELLM_HEALTH_PATCH_COMMIT}/litellm/proxy/utils.py" -o "$tmpdir/utils.py" \
    && curl -fsSL --retry 4 --retry-all-errors --retry-delay 2 "https://raw.githubusercontent.com/BerriAI/litellm/${LITELLM_HEALTH_PATCH_COMMIT}/litellm/proxy/schema.prisma" -o "$tmpdir/schema.prisma" \
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

# Replace every HIGH/CRITICAL npm tree found in the base image. Download each
# verified tarball once to avoid O(N) network requests in loops.
RUN fetch_npm() { \
        name="$1"; ver="$2"; sha="$3"; dest="/tmp/${name}.tgz"; \
        curl -fsSL --retry 4 --retry-all-errors --retry-delay 2 \
          "https://registry.npmjs.org/${name}/-/${name}-${ver}.tgz" -o "$dest" \
        && echo "$sha  $dest" | sha256sum -c - || { rm -f "$dest"; return 1; }; \
      } \
    && replace_npm() { \
        name="$1"; tgz="/tmp/${name}.tgz"; \
        find /usr /opt /app /root -maxdepth 15 -path "*/node_modules/${name}" -type d 2>/dev/null \
        | while IFS= read -r d; do \
            rm -rf "$d" && mkdir -p "$d" && tar -xz -f "$tgz" --strip-components=1 -C "$d" || exit 1; \
          done; \
      } \
    && fetch_npm picomatch 4.0.4 "$PICOMATCH_SHA256" \
    && fetch_npm sigstore 4.1.1 "$SIGSTORE_SHA256" \
    && fetch_npm tar 7.5.22 "$TAR_SHA256" \
    && fetch_npm brace-expansion 5.0.9 "$BRACE_EXPANSION_SHA256" \
    && fetch_npm pacote 21.5.1 "$PACOTE_SHA256" \
    && fetch_npm ip-address 10.7.0 "$IP_ADDRESS_SHA256" \
    && replace_npm picomatch \
    && replace_npm sigstore \
    && replace_npm tar \
    && replace_npm brace-expansion \
    && replace_npm pacote \
    && replace_npm ip-address \
    && rm -f /tmp/picomatch.tgz /tmp/sigstore.tgz /tmp/tar.tgz \
         /tmp/brace-expansion.tgz /tmp/pacote.tgz /tmp/ip-address.tgz

# Carry repository and upstream attribution with the distributable image.
COPY --chmod=0644 LICENSE THIRD_PARTY_NOTICES.md /usr/share/licenses/litellm-patched-proxy/

# Keep build-time mutation privileged, then run the proxy with a numeric
# unprivileged identity. Preserve the inherited Prisma cache in writable
# non-root locations used by common container deployments. Drop uv/pip
# wheel archives first: Trivy treats their METADATA as installed packages.
RUN addgroup -S -g 10001 litellm \
    && adduser -S -D -H -h /home/litellm -u 10001 -G litellm litellm \
    && rm -rf /root/.cache/uv /root/.cache/pip \
    && mkdir -p /home/litellm/.cache /app/.cache \
    && cp -a /root/.cache/. /home/litellm/.cache/ \
    && cp -a /root/.cache/. /app/.cache/ \
    && chown -R 10001:10001 /home/litellm /app/.cache \
    && rm -rf /root/.cache \
    && test ! -e /app/.cache/uv \
    && test ! -e /home/litellm/.cache/uv

ENV HOME=/home/litellm

USER 10001:10001
