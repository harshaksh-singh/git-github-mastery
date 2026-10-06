# labs/capstone/replay-lib.bash — helpers for the capstone replay scripts. Sourced after
# labs/lib/lab-env.sh, capstone/lib/capstone-lib.bash and lab_begin. Never run directly.

# cap_replay <n>: build the state at the start of stage n, prove that the stage's check rejects
# it, play the model solution with transcript capture, and require that the check then passes.
cap_replay() {
  cap_build_to "$1"
  CAP_STAGE="$1"
  if cap_check "$1" > /dev/null 2>&1; then
    printf 'replay: check.sh passes before stage %s is solved\n' "$1" >&4
    exit 98
  fi
  CAP_SILENT=""
  . "$COURSE_ROOT/labs/capstone/model-$(cap_slug "$1").bash"
  lab_end
  [ "${CAP_RC:-1}" -eq 0 ] || { printf 'replay: the final check of stage %s failed\n' "$1" >&2; exit 99; }
}
