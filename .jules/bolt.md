## 2024-05-15 - Dockerfile loop network requests
**Learning:** Making network requests inside `find ... | while read ...` loops in Dockerfiles can significantly slow down the build by issuing O(N) requests when patching multiple directories.
**Action:** Download remote assets once to a temporary file before iterating through directories.
