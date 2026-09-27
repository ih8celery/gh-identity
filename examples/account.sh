# gh-identity's chooser. Copy to ~/.config/gh-identity/account.sh and edit.
#
# gh_identity_account runs in the folder git or gh acts in and prints one
# GitHub login, or nothing, which leaves git and gh untouched. Each login it
# prints needs a file in ~/.config/gh-identity/accounts/. A non-zero exit
# stops the command, so a broken rule cannot quietly pick the wrong account.
#
# Printing nothing is safer than printing your main login: a chosen account's
# SSH key is used for every ssh remote, not only github.com.

gh_identity_account() {
  # Rule 1, by folder: everything under ~/work is the work account.
  case "$PWD/" in
    "$HOME"/work/*) echo my-work-login; return ;;
  esac

  # Rule 2, by a file in the project: the nearest project.json's "owner".
  local dir="$PWD" owner
  while [ "$dir" != / ]; do
    if [ -f "$dir/project.json" ]; then
      owner="$(plutil -extract owner raw -o - "$dir/project.json" 2>/dev/null)"
      case "$owner" in
        work) echo my-work-login ;;
        *) echo my-main-login ;;
      esac
      return
    fi
    dir="$(dirname "$dir")"
  done
}
