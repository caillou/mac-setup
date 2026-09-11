#!/usr/bin/env bats
#
# chezmoi's own config template: what `chezmoi init` writes on a clean HOME,
# how the machine is detected, and that an answer given once is kept.

setup() {
  load helpers
  export HOME="$BATS_TEST_TMPDIR/home"
  # XDG_CONFIG_HOME is set on this Mac and wins over HOME, so isolate it too:
  # a test must never write into the real home directory.
  export XDG_CONFIG_HOME="$HOME/.config"
  export XDG_CACHE_HOME="$HOME/.cache"
  export XDG_DATA_HOME="$HOME/.local/share"
  export XDG_STATE_HOME="$HOME/.local/state"
  mkdir -p "$HOME"
  CONFIG="$XDG_CONFIG_HOME/chezmoi/chezmoi.toml"
}

# stub_profiles <enrollment line>
stub_profiles() {
  mkdir -p "$BATS_TEST_TMPDIR/bin"
  cat >"$BATS_TEST_TMPDIR/bin/profiles" <<EOF
#!/bin/sh
echo "Enrolled via DEP: No"
echo "$1"
EOF
  chmod +x "$BATS_TEST_TMPDIR/bin/profiles"
  export PATH="$BATS_TEST_TMPDIR/bin:$PATH"
}

init() {
  run chezmoi init --source "$REPO_ROOT" --promptDefaults
  [ "$status" -eq 0 ]
}

@test "init on a clean HOME writes the machine facts and the source directory" {
  stub_profiles 'MDM enrollment: No'
  init
  [ -f "$CONFIG" ]
  grep -qx "sourceDir = \"$REPO_ROOT\"" "$CONFIG"
  grep -qx 'managed = false' "$CONFIG"
  grep -qx 'personal = false' "$CONFIG"
  grep -qx 'embedded = false' "$CONFIG"
}

@test "managed defaults to the enrollment detection" {
  stub_profiles 'MDM enrollment: Yes (User Approved)'
  init
  grep -qx 'managed = true' "$CONFIG"
}

@test "a stored answer survives a second init" {
  stub_profiles 'MDM enrollment: No'
  init
  grep -qx 'managed = false' "$CONFIG"

  # The answer is editable in the generated config; detection must not undo it.
  sed -i '' 's/^managed = false$/managed = true/' "$CONFIG"
  init
  grep -qx 'managed = true' "$CONFIG"
}

@test "an edited group flag survives a second init" {
  stub_profiles 'MDM enrollment: No'
  init
  sed -i '' 's/^personal = false$/personal = true/' "$CONFIG"
  init
  grep -qx 'personal = true' "$CONFIG"
  grep -qx 'embedded = false' "$CONFIG"
}
