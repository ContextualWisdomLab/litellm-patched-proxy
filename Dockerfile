FROM ghcr.io/berriai/litellm:v1.83.7-stable@sha256:af0152ca6dfb6703b35c0d4899effa9ac132bce9a4fbcbe1dc6ef145c100db26

ENV PIP_ROOT_USER_ACTION=ignore

ARG LITELLM_PATCH_COMMIT=661948eb340aa7661a4203205154cf22106077df
ARG LITELLM_REDIS_CACHE_URL=https://raw.githubusercontent.com/Seongho-Bae/litellm/661948eb340aa7661a4203205154cf22106077df/litellm/caching/redis_cache.py
ARG LITELLM_REDIS_CACHE_SHA256=0fabfb741e3a482b002d70cbf59c0627239b59d0ba08a0300c06f9d049f09c81
ARG LITELLM_LOWEST_LATENCY_URL=https://raw.githubusercontent.com/Seongho-Bae/litellm/661948eb340aa7661a4203205154cf22106077df/litellm/router_strategy/lowest_latency.py
ARG LITELLM_LOWEST_LATENCY_SHA256=ae110430f0eba972cdfa5cb6e66875f0d586c646c34a2520815da12c8e46d448

# Install OS packages, keep pinned functional deps, and upgrade Python packages
# that carry HIGH vulnerabilities shipped in the base image:
#   orjson>=3.11.6            fixes CVE-2025-67221
#   Pillow>=12.2.0            fixes CVE-2026-40192
#   python-multipart>=0.0.22  fixes CVE-2026-24486
RUN apk update \
    && apk add --no-cache curl jq python3 py3-pip ffmpeg \
    && apk upgrade --no-cache python-3.13 python-3.13-base \
    && python3 -m pip install --no-cache-dir "uv==0.11.7" "hypercorn==0.18.0" \
    && python3 -m pip install --no-cache-dir \
         "orjson>=3.11.6" \
         "Pillow>=12.2.0" \
         "python-multipart>=0.0.22"

# Overlay the Redis timedelta serialization fix from Seongho-Bae/litellm PR #7
# onto the pinned upstream image without changing the base digest.
RUN tmpdir="$(mktemp -d)" \
    && pkg_root="$(python3 -c 'import litellm, pathlib; print(pathlib.Path(litellm.__file__).resolve().parent)')" \
    && curl -fsSL "$LITELLM_REDIS_CACHE_URL" -o "$tmpdir/redis_cache.py" \
    && curl -fsSL "$LITELLM_LOWEST_LATENCY_URL" -o "$tmpdir/lowest_latency.py" \
    && printf '%s  %s\n' "$LITELLM_REDIS_CACHE_SHA256" "$tmpdir/redis_cache.py" | sha256sum -c - \
    && printf '%s  %s\n' "$LITELLM_LOWEST_LATENCY_SHA256" "$tmpdir/lowest_latency.py" | sha256sum -c - \
    && install -m 0644 "$tmpdir/redis_cache.py" "$pkg_root/caching/redis_cache.py" \
    && install -m 0644 "$tmpdir/lowest_latency.py" "$pkg_root/router_strategy/lowest_latency.py" \
    && rm -rf "$tmpdir"

ARG PICOMATCH_SHA256=515b5ab666558ed9a117483a310892aede54a68dd78f2d8db6604513e578571c

# Upgrade every picomatch installation found in the base image to 4.0.4 to fix
# CVE-2026-33671 (ReDoS via extglob quantifiers in picomatch <4.0.4).
RUN tmpball="$(mktemp)" \
    && curl -fsSL "https://registry.npmjs.org/picomatch/-/picomatch-4.0.4.tgz" -o "$tmpball" \
    && printf '%s  %s\n' "$PICOMATCH_SHA256" "$tmpball" | sha256sum -c - \
    && find /usr /opt /app /root -path "*/node_modules/picomatch" -maxdepth 15 -type d 2>/dev/null \
        | while read -r d; do \
            tar -xz --strip-components=1 -C "$d" -f "$tmpball"; \
        done \
    && rm -f "$tmpball"
