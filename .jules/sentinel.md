## 2026-06-18 - Prevent ABI mismatch when patching Python packages in Alpine
**Vulnerability:** Upgrading Python packages with native extensions (like cryptography) via `apk upgrade` can cause ABI mismatch errors (e.g., `undefined symbol: XML_SetHashSalt16Bytes`) in Alpine/Chainguard base images.
**Learning:** The underlying shared C-library dependency (e.g., `expat`) must be explicitly included in BOTH the `apk add` and `apk upgrade` commands. Avoid using Debian/Ubuntu package names like `libexpat1` in Alpine environments.
**Prevention:** Always explicitly upgrade shared C-library dependencies when upgrading Python packages that rely on them in Alpine base images.
