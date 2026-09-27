#!/usr/bin/env bats
# lib/identity.sh: which folder, which login, which settings, which real
# command. Everything the wrappers decide is decided here.

load helpers

setup() {
  gid_test_setup
  . "$REPO/lib/identity.sh"
}

@test "git dir is the current folder when there is no -C" {
  run gid_git_dir status
  [ "$output" = "$WORK" ]
}

@test "git dir follows -C, relative and absolute, in order" {
  run gid_git_dir -C /abs -C rel log
  [ "$output" = "/abs/rel" ]
  run gid_git_dir -C sub status
  [ "$output" = "$WORK/sub" ]
}

@test "git dir skips -c values and stops at the subcommand" {
  run gid_git_dir -c core.pager=cat -C x log -C y
  [ "$output" = "$WORK/x" ]
}

@test "git dir does not loop on a trailing -c or -C" {
  run gid_git_dir -c
  [ "$output" = "$WORK" ]
  run gid_git_dir -C
  [ "$output" = "$WORK" ]
}

@test "no chooser file means no opinion" {
  run gid_choose "$WORK"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "the chooser's login is printed" {
  write_chooser 'echo alice'
  run gid_choose "$WORK"
  [ "$status" -eq 0 ]
  [ "$output" = "alice" ]
}

@test "the chooser runs in the folder it is asked about" {
  mkdir -p "$WORK/bob-project"
  write_chooser 'case "$PWD" in */bob-project) echo bob ;; esac'
  run gid_choose "$WORK/bob-project"
  [ "$output" = "bob" ]
  run gid_choose "$WORK"
  [ -z "$output" ]
}

@test "a chooser that fails stops everything" {
  write_chooser 'return 3'
  run gid_choose "$WORK"
  [ "$status" -eq 1 ]
  [[ "$output" == *"chooser"*"failed"* ]]
}

@test "a chooser file without the function stops everything" {
  echo '# empty' > "$GH_IDENTITY_CONFIG/account.sh"
  run gid_choose "$WORK"
  [ "$status" -eq 1 ]
}

@test "a chooser that prints something that is not a login stops everything" {
  write_chooser 'echo me@example.com'
  run gid_choose "$WORK"
  [ "$status" -eq 1 ]
  [[ "$output" == *"not a GitHub login"* ]]
}

@test "a folder that does not exist is no opinion, left for git to report" {
  write_chooser 'echo alice'
  run gid_choose "$WORK/nope"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}
