#!/bin/sh
# Fails when anything secret-shaped is in the source directory, so this repo
# can stay public and be cloned anonymously on a fresh Mac.
#
# Usage: tests/secrets-check.sh [directory]
set -eu

root="${1:-$(cd "$(dirname "$0")/.." && pwd)}"

# gh tokens, GitHub fine-grained tokens, Slack tokens, AWS keys, Anthropic
# keys, and any private key header.
tokens='(gh[pousr]_[A-Za-z0-9]{30,})'
tokens="$tokens|(github_pat_[A-Za-z0-9_]{30,})"
tokens="$tokens|(xox[baprs]-[A-Za-z0-9-]{10,})"
tokens="$tokens|(AKIA[0-9A-Z]{16})"
tokens="$tokens|(sk-ant-[A-Za-z0-9_-]{20,})"
tokens="$tokens|(-----BEGIN [A-Z ]*PRIVATE KEY-----)"

files="$(mktemp)"
trap 'rm -f "$files"' EXIT
find "$root" \
  -type d \( -name .git -o -name node_modules \) -prune -o \
  -type f -print >"$files"

found=0
report() {
  printf '%s: %s\n' "$2" "$1" >&2
  found=1
}

while IFS= read -r file; do
  name="${file##*/}"
  case "$name" in
  hosts.yml)
    report "$file" 'gh credentials file'
    continue
    ;;
  *.pub) ;;
  id_*)
    report "$file" 'private key file'
    continue
    ;;
  esac
  if grep -I -l -E "$tokens" "$file" >/dev/null 2>&1; then
    report "$file" 'token-shaped string'
  fi
done <"$files"

if [ "$found" -ne 0 ]; then
  echo "secrets check failed in $root" >&2
  exit 1
fi
echo "secrets check passed: $root"
