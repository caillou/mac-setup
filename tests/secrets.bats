#!/usr/bin/env bats
#
# The secrets check, which keeps the repo publishable.

setup() {
  load helpers
  CHECK="$REPO_ROOT/tests/secrets-check.sh"
  FIXTURE="$BATS_TEST_TMPDIR/source"
  mkdir -p "$FIXTURE"
  echo 'nothing to see here' >"$FIXTURE/README.md"
}

# The literals below are assembled at run time so this file never contains a
# token-shaped string itself.
fake_token() {
  printf 'gh%s_%s\n' 'p' '0123456789abcdef0123456789abcdef0123'
}

@test "the source directory passes" {
  run "$CHECK"
  [ "$status" -eq 0 ]
}

@test "a gh hosts.yml fails the check" {
  mkdir -p "$FIXTURE/private_dot_config/gh"
  echo 'github.com:' >"$FIXTURE/private_dot_config/gh/hosts.yml"
  run "$CHECK" "$FIXTURE"
  [ "$status" -eq 1 ]
  [[ "$output" == *'gh credentials file'* ]]
}

@test "a private key file fails the check" {
  mkdir -p "$FIXTURE/private_dot_ssh"
  echo 'key material' >"$FIXTURE/private_dot_ssh/id_rsa"
  run "$CHECK" "$FIXTURE"
  [ "$status" -eq 1 ]
  [[ "$output" == *'private key file'* ]]
}

@test "a public key file passes the check" {
  mkdir -p "$FIXTURE/private_dot_ssh"
  echo 'ssh-rsa AAAA...' >"$FIXTURE/private_dot_ssh/id_rsa.pub"
  run "$CHECK" "$FIXTURE"
  [ "$status" -eq 0 ]
}

@test "a token-shaped string fails the check" {
  fake_token >"$FIXTURE/notes.md"
  run "$CHECK" "$FIXTURE"
  [ "$status" -eq 1 ]
  [[ "$output" == *'token-shaped string'* ]]
}

@test "a private key header fails the check" {
  printf -- '-----BEGIN OPENSSH %s-----\n' 'PRIVATE KEY' >"$FIXTURE/key.txt"
  run "$CHECK" "$FIXTURE"
  [ "$status" -eq 1 ]
  [[ "$output" == *'token-shaped string'* ]]
}
