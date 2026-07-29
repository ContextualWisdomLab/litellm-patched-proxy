# LiteLLM overlay patches

These patches are generated against the pinned `BerriAI/litellm` `v1.84.10`
source tree. They replace unauthenticated runtime downloads while preserving
the reviewed fork commits:

- Redis and lowest-latency fixes: `661948eb340aa7661a4203205154cf22106077df`
- Health-history fixes: `fce13be05e620bea3e4ba38139c0e878b0842cbe`

The Docker build decompresses and applies every patch to each installed package
referenced by a LiteLLM CLI, then verifies the complete files against the
SHA-256 values in the Dockerfile. The gzip files use `gzip -n` so their bytes
are reproducible. Do not edit the generated patch contents without updating the
source commit, complete-file hashes, and runtime verification.
