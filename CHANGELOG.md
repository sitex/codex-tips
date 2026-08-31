# Changelog

All notable changes to this project are documented here.

## [Unreleased]

## [0.1.0] - 2026-09-01

### Added

- Predict a short next prompt after eligible completed Codex turns.
- Render the prediction as dim composer text without submitting it.
- Accept with `Tab` or Right Arrow and dismiss on manual input or stale state.
- Cancel abandoned hidden requests and suppress suggestions during incomplete flows.
- Install a reproducible Codex 0.151.0 patch from a pinned upstream commit.
- Restore the matching `codex-code-mode-host` and managed Codex launcher on fast-path installs.

### Security

- Exclude tools from hidden prediction requests and filter unsafe composer output.
- Refuse unsupported Codex versions, untrusted upstream commits, and unmanaged launcher paths.
- Use an independently authored prediction instruction with no proprietary prompt text.
