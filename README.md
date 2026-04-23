# pre-secured-llm-proxy

Pre-secured LiteLLM image build and GHCR security scanning.

## GitHub AI automation

This repository is intended to let GitHub-native AI handle the vulnerability
remediation loop:

- Trivy findings create or update a deduplicated remediation issue
- Copilot is assigned automatically to AI-ready remediation issues
- Copilot-created remediation PRs can be placed on GitHub auto-merge once the
  required checks pass
