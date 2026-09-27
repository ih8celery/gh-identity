# Shared by ./install and ./uninstall: where the links go, what a
# git|gh|both argument means, and whether a file there is our link.

gid_bin_dir() {
  printf '%s\n' "${GH_IDENTITY_BIN:-$HOME/.local/bin}"
}

# The wrappers WHICH (git|gh|both) stands for, one per line.
gid_targets() {
  case "${1:-}" in
    git | gh) printf '%s\n' "$1" ;;
    both) printf 'git\ngh\n' ;;
    *)
      gid_err "say which: git, gh or both"
      return 2 ;;
  esac
}

# True when LINK is a symlink to this checkout's bin/NAME.
gid_owned() {
  [ -L "$1" ] && [ "$1" -ef "$GID_HOME/bin/$2" ]
}
