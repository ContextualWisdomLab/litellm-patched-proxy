## 2024-06-10 - Network bottlenecks in Dockerfile iterations
**Learning:** Found an O(N) network bottleneck where `curl` was downloading the same package tarball (`picomatch`) repeatedly inside a `find ... | while read ...` loop. This multiplied build latency and external network requests by the number of matching directories.
**Action:** When patching files across multiple directories via shell iterations in Dockerfiles, always download remote assets to a temporary file *once* outside the loop, use the local file during iteration, and remove the temp file afterward.
## 2024-06-11 - Package installation bottleneck inside Dockerfile
**Learning:** Found a build-time performance bottleneck using the standard `python3 -m pip install` to install large dependencies (like litellm and its transitive dependencies). It took ~2.1s natively, whereas utilizing `uv` (`uv pip install --system --no-cache`) reduced the dependency installation time to ~0.3s (nearly 7x faster).
**Action:** When working in Dockerfiles with Python package installations, install `uv` early and leverage it as a drop-in replacement (`uv pip install --system`) to vastly decrease container build latency.
