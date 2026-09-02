# litellm-patched-proxy

[![Ask DeepWiki](https://deepwiki.com/badge.svg)](https://deepwiki.com/ContextualWisdomLab/litellm-patched-proxy)

`litellm-patched-proxy` produces a maintained downstream LiteLLM proxy image with bounded operational patches and supply-chain evidence suitable for governed deployments.

## What it provides

- An upstream-digest-pinned LiteLLM proxy image.
- Reviewed downstream patches, including bounded health-check history queries.
- Immutable `sha-<gitsha>` image tags plus default-branch `edge` publication.
- Trivy vulnerability evidence and CycloneDX SBOM artifacts.
- A deduplicated remediation path when high-severity findings remain.

## Operating boundary

Image publication and security evidence are owned here. Deployment promotion should consume a reviewed immutable image identity and retain environment-specific rollout, rollback, credentials, routing, and policy in the deployment authority that consumes the image.

## Onboarding

Start with the [repository README](https://github.com/ContextualWisdomLab/litellm-patched-proxy/blob/develop/README.md) for current image/tagging conventions and CI evidence. Review the repository workflows before changing the upstream digest, package set, patch overlay, or release behavior.

## Release and verification

A source change is not a release. Treat a published immutable image tag, its associated Git commit, successful required checks, vulnerability evidence, and SBOM as the relevant delivery evidence. Do not infer GitHub Pages publication from this source file alone; the live repository Pages state must be verified after settings reconciliation.

## License and provenance

ContextualWisdomLab-authored repository source and documentation are MIT-licensed. The downstream image also contains independently licensed software, including MIT-licensed LiteLLM source overlaid from immutable fork commits. The repository grant does not replace third-party terms.

- [Repository](https://github.com/ContextualWisdomLab/litellm-patched-proxy)
- [README](https://github.com/ContextualWisdomLab/litellm-patched-proxy/blob/develop/README.md)
- [License](https://github.com/ContextualWisdomLab/litellm-patched-proxy/blob/develop/LICENSE)
- [Third-party notices](https://github.com/ContextualWisdomLab/litellm-patched-proxy/blob/develop/THIRD_PARTY_NOTICES.md)
- [Ask DeepWiki](https://deepwiki.com/ContextualWisdomLab/litellm-patched-proxy)
