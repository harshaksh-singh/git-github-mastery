# labs/incidents/replay-lib.bash — helpers for the incident replay scripts (solve-NN-slug.sh).
# Sourced after labs/lib/lab-env.sh and lab_begin. Never run directly.

# incident_load <name>: build the incident inside the replay sandbox by sourcing its generator,
# then prove that check.sh rejects the untouched incident. If the check passed here it would be
# worthless, so the replay stops with status 98.
incident_load() {
  INC="$1"
  LAB_REPLAY=1 . "$COURSE_ROOT/incidents/$1/generate.sh"
  cd "$LAB_DIR" || exit 97
  if bash "$COURSE_ROOT/incidents/$INC/check.sh" "$LAB_DIR" > /dev/null 2>&1; then
    printf 'replay: check.sh passes on the freshly generated incident %s\n' "$INC" >&4
    exit 98
  fi
}

# show_check: print the check as the learner types it (from the course root) and run it against
# the replay sandbox. The exit status is kept for incident_done.
show_check() {
  printf '$ incidents/%s/check.sh\n' "$INC"
  bash "$COURSE_ROOT/incidents/$INC/check.sh" "$LAB_DIR"
  INC_RC=$?
  printf '[exit status: %s]\n' "$INC_RC"
}

# incident_done: close the replay. A replay whose final check did not pass is a failed replay.
incident_done() {
  lab_end
  [ "${INC_RC:-1}" -eq 0 ] || { printf 'replay: final check failed for %s\n' "$INC" >&2; exit 99; }
}
