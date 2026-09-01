# Repository instructions

## Purpose

This repository builds a downstream LiteLLM proxy image with reviewed production
patches. Keep each patch attributable to an upstream issue or pull request, pin
the upstream image by digest, and preserve a runnable check that fails when the
patch no longer applies.

## Required skills

- Before generating or creating a commit, read and follow the shared
  `Git Commit Format` skill at
  `~/.agents/skills/git-commit-format/SKILL.md`.
- Apply the Ponytail minimal-solution ladder: reuse upstream or existing project
  code before adding the smallest downstream change that fixes the root cause.

## Commit requirements

- Use Conventional Commits: `<type>(<scope>): <description>`.
- Add `Signed-off-by: Name <email>` from the configured Git author to every
  commit, normally with `git commit --signoff`. This is a DCO-style trailer; it
  is not a substitute for cryptographic commit signing when branch policy also
  requires a verified signature.
- Add the assisted-by trailer required by the `Git Commit Format` skill whenever
  an AI assistant helps compose the commit message.
- Do not bypass protected-branch checks, required reviews, or signed-commit
  policy.

## Working conventions

- If `.codegraph/` exists, use CodeGraph before broad searches or file-reading
  loops. If the index is unhealthy, run `codegraph sync`; do not delete it.
- Treat this as a downstream patch carrier, not an independent LiteLLM fork.
  Prefer removing a patch after its upstream replacement is present in the
  pinned base image.
- Keep GHCR paths lowercase. The canonical organization name in GitHub URLs is
  `ContextualWisdomLab`; the image namespace is `contextualwisdomlab`.
- Validate workflow changes with `actionlint` and all changes with
  `git diff --check` before pushing.
