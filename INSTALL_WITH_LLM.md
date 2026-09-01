# Install with an LLM

Use a local coding agent that can inspect your machine and run terminal commands.
Give it this prompt:

> Install `codex-tips` by following the instructions at
> <https://github.com/sitex/codex-tips/blob/main/INSTALL_WITH_LLM.md>. Do not
> bypass compatibility or checksum checks. Ask before using `--force` or
> `-Force`, replacing a launcher, or changing my `PATH`.

## Instructions for the coding agent

1. Read the Compatibility and Install sections in [README.md](README.md) and the
   project [security policy](SECURITY.md). Use the release linked by the README,
   not an automatically generated source archive.
2. Before changing the machine, detect and report:
   - the operating system and architecture;
   - the output of `codex --version` and the resolved `codex` command path;
   - whether Git, Rust, Cargo, and the platform shell required by the README are
     available.
3. Stop if the installed Codex version or platform is unsupported. Do not patch
   a different version or bypass the installer's pinned-commit checks.
4. Download both the release archive and its `.sha256` file into a new temporary
   directory. Verify the checksum with the platform-specific command from the
   README before extracting the archive. Stop on any mismatch.
5. Run the documented installer for the detected platform. Do not use `--force`
   or `-Force`, replace an unmanaged launcher, or make a persistent `PATH` change
   without the user's explicit approval.
6. After installation, resolve the `codex-tips` and `codex` command paths and run
   both commands with `--version`. Report the installed paths, versions, and any
   files or environment settings changed.
7. Tell the user to restart existing Codex sessions. If a step fails, report the
   exact failing check instead of weakening or skipping it.
