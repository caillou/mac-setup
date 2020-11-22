# Mac Setup

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"
brew install \
  fish \
  git \
  the_silver_searcher \
  thefuck \
  ruby \
  wget
sudo bash -c 'echo /usr/local/bin/fish >> /etc/shells'
chsh -s /usr/local/bin/fish
```

Now close the terminal.

```bash
brew cask install \
  iterm2 \
  docker \
  google-chrome \
  alfred \
  istat-menus \
  hammerspoon \
  visual-studio-code \
  nextcloud \
  whatsapp \
  telegram \
  signal \
  spotify \
  microsoft-teams \
  spotify

cd ~/Downloads && wget https://raw.githubusercontent.com/caillou/mac-setup/main/ayu%20dark.itermcolors && open "ayu Dark.itermcolors"
```
