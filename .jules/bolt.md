## 2024-06-10 - Network bottlenecks in Dockerfile iterations
**Learning:** Found an O(N) network bottleneck where `curl` was downloading the same package tarball (`picomatch`) repeatedly inside a `find ... | while read ...` loop. This multiplied build latency and external network requests by the number of matching directories.
**Action:** When patching files across multiple directories via shell iterations in Dockerfiles, always download remote assets to a temporary file *once* outside the loop, use the local file during iteration, and remove the temp file afterward.
