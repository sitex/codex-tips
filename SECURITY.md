# Security policy

## Supported versions

Only the latest `codex-tips` release and the exact Codex version named by that
release are supported. Platform support is limited to the operating systems and
architectures explicitly marked as tested in the release README; ARM64 is not a
supported configuration for 0.2.0.

Installers trust only the pinned upstream Codex commit and the platform runtime
package from the detected official Codex installation. They refuse unsupported
versions and unmanaged launcher paths.

## Reporting a vulnerability

Do not open a public issue for credentials, private conversation disclosure,
unsafe suggestion generation, installer path replacement, or release integrity
problems. Use GitHub's private security-advisory flow for this repository.

Include the `codex-tips` release, Codex version, operating system, reproduction
steps, and impact. Remove tokens, credentials, conversation content, and other
personal data from reports and logs.
