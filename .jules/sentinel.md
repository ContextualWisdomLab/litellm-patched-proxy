## 2024-05-18 - urllib3 vulnerability
**Vulnerability:** urllib3 vulnerabilities (CVE-2026-44431, CVE-2026-44432) found by trivy in the container image.
**Learning:** `urllib3` is pulled in as a dependency by `litellm` or one of its dependencies and is not explicitly specified in the Dockerfile, which leads to these vulnerabilities being unpatched.
**Prevention:** Pin or upgrade `urllib3` explicitly in the `Dockerfile` to at least `2.7.0` using pip.
