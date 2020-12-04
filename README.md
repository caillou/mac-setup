# Mac Setup

## Todo

- Use https://github.com/Homebrew/homebrew-bundle
- Dotfiles

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"
xcode-select --install
brew install \
  fish \
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
  telegram \
  visual-studio-code \
  vlc \
  whatsapp

cd ~/Downloads && wget https://raw.githubusercontent.com/caillou/mac-setup/main/ayu%20dark.itermcolors && open "ayu Dark.itermcolors"

git config --global user.email "pierre.spring@caillou.ch"
git config --global user.name "Pierre Spring"

sudo mas install 668208984 # GIPHY CAPTURE
```
