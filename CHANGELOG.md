# Changelog

All notable changes to this project are documented here.

## [Unreleased]

## [0.2.0] - 2026-09-01

### Added

- Support source builds and managed launchers on x86_64 macOS and native Windows.
- Add a native PowerShell installer and Windows installer regression.
- Exercise Unix installers on Linux and macOS in CI, with manual full-build gates for all three supported operating systems.

### Changed

- Install the complete official platform runtime package while replacing only the patched `codex` binary.
- Restore bundled helpers such as `bwrap`, ripgrep, code mode, and Windows sandbox executables on fast-path installs.
- Make the Unix installer compatible with the Bash and BSD userland shipped by macOS.

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
