# iTerm2 preferences

iTerm2 loads and saves its preferences here instead of
`~/Library/Preferences/com.googlecode.iterm2.plist`. `run_after_63-iterm2.sh.tmpl`
points it at this folder on every apply: `PrefsCustomFolder`,
`LoadPrefsFromCustomFolder`, and the two
`NoSyncNeverRemindPrefsChangesLostForFile` keys that turn "save changes" into
"save automatically".

- `com.googlecode.iterm2.plist` is the whole configuration: profile, font and
  colours. It is exported into this folder once, when this Mac is migrated.
- iTerm2 rewrites it on quit, so a setting changed in the UI turns into repo
  drift: after quitting iTerm2, `git status` shows the file and the change is
  committed like any other edit.
- The four keys above are excluded from what iTerm2 exports, so no machine
  path or username ends up in the committed plist.
- `ayu dark.itermcolors` is the old colour-scheme export, kept as a reference.
  The colours in use live in the profile inside the plist.

This folder is dot-prefixed, so chezmoi never treats it as a target to write
into the home directory.
