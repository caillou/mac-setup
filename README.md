# Mac Setup

## Todo

- Use https://github.com/Homebrew/homebrew-bundle
- Dotfiles

```bash
xcode-select --install
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"
brew install \
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

## ZSH Setup

For my ZSH setup, check the following link: https://gist.github.com/caillou/adf85eca6318b2d189d7e7af39b332ed#file-zsh-macos-md

## pyenv

1. Install `pyenv`: `brew install pyenv`
2. Config shell for `pyenv`: c.f. Step 2 of https://github.com/pyenv/pyenv#basic-github-checkout
3. `pyenv install 3.10.2`
4. `pyenv global 3.10.2`
5. `npm install`
