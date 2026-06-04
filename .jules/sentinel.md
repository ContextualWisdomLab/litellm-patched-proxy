## 2026-06-04 - [Patch Python base image dependencies]
**Vulnerability:** [HIGH severity vulnerabilities in the base image dependencies (litellm: CVE-2026-40217, urllib3: CVE-2026-44431, CVE-2026-44432)]
**Learning:** [The litellm base image ships with vulnerable versions of pip packages. These vulnerabilities must be mitigated explicitly by upgrading the versions in the Dockerfile rather than trusting the upstream base image.]
**Prevention:** [Continuously scan base images in CI and update dependency installations to overwrite vulnerable packages before releasing to production.]
