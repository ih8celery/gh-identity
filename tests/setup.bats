#!/usr/bin/env bats
# lib/runbook.sh and ./setup: SETUP.md read as steps, each shown, asked
# about, and run in its own bash.

load helpers

setup() {
  gid_test_setup
  . "$REPO/lib/identity.sh"
  . "$REPO/lib/runbook.sh"
  export GH_IDENTITY_SETUP_FILE="$REPO/tests/fixtures/steps.md"
}

@test "numbered headings are steps; other headings end them" {
  rb_parse "$GH_IDENTITY_SETUP_FILE"
  [ "$RB_COUNT" -eq 4 ]
  [ "${RB_NUM[0]}" = 0 ]
  [ "${RB_TITLE[0]}" = First ]
  [ "${RB_CODE[0]}" = "echo hello-from-zero"$'\n' ]
  [ -z "${RB_CODE[1]}" ]
  [ "${RB_NUM[3]}" = 10 ]
  [ "${RB_CODE[3]}" = "echo hello-from-ten"$'\n' ]
}

@test "prose keeps the words and leaves out the code" {
  rb_parse "$GH_IDENTITY_SETUP_FILE"
  [[ "${RB_PROSE[0]}" == *"Say hello."* ]] || false
  [[ "${RB_PROSE[0]}" != *"echo"* ]] || false
  [[ "${RB_PROSE[2]}" != *"Not a step"* ]] || false
}

@test "headings inside a non-bash fence are prose, not steps" {
  rb_parse "$GH_IDENTITY_SETUP_FILE"
  [ "$RB_COUNT" -eq 4 ]
  [ "${RB_TITLE[1]}" = "Only words" ]
  [[ "${RB_PROSE[1]}" == *"## 5. Not a step, just output"* ]] || false
  [ -z "${RB_CODE[1]}" ]
  [ "${RB_NUM[2]}" = 2 ]
}

@test "yes runs a step, skip does not, quit says how to resume" {
  run "$REPO/setup" <<'EOF'
y
q
EOF
  [ "$status" -eq 0 ]
  [[ "$output" == *"hello-from-zero"* ]] || false
  [ "$(grep -c about-to-fail <<<"$output")" -eq 1 ]  # shown before the question, never run
  [[ "$output" == *"./setup --from 2"* ]] || false
}

@test "--from starts at that step" {
  run "$REPO/setup" --from 10 <<'EOF'
y
EOF
  [ "$status" -eq 0 ]
  [[ "$output" != *"hello-from-zero"* ]] || false
  [[ "$output" == *"hello-from-ten"* ]] || false
  [[ "$output" == *"All steps done"* ]] || false
}

@test "a failed step can be retried, then skipped" {
  run "$REPO/setup" --from 2 <<'EOF'
y
r
s
s
EOF
  [ "$status" -eq 0 ]
  [ "$(grep -c about-to-fail <<<"$output")" -eq 3 ]
  [[ "$output" == *"Step 2 failed (exit 4)"* ]] || false
  [[ "$output" != *"never-run"* ]] || false
}

@test "quitting after a failure fails" {
  run "$REPO/setup" --from 2 <<'EOF'
y
q
EOF
  [ "$status" -eq 1 ]
}

@test "a bad --from is refused" {
  run "$REPO/setup" --from two
  [ "$status" -eq 2 ]
}

@test "the real SETUP.md is steps 0 to 9, each with something to run" {
  rb_parse "$REPO/SETUP.md"
  [ "$RB_COUNT" -eq 10 ]
  local i
  for ((i = 0; i < 10; i++)); do
    [ "${RB_NUM[i]}" = "$i" ]
    [ -n "${RB_CODE[i]}" ]
  done
}
