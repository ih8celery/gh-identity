# gh-identity configure: ask for both accounts' details, write one account
# file each, and write setup.env, which SETUP.md's later steps load.
# Re-running it offers what is already there as each default.

# Ask QUESTION on stderr, offering DEFAULT; print the answer.
gid_ask() {
  local question="$1" default="${2:-}" answer
  if [ -n "$default" ]; then
    printf '%s [%s]: ' "$question" "$default" >&2
  else
    printf '%s: ' "$question" >&2
  fi
  IFS= read -r answer || return 1
  printf '%s\n' "${answer:-$default}"
}

# Write CONTENT to FILE all at once, so a reader never sees half of it.
gid_write() {
  local file="$1" content="$2" tmp="$1.tmp.$$"
  printf '%s\n' "$content" > "$tmp" && mv -f "$tmp" "$file"
}

# Ask for one account and write its file. LABEL is "Main" or "Second";
# DEFAULT_KEY may contain LOGIN, replaced by the login given. Prints the login.
gid_configure_account() {
  local label="$1" default_key="$2" login file email name key
  login="$(gid_ask "$label GitHub login")" || return 1
  case "$login" in
    "" | *[!A-Za-z0-9-]*)
      gid_err "'$login' is not a GitHub login"
      return 1 ;;
  esac
  file="$(gid_config_dir)/accounts/$login"
  if [ -f "$file" ]; then
    email="$(gid_field "$file" email)"
    name="$(gid_field "$file" name)"
    default_key="$(gid_field "$file" ssh_key)"
  fi
  email="$(gid_ask "Email on commits as $login" "$email")" || return 1
  if [ -z "$email" ]; then
    gid_err "$login needs an email for commits"
    return 1
  fi
  name="$(gid_ask "Name on commits as $login (blank keeps git's user.name)" "$name")" || return 1
  key="$(gid_ask "SSH key for $login" "${default_key//LOGIN/$login}")" || return 1
  gid_write "$file" "email=$email
name=$name
ssh_key=$key" || return 1
  printf '%s\n' "$login"
}

gid_configure() {
  local dir main second key
  dir="$(gid_config_dir)"
  mkdir -p "$dir/accounts" || return 1
  printf 'The account you use most, already signed in to gh.\n' >&2
  main="$(gid_configure_account Main '~/.ssh/id_ed25519')" || return 1
  printf '\nThe second account, which gets its own SSH key.\n' >&2
  second="$(gid_configure_account Second '~/.ssh/id_ed25519_LOGIN')" || return 1
  if [ "$main" = "$second" ]; then
    gid_err "the two logins must differ"
    return 1
  fi
  key="$(gid_field "$dir/accounts/$second" ssh_key)"
  case "$key" in "~/"*) key="$HOME/${key:2}" ;; esac
  gid_write "$dir/setup.env" "$(printf 'MAIN_LOGIN=%q\nSECOND_LOGIN=%q\nSECOND_EMAIL=%q\nSECOND_KEY=%q' \
    "$main" "$second" "$(gid_field "$dir/accounts/$second" email)" "$key")" || return 1
  printf '\nWrote %s/accounts/%s, %s/accounts/%s and %s/setup.env\n' \
    "$dir" "$main" "$dir" "$second" "$dir"
}
