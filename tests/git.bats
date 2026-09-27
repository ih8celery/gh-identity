#!/usr/bin/env bats
# bin/git: untouched with no opinion; the chosen account's key and email
# otherwise; a hard stop, with the real git never run, when anything is
# missing.

load helpers

setup() {
  gid_test_setup
  GIT="$REPO/bin/git"
}

@test "no opinion runs the real git untouched" {
  run "$GIT" status --short
  [ "$status" -eq 0 ]
  [ "${lines[0]}" = "ran real git: status --short" ]
  [ "${lines[1]}" = "GIT_SSH_COMMAND=unset" ]
  [ "${lines[2]}" = "GIT_AUTHOR_EMAIL=unset" ]
}

@test "a chosen account sets its key and commit identity" {
  write_account alice a@example.com "Alice A"
  write_chooser 'echo alice'
  run "$GIT" push
  [ "$status" -eq 0 ]
  [ "${lines[0]}" = "ran real git: push" ]
  [ "${lines[1]}" = "GIT_SSH_COMMAND=ssh -i '$BATS_TEST_TMPDIR/keys/id_alice' -o IdentitiesOnly=yes" ]
  [ "${lines[2]}" = "GIT_AUTHOR_EMAIL=a@example.com" ]
  [ "${lines[3]}" = "GIT_COMMITTER_EMAIL=a@example.com" ]
  [ "${lines[4]}" = "GIT_AUTHOR_NAME=Alice A" ]
}

@test "a blank name leaves git's own user.name alone" {
  write_account alice a@example.com
  write_chooser 'echo alice'
  run "$GIT" commit
  [ "${lines[4]}" = "GIT_AUTHOR_NAME=unset" ]
}

@test "git -C asks the chooser about that folder, not this one" {
  mkdir -p "$WORK/alice-project"
  write_account alice a@example.com
  write_chooser 'case "$PWD" in */alice-project) echo alice ;; esac'
  run "$GIT" -C alice-project log
  [ "${lines[2]}" = "GIT_AUTHOR_EMAIL=a@example.com" ]
}

@test "a missing account file stops before the real git runs" {
  write_chooser 'echo alice'
  run "$GIT" push
  [ "$status" -eq 1 ]
  [[ "$output" != *"ran real git"* ]]
  [[ "$output" == *"accounts/alice"* ]]
}

@test "the real git's exit status comes back unchanged" {
  FAKE_EXIT=5 run "$GIT" status
  [ "$status" -eq 5 ]
}

@test "reached through a symlink on PATH, it runs the real git, not itself" {
  mkdir -p "$BATS_TEST_TMPDIR/links"
  ln -s "$GIT" "$BATS_TEST_TMPDIR/links/git"
  PATH="$BATS_TEST_TMPDIR/links:$PATH"
  run git status
  [ "$status" -eq 0 ]
  [ "${lines[0]}" = "ran real git: status" ]
}
