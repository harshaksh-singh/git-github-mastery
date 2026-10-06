# labs/ex1/replay-lib.bash — helpers for the replay scripts of the generated exercises
# (solve-mNN-<slug>.sh). Sourced after labs/lib/lab-env.sh and lab_begin. Never run directly.

# exercise_load <name>: build the exercise inside the replay sandbox by sourcing its generator,
# then prove that check.sh rejects the untouched state. A check that passed here would be
# worthless, so the replay stops with status 98.
exercise_load() {
  EXN="$1"
  LAB_REPLAY=1 . "$COURSE_ROOT/exercises/gen/$1/generate.sh"
  cd "$LAB_DIR" || exit 97
  if bash "$COURSE_ROOT/exercises/gen/$EXN/check.sh" "$LAB_DIR" > /dev/null 2>&1; then
    printf 'replay: check.sh passes on the freshly generated exercise %s\n' "$EXN" >&4
    exit 98
  fi
}

# show_check: print the check as the learner types it (from the course root) and run it against
# the replay sandbox. The exit status is kept for exercise_done.
show_check() {
  printf '$ exercises/gen/%s/check.sh\n' "$EXN"
  bash "$COURSE_ROOT/exercises/gen/$EXN/check.sh" "$LAB_DIR"
  EX_RC=$?
  printf '[exit status: %s]\n' "$EX_RC"
}

# exercise_done: close the replay. A replay whose final check did not pass is a failed replay.
exercise_done() {
  lab_end
  [ "${EX_RC:-1}" -eq 0 ] || { printf 'replay: final check failed for %s\n' "$EXN" >&2; exit 99; }
}
