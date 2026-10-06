# labs/ex2/replay-lib.bash — helpers for the replay scripts of the Module 11 to 18 exercises.
# Sourced after labs/lib/lab-env.sh and lab_begin. Never run directly.

# ex_load <generator name>: build the exercise inside the replay sandbox by sourcing its
# generator. If the exercise has a check.sh, prove that it rejects the untouched state: a check
# that passes here would be worthless, so the replay stops with status 98.
ex_load() {
  EXG="$1"
  LAB_REPLAY=1 . "$COURSE_ROOT/exercises/gen/$1/generate.sh"
  cd "$LAB_DIR" || exit 97
  EX_RC=0
  if [ -f "$COURSE_ROOT/exercises/gen/$EXG/check.sh" ]; then
    EX_RC=1
    if bash "$COURSE_ROOT/exercises/gen/$EXG/check.sh" "$LAB_DIR" > /dev/null 2>&1; then
      printf 'replay: check.sh passes on the freshly generated exercise %s\n' "$EXG" >&4
      exit 98
    fi
  fi
}

# show_check: print the check as the learner types it (from the course root) and run it against
# the replay sandbox. The exit status is kept for ex_done.
show_check() {
  printf '$ exercises/gen/%s/check.sh\n' "$EXG"
  bash "$COURSE_ROOT/exercises/gen/$EXG/check.sh" "$LAB_DIR"
  EX_RC=$?
  printf '[exit status: %s]\n' "$EX_RC"
}

# ex_done: close the replay. A replay whose final check did not pass is a failed replay.
ex_done() {
  lab_end
  [ "${EX_RC:-1}" -eq 0 ] || { printf 'replay: final check failed for %s\n' "$EXG" >&2; exit 99; }
}

# sid '<subject>' [<revision>...]: short ID of the newest commit with exactly this subject
# (searched in all refs unless revisions are given). Replays capture IDs with it instead of
# hardcoding them.
sid() {
  local s="$1"; shift
  [ $# -gt 0 ] || set -- --all
  git log --format='%h %s' "$@" | awk -v s="$s" '{h=$1; sub(/^[^ ]+ /,""); if ($0 == s) {print h; exit}}'
}
