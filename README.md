# Mac Setup

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"
brew install \
  fish \
  git \
  thefuck
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
```
