## 2026-06-08 - [Dockerfile Optimization]
**Learning:** Avoid O(N) network requests in Dockerfile loops when applying patches across multiple directories.
**Action:** Download remote assets once to a temporary file before iterating, and extract from the local copy to save time and bandwidth.