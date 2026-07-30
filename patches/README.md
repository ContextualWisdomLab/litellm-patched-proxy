# LiteLLM overlays

These patches are generated from reviewed commits in `Seongho-Bae/litellm` so
image builds do not depend on GitHub raw-content availability.

- `router-timedelta-661948eb`: commit
  `661948eb340aa7661a4203205154cf22106077df`
- `health-history-fce13be0`: commit
  `fce13be05e620bea3e4ba38139c0e878b0842cbe`
- `async-client-cleanup-91a5f2f4`: commit
  `91a5f2f4d459a7da84c4b354fbf281ffc834147a`
- `langfuse-none-dynamic-params-d63a6438`: commit
  `d63a6438f13774392f14d9af5ada0fe1974cd0ff`

The Dockerfile verifies each patch, applies it to pinned LiteLLM 1.84.10, then
verifies every resulting file against its pinned SHA-256. Update the source
commit, patch, patch checksum, and resulting file checksums together.
