## 2026-06-17 - Update vulnerable Docker image dependencies
**Vulnerability:** CRITICAL/HIGH vulnerabilities found in base container image due to outdated python dependencies (litellm, python-multipart, starlette, etc.) and OS libraries (libcrypto3, libssl3, openssl, busybox).
**Learning:** Trivy scanning a container base image effectively exposes dependency vulnerabilities that must be overridden using explicit upgrades in the Dockerfile.
**Prevention:** Automate and pin dependency upgrades inside the container build process, running Trivy scans within the CI pipeline before publishing the container.
