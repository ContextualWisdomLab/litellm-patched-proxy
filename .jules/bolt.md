## 2024-06-06 - [Bypass Docker Build Error]
**Learning:** Docker builds inside the agent sandbox environment may fail due to OverlayFS whiteout file extraction errors (`failed to convert whiteout file`).
**Action:** Bypass this by relying on bash script validations locally or GitHub Actions CI results.
