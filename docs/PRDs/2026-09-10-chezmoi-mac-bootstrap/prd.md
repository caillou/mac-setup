# Bootstrap and sync Macs with chezmoi

## Problem Statement

I set up a new, employer-managed Mac and want it to feel like my personal Mac within minutes: same shell, same prompt, same fonts, same keyboard remaps, same Finder, Dock, screenshot, trackpad and Desktop behaviour, same git and GitHub tooling, same language runtimes.

Today none of that is reproducible. This repo is a README of commands to paste by hand plus a defaults script from 2023 that has drifted from what my Mac actually does. My fish config, prompt settings, git config, Hammerspoon and Karabiner setups live only on one machine. The two Macs have different usernames, so even copying files would break every hardcoded path. The new Mac is enrolled in MDM, so desktop apps come from the employer and must not be installed or adopted by Homebrew there. And some macOS settings are not scriptable at all, but nobody tells me which ones I still have to click.

Every new machine, and every "why is this different here", costs an afternoon.

## Solution

One public git repo, `caillou/dotfiles`, managed by chezmoi, that turns a fresh Mac into my Mac with one command, and re-syncs any Mac with one command.

The first command installs chezmoi, clones the repo, installs Homebrew (which brings the Command Line Tools), and applies everything: packages, shell, git, asdf, Hammerspoon and Karabiner configs, macOS defaults, Dock, wallpaper, iTerm2. It asks once whether the machine is personal and which optional package groups it should get, detects on its own whether the machine is managed, and remembers the answers. On a managed Mac it installs only command-line tools and fonts, and prints which desktop apps are missing so I can request them from the employer's portal.

At the end it prints the short list of things macOS refuses to let a script do, so I click through those once and I'm done. Re-syncing later is `chezmoi update`.

## User Stories

1. As a Mac owner, I want to bootstrap a fresh Mac with a single command, so that I never paste a README by hand again.
2. As a Mac owner, I want to re-sync an existing Mac with a single command, so that a change made on one machine reaches the other without thinking.
3. As a Mac owner, I want to see a diff of what a sync would change before it changes anything, so that a mistake in the repo cannot surprise me.
4. As a user with different usernames on different Macs, I want every path in my config derived from the actual home directory, so that the same files work on both machines.
5. As an employee with a managed Mac, I want the setup to detect MDM enrollment on its own, so that I don't have to remember which mode to run.
6. As an employee with a managed Mac, I want to override the detected mode explicitly, so that detection getting it wrong doesn't block me.
7. As an employee with a managed Mac, I want no desktop apps or App Store apps installed by Homebrew there, so that Homebrew never fights the employer's software distribution.
8. As an employee with a managed Mac, I want a printed list of the allow-listed apps that are missing, so that I can request them from the Self Service Portal.
9. As a Mac owner, I want a cask skipped when its app already exists in Applications, so that the bootstrap never aborts on a pre-installed app and never adopts one.
10. As a Mac owner, I want fonts installed on every machine, managed or not, so that my terminal looks the same everywhere.
11. As a Mac owner, I want one curated package list with optional groups such as personal and embedded, so that the work Mac doesn't receive games and synth toolchains.
12. As a Mac owner, I want to answer the group questions once per machine and be able to change them later in a config file, so that the choice is durable and editable.
13. As a Mac owner, I want manually installed packages left alone by the sync, so that experimenting doesn't get undone.
14. As a Mac owner, I want a documented two-step way to add a package to the list, so that the list stays the source of truth.
15. As a fish user, I want fish installed, configured with my abbreviations, prompt, colours and plugins, and registered as my login shell, so that the first terminal I open is mine.
16. As a fish user, I want the settings currently hiding in fish's universal variables moved into versioned files, so that they reach other machines and the dead ones disappear.
17. As a Claude Code user, I want the zsh login profile mirroring the fish environment, so that non-interactive tool shells find Homebrew, asdf and the locale.
18. As a git user, I want my gitconfig with the personal identity as default and an ICFM identity for the ICFM repos folder, so that commits carry the address each client expects.
19. As a git user, I want the identity override to work on a folder that doesn't exist yet, so that the first ICFM clone on a new Mac is already correct.
20. As a GitHub user, I want gh installed, logged in once through the browser, and my aliases in place, so that pull request work is the same on both Macs.
21. As an ssh user, I want a fresh RSA key generated on any Mac that has none, uploaded to GitHub automatically and printed for Azure DevOps, so that keys are never copied between machines and Azure DevOps still accepts them.
22. As an ssh user, I want my ssh client config with agent forwarding and keep-alive, so that remote sessions behave as they do today.
23. As a developer, I want asdf installed from Homebrew with my plugins and global tool versions, so that node and python are present at the versions I use.
24. As a developer, I want the old git-clone asdf on my current Mac retired without losing installed versions, so that migration costs nothing.
25. As a keyboard nerd, I want my Hammerspoon config managed as plain files and my Karabiner rules generated from source inside the same repo, so that keyboard behaviour is versioned with everything else and edited the same way.
26. As a keyboard nerd, I want the Karabiner build and the Hammerspoon setup helpers skipped when those apps aren't installed, so that a managed Mac without them doesn't fail the sync.
27. As a Mac user, I want F1 to F12 to be standard function keys and the Fn key alone to do nothing, so that the printed media keys need Fn and nothing pops up by accident.
28. As a Mac user, I want the key repeat fast, press-and-hold off, and smart quotes, dashes, periods and capitalisation off, so that typing code isn't fought by the OS.
29. As a Mac user, I want natural scrolling off and swipe-between-pages off, so that scrolling matches my other Mac.
30. As a trackpad user, I want tap to click, two-finger secondary click, silent light clicks, no force click, no three-finger drag, and my gesture assignments, so that the trackpad behaves identically on both Macs.
31. As a trackpad user, I want the pointer speed set to my usual notch with a best-effort apply and a warning if it didn't stick, so that I only visit the settings pane when the script really couldn't do it.
32. As a Mac user, I want screenshots saved to Downloads as PNG with no floating thumbnail, so that a capture is just a file.
33. As a Finder user, I want new Finder windows to open Downloads, so that Cmd+N lands where my files arrive.
34. As a Finder user, I want Downloads to open in list view with a Date Added column, sorted newest first, so that the latest download is always on top.
35. As a Finder user, I want extensions shown, the status bar on, folders sorted first, no extension-change warning, and no .DS_Store files on network or USB volumes, so that Finder behaves like my other Mac.
36. As a Desktop user, I want a black wallpaper, desktop items hidden, and, should items ever show, my icon size, grid and sort order, so that the Desktop is calm.
37. As a Desktop user, I want clicking the wallpaper to do nothing outside Stage Manager, and widgets hidden on the Desktop, so that a stray click never sweeps my windows away.
38. As a Dock user, I want the Dock hidden with my delay, tiny tiles with magnification, no recents, no launch animation, no hot corners, so that the Dock is out of the way until I want it.
39. As a Dock user, I want the Dock to contain exactly an allow-list of apps plus a Downloads stack in fan view sorted by date added, so that Apple's default set is gone.
40. As a dictation user, I want dictation enabled with the press-Control-twice shortcut and my three languages listed, so that speech-to-text is a double tap away.
41. As a laptop user, I want the Mac to never sleep on the power adapter when the display is off, display sleep at my timings, and no dimming on battery, so that remote sessions and background jobs survive.
42. As a laptop user, I want auto-brightness turned off for every display, with a read-back and a clear manual instruction if the write didn't hold, so that the screen stops adapting. True Tone stays at its default.
43. As an iTerm2 user, I want iTerm2 to load and save its preferences from a folder in the repo, so that profile, font and colours sync in both directions.
44. As a Mac owner, I want a printed checklist of the steps macOS won't let a script do, so that I know exactly what's left after the bootstrap.
45. As a Mac owner, I want every script safe to re-run, so that an interrupted bootstrap resumes with the same command.
46. As a Mac owner, I want no secret in the repo, so that it can stay public and be cloned anonymously on a fresh Mac.
47. As the maintainer, I want a README that explains bootstrap, re-sync, adding a package, adding a defaults key and the manual checklist, so that future me doesn't have to re-derive this conversation.
48. As the maintainer, I want the repo renamed to dotfiles and my current Mac migrated onto it, so that the current Mac is the first machine kept in sync, not an exception.

## Implementation Decisions

### Tooling and repo

- chezmoi manages the files. Files are copied, never symlinked: macOS 14 and later rewrite symlinked preference files, and Karabiner ignores changes to a symlinked config.
- Bootstrap follows chezmoi's canonical pattern: the official installer, then `init --apply` with the built-in git enabled. The built-in git is required because a fresh Mac's `/usr/bin/git` is a stub that opens the Command Line Tools dialog and fails; chezmoi's automatic fallback doesn't trigger because the stub counts as present.
- The built-in git clones over HTTPS only, so the repo stays public and contains no secrets by construction.
- The existing GitHub repo `caillou/mac-setup` is renamed to `caillou/dotfiles`. GitHub redirects the old URL.
- The chezmoi source directory is `~/repos/caillou/dotfiles` on every machine. The bootstrap passes it explicitly; the config template pins it so later commands need no flag. It is the only repo the setup needs: the Hammerspoon config is managed as files and the Karabiner source lives in a project directory inside it. The former `caillou/keyboard` and `caillou/karabiner.ts` repos are archived with a pointer to dotfiles; their history and the keyboard repo's test suite stay there.
- chezmoi itself is listed in the Brewfile so Homebrew keeps it current; the installer-provided binary is purged after the first apply.
- Re-sync is plain `chezmoi update`. No alias, no wrapper.

### Machine facts and configuration data

- The config template detects enrollment with `profiles status -type enrollment` and records a `managed` boolean. The user can override it in the config file.
- The config template prompts once for group flags, initially `personal` and `embedded`, and records them. Names are finalised when the package list is sorted.
- The Intune MDM and the ManageEngine self-service agent coexist on the work Mac; detection uses only the generic enrollment command, never a vendor agent.
- A small shell library provides pure predicates used by several scripts: is managed, is app bundle present in Applications, is command available, is key already at value. It is the only place these checks are written.

### Homebrew and packages

- A run-once "before" script guarded to macOS runs `sudo -v` and the official Homebrew installer, which installs the Command Line Tools headlessly when missing. No separate tools wait loop.
- One templated Brewfile: a core section for every machine, then flag-guarded blocks per group. Casks are emitted only when not managed and only when the app bundle is absent; App Store entries only when not managed; fonts always. Formulae always.
- The initial list is a curated sort of a dump from the current Mac into core and groups, reviewed as a proposal, not entry by entry. Duplicate cask names on the current Mac are dropped.
- A change-triggered script runs `brew bundle` with the rendered file. Cleanup is never automated; `brew bundle cleanup` is a documented manual check.
- Homebrew never adopts an existing app. On a managed Mac the script prints the allow-listed casks whose apps are missing.

### Shell

- fish config is written with home-relative paths (`~`, `$HOME`) and is not a template, so `chezmoi re-add` works on it. Abbreviations, locale, pager, path additions, Homebrew shellenv, asdf init and the Karabiner restart function are managed.
- The frozen theme file that fish 4.3 generated from the Ayu Dark colours is managed as a plain conf.d file. A new conf.d file holds the settings currently in universal variables that are worth keeping: XDG config home, emoji width, and the Pure prompt options that differ from Pure's defaults. Which Pure options differ is determined by diffing against Pure's defaults during the migration.
- The universal variables file is not managed. Migration on the current Mac erases the dead entries: BrowserStack, pyenv, Spacefish, the 28 colour variables superseded by the theme file.
- Plugins are z, Pure and fzf via fisher, declared in the `fish_plugins` file. A change-triggered script installs fisher if absent and runs `fisher update`.
- fish becomes the login shell: appended to `/etc/shells` if missing, then `chsh`, both guarded.
- The zsh login profile, zshrc, bash profile and readline config are managed as today, written with home-relative paths. The asdf line changes to the Homebrew asdf form.
- Templates are limited to files that truly vary per machine: chezmoi's own config, the Brewfile, the defaults script, the iTerm2 preference keys. Everything else is a plain file so edits made in the home directory can be copied back with `chezmoi re-add`.

### Git, GitHub, ssh

- gitconfig: personal identity as default, `pull.ff only`, default branch main, comment char `|`, a conditional include for `~/repos/icfm/` pointing at an ICFM identity file that lives in the repo. The BKW and Apprentice overrides are dropped. The global ignore is managed.
- gh config with the `co` alias. A run-once script runs the browser login when `gh auth status` fails, then uploads the ssh key.
- ssh: one RSA 4096 key generated when the ssh folder has no key, because Azure DevOps accepts RSA only and has no API for adding keys. The public key is uploaded to GitHub via gh and printed for manual paste into Azure DevOps. The ssh client config (agent forwarding, keep-alive, identity file) is a template.
- The keyboard repos are cloned after this module so they can use ssh.

### asdf

- Homebrew asdf (0.16 line, Go). Plugins nodejs and python, global versions pinned in the managed tool-versions file, legacy version files enabled. A change-triggered script adds plugins and installs the pinned versions.
- Migration on the current Mac removes the sourcing of the git-clone install; the data directory with installed versions is kept and reused.

### Hammerspoon

- `~/.hammerspoon` is managed directly by chezmoi as plain files: `init.lua`, `windows.lua` (the Ctrl+S window-layout modal), `status-message.lua` (on-screen overlay), and `setup.lua` (machine-setup helpers, below). No symlink, no installer, no Lua toolchain, no tests: the keyboard repo's space-fn engine, spec suite, Makefile, luarocks tree, lefthook, stylua and EmmyLua stubs are not carried over and remain in the archived repo.
- `init.lua` is trimmed to: install the `hs` command line into `~/.local`, reload hotkey, a single change watcher on the config folder, `require` of the windows module, ready alert. The symlink-following watcher and the EmmyLua spoon are dropped. The two lines in the windows module that pause and resume space-fn are removed.
- `~/.hammerspoon/Spoons` is never managed; Hammerspoon writes there at runtime.
- `setup.lua` exposes functions callable from a script through the `hs` command line once Hammerspoon runs and has Accessibility: set the wallpaper on every screen through Hammerspoon's desktop-image API (no System Events, so no Automation prompt), and print the machine-setup status overlay. It is loaded on demand, not at startup. Further helpers (pointer-speed pane, dictation activation) are candidates, not commitments.
- The wallpaper step in the defaults script calls this helper when Hammerspoon is running, and falls back to System Events otherwise.

### Karabiner

- The karabiner.ts source (one TypeScript file, package file, lockfile) lives in a project directory inside the dotfiles repo, excluded from the home directory by `.chezmoiignore`. A change-triggered script, hashed on the source, runs the install and build after asdf has provided node; the build writes the rules into Karabiner's own config file, preserving Karabiner's other settings. The generated JSON is never in the repo because Karabiner rewrites it.
- The build targets Karabiner's "Default profile", which Karabiner creates on first launch, so no profile has to be created by hand. Karabiner still needs to have been launched once; the manual checklist says so.
- Dependencies are pinned in the lockfile rather than tracking `latest`. Tooling choice (karabiner.ts versus alternatives) is confirmed by the research recorded in the notes.
- The step is guarded on the Karabiner app being present.

### macOS defaults

One change-triggered script, plain POSIX sh, that quits System Settings first, writes everything, runs the private `activateSettings -u` as the logged-in user so input settings apply without logout, then restarts Finder, Dock and SystemUIServer. Values are the current Mac's:

- Keyboard: standard function keys on; Fn key alone does nothing; key repeat 2, initial repeat 15; press-and-hold off; full keyboard access; automatic capitalisation, smart dashes, period substitution and smart quotes off.
- Scrolling: natural scrolling off; swipe between pages off.
- Trackpad, written to the built-in and Bluetooth trackpad domains and the global and per-host copies: tap to click; two-finger secondary click; three-finger tap off; force click off with silent clicking and lightest firmness; pinch, rotate, smart zoom on; four-finger horizontal and vertical swipes; two-finger edge swipe for Notification Centre; five-finger pinch for Launchpad; three-finger drag off. Pointer speed 0.6875 for trackpad and mouse, applied best-effort, read back through hidutil, warning printed if unchanged.
- Screenshots: location Downloads, PNG, thumbnail off.
- Finder: new window target Downloads; extensions shown; status bar; folders first; no extension-change warning; no .DS_Store on network and USB volumes; internal drives hidden on the Desktop, external and removable shown; save and print panels expanded; save to disk rather than iCloud; Desktop icon view arranged by kind with the current icon size, grid spacing, text size and label position.
- Window manager: click wallpaper to show desktop only in Stage Manager; desktop items hidden; widgets hidden on the Desktop.
- Dock: autohide on with a 0.5 s delay; tile size 16; magnification on, large size 128; bottom; no recents; no launch animation; all four hot corners off.
- Wallpaper: the system solid black. Set through the Hammerspoon setup helper (desktop-image API, no permission prompt) when Hammerspoon is running, else through System Events to the black solid-colour image that ships with macOS; written unconditionally because a system colour can't be read back.
- Dictation: enabled, shortcut press Control twice, preferred languages en_US, fr_CH, de_CH. First activation consent and language model downloads are on the manual checklist.
- Power, via pmset with sudo: on adapter never sleep, display sleep 10 minutes; on battery display sleep 15 minutes, no dimming.
- Dropped from the old script: the Safari and Messages tweaks (need Full Disk Access, and the Do Not Track header is obsolete), quarantine disabling (a security setting and likely MDM policy), and the accessibility zoom keys (need Full Disk Access). Locale and language lists are not written.

### Dock allow-list

- dockutil from Homebrew. The script removes all persistent apps and re-adds the allow-list in order, then the Downloads folder in the others section as a stack, fan view, sorted by date added. Seed allow-list: Freeform, iPhone Mirroring, Numbers. Change-triggered, so the Dock is only rebuilt when the list changes.

### Downloads view writer

- A small Python module, run with a throwaway virtualenv and the `ds_store` library, writes the Downloads record into the home folder's `.DS_Store`: view style list, and a list-view blob with sort column Date Added descending, Date Added visible. It runs after `killall Finder` (closing all windows, so Finder's cache can't overwrite it) and is followed by a second `killall Finder`. Verified working on macOS 26.6 on both Macs.
- The record shape, from the prototype, is the decision: three entries on the `Downloads` key of the parent folder's store, `vstl` of type `type` with value `Nlsv`, `vSrn` of type `long` with value 1, and `lsvC` of type `blob` holding a binary plist with `sortColumn` `dateAdded`, `viewOptionsVersion` 1, and a `columns` list where each column has `identifier`, `visible`, `ascending`, `width`. The blob bytes are those captured from the current Mac.
- AppleScript cannot do this: Finder's scripting dictionary has no Date Added column.

### iTerm2

- A preferences folder in the repo. Two iTerm2 keys point iTerm2 at it and enable saving changes back on quit. Migration exports the current preferences into that folder. The old Ayu Dark colour file is kept there as reference.

### Display settings

- Auto-brightness is stored in root's CoreBrightness preferences as one `AutoBrightnessEnable` flag per display entry (confirmed on the personal Mac, where it is false). A sudo script sets the flag to false on every display entry, restarts the brightness daemon, reads back, and prints the manual instruction if the value didn't hold. Display identifiers differ per machine, so the script iterates the entries rather than hardcoding one.
- True Tone has no key in that file on the personal Mac, meaning it was never toggled and sits at Apple's default, on. The setup leaves it alone.
- The script never fails the apply.

### Manual-steps report

- The last script prints a checklist: admin password prompts explained; Privacy & Security approvals for Karabiner and Hammerspoon (Input Monitoring, Accessibility, driver extension); Azure DevOps ssh key paste; App Store sign-in on personal Macs; Self Service requests on managed Macs; first dictation activation; pointer speed and auto-brightness to verify; Karabiner first launch.

### README

The README is the operating manual and is written together with the repo. Sections, in order:

- Setup: the one-line bootstrap, what it asks (group flags), what it detects (managed), what it prompts for (admin password, gh browser login), and how long the Command Line Tools and Homebrew steps take.
- Re-sync: `chezmoi update`, and `chezmoi diff` to preview.
- Editing loop: edit a file in place, `chezmoi status` and `chezmoi diff` to see drift, `chezmoi re-add` to copy it back (or `chezmoi edit` to skip that step), commit and push from `chezmoi cd`, `chezmoi update` on the other Mac. `chezmoi merge` for conflicts.
- Two fish rules: settings go in `config.fish` or `conf.d`, never `set -U`, because universal variables are not synced; themes are fine because fish writes them to a managed file.
- Template rule: which files are templates and why, and that those are edited on the repo side, never re-added.
- Adding a package: `brew install`, then add the line to the matching Brewfile block and commit; or add the line first and `chezmoi apply`. `brew bundle cleanup` as the periodic drift check.
- Adding a macOS setting: how to find a key (defaults diff before and after a change in System Settings, macos-defaults.com, nix-darwin modules), where to add it in the defaults script, and which process to restart.
- Managed Mac notes: what is skipped, how to override detection, how to read the missing-apps list.
- Manual checklist: the same list the final script prints.
- Layout: what lives where in the source directory, and the numbering of scripts.

### Migration of the current Mac

- One issue: rename the GitHub repo; move the local checkout to `~/repos/caillou/dotfiles`; copy the three Hammerspoon files and the Karabiner source into the repo; archive `caillou/keyboard` and `caillou/karabiner.ts` on GitHub with a README pointer and remove their local checkouts; replace the `~/.hammerspoon/keyboard` symlink with the managed files; adopt the current dotfiles into chezmoi; purge dead universal variables; switch asdf; export iTerm2 prefs; run the first apply and review the diff.

### Ordering and idempotency

- Scripts are numbered so the order is: Homebrew, packages, shell, git and ssh, asdf, Karabiner build, defaults, Dock, Downloads view, iTerm2, display, report. Hammerspoon files are applied with the other dotfiles and need no script. Every script is re-runnable. Change-triggered scripts embed hashes of the files they depend on.

## Testing Decisions

A good test checks observable behaviour through the module's interface and never its internals. For this repo that means: given machine facts, is the rendered output right; given a file, is the written record right; given stubbed commands, does a predicate answer correctly. Tests never install packages or write real preferences.

- The Downloads view writer gets Python unit tests against a temporary `.DS_Store`: writes the record, reads it back, asserts the three entries and the decoded sort column. This makes the earlier manual check permanent.
- The machine facts library gets bats tests with stubbed `profiles`, `ls` and `command`, covering managed and unmanaged, app present and absent, key set and unset.
- The Brewfile and the defaults script get template render tests: chezmoi renders them with fake data for the four combinations of managed and personal, and the tests assert which casks and blocks appear. No installing.
- Every shell script passes shellcheck. A GitHub Actions job on a macOS runner installs chezmoi, initialises from the checkout with fake config data, and runs a dry-run apply, catching template errors and script ordering mistakes on a fresh machine.
- Prior art: the archived keyboard repo's busted suite and lefthook config are the model for "tests plus pre-commit lint" in a personal repo. The Lua files themselves are not unit-tested in dotfiles; the window-layout modal is verified by use.
- Not tested automatically: the effect of defaults writes, the Homebrew install, and the Dock rebuild. Those are verified by hand on the new Mac after the first bootstrap, and the pointer-speed persistence across a reboot is checked then.

## Out of Scope

- Claude Code configuration, skills, agents and memory. Memory folders are named after absolute project paths that include the username, so they cannot sync between these two Macs. Claude config gets its own, probably private, repo later.
- VS Code, which already uses Settings Sync.
- Syncing project repositories. Only the two keyboard projects are cloned.
- Secrets management. The repo holds none; ssh keys are per machine; Bitwarden is personal-Mac only and not wired in.
- Installing desktop apps on the managed Mac, and anything MDM policy forbids.
- Granting privacy permissions; macOS never lets a script do this.
- Locale, language and region settings, login items, Safari and Messages preferences.
- Intel Macs and Linux. Homebrew paths assume Apple Silicon.
- Automated package cleanup.
- Space-fn and the Lua test suite; both remain in the archived keyboard repo.
- True Tone; left at its default.

## Further Notes

- The old defaults script from 2023 is the seed for the defaults module; most of its keys are still valid on macOS 26.6 and were confirmed against the current Mac.
- A live test during research briefly changed and then restored the trackpad, mouse and double-click keys on the current Mac; the final state was verified identical to the original.
- The pointer speed keys were reported broken on macOS 26.1 because System Settings stopped writing them. Writing them still takes effect when followed by `activateSettings -u`, verified on 26.6.2, but whether the settings slider reflects the value and whether it survives a reboot is unverified.
- Candidates for later: locale settings, LinearMouse for external mice, mise as an asdf replacement, Bitwarden-backed secrets on the personal Mac, a private Claude config repo.
- Useful references for new defaults keys: macos-defaults.com and the nix-darwin defaults modules, both actively maintained in 2026. The mathiasbynens script is unmaintained since 2020 and serves as a catalogue only.
