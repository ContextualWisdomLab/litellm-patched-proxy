## 2026-05-31 - Network calls inside Dockerfile find/while loops
**Learning:** Found an anti-pattern where a file (`curl` download) was being redundantly downloaded inside a `find ... | while read ...` loop meant to patch multiple duplicate node_modules. This creates an O(N) external network call bottleneck during the Docker build.
**Action:** When updating duplicated dependencies across multiple paths in a Dockerfile, always fetch the asset once to a temporary file before the loop, extract/copy it inside the loop, and clean up the temporary file afterward.
