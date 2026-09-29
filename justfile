# Development commands for gh-identity.
# bash 3.2 and bats. Nothing to build or install to develop it.

# List commands without starting work.
default:
    @just --list

# Explain one command: what it covers, what it needs, what success means.
help target="":
    #!/bin/sh
    case "{{target}}" in
      test)     echo "just test — every bats suite in tests/. Uses fake git and gh"
                echo "and a throwaway config; touches no real account. Needs bats." ;;
      lint)     echo "just lint — bash -n on every script. shellcheck is not installed,"
                echo "so syntax is the only static check." ;;
      premerge) echo "just premerge — lint, then test. Does not commit or push." ;;
      format|build|e2e)
                echo "just {{target}} — not supported here; run it to see why." ;;
      "")       echo "Usage: just help <target>. Targets: test lint premerge format build e2e" ;;
      *)        echo "Unknown target '{{target}}'. Targets: test lint premerge format build e2e" >&2; exit 1 ;;
    esac

# Run every bats suite.
test:
    bats tests

# Syntax-check every shell script.
lint:
    for f in bin/* lib/*.sh install uninstall setup examples/*.sh tests/helpers.bash; do [ -f "$f" ] || continue; bash -n "$f" || exit 1; done; echo "bash -n: ok"

# Lint, then test.
premerge: lint test

# Not supported: no formatter has been agreed for this project.
format:
    @echo "just format — not supported: no shell formatter is agreed here." >&2; exit 1

# Not supported: scripts run from the checkout; there is no artifact.
build:
    @echo "just build — not supported: nothing is built; ./install links the scripts." >&2; exit 1

# Not supported: the end-to-end check is SETUP.md's last step, run by hand.
e2e:
    @echo "just e2e — not supported: run ./setup --from 9 on a machine with both accounts." >&2; exit 1
