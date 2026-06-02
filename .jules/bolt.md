## 2025-02-23 - O(N) Network Calls in Docker Builds
**Learning:** Discovered a codebase-specific performance anti-pattern in the vulnerability remediation script: downloading the same tarball via network request repeatedly inside a `find` loop (O(N) network calls).
**Action:** When applying vulnerability patches across multiple directories via scripts, always download the necessary remote assets once to a temporary file before iterating.
