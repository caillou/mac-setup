#!/usr/bin/env bats
#
# The Dock allow-list: which tiles the script hands dockutil, in which order,
# what it does with an app that is not installed, and what makes chezmoi rebuild
# the Dock at all.
#
# Nothing here touches the real Dock: `dockutil`, `killall` and `defaults` are
# stubs that only log their arguments, and the two Applications folders are
# temporary directories the tests fill in themselves.

setup() {
  load helpers
  export HOME="$BATS_TEST_TMPDIR/home"
  # XDG_CONFIG_HOME is set on this Mac and wins over HOME, so isolate it too:
  # a test must never write into the real home directory.
  export XDG_CONFIG_HOME="$HOME/.config"
  export XDG_CACHE_HOME="$HOME/.cache"
  export XDG_DATA_HOME="$HOME/.local/share"
  export XDG_STATE_HOME="$HOME/.local/state"
  mkdir -p "$HOME/Downloads"

  export DOTFILES_STATE="$BATS_TEST_TMPDIR/state"
  export DOTFILES_APPLICATIONS="$BATS_TEST_TMPDIR/Applications"
  export DOTFILES_SYSTEM_APPLICATIONS="$BATS_TEST_TMPDIR/System/Applications"
  export DOTFILES_DOCKUTIL="$BATS_TEST_TMPDIR/seam/dockutil"
  mkdir -p "$DOTFILES_APPLICATIONS" "$DOTFILES_SYSTEM_APPLICATIONS" \
    "$BATS_TEST_TMPDIR/seam" "$BATS_TEST_TMPDIR/bin"

  DOCKLOG="$BATS_TEST_TMPDIR/dockutil.log"
  KILLLOG="$BATS_TEST_TMPDIR/killall.log"
  DEFAULTSLOG="$BATS_TEST_TMPDIR/defaults.log"
  DOCK="$REPO_ROOT/.chezmoiscripts/run_onchange_after_61-dock.sh.tmpl"

  # `killall` and `defaults` are found on PATH. Homebrew's shellenv prepends
  # its own directories inside the script, which leaves this one ahead of
  # /usr/bin, where the real commands live.
  stub_on_path killall "$KILLLOG"
  stub_on_path defaults "$DEFAULTSLOG"
  PATH="$BATS_TEST_TMPDIR/bin:$PATH"
  export PATH

  stub_dockutil
}

# stub_on_path <command> <log file>
stub_on_path() {
  cat >"$BATS_TEST_TMPDIR/bin/$1" <<EOF
#!/bin/sh
printf '%s\n' "\$*" >>"$2"
EOF
  chmod +x "$BATS_TEST_TMPDIR/bin/$1"
}

# stub_dockutil [exit code] -> a dockutil that logs its arguments and writes nothing
stub_dockutil() {
  cat >"$DOTFILES_DOCKUTIL" <<EOF
#!/bin/sh
printf '%s\n' "\$*" >>"$DOCKLOG"
exit ${1:-0}
EOF
  chmod +x "$DOTFILES_DOCKUTIL"
}

# system_app "Freeform.app" -> an app bundle on the (stubbed) system volume
system_app() {
  mkdir -p "$DOTFILES_SYSTEM_APPLICATIONS/$1"
}

# user_app "Numbers.app" -> an app bundle in the (stubbed) Applications folder
user_app() {
  mkdir -p "$DOTFILES_APPLICATIONS/$1"
}

# the whole allow-list installed
allow_list_installed() {
  system_app "Freeform.app"
  system_app "iPhone Mirroring.app"
  user_app "Numbers.app"
}

# dock [managed] -> renders the script and runs it
dock() {
  chezmoi_config "${1:-false}"
  local script="$BATS_TEST_TMPDIR/dock.sh"
  render --file "$DOCK" >"$script"
  run sh "$script"
}

dock_calls() {
  cat "$DOCKLOG"
}

# --- the rebuild -----------------------------------------------------------

@test "the Dock is emptied and rebuilt with the allow-list, in order" {
  allow_list_installed
  dock
  [ "$status" -eq 0 ]
  [ "$(dock_calls)" = "--remove all --no-restart
--add $DOTFILES_SYSTEM_APPLICATIONS/Freeform.app --section apps --no-restart
--add $DOTFILES_SYSTEM_APPLICATIONS/iPhone Mirroring.app --section apps --no-restart
--add $DOTFILES_APPLICATIONS/Numbers.app --section apps --no-restart
--add $HOME/Downloads --section others --display stack --view fan --sort dateadded --no-restart" ]
}

@test "the Downloads stack is a stack in fan view sorted by date added" {
  allow_list_installed
  dock
  [ "$status" -eq 0 ]
  run grep -F -- "--add $HOME/Downloads" "$DOCKLOG"
  [ "$output" = "--add $HOME/Downloads --section others --display stack --view fan --sort dateadded --no-restart" ]
}

@test "the allow-list apps go to the apps section and nothing else does" {
  allow_list_installed
  dock
  run grep -c -- '--section apps' "$DOCKLOG"
  [ "$output" = 3 ]
  run grep -c -- '--section others' "$DOCKLOG"
  [ "$output" = 1 ]
}

@test "a managed Mac gets the same Dock" {
  allow_list_installed
  dock true
  [ "$status" -eq 0 ]
  run grep -c -- '--add ' "$DOCKLOG"
  [ "$output" = 4 ]
}

# --- restarting ------------------------------------------------------------

@test "every dockutil call defers the restart and the Dock is restarted once" {
  allow_list_installed
  dock
  [ "$status" -eq 0 ]
  run grep -vc -- '--no-restart' "$DOCKLOG"
  [ "$output" = 0 ]
  [ "$(cat "$KILLLOG")" = 'Dock' ]
}

@test "a Dock that is not running is not a failure" {
  allow_list_installed
  cat >"$BATS_TEST_TMPDIR/bin/killall" <<'EOF'
#!/bin/sh
echo "No matching processes belonging to you were found" >&2
exit 1
EOF
  chmod +x "$BATS_TEST_TMPDIR/bin/killall"
  dock
  [ "$status" -eq 0 ]
  [[ "$output" == *'dock: rebuilt from the allow-list'* ]]
}

# --- apps that are not installed -------------------------------------------

@test "a missing app is skipped with a message, not an error" {
  user_app "Numbers.app"
  dock
  [ "$status" -eq 0 ]
  [[ "$output" == *'dock: Freeform.app is not installed, leaving it out of the Dock'* ]]
  [[ "$output" == *'dock: iPhone Mirroring.app is not installed, leaving it out of the Dock'* ]]
  [ "$(dock_calls)" = "--remove all --no-restart
--add $DOTFILES_APPLICATIONS/Numbers.app --section apps --no-restart
--add $HOME/Downloads --section others --display stack --view fan --sort dateadded --no-restart" ]
}

@test "a Mac where nothing on the list is installed still gets the Downloads stack" {
  dock
  [ "$status" -eq 0 ]
  run grep -c -- '--section apps' "$DOCKLOG"
  [ "$output" = 0 ]
  run grep -c -- '--section others' "$DOCKLOG"
  [ "$output" = 1 ]
  [ "$(cat "$KILLLOG")" = 'Dock' ]
}

@test "a home directory without Downloads is skipped with a message" {
  allow_list_installed
  rmdir "$HOME/Downloads"
  dock
  [ "$status" -eq 0 ]
  [[ "$output" == *'dock: there is no ~/Downloads'* ]]
  run grep -c -- '--section others' "$DOCKLOG"
  [ "$output" = 0 ]
}

# --- dockutil missing ------------------------------------------------------

@test "no dockutil yet means a message and nothing touched" {
  allow_list_installed
  rm "$DOTFILES_DOCKUTIL"
  dock
  [ "$status" -eq 0 ]
  [[ "$output" == *'dock: dockutil is not installed'* ]]
  [ ! -e "$DOCKLOG" ]
  [ ! -e "$KILLLOG" ]
}

@test "a dockutil that fails stops the apply so the next one retries" {
  allow_list_installed
  stub_dockutil 1
  dock
  [ "$status" -ne 0 ]
  [ ! -e "$KILLLOG" ]
}

# --- what the script may and may not do ------------------------------------

@test "the Dock script writes no preferences" {
  allow_list_installed
  dock
  [ "$status" -eq 0 ]
  [ ! -e "$DEFAULTSLOG" ]
  run grep -c 'defaults write\|com.apple.dock' "$DOCK"
  [ "$output" = 0 ]
}

@test "the Dock script leaves no marker or hash behind: chezmoi owns the trigger" {
  allow_list_installed
  dock
  [ "$status" -eq 0 ]
  run ls -A "$DOTFILES_STATE"
  [ -z "$output" ]
}

# --- the allow-list is the only place an app is named ----------------------

@test "the allow-list is data, so adding an app is a one-line change" {
  # No entry is named in the script, not even in a comment: the examples there
  # are deliberately apps that are not on the list.
  run grep -c 'Freeform\|iPhone Mirroring\|Numbers' "$DOCK"
  [ "$output" = 0 ]
  run grep -c '^    - /' "$REPO_ROOT/.chezmoidata/dock.yaml"
  [ "$output" = 3 ]
  run render '{{ .dock.apps | join "\n" }}'
  [ "$output" = '/System/Applications/Freeform.app
/System/Applications/iPhone Mirroring.app
/Applications/Numbers.app' ]
}

# --- the change trigger ----------------------------------------------------

@test "re-running with an unchanged list does not restart the Dock" {
  # chezmoi keys a run_onchange_ script by its rendered content, so an apply
  # whose render is byte-identical does not run the script again at all.
  chezmoi_config false
  render --file "$DOCK" >"$BATS_TEST_TMPDIR/first.sh"
  render --file "$DOCK" >"$BATS_TEST_TMPDIR/second.sh"
  run diff "$BATS_TEST_TMPDIR/first.sh" "$BATS_TEST_TMPDIR/second.sh"
  [ "$status" -eq 0 ]
}

@test "changing the allow-list changes the script, and its hash line" {
  chezmoi_config false
  render --file "$DOCK" >"$BATS_TEST_TMPDIR/before.sh"
  render --override-data '{"dock":{"apps":["/Applications/Numbers.app"]}}' \
    --file "$DOCK" >"$BATS_TEST_TMPDIR/after.sh"
  run diff "$BATS_TEST_TMPDIR/before.sh" "$BATS_TEST_TMPDIR/after.sh"
  [ "$status" -ne 0 ]

  local before after
  before="$(sed -n 's/^# allow-list: //p' "$BATS_TEST_TMPDIR/before.sh")"
  after="$(sed -n 's/^# allow-list: //p' "$BATS_TEST_TMPDIR/after.sh")"
  [ -n "$before" ]
  [ "$before" != "$after" ]
}
