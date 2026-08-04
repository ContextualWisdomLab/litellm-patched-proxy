# LiteLLM overlay sources

These files are vendored from immutable commits in `Seongho-Bae/litellm` so
the image build does not depend on private repository access or mutable branch
content.

- `caching/redis_cache.py` and `router_strategy/lowest_latency.py` come from
  commit `661948eb340aa7661a4203205154cf22106077df`.
- The remaining files come from commit
  `74da1d5af1d50bca763a85a2b15b85d08e6df3d4`, merged by LiteLLM PR #16.

The Dockerfile checks every file against its pinned SHA-256 before installing
it into the image. Update the source commit, vendored file, and expected hash
together.
