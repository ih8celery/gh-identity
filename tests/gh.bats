#!/usr/bin/env bats
# bin/gh: the git settings plus the chosen account's token from gh's own
# keychain. `gh auth ...` always runs untouched.

load helpers

setup() {
  gid_test_setup
  GH="$REPO/bin/gh"
}

@test "no opinion runs the real gh untouched" {
  run "$GH" pr list
  [ "$status" -eq 0 ]
  [ "${lines[0]}" = "ran real gh: pr list" ]
  [ "${lines[3]}" = "GH_TOKEN=unset" ]
}

@test "a chosen, signed-in account gets its token and git settings" {
  write_account alice a@example.com
  write_chooser 'echo alice'
  sign_in alice
  run "$GH" pr create
  [ "$status" -eq 0 ]
  [ "${lines[0]}" = "ran real gh: pr create" ]
  [ "${lines[2]}" = "GIT_AUTHOR_EMAIL=a@example.com" ]
  [ "${lines[3]}" = "GH_TOKEN=token-for-alice" ]
}

@test "a chosen account that is not signed in stops before gh runs" {
  write_account alice a@example.com
  write_chooser 'echo alice'
  run "$GH" pr create
  [ "$status" -eq 1 ]
  [[ "$output" != *"ran real gh"* ]]
  [[ "$output" == *"alice is not signed in"* ]]
}

@test "gh auth runs untouched even where the chosen account is broken" {
  write_chooser 'echo alice'
  run "$GH" auth status
  [ "$status" -eq 0 ]
  [ "${lines[0]}" = "ran real gh: auth status" ]
  [ "${lines[3]}" = "GH_TOKEN=unset" ]
}
