# fish's own configuration. Read after every conf.d snippet.
#
# Plain file, never a chezmoi template, and every path is home-relative, so
# `chezmoi re-add ~/.config/fish/config.fish` round-trips edits made here.
# The non-interactive half of this file is mirrored in ~/.zprofile, which is
# what Claude Code's tool shell reads.

eval $(/opt/homebrew/bin/brew shellenv)

set -x LC_ALL en_US.UTF-8
set -x LC_CTYPE en_US.UTF-8
set -x LANG en_US.UTF-8

# Pass ANSI colours through. more(1) is less in compat mode and reads MORE
# instead of LESS: https://ryangreenberg.com/til/less-env-var/
set -x LESS -R
set -x MORE -R

set PATH ./node_modules/.bin $PATH

if test -d ~/.docker/bin
    set PATH $PATH ~/.docker/bin
end

if test -d (brew --prefix)/share/fish/completions
    set -gx fish_complete_path $fish_complete_path (brew --prefix)/share/fish/completions
end

if test -d (brew --prefix)/share/fish/vendor_completions.d
    set -gx fish_complete_path $fish_complete_path (brew --prefix)/share/fish/vendor_completions.d
end

# Added by Docker Desktop; absent on a Mac that has never run it.
if test -f ~/.docker/init-fish.sh
    source ~/.docker/init-fish.sh
end

abbr -a -- a atom
abbr -a -- ag 'rg -S'
abbr -a -- c cal -3
abbr -a -- d date
abbr -a -- e code
abbr -a -- g lazygit
abbr -a -- gb 'git branch --sort=-committerdate'
abbr -a -- gc 'git checkout'
abbr -a -- gd 'git diff --color-words'
abbr -a -- ggl 'git pull'
abbr -a -- ggp 'git push'
abbr -a -- glog 'git log --pretty=\'format:%C(auto)%h %s %Cgreen@%al %Cred@%ar\' --graph'
abbr -a -- gr 'git reset HEAD -- .'
abbr -a -- gs 'git status'
abbr -a -- j z
abbr -a -- more less
abbr -a -- t tmux
abbr -a -- unifi 'java -jar /Applications/UniFi.app/Contents/Resources/lib/ace.jar ui'
abbr -a -- w wt switch
abbr -a -- wr wt remove
abbr -a -- watt 'system_profiler SPPowerDataType'

# asdf 0.16 and later (the Go rewrite Homebrew ships) has no script to source:
# the shims directory on PATH is the whole shell integration. It has to come
# after the PATH edits above so the shims win.
if not contains ~/.asdf/shims $PATH
    set -gx --prepend PATH ~/.asdf/shims
end

# Where uv and other user-level installers put their binaries.
set PATH $PATH ~/.local/bin
