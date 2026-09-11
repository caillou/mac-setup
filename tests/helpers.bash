# Shared bats helpers.

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export REPO_ROOT

# Git's own environment, dropped.
#
# A commit exports GIT_DIR, GIT_INDEX_FILE and friends into every hook, and
# they outrank any path an argument names: under `lefthook run pre-commit`,
# `git init "$BATS_TEST_TMPDIR/repo"` re-initialises the *real* repository
# instead, and with no work tree in sight it marks that repository bare. Every
# later `git -C "$fixture" ...` then reads the real checkout too, which is why
# `remote add origin` answered "remote origin already exists".
#
# Sourced from each file's setup(), so this runs before every test: a test
# talks to the repository it just created, never to the one it runs inside.
unset GIT_DIR GIT_WORK_TREE GIT_INDEX_FILE GIT_PREFIX \
  GIT_OBJECT_DIRECTORY GIT_COMMON_DIR

# chezmoi_config <managed> <personal> <embedded>
#
# Writes a throwaway chezmoi config carrying the machine facts, so templates
# can be rendered for any machine without touching the real config.
chezmoi_config() {
  CHEZMOI_CONFIG="$BATS_TEST_TMPDIR/chezmoi.toml"
  cat >"$CHEZMOI_CONFIG" <<EOF
sourceDir = "$REPO_ROOT"

[data]
managed = ${1:-false}
personal = ${2:-false}
embedded = ${3:-false}
EOF
  export CHEZMOI_CONFIG
}

# render <template>...  -> the rendered text on stdout
render() {
  [ -n "${CHEZMOI_CONFIG:-}" ] || chezmoi_config false false false
  chezmoi --config "$CHEZMOI_CONFIG" --source "$REPO_ROOT" execute-template "$@"
}

# render_facts [managed] -> path of the rendered facts preamble
render_facts() {
  chezmoi_config "${1:-false}"
  local facts="$BATS_TEST_TMPDIR/facts.sh"
  render '{{ template "facts.sh" . }}' >"$facts"
  printf '%s' "$facts"
}

# facts_probe <facts-file> <shell code> -> runs the code with the preamble loaded
facts_probe() {
  local facts="$1" code="$2" probe="$BATS_TEST_TMPDIR/probe.sh"
  {
    printf '#!/bin/sh\n'
    printf '. "%s"\n' "$facts"
    printf '%s\n' "$code"
  } >"$probe"
  run sh "$probe"
}
