# litellm-patched-proxy

[![Ask DeepWiki](https://deepwiki.com/badge.svg)](https://deepwiki.com/ContextualWisdomLab/litellm-patched-proxy)

Downstream LiteLLM proxy image with bounded health-check history queries and maintained production patches.

## Product responsibility

This repository builds and publishes a hardened LiteLLM proxy image that:

- stays pinned to the approved upstream LiteLLM base digest,
- pre-bakes runtime tools that would otherwise be installed at container startup,
- carries reviewed downstream patches such as bounded health-check history queries,
- publishes commit-addressable image tags plus a content digest, and
- records vulnerability-scan and SBOM evidence in GitHub Actions and code scanning.

The reduction strategy is conservative: remove only packages that are not proven runtime requirements and preserve Python/LiteLLM + Hypercorn compatibility before promotion.

## Published image

- GHCR package: `ghcr.io/seongho-bae/pre-secured-llm-proxy`

## Tagging and immutable identity

- `edge` follows the default branch and is intentionally mutable.
- `sha-<gitsha>` is derived from the source commit for CI traceability; the repository does not claim registry-level tag immutability.
- semver tags are emitted when the repository itself is tagged.
- the pushed OCI image digest reported by the build is the immutable content identity to retain for deployment or provenance evidence.

## Evidence

The workflows produce:

- Trivy SARIF for GitHub code scanning
- Trivy JSON scan artifacts
- CycloneDX SBOM artifacts
- the pushed OCI image digest in the build summary

A separate workflow reads the Trivy artifact after PR validation or image publication. When HIGH/CRITICAL findings exist, it creates or updates one scope-keyed remediation issue with the exact source commit, workflow run, severity counts, and package/vulnerability table; when the scope becomes clean, it closes that issue.

## Automated remediation loop

- Trivy findings create or update a deduplicated `copilot-candidate` remediation issue.
- The repository attempts to assign GitHub Copilot to such issues; assignment failure is tolerated and is not remediation evidence.
- Non-draft Copilot remediation PRs are configured for GitHub auto-merge with squash, but normal required checks and merge governance still decide whether integration can occur.

## Documentation

See [`docs/index.md`](docs/index.md) for the repository-facing product, release, and verification landing page, or [Ask DeepWiki](https://deepwiki.com/ContextualWisdomLab/litellm-patched-proxy) for a navigable repository view.

## License and upstream provenance

ContextualWisdomLab-authored source and documentation in this repository are licensed under the [MIT License](LICENSE).

The distributed image also contains third-party software under independent terms. In particular, the Docker build overlays selected non-`enterprise/` LiteLLM source files from immutable fork commits; those paths inherit LiteLLM's MIT license and Berri AI attribution rather than this repository's grant. The build copies this repository's license and the retained upstream notice into `/usr/share/licenses/litellm-patched-proxy/` in the image. See [`THIRD_PARTY_NOTICES.md`](THIRD_PARTY_NOTICES.md) for the provenance boundary. Other base-image, Python, npm, and operating-system packages remain under their own licenses.
