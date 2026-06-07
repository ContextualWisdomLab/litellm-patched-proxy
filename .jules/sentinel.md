## 2026-06-07 - [Dockerfile Base Image Vulnerabilities]
**Vulnerability:** [HIGH severity vulnerabilities in base image dependencies (e.g. py3-pip-wheel, urllib3, litellm, python-multipart)]
**Learning:** [Base image vulnerabilities require explicit package upgrades in Dockerfile if base image tag is pinned]
**Prevention:** [Keep base image updated or explicitly patch known vulnerable packages in the build process]
