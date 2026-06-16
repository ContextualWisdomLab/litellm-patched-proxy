## 2024-06-10 - Network bottlenecks in Dockerfile iterations
**Learning:** Found an O(N) network bottleneck where `curl` was downloading the same package tarball (`picomatch`) repeatedly inside a `find ... | while read ...` loop. This multiplied build latency and external network requests by the number of matching directories.
**Action:** When patching files across multiple directories via shell iterations in Dockerfiles, always download remote assets to a temporary file *once* outside the loop, use the local file path during iteration, and remove the temp file afterward.

## 2025-01-29 - Improve Docker build step container dependency build latency
**Learning:** `python -m pip install` commands used for installing Python packages inside Docker images introduce a bottleneck due to `pip`'s dependency resolution algorithms which impacts build speed. Replacing standard `pip` with `uv pip` directly speeds up container dependency build times. Using Alpine Python 3.13 requires the `--break-system-packages` flag.
**Action:** Install `uv` via `python -m pip install --break-system-packages uv` first. Then run `uv pip install --system --break-system-packages --no-cache` for the rest of Python packages for faster build speed inside Docker.

## 2025-01-29 - Avoid pyexpat ABI mismatch errors in Alpine/Chainguard
**Learning:** Upgrading Python base packages in Alpine/Chainguard Linux without also upgrading their underlying C-library dependencies can cause ABI mismatch errors. For example, upgrading Python without `libexpat1` leads to an `undefined symbol: XML_SetHashSalt16Bytes` error in `pyexpat.cpython.so` when using `pip`. In Chainguard images, the shared library for expat is specifically packaged as `libexpat1`.
**Action:** Always include the underlying shared C-libraries (e.g., `libexpat1`) explicitly in both `apk add` and `apk upgrade` commands when dealing with Python environments in Chainguard/Alpine.
