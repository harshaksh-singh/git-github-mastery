#!/usr/bin/env bash
# capstone/setup.sh — builds the capstone sandbox: the repository "intent-router" of the
# fictional company Tessaly, with a bare repository as the server and one clone per person.
#
#   capstone/setup.sh              the company repository with the incident of stage 1 applied
#   capstone/setup.sh --stage N    the state at the start of stage N (1 to 8): stages 1 to N-1 are
#                                  solved with the model solutions, then the incident of stage N
#                                  is applied. Use it to retake a stage or to skip one.
#   capstone/setup.sh --stage 0    the company repository alone, before any incident
#
# Every run deletes the sandbox and builds it afresh with the fixed lab clock, so the same
# command always produces the same commit IDs. Read capstone/README.md first.
. "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib/capstone-lib.bash"

stage=1
while [ $# -gt 0 ]; do
  case "$1" in
    --stage) stage="${2:-}"; shift 2 ;;
    --stage=*) stage="${1#--stage=}"; shift ;;
    *) printf 'usage: capstone/setup.sh [--stage N]   (N is 0 to 8)\n' >&2; exit 2 ;;
  esac
done
case "$stage" in [0-8]) ;; *) printf 'capstone/setup.sh: the stage must be a number from 0 to 8\n' >&2; exit 2 ;; esac

sandbox_begin capstone "$CAP_NAME"
cap_build_to "$stage" || exit 1

if [ "$stage" = 0 ]; then
  printf 'The company repository is ready in %s\nNo incident is applied. Look around:\n  labs/shell "%s/you"\n' "$LAB_DIR" "$LAB_DIR"
else
  printf 'Stage %s is ready in %s\n' "$stage" "$LAB_DIR"
  printf 'Read capstone/stage-%s/BRIEFING.md, then open a lab shell:\n  labs/shell "%s/you"\n' "$(cap_slug "$stage")" "$LAB_DIR"
fi
