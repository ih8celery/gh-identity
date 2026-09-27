#!/usr/bin/env bats
# bin/gh-identity: `which` says who git and gh would act as here and
# whether that will work; `configure` writes the account files and
# setup.env from answers to prompts.

load helpers

setup() {
  gid_test_setup
  GI="$REPO/bin/gh-identity"
}

@test "which, with no opinion, says git and gh run untouched" {
  run "$GI" which
  [ "$status" -eq 0 ]
  [[ "$output" == *"no opinion"* ]]
}

@test "which shows the chosen account and that it is ready" {
  write_account alice a@example.com "Alice A"
  write_chooser 'echo alice'
  sign_in alice
  run "$GI" which
  [ "$status" -eq 0 ]
  [[ "$output" == *"account:  alice"* ]]
  [[ "$output" == *"email:    a@example.com"* ]]
  [[ "$output" == *"ssh key:  $BATS_TEST_TMPDIR/keys/id_alice"* ]]
  [[ "$output" == *"gh:       signed in"* ]]
}

@test "which fails when the chosen account is not signed in" {
  write_account alice a@example.com
  write_chooser 'echo alice'
  run "$GI" which
  [ "$status" -eq 1 ]
  [[ "$output" == *"NOT signed in"* ]]
}

@test "which takes a folder" {
  mkdir -p "$WORK/alice-project"
  write_account alice a@example.com
  write_chooser 'case "$PWD" in */alice-project) echo alice ;; esac'
  sign_in alice
  run "$GI" which "$WORK/alice-project"
  [[ "$output" == *"account:  alice"* ]]
}

@test "no subcommand prints usage and fails" {
  run "$GI"
  [ "$status" -eq 2 ]
  [[ "$output" == *"usage"* ]]
}

@test "configure writes both account files and setup.env" {
  export HOME="$BATS_TEST_TMPDIR/home"
  run "$GI" configure <<'EOF'
alice
a@example.com
Alice A

bob
b@example.com


EOF
  [ "$status" -eq 0 ]
  [ "$(cat "$GH_IDENTITY_CONFIG/accounts/alice")" = "$(printf 'email=a@example.com\nname=Alice A\nssh_key=~/.ssh/id_ed25519')" ]
  [ "$(cat "$GH_IDENTITY_CONFIG/accounts/bob")" = "$(printf 'email=b@example.com\nname=\nssh_key=~/.ssh/id_ed25519_bob')" ]
  . "$GH_IDENTITY_CONFIG/setup.env"
  [ "$MAIN_LOGIN" = alice ]
  [ "$SECOND_LOGIN" = bob ]
  [ "$SECOND_EMAIL" = b@example.com ]
  [ "$SECOND_KEY" = "$HOME/.ssh/id_ed25519_bob" ]
}

@test "configure offers what is already there as the default" {
  printf 'email=old@example.com\nname=Old\nssh_key=~/.ssh/old\n' \
    > "$GH_IDENTITY_CONFIG/accounts/alice"
  run "$GI" configure <<'EOF'
alice



bob
b@example.com


EOF
  [ "$status" -eq 0 ]
  [ "$(cat "$GH_IDENTITY_CONFIG/accounts/alice")" = "$(printf 'email=old@example.com\nname=Old\nssh_key=~/.ssh/old')" ]
}

@test "configure refuses a login that cannot be a GitHub login" {
  run "$GI" configure <<'EOF'
me@example.com
EOF
  [ "$status" -eq 1 ]
  [[ "$output" == *"not a GitHub login"* ]]
}

@test "configure refuses the same login twice" {
  run "$GI" configure <<'EOF'
alice
a@example.com


alice
a@example.com


EOF
  [ "$status" -eq 1 ]
  [[ "$output" == *"must differ"* ]]
}
