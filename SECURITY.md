# Security policy

## Supported versions

Only the latest `codex-tips` release and the exact Codex versions named by that
release are supported. Release 0.2.0 supports Codex CLI 0.151.0 at upstream commit
`78c290807ce710180111df227df3b7a4fe845452` and Codex CLI 0.152.0 at upstream
commit `316795b3cf2a45e90d121d9f46499d4658b2645c`; 0.152.0 is latest and
recommended. Its release-gated platforms are x86_64 Linux, macOS, and native
Windows. ARM64 is not release-gated.

Installers select `patches/codex-tips/rust-v<version>.patch` for the detected
official Codex installation and trust only that version's pinned upstream commit
and platform runtime package. They refuse unsupported versions and unmanaged
launcher paths.

## Reporting a vulnerability

Do not open a public issue for credentials, private conversation disclosure,
unsafe suggestion generation, installer path replacement, or release integrity
problems. Use GitHub's private security-advisory flow for this repository.

Include the `codex-tips` release, Codex version, operating system, reproduction
steps, and impact. Remove tokens, credentials, conversation content, and other
personal data from reports and logs.
