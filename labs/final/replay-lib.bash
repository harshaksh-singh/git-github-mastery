# labs/final/replay-lib.bash — helpers for the replay scripts of the final test's practical labs
# (solve-<name>.sh). Sourced after labs/lib/lab-env.sh and lab_begin. Never run directly.

# final_load <name>: build the lab inside the replay sandbox by sourcing its generator
# (assessments/gen/final-<name>/generate.sh), then prove that check.sh rejects the untouched
# state. A check that passed here would be worthless, so the replay stops with status 98.
final_load() {
  GEN="$1"
  LAB_REPLAY=1 . "$COURSE_ROOT/assessments/gen/final-$1/generate.sh"
  cd "$LAB_DIR" || exit 97
  if bash "$COURSE_ROOT/assessments/gen/final-$GEN/check.sh" "$LAB_DIR" > /dev/null 2>&1; then
    printf 'replay: check.sh passes on the freshly generated final-%s\n' "$GEN" >&4
    exit 98
  fi
}

# show_check: print the check as the learner types it (from the course root) and run it against
# the replay sandbox. The exit status is kept for final_done.
show_check() {
  printf '$ assessments/gen/final-%s/check.sh\n' "$GEN"
  bash "$COURSE_ROOT/assessments/gen/final-$GEN/check.sh" "$LAB_DIR"
  F_RC=$?
  printf '[exit status: %s]\n' "$F_RC"
}

# final_done: close the replay. A replay whose final check did not pass is a failed replay.
final_done() {
  lab_end
  [ "${F_RC:-1}" -eq 0 ] || { printf 'replay: final check failed for final-%s\n' "$GEN" >&2; exit 99; }
}
