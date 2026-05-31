## 2024-05-24 - Unverified External Downloads in Build Process
**Vulnerability:** The `Dockerfile` downloaded `picomatch` from `registry.npmjs.org` and extracted it directly without verifying the tarball's integrity (e.g. SHA256 checksum).
**Learning:** This exposes the image build process to supply chain attacks. If the registry is compromised or a man-in-the-middle attack occurs, malicious code could be injected into the Docker image without detection.
**Prevention:** Always use cryptographic checksums (e.g., `sha256sum`) to verify downloaded artifacts before extracting or using them.
