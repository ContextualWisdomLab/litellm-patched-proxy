## 2026-06-06 - [urllib3 CVE patching in container images]
**Vulnerability:** Found High severity CVEs in `urllib3` package pre-installed in the base container image.
**Learning:** Container base images often bundle slightly outdated dependencies. Trivy scanning is critical to identify these before deployment, but fixing them inside the Dockerfile via `pip install --upgrade` for specific packages is an effective and isolated way to mitigate them without breaking the base image.
**Prevention:** Ensure continuous container image scanning via Trivy or similar tools is active in the CI pipeline, and proactively pin security updates for transitive or base-level dependencies directly in the container build process.
