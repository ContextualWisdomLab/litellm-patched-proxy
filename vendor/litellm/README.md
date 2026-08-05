# LiteLLM overlay sources

These files are vendored from immutable commits in `Seongho-Bae/litellm` so
the image build does not depend on private repository access or mutable branch
content.

- `caching/redis_cache.py` and `router_strategy/lowest_latency.py` come from
  commit `661948eb340aa7661a4203205154cf22106077df`.
- `proxy/health_check.py` comes from commit
  `bdbe9f2fa7fe8daa52539c516b99e9f6f0013ed1`, which prevents invalid
  generation fields on typed APIs and enforces provider-safe output floors.
- The remaining files come from commit
  `4b5e57c14b12f427546afc0cc7c89a2caff8bc34`, which contains the merged
  LiteLLM PRs #16 and #20. PR #20 adds event-time Prisma spend transaction
  diagnostics without changing reconnect behavior.

The Dockerfile checks every file against its pinned SHA-256 before installing
it into the image. Update the source commit, vendored file, and expected hash
together.
