#!/usr/bin/env bash
set -euo pipefail

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
fixture=$(mktemp -d "${TMPDIR:-/tmp}/install-codex-tips-test.XXXXXX")
trap 'rm -rf "$fixture"' EXIT

package_root="$fixture/npm/lib/node_modules/@openai/codex"
launcher="$package_root/bin/codex.js"
runtime_root="$package_root/node_modules/@openai/codex-linux-x64/vendor/x86_64-unknown-linux-musl"
runtime_bin="$runtime_root/bin"
host_source="$runtime_bin/codex-code-mode-host"
bwrap_source="$runtime_root/codex-resources/bwrap"
rg_source="$runtime_root/codex-path/rg"
manifest_source="$runtime_root/codex-package.json"
install_root="$fixture/install"
installed_dir="$install_root/0.152.0"
installed_binary="$installed_dir/bin/codex"
stable_link="$fixture/prefix/bin/codex-tips"
codex_alias="$fixture/prefix/bin/codex"
portable_bin="$fixture/portable-bin"

mkdir -p \
  "$(dirname "$launcher")" \
  "$runtime_bin" \
  "$(dirname "$bwrap_source")" \
  "$(dirname "$rg_source")" \
  "$(dirname "$installed_binary")" \
  "$fixture/bin" \
  "$portable_bin"
printf '%s\n' '#!/bin/sh' 'printf "%s\\n" "codex-cli 0.152.0"' >"$launcher"
printf '%s\n' 'host fixture' >"$host_source"
printf '%s\n' 'bwrap fixture' >"$bwrap_source"
printf '%s\n' 'rg fixture' >"$rg_source"
printf '%s\n' '{"layoutVersion":1,"version":"0.152.0"}' >"$manifest_source"
cp "$launcher" "$runtime_bin/codex"
chmod 0755 "$launcher" "$runtime_bin/codex" "$host_source" "$bwrap_source" "$rg_source"
cp "$launcher" "$installed_binary"
ln -s "$launcher" "$fixture/bin/codex"

# Given a BSD-like userland that rejects GNU-only flags.
real_readlink=$(command -v readlink)
real_sort=$(command -v sort)
real_mv=$(command -v mv)
# shellcheck disable=SC2016
printf '%s\n' \
  '#!/bin/sh' \
  'if [ "${1:-}" = "-f" ]; then exit 64; fi' \
  'exec "$CODEX_TIPS_TEST_REAL_READLINK" "$@"' >"$portable_bin/readlink"
# shellcheck disable=SC2016
printf '%s\n' \
  '#!/bin/sh' \
  'for arg in "$@"; do if [ "$arg" = "-V" ]; then exit 64; fi; done' \
  'exec "$CODEX_TIPS_TEST_REAL_SORT" "$@"' >"$portable_bin/sort"
# shellcheck disable=SC2016
printf '%s\n' \
  '#!/bin/sh' \
  'for arg in "$@"; do case "$arg" in -*T*) exit 64 ;; esac; done' \
  'exec "$CODEX_TIPS_TEST_REAL_MV" "$@"' >"$portable_bin/mv"
chmod 0755 "$portable_bin/readlink" "$portable_bin/sort" "$portable_bin/mv"
if grep -q 'mapfile' "$repo_root/bin/install-codex-tips"; then
  printf 'installer must remain compatible with the Bash shipped by macOS\n' >&2
  exit 1
fi

# When the existing install is repaired through the public Unix installer.
install_output=$(env \
  PATH="$portable_bin:$fixture/bin:$PATH" \
  CODEX_TIPS_TEST_REAL_READLINK="$real_readlink" \
  CODEX_TIPS_TEST_REAL_SORT="$real_sort" \
  CODEX_TIPS_TEST_REAL_MV="$real_mv" \
  CODEX_TIPS_INSTALL_ROOT="$install_root" \
  CODEX_TIPS_LINK="$stable_link" \
  CODEX_TIPS_ALIAS="$codex_alias" \
  "$repo_root/bin/install-codex-tips")

# Then the complete runtime package is present and launchers target the patched binary.
cmp "$host_source" "$installed_dir/bin/codex-code-mode-host"
cmp "$bwrap_source" "$installed_dir/codex-resources/bwrap"
cmp "$rg_source" "$installed_dir/codex-path/rg"
cmp "$manifest_source" "$installed_dir/codex-package.json"
test -x "$installed_dir/bin/codex-code-mode-host"
test "$(readlink "$stable_link")" = "$installed_binary"
test "$(readlink "$codex_alias")" = "$stable_link"
test "$("$codex_alias" --version)" = 'codex-cli 0.152.0'
[[ $install_output == *"run \`hash -r\` in long-lived Bash shells"* ]]

# Given the fast-path installation loses runtime support files.
rm "$installed_dir/bin/codex-code-mode-host" "$installed_dir/codex-resources/bwrap"
# When the installer repairs the existing installation.
env \
  PATH="$portable_bin:$fixture/prefix/bin:$fixture/bin:$PATH" \
  CODEX_TIPS_TEST_REAL_READLINK="$real_readlink" \
  CODEX_TIPS_TEST_REAL_SORT="$real_sort" \
  CODEX_TIPS_TEST_REAL_MV="$real_mv" \
  CODEX_TIPS_INSTALL_ROOT="$install_root" \
  CODEX_TIPS_LINK="$stable_link" \
  CODEX_TIPS_ALIAS="$codex_alias" \
  "$repo_root/bin/install-codex-tips" >/dev/null

# Then both files are restored without replacing the patched binary.
cmp "$host_source" "$installed_dir/bin/codex-code-mode-host"
cmp "$bwrap_source" "$installed_dir/codex-resources/bwrap"
test "$("$installed_binary" --version)" = 'codex-cli 0.152.0'

# Given an installed Codex version without a matching release patch.
unsupported_launcher="$fixture/bin/codex-unsupported"
printf '%s\n' '#!/bin/sh' 'printf "%s\\n" "codex-cli 0.153.0"' >"$unsupported_launcher"
chmod 0755 "$unsupported_launcher"

# When installation is attempted, then it fails before fetching or building upstream.
if unsupported_output=$(env \
  PATH="$portable_bin:$PATH" \
  CODEX_TIPS_TEST_REAL_READLINK="$real_readlink" \
  CODEX_TIPS_TEST_REAL_SORT="$real_sort" \
  CODEX_TIPS_TEST_REAL_MV="$real_mv" \
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
[[ $unsupported_output == *'unsupported Codex version 0.153.0'* ]]
