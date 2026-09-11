#!/usr/bin/env bats
#
# The source directory as chezmoi sees it: repo-only content must never become
# a file in the home directory.

setup() {
  load helpers
  chezmoi_config false false false
  DEST="$BATS_TEST_TMPDIR/home"
  mkdir -p "$DEST"
}

managed_targets() {
  chezmoi --config "$CHEZMOI_CONFIG" --source "$REPO_ROOT" --destination "$DEST" managed
}

@test "chezmoi manages no repo-only file" {
  run managed_targets
  [ "$status" -eq 0 ]
  # `.chezmoiscripts/...` entries are the scripts chezmoi runs; they are never
  # written into the destination, so they are not repo-only files.
  for target in README.md lefthook.yml docs tests macos "ayu dark.itermcolors" \
    .github .editorconfig .chezmoi.toml.tmpl .chezmoiignore; do
    refute_line "$target"
  done
}

refute_line() {
  while read -r line; do
    if [ "$line" = "$1" ] || [ "${line#"$1"/}" != "$line" ]; then
      echo "chezmoi manages repo-only target: $line" >&2
      return 1
    fi
  done <<<"$output"
}
