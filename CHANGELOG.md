# Changelog

All notable changes to this project are documented here.

## [Unreleased]

## [0.3.0] - 2026-09-11

### Added

- Port the next-prompt patch to Codex CLI 0.154.0, pinned to upstream commit
  `6b9826e3aa83b1a5947db50f4332cb9c65f1b340`.
- Include exact patches for Codex 0.152.1, 0.153.2, and 0.153.4.
- Include the optional manual `$tip` skill.

### Changed

- Cover all six saved versions in both installers, regression tests, and CI.
- Compare raw PowerShell exception messages so terminal wrapping does not break
  the unsupported-version regression check.
- Allow selecting a single Codex version for the full-platform build workflow.
- Document that source builds can take from tens of minutes to several hours.
- Preserve upstream worktree, read-only session, and model picker behavior while
  retaining suggestion acceptance, cancellation, and stale-result protection.

## [0.2.0] - 2026-09-01

### Added

- Support source builds and managed launchers on x86_64 macOS and x86_64 native Windows.
- Add a native PowerShell installer and Windows installer regression.
- Add a Codex/LLM-guided installation checklist with compatibility and checksum safeguards.
- Exercise Unix installers on Linux and macOS in CI, with manual full-build gates for all three supported operating systems.

### Changed

- Store matching patches per Codex version and support Codex CLI 0.151.0 (`78c290807ce710180111df227df3b7a4fe845452`) and 0.152.0 (`316795b3cf2a45e90d121d9f46499d4658b2645c`), with 0.152.0 latest and recommended.
- Keep the same hide-while-typing, clear-to-restore, and stale-to-discard suggestion behavior on both supported Codex versions.
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
