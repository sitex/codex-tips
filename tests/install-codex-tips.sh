#!/usr/bin/env bash
set -euo pipefail

repo_root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
fixture=$(mktemp -d "${TMPDIR:-/tmp}/install-codex-tips-test.XXXXXX")
trap 'rm -rf -- "$fixture"' EXIT

package_root="$fixture/npm/lib/node_modules/@openai/codex"
launcher="$package_root/bin/codex.js"
host_source="$package_root/node_modules/@openai/codex-linux-x64/vendor/x86_64-unknown-linux-musl/bin/codex-code-mode-host"
install_root="$fixture/install"
installed_dir="$install_root/0.151.0"
stable_link="$fixture/prefix/bin/codex-tips"
codex_alias="$fixture/prefix/bin/codex"

mkdir -p "$(dirname -- "$launcher")" "$(dirname -- "$host_source")" "$installed_dir" "$fixture/bin"
printf '%s\n' '#!/bin/sh' 'printf "%s\\n" "codex-cli 0.151.0"' >"$launcher"
printf '%s\n' 'host fixture' >"$host_source"
chmod 0755 "$launcher" "$host_source"
cp "$launcher" "$installed_dir/codex"
ln -s "$launcher" "$fixture/bin/codex"

install_output=$(env \
  PATH="$fixture/bin:$PATH" \
  CODEX_TIPS_INSTALL_ROOT="$install_root" \
  CODEX_TIPS_LINK="$stable_link" \
  CODEX_TIPS_ALIAS="$codex_alias" \
  "$repo_root/bin/install-codex-tips")

# Then the standalone launchers target the installed binary without a host wrapper.
cmp "$host_source" "$installed_dir/codex-code-mode-host"
test -x "$installed_dir/codex-code-mode-host"
test "$(readlink -- "$stable_link")" = "$installed_dir/codex"
test "$(readlink -- "$codex_alias")" = "$stable_link"
test "$("$codex_alias" --version)" = 'codex-cli 0.151.0'
[[ $install_output == *"run \`hash -r\` in long-lived Bash shells"* ]]

# Given the fast-path installation loses its companion host.
rm "$installed_dir/codex-code-mode-host"
# When the installer repairs the existing installation.
env \
  PATH="$fixture/prefix/bin:$fixture/bin:$PATH" \
  CODEX_TIPS_INSTALL_ROOT="$install_root" \
  CODEX_TIPS_LINK="$stable_link" \
  CODEX_TIPS_ALIAS="$codex_alias" \
  "$repo_root/bin/install-codex-tips" >/dev/null

# Then the companion host is restored.
cmp "$host_source" "$installed_dir/codex-code-mode-host"

# Given an installed Codex version without a matching release patch.
unsupported_launcher="$fixture/bin/codex-unsupported"
printf '%s\n' '#!/bin/sh' 'printf "%s\\n" "codex-cli 0.152.0"' >"$unsupported_launcher"
chmod 0755 "$unsupported_launcher"

# When installation is attempted, then it fails before fetching or building upstream.
if unsupported_output=$(env \
  CODEX_TIPS_CODEX="$unsupported_launcher" \
  CODEX_TIPS_CACHE_DIR="$fixture/unsupported-cache" \
  CODEX_TIPS_TARGET_DIR="$fixture/unsupported-target" \
  CODEX_TIPS_INSTALL_ROOT="$fixture/unsupported-install" \
  CODEX_TIPS_LINK="$fixture/unsupported-prefix/codex-tips" \
  CODEX_TIPS_ALIAS="$fixture/unsupported-prefix/codex" \
  CODEX_TIPS_UPSTREAM="$fixture/missing-upstream" \
  "$repo_root/bin/install-codex-tips" 2>&1); then
  printf 'expected unsupported Codex version to fail\n' >&2
  exit 1
fi
[[ $unsupported_output == *'unsupported Codex version 0.152.0'* ]]
