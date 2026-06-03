## 2024-05-24 - [Avoid O(N) Network Requests in Dockerfile loops]
**Learning:** Network operations inside loops (like updating multiple packages across directories) in Dockerfiles can result in significant build delays due to O(N) repeated network requests.
**Action:** Always download remote assets to a temporary file before iterating, reducing network calls to O(1).
