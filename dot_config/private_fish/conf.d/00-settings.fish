# The settings that used to live in fish's universal variables.
#
# ~/.config/fish/fish_variables is machine state that fish rewrites at will,
# so it is never managed. Everything worth keeping from it lives here instead,
# and conf.d snippets are read before config.fish, so this runs first.
#
# Pure's options are deliberately absent. All 73 `pure_*` universal variables
# on this Mac hold exactly the value Pure sets itself in the
# `_pure_set_default` calls of its own conf.d/pure.fish, so the set that
# differs from Pure's defaults is empty and there is nothing to carry over.

set -gx XDG_CONFIG_HOME $HOME/.config

# Emoji occupy two columns in iTerm2 and every other terminal in use here;
# fish's default of 1 leaves the prompt smeared after an emoji.
set -g fish_emoji_width 2
