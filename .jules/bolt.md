## 2024-06-10 - Network bottlenecks in Dockerfile iterations
**Learning:** Found an O(N) network bottleneck where `curl` was downloading the same package tarball (`picomatch`) repeatedly inside a `find ... | while read ...` loop. This multiplied build latency and external network requests by the number of matching directories.
**Action:** When patching files across multiple directories via shell iterations in Dockerfiles, always download remote assets to a temporary file *once* outside the loop, use the local file during iteration, and remove the temp file afterward.
## 2026-06-14 - Optimize Python Package Installation in Dockerfile
**Learning:** Using `uv pip install --system --break-system-packages --no-cache` inside Alpine Linux Dockerfiles dramatically decreases container dependency build latency and safely bypasses PEP 668 restrictions.
**Action:** Replace `python3 -m pip install` with `uv pip install` along with the `--system --break-system-packages` flags when installing system-wide Python dependencies in Alpine Dockerfiles to improve build times.
