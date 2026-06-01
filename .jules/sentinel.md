## 2024-06-01 - Missing Integrity Check in Build Scripts
**Vulnerability:** A `RUN` block in the Dockerfile downloaded a `.tgz` from npmjs inside a `while` loop, extracting it directly over matching `node_modules/picomatch` directories without any hash verification.
**Learning:** Build scripts patching dependencies must verify the checksum of the downloaded payload before extraction to protect the supply chain. Otherwise, registry compromises or MITM attacks during the build process could result in malicious code injection.
**Prevention:** Download the asset to a temporary file, check its hash (e.g., `sha256sum -c`), and only then apply/extract it.
