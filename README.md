# gh-identity

Two GitHub accounts on one Mac. `git` and `gh` act as the right one for each
project, on their own, one command at a time.

## How it works

You write one shell function, `gh_identity_account`, that looks at the
folder it runs in and prints a GitHub login, or nothing. `git` and `gh`
wrappers ask it before every command:

- **It prints nothing:** the real `git` or `gh` runs untouched.
- **It prints a login:** for that one command, git uses that account's SSH
  key and commit email, and `gh` also gets that account's token from `gh`'s
  own keychain.
- **Anything is missing** (the account's settings, its key, its sign-in):
  the command stops and says which step of `SETUP.md` fixes it. It never
  falls back to the other account.

Nothing is switched globally, so two terminals in different projects never
interfere.

## Setting up

`./setup` walks through `SETUP.md` step by step, or read it and copy the
steps yourself.

## Commands

```
gh-identity which [folder]   who git and gh would act as there
gh-identity configure        set up both accounts' details
./install git|gh|both        link the wrappers into ~/.local/bin
./uninstall git|gh|both      remove them again
```

## Where your details live

In `~/.config/gh-identity/` (or `$GH_IDENTITY_CONFIG`), never in this repo:

```
account.sh          your chooser
accounts/<login>    email=, name=, ssh_key= for each account
setup.env           what SETUP.md's steps need
```

## Limits

- Apps that run git by its full path, such as Xcode and GitHub Desktop,
  skip the wrapper.
- `git -C <folder>` is followed; `gh -R owner/repo` is not, since the
  chooser decides by folder.
- In a chosen project, that account's key is used for every ssh remote, not
  only github.com.
- github.com only, over ssh.

## Developing

`just test` runs the bats suites against fake `git` and `gh`; nothing touches
a real account. bash 3.2, since that is macOS's `/bin/bash`.
