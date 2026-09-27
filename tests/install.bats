#!/usr/bin/env bats
# ./install and ./uninstall: link or unlink the wrappers in a bin folder,
# and never touch a file there that is not one of our links.

load helpers

setup() {
  gid_test_setup
  export GH_IDENTITY_BIN="$BATS_TEST_TMPDIR/bin"
  mkdir -p "$GH_IDENTITY_BIN"
  PATH="$GH_IDENTITY_BIN:$PATH"
}

@test "install both links git, gh and gh-identity" {
  run "$REPO/install" both
  [ "$status" -eq 0 ]
  [ "$GH_IDENTITY_BIN/git" -ef "$REPO/bin/git" ]
  [ "$GH_IDENTITY_BIN/gh" -ef "$REPO/bin/gh" ]
  [ "$GH_IDENTITY_BIN/gh-identity" -ef "$REPO/bin/gh-identity" ]
}

@test "install git leaves gh alone" {
  run "$REPO/install" git
  [ -L "$GH_IDENTITY_BIN/git" ]
  [ ! -e "$GH_IDENTITY_BIN/gh" ]
}

@test "installing twice is fine" {
  "$REPO/install" both
  run "$REPO/install" both
  [ "$status" -eq 0 ]
  [[ "$output" == *"already linked"* ]]
}

@test "install never replaces a file that is not ours" {
  echo "someone else's" > "$GH_IDENTITY_BIN/gh"
  run "$REPO/install" both
  [ "$status" -eq 1 ]
  [ "$(cat "$GH_IDENTITY_BIN/gh")" = "someone else's" ]
  [ -L "$GH_IDENTITY_BIN/git" ]
}

@test "install warns when another git comes first on PATH" {
  PATH="$FAKE_BIN:$PATH"
  run "$REPO/install" git
  [[ "$output" == *"comes first on PATH"* ]]
}

@test "install and uninstall need to be told what" {
  run "$REPO/install"
  [ "$status" -eq 2 ]
  run "$REPO/uninstall" everything
  [ "$status" -eq 2 ]
}

@test "uninstall git keeps gh and gh-identity" {
  "$REPO/install" both
  run "$REPO/uninstall" git
  [ "$status" -eq 0 ]
  [ ! -e "$GH_IDENTITY_BIN/git" ]
  [ -L "$GH_IDENTITY_BIN/gh" ]
  [ -L "$GH_IDENTITY_BIN/gh-identity" ]
}

@test "uninstall both removes every link, gh-identity last" {
  "$REPO/install" both
  run "$REPO/uninstall" both
  [ "$status" -eq 0 ]
  [ -z "$(ls -A "$GH_IDENTITY_BIN")" ]
}

@test "uninstall never removes a file that is not ours" {
  echo "someone else's" > "$GH_IDENTITY_BIN/git"
  run "$REPO/uninstall" git
  [ "$status" -eq 1 ]
  [ "$(cat "$GH_IDENTITY_BIN/git")" = "someone else's" ]
}
