# Mac Setup

## Todo

- Use https://github.com/Homebrew/homebrew-bundle
- Dotfiles

```bash
xcode-select --install
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"
brew install \
  asdf \
  ffmpeg \
  fish \
  fzf \
  git \
  glib \
  graphicsmagick \
  htop \
  imagemagick \
  jesseduffield/lazygit/lazygit \
  libdvdcss \
  mas \
  maven \
  postgresql \
  rar \
  rename \
  ruby \
  sshuttle \
  tig \
  the_silver_searcher \
  thefuck \
  tree \
  wget \
  youtube-dl
sudo bash -c 'echo /usr/local/bin/fish >> /etc/shells'
chsh -s /usr/local/bin/fish
```

Now close the terminal.

```bash
brew tap homebrew/cask-fonts
brew tap homebrew/cask-versions
brew install --cask \
  alfred \
  boop \
  discord \
  docker \
  font-ibm-plex \
  google-chrome \
  google-chrome-canary \
  hammerspoon \
  handbrake \
  istat-menus \
  iterm2 \
  microsoft-edge \
  microsoft-teams \
  mongodb-compass \
  nextcloud \
  signal \
  spotify \
  steam \
  telegram \
  the-unarchiver \
  threema \
  visual-studio-code \
  vlc

cd ~/Downloads && wget https://raw.githubusercontent.com/caillou/mac-setup/main/ayu%20dark.itermcolors && open "ayu Dark.itermcolors"

git config --global user.email "pierre.spring@caillou.ch"
git config --global user.name "Pierre Spring"

sudo mas install 668208984 # GIPHY CAPTURE
sudo mas install 425264550 # Blackmagic Disk Speed Test
```

## Manual checklist

Some of macOS cannot be set from a script. The last step of every `chezmoi
apply` (`.chezmoiscripts/run_after_90-report.sh.tmpl`) prints the items that
apply to the machine in front of you; the full list is here.

Every apply:

- **Privacy & Security approvals for Karabiner-Elements**, when it is
  installed: Input Monitoring for Karabiner-Elements, `karabiner_grabber` and
  `karabiner_observer`, Accessibility for Karabiner-Elements, and the driver
  extension under General > Login Items & Extensions. Whether an approval was
  already given is in the TCC database, which no script may read, so this is
  listed as long as the app is installed.
- **Privacy & Security approvals for Hammerspoon**, when it is installed:
  Accessibility, plus Input Monitoring when a hotkey does not fire.
- **Launch Karabiner-Elements once**, while
  `~/.config/karabiner/karabiner.json` is missing. Karabiner creates the file
  and its Default profile on first launch; the next apply builds the rules
  into it.
- **Turn dictation on once**: press Control twice, accept the consent dialog,
  then let the language models for en_US, fr_CH and de_CH download in System
  Settings > Keyboard > Dictation.

Until the script that writes them records success in
`~/.local/state/dotfiles/`:

- **Check the tracking speed** in System Settings > Trackpad and > Mouse. The
  defaults script writes it and reads it back through `hidutil`; the item
  disappears once the read-back agreed (`pointer-speed-applied`).
- **Turn "Automatically adjust brightness" off** in System Settings > Displays,
  on every display. The display script does this through root's CoreBrightness
  preferences and reads it back (`auto-brightness-applied`).

Once, on a Mac that generated its own ssh key (`ssh-key-generated`):

- **Paste the public key into Azure DevOps** under User settings > SSH public
  keys > New key. Azure DevOps has no API for keys, so this is the one upload
  that stays manual; GitHub gets the same key from `gh ssh-key add`. The report
  prints the key. Once it is pasted, stop the reminder with
  `rm ~/.local/state/dotfiles/ssh-key-generated`.

On an unmanaged Mac, when the last `brew bundle` exited non-zero
(`packages-status`):

- **Finish the package install.** The report names what is still missing, then
  `chezmoi apply` again. The usual cause is a signed-out App Store: open the
  App Store, sign in, and re-run.

On a managed Mac:

- **Request the missing apps from the Self Service Portal.** Casks and App
  Store apps are never installed there, so the report lists the entries of
  `.chezmoidata/apps.yaml` in the enabled groups whose app is not in
  `/Applications` right now. Rows that install no app bundle (ngrok is a
  binary) are not listed.

The apply asks for the admin password more than once by design: the `sudo`
ticket expires during the long steps, and the display module reads preferences
that belong to root.

## ZSH Setup

For my ZSH setup, check the following link: https://gist.github.com/caillou/adf85eca6318b2d189d7e7af39b332ed#file-zsh-macos-md

## asdf

`asdf` manages tool versions (Python, Node.js, …). It is installed via Homebrew above.

### Fish integration

Add the shims to your `PATH` in `~/.config/fish/config.fish`:

```fish
set --prepend PATH "$HOME/.asdf/shims"
```

Optionally install the completions:

```fish
asdf completion fish > ~/.config/fish/completions/asdf.fish
```

### Legacy version files

To make `asdf` pick up tool-native version files like `.nvmrc` and `.python-version`, create `~/.asdfrc` with:

```
legacy_version_file = yes
```

### Install tools

```bash
asdf plugin add python
asdf install python 3.12.13
asdf set -u python 3.12.13

asdf plugin add nodejs
asdf install nodejs latest
asdf set -u nodejs latest
```

`asdf set -u` writes the version to `~/.tool-versions`, making it the global default. (It replaces `asdf global`, which was removed in asdf 0.16.)
