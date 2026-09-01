# Contributing

`codex-tips` carries a versioned downstream Codex patch. Keep every change narrow,
auditable, and tied to one supported upstream tag.

Before opening a pull request:

1. add or update a focused regression for behavioral changes;
2. run `bash tests/install-codex-tips.sh` on Linux or macOS;
3. run `pwsh -NoProfile -File tests/install-codex-tips.ps1` on Windows;
4. run `shellcheck bin/install-codex-tips tests/install-codex-tips.sh`;
5. verify the patch applies to the pinned upstream commit;
6. run the relevant upstream Rust tests with `RUST_MIN_STACK=8388608` and build
   `codex-cli --release`;
7. exercise the built TUI and record the observed composer behavior;
8. update `CHANGELOG.md` for user-visible changes.

Do not include credentials, conversation transcripts, private infrastructure,
generated binaries, Cargo targets, release archives, or unrelated Codex changes.

New Codex versions require a new `rust-vX.Y.Z.patch`, an explicitly pinned upstream
commit in the installer, focused compatibility tests, and a fresh live TUI check.
Platform support also requires a real full build and `codex-tips --version` run on
that operating system and architecture.
