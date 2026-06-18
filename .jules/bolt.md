## 2024-06-10 - Network bottlenecks in Dockerfile iterations
**Learning:** Found an O(N) network bottleneck where `curl` was downloading the same package tarball (`picomatch`) repeatedly inside a `find ... | while read ...` loop. This multiplied build latency and external network requests by the number of matching directories.
**Action:** When patching files across multiple directories via shell iterations in Dockerfiles, always download remote assets to a temporary file *once* outside the loop, use the local file during iteration, and remove the temp file afterward.## 2024-06-25 - Faster python dependencies installation using uv
**Learning:** Found an opportunity to optimize Docker build time. Using `uv pip install` after a standard `pip install uv` is vastly faster than standard pip, drastically decreasing container latency.
**Action:** Always install `uv` with standard pip first, then use `uv pip install` to resolve remaining dependencies.
