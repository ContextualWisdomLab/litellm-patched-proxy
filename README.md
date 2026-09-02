# litellm-patched-proxy

[![Ask DeepWiki](https://deepwiki.com/badge.svg)](https://deepwiki.com/ContextualWisdomLab/litellm-patched-proxy)

Downstream LiteLLM proxy image with bounded health-check history queries and maintained production patches.

## Product responsibility

This repository builds and publishes a hardened LiteLLM proxy image that:

- stays pinned to the approved upstream LiteLLM base digest,
- pre-bakes runtime tools that would otherwise be installed at container startup,
- carries reviewed downstream patches such as bounded health-check history queries,
- publishes immutable CI-traceable image tags, and
- records vulnerability-scan and SBOM evidence in GitHub Actions and code scanning.

The reduction strategy is conservative: remove only packages that are not proven runtime requirements and preserve Python/LiteLLM + Hypercorn compatibility before promotion.

## Published image

- GHCR package: `ghcr.io/seongho-bae/pre-secured-llm-proxy`

## Tagging

- `edge` from the default branch
- `sha-<gitsha>` for immutable CI traceability
- semver tags when the repository itself is tagged

## Evidence

The workflows produce:

- Trivy SARIF for GitHub code scanning
- Trivy JSON scan artifacts
- CycloneDX SBOM artifacts

When HIGH/CRITICAL findings remain, repository automation can create or update a deduplicated remediation issue so the finding is actionable rather than existing only in a workflow log.

## Automated remediation loop

- Trivy findings create or update a deduplicated remediation issue.
- GitHub-native AI/Copilot can be assigned to AI-ready remediation work.
- Remediation pull requests remain subject to the repository's required checks and merge governance.

## Documentation

See [`docs/index.md`](docs/index.md) for the repository-facing product, release, and verification landing page, or [Ask DeepWiki](https://deepwiki.com/ContextualWisdomLab/litellm-patched-proxy) for a navigable repository view.

## License and upstream provenance

ContextualWisdomLab-authored source and documentation in this repository are licensed under the [MIT License](LICENSE).

The distributed image also contains third-party software under independent terms. In particular, the Docker build overlays selected non-`enterprise/` LiteLLM source files from immutable fork commits; those paths inherit LiteLLM's MIT license and Berri AI attribution rather than this repository's grant. See [`THIRD_PARTY_NOTICES.md`](THIRD_PARTY_NOTICES.md) for the retained upstream notice and provenance boundary. Other base-image, Python, npm, and operating-system packages remain under their own licenses.
