# Shared script preamble: environment plus pure predicates and marker helpers.
#
# Every `after` script inlines this file with a chezmoi template include right
# after its shebang. Scripts are separate `sh` processes, so nothing set here
# survives into the next script; inlining is the only mechanism.
#
# The Homebrew installer script does NOT include this file: chezmoi keys
# run-once scripts by rendered content, so editing this file would re-run it.

# Every script inlines the whole preamble and uses the part it needs, so the
# unused helpers are not a smell.
# shellcheck disable=SC2329
set -eu

# Scripts run in a plain `sh` without any of the user's shell config.
if [ -x /opt/homebrew/bin/brew ]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi
if [ -d "$HOME/.asdf/shims" ]; then
  PATH="$HOME/.asdf/shims:$PATH"
  export PATH
fi

# Where markers and hashes live. Overridable so tests can point it at a
# temporary directory.
STATE="${DOTFILES_STATE:-$HOME/.local/state/dotfiles}"
mkdir -p "$STATE"

# Where app bundles live. Overridable for the same reason.
APPLICATIONS="${DOTFILES_APPLICATIONS:-/Applications}"

# Is this machine managed by an employer? Answered once at `chezmoi init`
# (detected from `profiles status -type enrollment`) and editable in chezmoi's
# config afterwards, so no script ever re-detects it.
MANAGED={{ if .managed }}1{{ else }}0{{ end }}

is_managed() {
  [ "$MANAGED" = 1 ]
}

# app_present "Visual Studio Code.app"
app_present() {
  [ -d "$APPLICATIONS/$1" ]
}

# has_command brew
has_command() {
  command -v "$1" >/dev/null 2>&1
}

# default_is com.apple.dock tilesize 16
default_is() {
  [ "$(defaults read "$1" "$2" 2>/dev/null)" = "$3" ]
}

# mark ssh-key-generated [value]
mark() {
  if [ "$#" -gt 1 ]; then
    printf '%s\n' "$2" >"$STATE/$1"
  else
    : >"$STATE/$1"
  fi
}

# marked ssh-key-generated
marked() {
  [ -f "$STATE/$1" ]
}

# marker_value packages-status  -> the stored value, empty when unmarked
marker_value() {
  if [ -f "$STATE/$1" ]; then
    head -n 1 "$STATE/$1"
  fi
}

# hash_unchanged packages <hash>
hash_unchanged() {
  [ -f "$STATE/$1.hash" ] && [ "$(cat "$STATE/$1.hash")" = "$2" ]
}

# store_hash packages <hash>
store_hash() {
  printf '%s\n' "$2" >"$STATE/$1.hash"
}
