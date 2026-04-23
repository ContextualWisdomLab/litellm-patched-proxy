FROM ghcr.io/berriai/litellm:v1.83.7-stable@sha256:af0152ca6dfb6703b35c0d4899effa9ac132bce9a4fbcbe1dc6ef145c100db26

ENV PIP_ROOT_USER_ACTION=ignore

# Install OS packages, functional deps, and upgrade Python packages that carry
# HIGH vulnerabilities shipped in the base image:
#   orjson>=3.11.6        fixes CVE-2025-67221
#   Pillow>=12.2.0        fixes CVE-2026-40192
#   python-multipart>=0.0.22  fixes CVE-2026-24486
RUN apk update \
    && apk add --no-cache curl jq python3 py3-pip ffmpeg \
    && python3 -m pip install --no-cache-dir uv hypercorn \
    && python3 -m pip install --no-cache-dir \
         "orjson>=3.11.6" \
         "Pillow>=12.2.0" \
         "python-multipart>=0.0.22"

# Upgrade every picomatch installation found in the base image to 4.0.4 to fix
# CVE-2026-33671 (ReDoS via extglob quantifiers in picomatch <4.0.4).
RUN find /usr /opt /app /root -path "*/node_modules/picomatch" -maxdepth 15 -type d 2>/dev/null \
    | while read -r d; do \
        curl -fsSL "https://registry.npmjs.org/picomatch/-/picomatch-4.0.4.tgz" \
          | tar -xz --strip-components=1 -C "$d"; \
      done
