#!/usr/bin/env bats
# examples/account.sh: both rules it shows actually work.

load helpers

setup() {
  gid_test_setup
  export HOME="$BATS_TEST_TMPDIR/home"
  mkdir -p "$HOME/work/app" "$HOME/code/site/src" "$HOME/code/tool"
  printf '{"owner": "work"}\n' > "$HOME/code/site/project.json"
  printf '{"owner": "me"}\n' > "$HOME/code/tool/project.json"
  . "$REPO/examples/account.sh"
}

@test "folder rule: anything under ~/work is the work login" {
  cd "$HOME/work/app"
  [ "$(gh_identity_account)" = my-work-login ]
}

@test "file rule: the nearest project.json's owner decides" {
  cd "$HOME/code/site/src"
  [ "$(gh_identity_account)" = my-work-login ]
  cd "$HOME/code/tool"
  [ "$(gh_identity_account)" = my-main-login ]
}

@test "nothing matched is no opinion" {
  cd "$HOME"
  [ -z "$(gh_identity_account)" ]
}
