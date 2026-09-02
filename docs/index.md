# litellm-patched-proxy

[![Ask DeepWiki](https://deepwiki.com/badge.svg)](https://deepwiki.com/ContextualWisdomLab/litellm-patched-proxy)

`litellm-patched-proxy` produces a maintained downstream LiteLLM proxy image with bounded operational patches and supply-chain evidence suitable for governed deployments.

## What it provides

- An upstream-digest-pinned LiteLLM proxy image.
- Reviewed downstream patches, including bounded health-check history queries.
- Commit-derived `sha-<gitsha>` tags plus default-branch `edge` publication.
- A pushed OCI digest that serves as the immutable image content identity.
- Trivy vulnerability evidence and CycloneDX SBOM artifacts.
- A deduplicated remediation path when high-severity findings remain.

## Operating boundary

Image publication and security evidence are owned here. Deployment promotion should retain the reviewed OCI digest as the immutable image identity. Environment-specific rollout, rollback, credentials, routing, and policy remain owned by the deployment authority that consumes the image.

## Onboarding

Start with the [repository README](https://github.com/ContextualWisdomLab/litellm-patched-proxy/blob/develop/README.md) for current image/tagging conventions and CI evidence. Review the repository workflows before changing the upstream digest, package set, patch overlay, or release behavior.

## Release and verification

A source change is not a release. `edge`, `sha-*`, and semver are registry tags and may move unless an external registry policy proves otherwise; this repository does not claim that protection. For provenance or deployment, bind the source commit and successful required checks to the OCI digest emitted by the publish build, together with vulnerability evidence and the SBOM. Do not infer GitHub Pages publication from this source file alone; the live repository Pages state must be verified after settings reconciliation.

## License and provenance

ContextualWisdomLab-authored repository source and documentation are MIT-licensed. The downstream image also contains independently licensed software, including MIT-licensed LiteLLM source overlaid from immutable fork commits. The repository grant does not replace third-party terms. The build carries the repository license and retained upstream notice inside the image under `/usr/share/licenses/litellm-patched-proxy/`.

- [Repository](https://github.com/ContextualWisdomLab/litellm-patched-proxy)
- [README](https://github.com/ContextualWisdomLab/litellm-patched-proxy/blob/develop/README.md)
- [License](https://github.com/ContextualWisdomLab/litellm-patched-proxy/blob/develop/LICENSE)
- [Third-party notices](https://github.com/ContextualWisdomLab/litellm-patched-proxy/blob/develop/THIRD_PARTY_NOTICES.md)
- [Ask DeepWiki](https://deepwiki.com/ContextualWisdomLab/litellm-patched-proxy)
