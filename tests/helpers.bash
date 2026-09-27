# Shared by every suite: a throwaway config dir, fake "real" git and gh on
# PATH that report what they were given, and helpers to write accounts and
# choosers. No suite touches a real account, key, or ~/.config.

gid_test_setup() {
  REPO="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"

  unset GIT_SSH_COMMAND GIT_AUTHOR_EMAIL GIT_COMMITTER_EMAIL \
        GIT_AUTHOR_NAME GIT_COMMITTER_NAME GH_TOKEN GH_IDENTITY_BIN
  export GH_IDENTITY_CONFIG="$BATS_TEST_TMPDIR/config"
  mkdir -p "$GH_IDENTITY_CONFIG/accounts"

  export FAKE_TOKENS="$BATS_TEST_TMPDIR/tokens"
  mkdir -p "$FAKE_TOKENS"
  FAKE_BIN="$BATS_TEST_TMPDIR/fake-bin"
  mkdir -p "$FAKE_BIN"
  make_fake_git
  make_fake_gh
  export PATH="$FAKE_BIN:/usr/bin:/bin"

  WORK="$BATS_TEST_TMPDIR/work"
  mkdir -p "$WORK"
  cd "$WORK"
}

make_fake_git() {
  cat > "$FAKE_BIN/git" <<'EOF'
#!/bin/bash
echo "ran real git: $*"
echo "GIT_SSH_COMMAND=${GIT_SSH_COMMAND-unset}"
echo "GIT_AUTHOR_EMAIL=${GIT_AUTHOR_EMAIL-unset}"
echo "GIT_COMMITTER_EMAIL=${GIT_COMMITTER_EMAIL-unset}"
echo "GIT_AUTHOR_NAME=${GIT_AUTHOR_NAME-unset}"
echo "GH_TOKEN=${GH_TOKEN-unset}"
exit "${FAKE_EXIT:-0}"
EOF
  chmod +x "$FAKE_BIN/git"
}

make_fake_gh() {
  cat > "$FAKE_BIN/gh" <<'EOF'
#!/bin/bash
if [ "$1 $2" = "auth token" ]; then
  user=""
  while [ $# -gt 0 ]; do
    [ "$1" = --user ] && user="$2"
    shift
  done
  if [ -n "$user" ] && [ -f "$FAKE_TOKENS/$user" ]; then
    cat "$FAKE_TOKENS/$user"
    exit 0
  fi
  echo "no oauth token found for $user" >&2
  exit 1
fi
echo "ran real gh: $*"
echo "GIT_SSH_COMMAND=${GIT_SSH_COMMAND-unset}"
echo "GIT_AUTHOR_EMAIL=${GIT_AUTHOR_EMAIL-unset}"
echo "GH_TOKEN=${GH_TOKEN-unset}"
EOF
  chmod +x "$FAKE_BIN/gh"
}

# write_account LOGIN EMAIL [NAME] — an account file and a (fake) key.
write_account() {
  local key="$BATS_TEST_TMPDIR/keys/id_$1"
  mkdir -p "$BATS_TEST_TMPDIR/keys"
  : > "$key"
  printf 'email=%s\nname=%s\nssh_key=%s\n' "$2" "${3:-}" "$key" \
    > "$GH_IDENTITY_CONFIG/accounts/$1"
}

# write_chooser BODY — the body of gh_identity_account.
write_chooser() {
  printf 'gh_identity_account() {\n%s\n}\n' "$1" > "$GH_IDENTITY_CONFIG/account.sh"
}

# sign_in LOGIN — make the fake gh hold a token for LOGIN.
sign_in() {
  echo "token-for-$1" > "$FAKE_TOKENS/$1"
}
