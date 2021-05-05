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
  libdvdcss \
  mas \
  postgresql \
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
brew install --cask \
  alfred \
  discord \
  docker \
  font-ibm-plex \
  godot \
  google-chrome \
  hammerspoon \
  handbrake \
  istat-menus \
  iterm2 \
  microsoft-edge \
  microsoft-teams \
  nextcloud \
  signal \
  spotify \
  steam \
  telegram \
  visual-studio-code \
  vlc \
  whatsapp

cd ~/Downloads && wget https://raw.githubusercontent.com/caillou/mac-setup/main/ayu%20dark.itermcolors && open "ayu Dark.itermcolors"

git config --global user.email "pierre.spring@caillou.ch"
git config --global user.name "Pierre Spring"

sudo mas install 668208984 # GIPHY CAPTURE
sudo mas install 425264550 # Blackmagic Disk Speed Test
```
