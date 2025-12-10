#!/usr/bin/env bash
# Build script for better-claude-code
# Generates embedded content and runs bashly

set -euo pipefail

cd "$(dirname "$0")"

echo "Generating hook content..."
./scripts/generate-hook-content.sh

echo "Running bashly generate..."
if command -v bashly &>/dev/null; then
  bashly generate
else
  docker run --rm -v "$PWD:/app" dannyben/bashly generate
fi

echo "Adding POSIX bootstrap..."
# Prepend POSIX-compatible bootstrap that re-execs with modern bash if needed
BOOTSTRAP='#!/bin/sh
# POSIX bootstrap: re-exec with modern bash if needed
_need_modern_bash() {
  [ -z "$BASH_VERSION" ] && return 0
  _major=$(echo "$BASH_VERSION" | cut -d. -f1)
  [ "$_major" -lt 4 ] && return 0
  return 1
}
if _need_modern_bash; then
  for _b in /opt/homebrew/bin/bash /usr/local/bin/bash; do
    if [ -x "$_b" ]; then
      printf "Detected bash %s, using modern bash at %s...\\n" "$BASH_VERSION" "$_b"
      _tmp=$(mktemp)
      trap "rm -f \"$_tmp\"" EXIT
      curl -fsSL "https://raw.githubusercontent.com/AbdelrahmanHafez/better-claude-code/main/install.sh" -o "$_tmp"
      exec "$_b" "$_tmp" "$@"
    fi
  done
  printf "bash 4.4+ required. Install with: brew install bash\\n" >&2
  exit 1
fi
# === End bootstrap ===

'

# Remove bashly's shebang and prepend bootstrap
tail -n +2 install.sh > install.sh.tmp
echo "$BOOTSTRAP" | cat - install.sh.tmp > install.sh
rm install.sh.tmp

echo "Build complete: install.sh"
