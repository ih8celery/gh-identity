#!/usr/bin/env bats
# The harness itself: fakes come first on PATH and report their input.

load helpers

setup() {
  gid_test_setup
}

@test "the fake git is the git on PATH and reports its arguments" {
  run git status
  [ "$status" -eq 0 ]
  [ "${lines[0]}" = "ran real git: status" ]
  [ "${lines[1]}" = "GIT_SSH_COMMAND=unset" ]
}

@test "the fake gh hands out a token only for a signed-in login" {
  sign_in alice
  run gh auth token --hostname github.com --user alice
  [ "$output" = "token-for-alice" ]
  run gh auth token --hostname github.com --user bob
  [ "$status" -eq 1 ]
}
