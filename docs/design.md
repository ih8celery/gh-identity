# gh-identity — design

## What it is for

One person, two GitHub accounts, one machine. `git` and `gh` should act as the
right account for whatever project they are run in, without anyone switching
by hand, and without one terminal's switch leaking into another.

It is written to be shared: nothing personal lives in the repository. Account
names, emails, key paths and the rule for choosing an account all live in the
user's own config directory, outside the repo.

## The one thing a user writes: the chooser

Which account a project belongs to is different for every person — a folder,
a remote URL, a file in the project. So the repo does not decide it. The user
writes one shell function:

```bash
# ~/.config/gh-identity/account.sh
gh_identity_account() {
  # Runs in the directory git or gh was called from.
  # Print one account name, or nothing for "no opinion".
  case "$PWD" in
    "$HOME"/work/*) echo my-work-login ;;
  esac
}
```

The contract, and all of it:

- It is called with the working directory set to where `git`/`gh` was run.
- It prints one GitHub login, or nothing.
- Nothing printed means "no opinion": the real command runs untouched, exactly
  as if gh-identity were not installed.
- A non-zero exit is an error: the command stops and says the chooser failed.

The repo ships `examples/account.sh` with the folder rule above and a second
rule that reads an `owner` field from a JSON file in the project, so a reader
sees both shapes.

## Per-account settings

One small file per account, `~/.config/gh-identity/accounts/<login>`:

```
email=me@example.com
name=Jane Example
ssh_key=~/.ssh/id_ed25519_work
```

`KEY=value` lines, no shell code, read by a parser rather than sourced. A
chooser that names a login with no file here is an error, not a fallback.

The config directory is `$GH_IDENTITY_CONFIG`, defaulting to
`~/.config/gh-identity`. Tests point it at a temporary directory.

## The parts

- **`lib/identity.sh`** — loads the chooser, runs it, reads the account file,
  and produces the settings for one command. Shared by everything below.
- **`bin/git`** — when an account is chosen, sets `GIT_SSH_COMMAND` (that key,
  with `IdentitiesOnly=yes` so ssh cannot offer a different key first) and
  `GIT_AUTHOR_*`/`GIT_COMMITTER_*` name and email, then runs the real git.
- **`bin/gh`** — the same, plus `GH_TOKEN` from
  `gh auth token --user <login>` (the token stays in the keychain where `gh`
  already keeps it; gh-identity stores no secrets).
- **`bin/gh-identity`** — `gh-identity which` prints, for the current
  directory, the chosen login (or "no opinion"), the key, the email, and
  whether the token and key are actually present.
- **`install` / `uninstall`** — `./install git|gh|both` symlinks the wrappers
  into `~/.local/bin` (overridable with `$GH_IDENTITY_BIN`); `./uninstall`
  removes only links that point back into this checkout.

"The real git" is the next `git` on `PATH` after the wrapper's own directory,
so the wrapper never calls itself.

## Hard stops, never a quiet fallback

Each of these refuses to run the command, prints what is wrong and which
`SETUP.md` step fixes it, and exits non-zero:

- the chooser exits non-zero;
- the chosen login has no account file, or the file lacks `email` or `ssh_key`;
- the named SSH key does not exist;
- (`gh` only) `gh auth token --user <login>` fails — that account is not
  signed in.

Falling back to the other account is the one failure this tool exists to
prevent, so it never does.

## SETUP.md and the runner

`SETUP.md` is a normal guide: prose, then a fenced `bash` block per step. It
can be read, copied from one block at a time, or run with `./setup`, which
walks the same file: shows each step's heading and prose, asks
run / skip / quit, and runs the block. All blocks run in one shell session,
so variables set early carry through. `./setup --from N` resumes at step N.

Step 0 asks for the logins, emails and key path with `read` prompts and writes
the config files; a reader copying by hand edits the variables at the top of
the block instead. No personal values appear in the file.

The steps: fill in your details; check prerequisites; confirm the first
account is signed in to `gh`; sign the second one in and switch the active
account back (signing in makes the new account active for every terminal);
make the second SSH key (GitHub allows a key on one account only); upload it
with the second account's token; test it with `ssh -T`; write the chooser;
install the wrappers; check with `gh-identity which` in one project of each
kind.

## Testing

bats. Fake "real" `git` and `gh` scripts placed later on `PATH` print the
environment they received. Tests cover: no opinion passes through untouched;
each hard stop; the settings produced for a chosen account; the wrapper not
calling itself; install and uninstall (including refusing to remove a link it
does not own); the runner's parsing of `SETUP.md` and `--from`. No test
touches a real account, key, or `~/.config`.

## Not in scope

GUI apps that call git by full path (Xcode, GitHub Desktop) bypass the
wrapper. Narrowing token scopes. Anything other than github.com.

