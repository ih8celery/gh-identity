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
