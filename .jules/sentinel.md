## 2024-05-15 - [Base Image OS Packages]
**Vulnerability:** CRITICAL/HIGH CVEs in base Alpine image packages (e.g. busybox, libcrypto3)
**Learning:** Container security tools flag vulnerabilities inherited from upstream base images.
**Prevention:** Explicitly upgrade these common dependencies via apk in our own Dockerfile to ensure a clean vulnerability scan before runtime.
