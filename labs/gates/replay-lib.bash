# labs/gates/replay-lib.bash — helpers for the replay scripts of the gates' generated
# repositories (solve-gN-<variant>.sh). Sourced after labs/lib/lab-env.sh and lab_begin.
# Never run directly.

# gate_load <generator directory under assessments/gen>: build the repository inside the replay
# sandbox by sourcing its generator, then prove that check.sh rejects the untouched state. A
# check that passed here would be worthless, so the replay stops with status 98.
gate_load() {
  GEN="$1"
  LAB_REPLAY=1 . "$COURSE_ROOT/assessments/gen/$1/generate.sh"
  cd "$LAB_DIR" || exit 97
  if bash "$COURSE_ROOT/assessments/gen/$GEN/check.sh" "$LAB_DIR" > /dev/null 2>&1; then
    printf 'replay: check.sh passes on the freshly generated %s\n' "$GEN" >&4
    exit 98
  fi
}

# show_check: print the check as the learner types it (from the course root) and run it against
# the replay sandbox. The exit status is kept for gate_done.
show_check() {
  printf '$ assessments/gen/%s/check.sh\n' "$GEN"
  bash "$COURSE_ROOT/assessments/gen/$GEN/check.sh" "$LAB_DIR"
  G_RC=$?
  printf '[exit status: %s]\n' "$G_RC"
}

# gate_done: close the replay. A replay whose final check did not pass is a failed replay.
gate_done() {
  lab_end
  [ "${G_RC:-1}" -eq 0 ] || { printf 'replay: final check failed for %s\n' "$GEN" >&2; exit 99; }
}
