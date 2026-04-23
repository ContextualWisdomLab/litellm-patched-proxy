FROM ghcr.io/berriai/litellm:v1.83.7-stable@sha256:af0152ca6dfb6703b35c0d4899effa9ac132bce9a4fbcbe1dc6ef145c100db26

ENV PIP_ROOT_USER_ACTION=ignore

RUN apk update \
    && apk add --no-cache curl jq nodejs npm python3 py3-pip ffmpeg \
    && python3 -m pip install --no-cache-dir uv hypercorn
