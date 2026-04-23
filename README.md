# pre-secured-llm-proxy

Pre-secured LiteLLM image build and GHCR security scanning.

## GitHub AI remediation loop

This repository is intended to create or update a single remediation issue when
Trivy reports HIGH/CRITICAL findings, so GitHub-native AI/Copilot can be pointed
at a concrete issue instead of a failing workflow log.

- Trivy findings create or update a deduplicated remediation issue
- Copilot is assigned automatically to AI-ready remediation issues
- Copilot-created remediation PRs can be placed on GitHub auto-merge once the
  required checks pass
