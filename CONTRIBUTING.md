# Contributing

`codex-tips` carries a versioned downstream Codex patch. Keep every change narrow,
auditable, and tied to one supported upstream tag.

Before opening a pull request:

1. add or update a focused regression for behavioral changes;
2. run `bash tests/install-codex-tips.sh`;
3. run `shellcheck bin/install-codex-tips tests/install-codex-tips.sh`;
4. verify the patch applies to the pinned upstream commit;
5. run the relevant upstream Rust tests with `RUST_MIN_STACK=8388608` and build
   `codex-cli --release`;
6. exercise the built TUI and record the observed composer behavior;
7. update `CHANGELOG.md` for user-visible changes.

Do not include credentials, conversation transcripts, private infrastructure,
generated binaries, Cargo targets, release archives, or unrelated Codex changes.

New Codex versions require a new `rust-vX.Y.Z.patch`, an explicitly pinned upstream
commit in the installer, focused compatibility tests, and a fresh live TUI check.
