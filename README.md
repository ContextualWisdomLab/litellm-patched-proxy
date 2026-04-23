# pre-secured-llm-proxy

Builds and publishes a pre-secured LiteLLM image to GHCR with vulnerability
scanning evidence.

## Scope

This repository exists only to produce an immutable LiteLLM container image that:

- stays pinned to the approved upstream LiteLLM base digest,
- pre-bakes the runtime tools currently installed at container startup,
- publishes to GHCR, and
- records security-scan evidence in GitHub Actions and code scanning.

Current reduction strategy is conservative:

- remove only packages that are not yet proven to be runtime requirements,
- keep Python/LiteLLM + Hypercorn compatibility first,
- coordinate any deployment-time wrapper changes in the incident/operations repo
  before promoting the image into live runtime use.

## Published image

- GHCR package: `ghcr.io/seongho-bae/pre-secured-llm-proxy`

## Tagging

- `edge` from the default branch
- `sha-<gitsha>` for immutable CI traceability
- semver tags when the repository itself is tagged

## Evidence

The workflows upload:

- Trivy SARIF to GitHub code scanning
- Trivy JSON scan artifacts
- CycloneDX SBOM artifacts

## Notes

- This repository intentionally avoids organization/customer-specific product
  naming beyond the neutral `pre-secured` prefix.
- Runtime deployment cutovers are tracked in the incident/operations repository,
  not here.
