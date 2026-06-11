## 2026-06-11 - Transitive Vulnerabilities in Base Image
**Vulnerability:** HIGH vulnerability `CVE-2023-39810` in `busybox` was present in the base image.
**Learning:** Even when updating application packages (like Python packages), critical system utilities shipped with the base image can still carry vulnerabilities. Relying on the base image's default packages can leave the container exposed to vulnerabilities like `CVE-2023-39810`.
**Prevention:** Include essential system packages like `busybox` in the OS package upgrade step (`apk upgrade`) in the Dockerfile to ensure that transitively shipped vulnerabilities from the base image are mitigated.
