## 2023-10-27 - [Unverified External Packages]
**Vulnerability:** Found a dynamically fetched NPM tarball (`picomatch`) from a registry being extracted directly without checksum verification.
**Learning:** Supply chain attacks or MITM interventions could compromise dynamic downloads. We should not blindly trust remote downloads during container build without verification.
**Prevention:** Always verify downloaded artifacts against a known good SHA256 checksum using `sha256sum -c` before processing or extracting them.
