# Shared by bin/git, bin/gh and bin/gh-identity: which folder a command acts
# in, which account the user's chooser picks for it, that account's
# settings, and where the real command is.
#
# bash 3.2 compatible: it is what macOS ships as /bin/bash.

gid_err() {
  printf 'gh-identity: %s\n' "$*" >&2
}

gid_config_dir() {
  printf '%s\n' "${GH_IDENTITY_CONFIG:-$HOME/.config/gh-identity}"
}

# The folder git will act in: the current one, moved by each leading -C.
# Stops at the first argument that is not an option (the subcommand).
gid_git_dir() {
  local dir="$PWD"
  while [ $# -gt 0 ]; do
    case "$1" in
      -C)
        [ $# -ge 2 ] || break
        case "$2" in
          /*) dir="$2" ;;
          *) dir="$dir/$2" ;;
        esac
        shift 2 ;;
      -c)
        [ $# -ge 2 ] || break
        shift 2 ;;
      -*) shift ;;
      *) break ;;
    esac
  done
  printf '%s\n' "$dir"
}

# Ask the user's chooser which account DIR belongs to. Prints one login, or
# nothing for "no opinion". Fails when the chooser fails or prints something
# that cannot be a GitHub login: guessing is how the wrong account gets used.
gid_choose() {
  local dir="$1" chooser login
  chooser="$(gid_config_dir)/account.sh"
  [ -f "$chooser" ] || return 0
  [ -d "$dir" ] || return 0
  if ! login="$(cd "$dir" && . "$chooser" && gh_identity_account)"; then
    gid_err "the chooser in $chooser failed in $dir"
    return 1
  fi
  case "$login" in
    "") return 0 ;;
    *[!A-Za-z0-9-]*)
      gid_err "the chooser printed '$login', which is not a GitHub login"
      return 1 ;;
  esac
  printf '%s\n' "$login"
}

# The value of KEY in a file of KEY=value lines, or nothing.
gid_field() {
  local file="$1" key="$2" line
  while IFS= read -r line || [ -n "$line" ]; do
    case "$line" in
      "$key="*) printf '%s\n' "${line#*=}"; return 0 ;;
    esac
  done < "$file"
}

# Load LOGIN's account file into GID_EMAIL, GID_NAME and GID_SSH_KEY.
gid_load() {
  local login="$1" file
  file="$(gid_config_dir)/accounts/$login"
  if [ ! -f "$file" ]; then
    gid_err "the chooser picked $login, but $file does not exist (SETUP.md step 0)"
    return 1
  fi
  GID_EMAIL="$(gid_field "$file" email)"
  GID_NAME="$(gid_field "$file" name)"
  GID_SSH_KEY="$(gid_field "$file" ssh_key)"
  case "$GID_SSH_KEY" in
    "~/"*) GID_SSH_KEY="$HOME/${GID_SSH_KEY:2}" ;;
  esac
  if [ -z "$GID_EMAIL" ] || [ -z "$GID_SSH_KEY" ]; then
    gid_err "$file needs both an email= and an ssh_key= line (SETUP.md step 0)"
    return 1
  fi
  if [ ! -f "$GID_SSH_KEY" ]; then
    gid_err "$login's SSH key $GID_SSH_KEY does not exist (SETUP.md step 4)"
    return 1
  fi
}

# Make git, and anything git starts, act as the loaded account.
gid_export_git_env() {
  export GIT_SSH_COMMAND="ssh -i '$GID_SSH_KEY' -o IdentitiesOnly=yes"
  export GIT_AUTHOR_EMAIL="$GID_EMAIL" GIT_COMMITTER_EMAIL="$GID_EMAIL"
  if [ -n "$GID_NAME" ]; then
    export GIT_AUTHOR_NAME="$GID_NAME" GIT_COMMITTER_NAME="$GID_NAME"
  fi
}

# The first NAME on PATH that is not the file SELF, however SELF was
# reached: directly, or through a symlink such as ~/.local/bin/git.
gid_real() {
  local name="$1" self="$2" dir candidate
  local IFS=:
  for dir in $PATH; do
    candidate="${dir:-.}/$name"
    [ -f "$candidate" ] && [ -x "$candidate" ] || continue
    [ "$candidate" -ef "$self" ] && continue
    printf '%s\n' "$candidate"
    return 0
  done
  gid_err "no real $name on PATH apart from gh-identity's own"
  return 1
}
