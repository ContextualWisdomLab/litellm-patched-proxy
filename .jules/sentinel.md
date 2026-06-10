## 2024-05-18 - Fixing transitive vulnerabilities in base images
**Vulnerability:** Upstream LiteLLM image had HIGH severity CVEs in `urllib3` and `python-multipart`.
**Learning:** These vulnerabilities are built directly into the base image (often via transitive dependencies like `litellm`). Fixing them requires identifying the specific packages and actively upgrading them using `pip install` in the final `Dockerfile` to override the vulnerable versions before runtime.
**Prevention:** Always maintain a targeted upgrade block in the `Dockerfile` to continuously patch newly identified CVEs within the base image dependencies.
