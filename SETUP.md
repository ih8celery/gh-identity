# Setting up gh-identity

Two GitHub accounts on one machine, with `git` and `gh` acting as the right
one for each project on their own.

Read this as a guide, copy any step's block into a terminal opened in this
folder, or run the whole thing with `./setup`, which shows each step and asks
before running it. `./setup --from 4` picks up at step 4.

Every block stands alone. The ones that need your details load them from
`~/.config/gh-identity/setup.env`, which step 0 writes.

Two words used throughout. Your **main** account is the one you use most,
and it is probably already signed in to `gh`. Your **second** account is the
other one, and it gets its own SSH key.

## 0. Your details

This asks for each account's login, the email and name its commits should
carry, and its SSH key. It writes one file per account to
`~/.config/gh-identity/accounts/`, plus `setup.env`. Run it again any time;
it offers what is already there as each default.

To do it by hand instead, write `accounts/<login>` files with `email=`,
`name=` and `ssh_key=` lines, and a `setup.env` with `MAIN_LOGIN`,
`SECOND_LOGIN`, `SECOND_EMAIL` and `SECOND_KEY`.

```bash
./bin/gh-identity configure
```

## 1. Check the tools are here

`git`, `gh` (GitHub's CLI), and ssh's own tools. Anything missing is named.

```bash
for tool in git gh ssh ssh-keygen; do
  command -v "$tool" >/dev/null || echo "missing: $tool"
done
echo "checked"
```

## 2. Your main account is signed in to gh

If it is not, this signs it in. Say yes to SSH as the protocol.

```bash
. ~/.config/gh-identity/setup.env
if gh auth token --hostname github.com --user "$MAIN_LOGIN" >/dev/null 2>&1; then
  echo "$MAIN_LOGIN is signed in"
else
  gh auth login --hostname github.com --git-protocol ssh
fi
```

## 3. Sign your second account in to gh

`gh` can hold both accounts at once, and keeps both tokens in the macOS
keychain. gh-identity asks it for the right one each time, and stores no
tokens itself.

Signing in opens a browser. *The browser must be signed in to GitHub as the
second account*: use a private window, or sign out of the main account
first, or you will authorize the wrong one. To use a browser other than
your default, name it in `GH_BROWSER`, which `gh` reads: for example
`GH_BROWSER='open -a Safari' ./setup --from 3`.

Signing in also makes the new account the active one for every terminal on
the machine, so the last line switches back to your main account.

```bash
. ~/.config/gh-identity/setup.env
if ! gh auth token --hostname github.com --user "$SECOND_LOGIN" >/dev/null 2>&1; then
  gh auth login --hostname github.com --git-protocol ssh --skip-ssh-key \
    --scopes admin:public_key
fi
gh auth switch --hostname github.com --user "$MAIN_LOGIN"
gh auth status --hostname github.com
```

## 4. Make the second account's SSH key

GitHub lets a key belong to only one account, so the second account cannot
reuse your main key. This makes a new one, unless it already exists. A
passphrase is up to you.

```bash
. ~/.config/gh-identity/setup.env
if [ -f "$SECOND_KEY" ]; then
  echo "$SECOND_KEY already exists"
else
  ssh-keygen -t ed25519 -C "$SECOND_EMAIL" -f "$SECOND_KEY"
fi
```

## 5. Give the key to the second account

This uploads the public half, using the second account's token for this one
command only.

```bash
. ~/.config/gh-identity/setup.env
GH_TOKEN="$(gh auth token --hostname github.com --user "$SECOND_LOGIN")" \
  gh ssh-key add "$SECOND_KEY.pub" --title "$(hostname -s) gh-identity"
```

## 6. Check GitHub knows the key

GitHub should answer "Hi" and your second login. It also says it does not
provide shell access; that is normal, and so is `ssh` exiting with 1 here.

```bash
. ~/.config/gh-identity/setup.env
ssh -i "$SECOND_KEY" -o IdentitiesOnly=yes -T git@github.com 2>&1 | grep -F "Hi $SECOND_LOGIN!"
```

## 7. Write your chooser

This is the one piece of logic that is yours: a shell function that looks at
the folder it runs in and prints which login it belongs to, or nothing to
leave `git` and `gh` alone. This copies the example, which shows a rule by
folder and a rule by a file in the project, and opens it to edit.

```bash
dest="$HOME/.config/gh-identity/account.sh"
[ -f "$dest" ] || cp examples/account.sh "$dest"
"${EDITOR:-vi}" "$dest"
```

## 8. Install the wrappers

This links `git`, `gh` and `gh-identity` into `~/.local/bin`, which must come
before the real ones on your `PATH`; it warns you if it does not. To remove
them later: `./uninstall both`.

```bash
./install both
```

## 9. Check it

Run this in a project of each kind. `gh-identity which` says which account
applies and whether everything it needs is in place; a project your chooser
has no opinion on says so.

```bash
hash -r
command -v git gh
gh-identity which
```
