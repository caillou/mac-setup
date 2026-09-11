#!/usr/bin/env bats
#
# Homebrew installer and packages: what the Brewfile says for a given machine,
# which casks and App Store apps the script appends to it, and how it records
# the outcome of `brew bundle`.
#
# Nothing here installs anything: `brew` is a stub, and the Applications folder
# and the Caskroom are temporary directories the tests fill in themselves.

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
  export DOTFILES_CASKROOM="$BATS_TEST_TMPDIR/Caskroom"
  export DOTFILES_BREW="$BATS_TEST_TMPDIR/bin/brew"
  mkdir -p "$DOTFILES_APPLICATIONS" "$DOTFILES_CASKROOM" "$BATS_TEST_TMPDIR/bin"

  BREWLOG="$BATS_TEST_TMPDIR/brew.log"
  BREWFILE="$DOTFILES_STATE/Brewfile"
  PACKAGES="$REPO_ROOT/.chezmoiscripts/run_after_10-packages.sh.tmpl"
  HOMEBREW="$REPO_ROOT/.chezmoiscripts/run_once_before_00-homebrew.sh.tmpl"
}

# stub_brew [exit code] -> a brew that logs its arguments and installs nothing
stub_brew() {
  cat >"$DOTFILES_BREW" <<EOF
#!/bin/sh
echo "\$*" >>"$BREWLOG"
exit ${1:-0}
EOF
  chmod +x "$DOTFILES_BREW"
}

# packages <managed> <personal> <embedded>  -> runs the rendered script
packages() {
  chezmoi_config "${1:-false}" "${2:-false}" "${3:-false}"
  local script="$BATS_TEST_TMPDIR/packages.sh"
  render --file "$PACKAGES" >"$script"
  run sh "$script"
}

# installed <app bundle> [cask]  -> an app in Applications, optionally Homebrew's
installed() {
  mkdir -p "$DOTFILES_APPLICATIONS/$1"
  [ "$#" -lt 2 ] || mkdir -p "$DOTFILES_CASKROOM/$2"
}

brewfile_has() {
  grep -qxF "$1" "$BREWFILE"
}

refute_brewfile_has() {
  ! grep -qxF "$1" "$BREWFILE"
}

# --- the Brewfile template -------------------------------------------------

@test "every machine gets the core formulae, the taps and the fonts" {
  stub_brew
  for managed in true false; do
    packages "$managed"
    [ "$status" -eq 0 ]
    brewfile_has 'tap "jesseduffield/lazygit"'
    brewfile_has 'brew "chezmoi"'
    brewfile_has 'brew "fish"'
    brewfile_has 'brew "mas"'
    brewfile_has 'brew "jesseduffield/lazygit/lazygit"'
    brewfile_has 'brew "mactop"'
    brewfile_has 'cask "font-ibm-plex-mono"'
    brewfile_has 'cask "font-ibm-plex-sans"'
    brewfile_has 'cask "font-anonymice-nerd-font"'
  done
}

@test "a managed machine gets formulae and fonts only" {
  stub_brew
  packages true true true
  [ "$status" -eq 0 ]
  run grep -c '^mas ' "$BREWFILE"
  [ "$output" = 0 ]
  run grep '^cask ' "$BREWFILE"
  [ "$output" = 'cask "font-ibm-plex-mono"
cask "font-ibm-plex-sans"
cask "font-anonymice-nerd-font"' ]
}

@test "the personal group appears only when its flag is set" {
  stub_brew
  packages false false false
  refute_brewfile_has 'tap "gbevin/tools"'
  refute_brewfile_has 'brew "gbevin/tools/sendmidi"'
  refute_brewfile_has 'brew "figlet"'
  refute_brewfile_has 'cask "spotify"'
  refute_brewfile_has 'mas "WhatsApp", id: 310633997'

  packages false true false
  brewfile_has 'tap "gbevin/tools"'
  brewfile_has 'brew "gbevin/tools/sendmidi"'
  brewfile_has 'brew "figlet"'
  brewfile_has 'cask "spotify"'
  brewfile_has 'mas "WhatsApp", id: 310633997'
}

@test "the embedded group appears only when its flag is set" {
  stub_brew
  packages false false false
  refute_brewfile_has 'brew "platformio"'
  refute_brewfile_has 'cask "gcc-arm-embedded"'

  packages false false true
  brewfile_has 'brew "platformio"'
  brewfile_has 'brew "open-ocd"'
  brewfile_has 'brew "dfu-util"'
  brewfile_has 'cask "gcc-arm-embedded"'
}

# --- the cask filter -------------------------------------------------------

@test "a cask whose app is missing is installed" {
  stub_brew
  packages false
  brewfile_has 'cask "google-chrome"'
}

@test "an app installed by hand is left alone" {
  stub_brew
  installed "Google Chrome.app"
  packages false
  [ "$status" -eq 0 ]
  refute_brewfile_has 'cask "google-chrome"'
  [[ "$output" == *"leaving Google Chrome.app alone"* ]]
}

@test "an app Homebrew installed stays in the Brewfile" {
  stub_brew
  installed "Google Chrome.app" google-chrome
  packages false
  brewfile_has 'cask "google-chrome"'
}

@test "a cask that installs no app bundle is always listed" {
  stub_brew
  packages false
  brewfile_has 'cask "ngrok"'
}

@test "the App Store rows are not filtered by presence" {
  stub_brew
  installed "Amphetamine.app"
  packages false
  brewfile_has 'mas "Amphetamine", id: 937984704'
}

# --- running brew bundle ---------------------------------------------------

@test "brew bundle runs against the generated Brewfile" {
  stub_brew
  packages false
  [ "$status" -eq 0 ]
  [ "$(cat "$BREWLOG")" = "bundle --file $BREWFILE" ]
}

@test "a failing brew bundle lands in the marker and the apply continues" {
  stub_brew 17
  packages false
  [ "$status" -eq 0 ]
  [ "$(cat "$DOTFILES_STATE/packages-status")" = 17 ]
  [ -f "$DOTFILES_STATE/packages.hash" ]
}

@test "an unchanged Brewfile after a successful run does not run brew bundle" {
  stub_brew
  packages false
  packages false
  [ "$status" -eq 0 ]
  [ "$(wc -l <"$BREWLOG")" -eq 1 ]
  [[ "$output" == *"nothing changed"* ]]
}

@test "an unchanged Brewfile after a failed run runs brew bundle again" {
  stub_brew 17
  packages false
  stub_brew
  packages false
  [ "$(wc -l <"$BREWLOG")" -eq 2 ]
  [ "$(cat "$DOTFILES_STATE/packages-status")" = 0 ]
}

@test "a changed Brewfile runs brew bundle again" {
  stub_brew
  packages false
  packages false true
  [ "$(wc -l <"$BREWLOG")" -eq 2 ]
}

@test "without Homebrew the script writes the Brewfile and stops" {
  export DOTFILES_BREW="$BATS_TEST_TMPDIR/bin/absent-brew"
  packages false
  [ "$status" -eq 0 ]
  [[ "$output" == *"Homebrew is not installed"* ]]
  [ -f "$BREWFILE" ]
  [ ! -f "$DOTFILES_STATE/packages.hash" ]
}

# --- the app table ---------------------------------------------------------

# rows <expression> -> one line per row of .chezmoidata/apps.yaml
rows() {
  chezmoi_config false true true
  render "{{ range .apps }}$1{{ \"\n\" }}{{ end }}"
}

@test "every row of the table is a cask or an App Store app in a known group" {
  run rows '{{ .kind }} {{ .group }}'
  [ "$status" -eq 0 ]
  while read -r kind group; do
    case "$kind" in cask | mas) ;; *) return 1 ;; esac
    case "$group" in core | personal | embedded) ;; *) return 1 ;; esac
  done <<<"$output"
}

@test "the table holds the reviewed classification" {
  # Counts from research-notes.md section 9: 17 core casks and 11 core App
  # Store apps, 14 personal casks and 12 personal App Store apps, one embedded
  # cask. A package moving group has to be a deliberate edit here.
  run rows '{{ .kind }}-{{ .group }}'
  [ "$(grep -c '^cask-core$' <<<"$output")" -eq 17 ]
  [ "$(grep -c '^mas-core$' <<<"$output")" -eq 11 ]
  [ "$(grep -c '^cask-personal$' <<<"$output")" -eq 14 ]
  [ "$(grep -c '^mas-personal$' <<<"$output")" -eq 12 ]
  [ "$(grep -c '^cask-embedded$' <<<"$output")" -eq 1 ]
  [ "$(grep -c '^mas-embedded$' <<<"$output")" -eq 0 ]
}

@test "the table names every package once and every App Store id is numeric" {
  run rows '{{ .name }}'
  [ "$(sort <<<"$output" | uniq -d)" = '' ]

  run rows '{{ .kind }} {{ .name }}'
  while read -r kind name; do
    case "$kind" in
    mas) case "$name" in *[!0-9]* | '') return 1 ;; esac ;;
    esac
  done <<<"$output"
}

# --- the Homebrew installer ------------------------------------------------

@test "the installer asks for sudo once and runs the official script" {
  run render --file "$HOMEBREW"
  [ "$status" -eq 0 ]
  [[ "$output" == *'sudo -v'* ]]
  [[ "$output" == *'NONINTERACTIVE=1'* ]]
  [[ "$output" == *'https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh'* ]]
}

@test "the installer does nothing when Homebrew is already there" {
  # sudo and curl are stubbed as well, so a broken guard cannot install
  # anything on the machine running the tests.
  local bin="$BATS_TEST_TMPDIR/installer-bin"
  mkdir -p "$bin"
  for command in brew sudo curl; do
    printf '#!/bin/sh\necho "%s $*" >>"%s"\n' "$command" "$BATS_TEST_TMPDIR/installer.log" >"$bin/$command"
    chmod +x "$bin/$command"
  done

  render --file "$HOMEBREW" >"$BATS_TEST_TMPDIR/homebrew.sh"
  PATH="$bin:$PATH" run sh "$BATS_TEST_TMPDIR/homebrew.sh"
  [ "$status" -eq 0 ]
  [[ "$output" == *'already installed'* ]]
  [ ! -f "$BATS_TEST_TMPDIR/installer.log" ]
}
