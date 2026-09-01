# Security Policy

## Scope

This repository builds and publishes a downstream patched LiteLLM image to GHCR.

## Reporting

Report security issues through the GitHub security advisory flow for this
repository or the owning organization's preferred private reporting channel.

## Build gate expectations

- image publishing is expected to run vulnerability scanning,
- scan evidence should be attached to workflow runs,
- high/critical findings should block promotion until reviewed.
