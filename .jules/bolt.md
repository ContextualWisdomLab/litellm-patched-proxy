## 2024-05-20 - Avoid O(N) Network Requests in Dockerfile Loops
**Learning:** Downloading remote assets inside a loop (like `while read`) within a Dockerfile causes O(N) network requests, slowing down the build significantly and risking transient network failures.
**Action:** Download the necessary remote assets once to a temporary file before iterating.
