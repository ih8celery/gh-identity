# Reads a guide like SETUP.md into steps and walks them. A step starts at a
# "## N. Title" heading and ends at the next heading of any kind. Its
# ```bash blocks are its code; every other line is its prose.

rb_parse() {
  local file="$1" line i=-1 in_step=0 in_code=0
  RB_NUM=() RB_TITLE=() RB_PROSE=() RB_CODE=()
  while IFS= read -r line || [ -n "$line" ]; do
    if [ "$in_code" = 1 ]; then
      if [ "$line" = '```' ]; then
        in_code=0
      elif [ "$in_step" = 1 ]; then
        RB_CODE[i]+="$line"$'\n'
      fi
      continue
    fi
    case "$line" in
      '## '[0-9]*'. '*)
        i=$((i + 1))
        in_step=1
        line="${line:3}"
        RB_NUM[i]="${line%%.*}"
        RB_TITLE[i]="${line#*. }"
        RB_PROSE[i]=""
        RB_CODE[i]="" ;;
      '#'*) in_step=0 ;;
      '```bash') in_code=1 ;;
      *) [ "$in_step" = 1 ] && RB_PROSE[i]+="$line"$'\n' ;;
    esac
  done < "$file"
  RB_COUNT=$((i + 1))
}

# Ask QUESTION until the answer is one of the letters in CHOICES; print it.
# End of input counts as q.
rb_ask() {
  local question="$1" choices="$2" answer
  while :; do
    printf '%s ' "$question" >&2
    IFS= read -r answer || { printf 'q\n'; return 0; }
    case "$answer" in
      ["$choices"]) printf '%s\n' "$answer"; return 0 ;;
    esac
  done
}

# Run step I's code until it succeeds or the user moves on. Returns 0 to go
# on to the next step, 1 when the user quits after a failure.
rb_run_step() {
  local i="$1" status
  while :; do
    bash -c "${RB_CODE[i]}"
    status=$?
    [ "$status" -eq 0 ] && return 0
    printf 'Step %s failed (exit %s).\n' "${RB_NUM[i]}" "$status"
    case "$(rb_ask "[r]etry / [s]kip / [q]uit?" rsq)" in
      s) return 0 ;;
      q)
        printf 'Stopped. Pick up here with: ./setup --from %s\n' "${RB_NUM[i]}"
        return 1 ;;
    esac
  done
}

# Walk every parsed step numbered FROM or later.
rb_run() {
  local from="$1" i
  for ((i = 0; i < RB_COUNT; i++)); do
    [ "${RB_NUM[i]}" -ge "$from" ] || continue
    printf '\n── %s. %s ──\n%s' "${RB_NUM[i]}" "${RB_TITLE[i]}" "${RB_PROSE[i]}"
    [ -n "${RB_CODE[i]}" ] || continue
    printf '%s' "${RB_CODE[i]}" | sed 's/^/    /'
    case "$(rb_ask "Run step ${RB_NUM[i]}? [y]es / [s]kip / [q]uit" ysq)" in
      s) continue ;;
      q)
        printf 'Stopped. Pick up here with: ./setup --from %s\n' "${RB_NUM[i]}"
        return 0 ;;
    esac
    rb_run_step "$i" || return 1
  done
  printf '\nAll steps done.\n'
}
