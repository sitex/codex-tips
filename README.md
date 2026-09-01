# codex-tips

`codex-tips` is an experimental downstream patch for Codex CLI that predicts the
user's likely next prompt after a completed turn and displays it as dim text in
the empty composer.

Press `Tab` or Right Arrow to copy the suggestion into the editable input without
sending it. Press `Enter` only after accepting it to submit. Typing normally,
starting another turn, or changing state dismisses a stale suggestion.

This is an independent community project. It is not affiliated with or supported
by OpenAI.

## Compatibility

Release 0.2.0 supports exactly Codex CLI `0.151.0` (`rust-v0.151.0`, upstream
commit `78c290807ce710180111df227df3b7a4fe845452`). The installer refuses other
versions instead of attempting an unverified patch port.

The release is tested on x86_64 Linux, macOS, and native Windows. ARM64 packages
exist upstream but are not release-gated by this project yet. The installer builds
Codex from source, so installation can take several minutes and use several
gigabytes of disk.

Requirements:

- the official Codex CLI 0.151.0 installation;
- Git;
- Rust and Cargo compatible with the upstream `rust-toolchain.toml`;
- Bash 3.2 or newer on Linux and macOS, or PowerShell 7 on Windows.

## Install 0.2.0

Download both assets from the
[v0.2.0 release](https://github.com/sitex/codex-tips/releases/tag/v0.2.0):

```text
codex-tips-0.2.0.tar.gz
codex-tips-0.2.0.tar.gz.sha256
```

On Linux or macOS, verify and extract the release before running it:

```bash
sha256sum -c codex-tips-0.2.0.tar.gz.sha256
tar -xzf codex-tips-0.2.0.tar.gz
cd codex-tips-0.2.0
./bin/install-codex-tips
```

macOS provides `shasum` instead of `sha256sum` by default:

```bash
shasum -a 256 -c codex-tips-0.2.0.tar.gz.sha256
```

On Windows, use PowerShell:

```powershell
$expected = (Get-Content .\codex-tips-0.2.0.tar.gz.sha256).Split()[0]
$actual = (Get-FileHash .\codex-tips-0.2.0.tar.gz -Algorithm SHA256).Hash.ToLowerInvariant()
if ($actual -ne $expected) { throw "release checksum mismatch" }
tar -xzf .\codex-tips-0.2.0.tar.gz
Set-Location .\codex-tips-0.2.0
$env:CODEX_TIPS_UPDATE_PATH = "1"
.\bin\install-codex-tips.ps1
```

The installer:

1. detects the official Codex version;
2. fetches the matching OpenAI Codex tag and verifies its pinned commit;
3. applies the versioned patch;
4. builds `codex-cli --release`;
5. copies the matching official runtime package and replaces only its `codex`
   binary with the patched build;
6. creates managed `codex-tips` and `codex` launchers.

The installer refuses to overwrite commands or symlinks it does not own. Use
`--force` on Unix or `-Force` on Windows to rebuild the supported version.
Environment overrides are listed by `./bin/install-codex-tips --help`; the
PowerShell installer uses the corresponding `CODEX_TIPS_*` variables.

Unix installs under `~/.local/lib/codex-tips/` and links commands from
`~/.local/bin/`. Windows installs under `%LOCALAPPDATA%\codex-tips\` and only
updates the user `PATH` when `CODEX_TIPS_UPDATE_PATH=1` is set.

Restart existing Codex sessions after installation. Long-lived Bash shells may
also need `hash -r`.

## Behavior and privacy

Suggestion generation is a hidden, read-only model request using a bounded tail
of prompt-visible history from the current loaded thread. It does not advance the
conversation, invoke tools, or automatically submit the suggestion.

The request uses the same configured model provider as Codex and may consume model
tokens. Recent conversation content is therefore sent to that provider in the same
way as an ordinary Codex request. `codex-tips` adds no separate network service,
telemetry, account, or persistence layer.

Suggestions are suppressed when recent history is incomplete, the session is not
idle, or the generated text fails composer-safety filters. Security-sensitive and
private-data continuations are explicitly excluded by the prediction instruction.

## Uninstall

On Linux or macOS, first inspect the managed links:

```bash
readlink ~/.local/bin/codex
readlink ~/.local/bin/codex-tips
```

If they point to the paths installed above, remove those two links and the matching
`~/.local/lib/codex-tips/0.151.0/` directory. Then ensure the official Codex launcher
is next on `PATH` and run `hash -r`.

On Windows, inspect and remove the managed `codex.cmd` and `codex-tips.cmd` files
plus the matching version directory under `%LOCALAPPDATA%\codex-tips\`. If the
installer added its bin directory to the user `PATH`, remove that entry as well.

## Development

Run the standalone installer regression and shell lint:

```bash
bash tests/install-codex-tips.sh
shellcheck bin/install-codex-tips tests/install-codex-tips.sh
```

On Windows, run:

```powershell
pwsh -NoProfile -File tests\install-codex-tips.ps1
```

Verify the patch against the pinned upstream checkout:

```bash
git clone --depth 1 --branch rust-v0.151.0 https://github.com/openai/codex.git /tmp/codex-tips-upstream
test "$(git -C /tmp/codex-tips-upstream rev-parse HEAD)" = 78c290807ce710180111df227df3b7a4fe845452
git -C /tmp/codex-tips-upstream apply --check "$PWD/patches/codex-tips/rust-v0.151.0.patch"
```

See [CONTRIBUTING.md](CONTRIBUTING.md) for the release gates.

## License

Licensed under Apache License 2.0. The patch modifies Apache-2.0-licensed OpenAI
Codex sources; attribution is recorded in [NOTICE](NOTICE).
