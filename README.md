# Mac Setup

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"
brew install \
  fish \
  git \
  the_silver_searcher \
  thefuck \
  ruby \
  wget \
  youtube-dl \
  libdvdcss
sudo bash -c 'echo /usr/local/bin/fish >> /etc/shells'
chsh -s /usr/local/bin/fish
```

Now close the terminal.

```bash
brew cask install \
  alfred \
  docker \
  google-chrome \
  hammerspoon \
  handbrake \
  istat-menus \
  iterm2 \
  microsoft-teams \
  nextcloud \
  signal \
  spotify \
  spotify \
  telegram \
  unrar \
  visual-studio-code \
  vlc \
  whatsapp

cd ~/Downloads && wget https://raw.githubusercontent.com/caillou/mac-setup/main/ayu%20dark.itermcolors && open "ayu Dark.itermcolors"
```
