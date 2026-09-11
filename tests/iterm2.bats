#!/usr/bin/env bats
#
# The iTerm2 script: which keys it sets so iTerm2 loads and saves its
# preferences in the repo folder, and when it leaves them alone.
#
# Nothing here touches this Mac's preferences: `defaults` is a stub over a
# directory of key files, and the Applications folder is a temporary directory
# the tests fill in themselves.

setup() {
  load helpers
  export HOME="$BATS_TEST_TMPDIR/home"
  # XDG_CONFIG_HOME is set on this Mac and wins over HOME, so isolate it too:
  # a test must never write into the real home directory.
  export XDG_CONFIG_HOME="$HOME/.config"
  export XDG_CACHE_HOME="$HOME/.cache"
  export XDG_DATA_HOME="$HOME/.local/share"
  export XDG_STATE_HOME="$HOME/.local/state"
  mkdir -p "$HOME"

  export DOTFILES_STATE="$BATS_TEST_TMPDIR/state"
  export DOTFILES_APPLICATIONS="$BATS_TEST_TMPDIR/Applications"
  export DEFAULTS_STORE="$BATS_TEST_TMPDIR/defaults"
  export DEFAULTS_LOG="$BATS_TEST_TMPDIR/defaults.log"
  mkdir -p "$DOTFILES_APPLICATIONS" "$DEFAULTS_STORE" "$BATS_TEST_TMPDIR/bin"
  : >"$DEFAULTS_LOG"

  ITERM2="$REPO_ROOT/.chezmoiscripts/run_after_63-iterm2.sh.tmpl"
  PREFS="$REPO_ROOT/.iterm2"
  stub_defaults
}

# A `defaults` that reads and writes a directory of files and logs every write,
# so a test can set the starting state and assert what the script wrote.
stub_defaults() {
  cat >"$BATS_TEST_TMPDIR/bin/defaults" <<'EOF'
#!/bin/sh
key="$DEFAULTS_STORE/$2.$3"
case "$1" in
read)
  [ -f "$key" ] || {
    echo "The domain/default pair of ($2, $3) does not exist" >&2
    exit 1
  }
  cat "$key"
  ;;
write)
  printf '%s %s %s %s\n' "$2" "$3" "$4" "$5" >>"$DEFAULTS_LOG"
  value="$5"
  if [ "$4" = -bool ]; then
    case "$5" in
    true | yes | 1) value=1 ;;
    *) value=0 ;;
    esac
  fi
  printf '%s\n' "$value" >"$key"
  ;;
*)
  echo "unexpected: defaults $*" >&2
  exit 64
  ;;
esac
EOF
  chmod +x "$BATS_TEST_TMPDIR/bin/defaults"
  export PATH="$BATS_TEST_TMPDIR/bin:$PATH"
}

# preset <key> <value as `defaults read` prints it>
preset() {
  printf '%s\n' "$2" >"$DEFAULTS_STORE/com.googlecode.iterm2.$1"
}

installed() {
  mkdir -p "$DOTFILES_APPLICATIONS/iTerm.app"
}

# iterm2 [managed] -> runs the rendered script
iterm2() {
  chezmoi_config "${1:-false}" false false
  local script="$BATS_TEST_TMPDIR/iterm2.sh"
  render --file "$ITERM2" >"$script"
  : >"$DEFAULTS_LOG"
  run sh "$script"
}

wrote() {
  grep -qxF "com.googlecode.iterm2 $1" "$DEFAULTS_LOG"
}

wrote_nothing() {
  [ ! -s "$DEFAULTS_LOG" ]
}

# --- the folder in the repo ------------------------------------------------

@test "the preferences folder is in the source directory and holds the colours" {
  [ -d "$PREFS" ]
  [ -f "$PREFS/ayu dark.itermcolors" ]
  [ ! -e "$REPO_ROOT/ayu dark.itermcolors" ]
}

@test "the moved colour file needs no ignore rule any more" {
  run grep -c 'itermcolors' "$REPO_ROOT/.chezmoiignore"
  [ "$output" = 0 ]
}

# --- the script ------------------------------------------------------------

@test "it skips, without writing preferences, when iTerm2 is not installed" {
  iterm2
  [ "$status" -eq 0 ]
  wrote_nothing
  [[ "$output" == *"not installed"* ]]
}

@test "it skips on a managed machine too, until iTerm2 arrives" {
  iterm2 true
  [ "$status" -eq 0 ]
  wrote_nothing
}

@test "it points iTerm2 at the folder in the repo" {
  installed
  iterm2
  [ "$status" -eq 0 ]
  wrote "PrefsCustomFolder -string $PREFS"
  wrote 'LoadPrefsFromCustomFolder -bool true'
  [[ "$output" == *"$PREFS"* ]]
}

@test "it sets both keys that make iTerm2 save changes without asking" {
  installed
  iterm2
  wrote 'NoSyncNeverRemindPrefsChangesLostForFile -bool true'
  wrote 'NoSyncNeverRemindPrefsChangesLostForFile_selection -int 2'
}

@test "it sets the reminder flag even when the selection is already 2" {
  installed
  preset NoSyncNeverRemindPrefsChangesLostForFile_selection 2
  iterm2
  wrote 'NoSyncNeverRemindPrefsChangesLostForFile -bool true'
  ! wrote 'NoSyncNeverRemindPrefsChangesLostForFile_selection -int 2'
}

@test "it is a no-op when the keys already point at the folder" {
  installed
  iterm2
  [ "$status" -eq 0 ]
  iterm2
  [ "$status" -eq 0 ]
  wrote_nothing
  [[ "$output" == *"already"* ]]
}

@test "it repoints iTerm2 when the folder is somewhere else" {
  installed
  preset PrefsCustomFolder "$HOME/elsewhere"
  preset LoadPrefsFromCustomFolder 1
  preset NoSyncNeverRemindPrefsChangesLostForFile 1
  preset NoSyncNeverRemindPrefsChangesLostForFile_selection 2
  iterm2
  [ "$status" -eq 0 ]
  wrote "PrefsCustomFolder -string $PREFS"
  ! wrote 'LoadPrefsFromCustomFolder -bool true'
}

@test "it turns loading back on when it was switched off" {
  installed
  preset PrefsCustomFolder "$PREFS"
  preset LoadPrefsFromCustomFolder 0
  iterm2
  wrote 'LoadPrefsFromCustomFolder -bool true'
  ! wrote "PrefsCustomFolder -string $PREFS"
}
