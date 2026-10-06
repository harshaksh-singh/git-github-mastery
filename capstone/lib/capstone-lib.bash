# capstone/lib/capstone-lib.bash — helpers shared by setup.sh, the stage inject scripts and the
# replay scripts of the capstone. Sourced, never run.
#
# The sandbox ($GIT_MASTERY_LABS/capstone/intent-router) has this layout:
#   server.git   a bare repository: the server, the part GitHub plays in real life
#   pr           a small script that plays the pull-request side of GitHub (capstone/lib/pr.sh)
#   you/         your clone
#   nandini/ kabir/ tanvi/   your teammates' clones, each with its own user.name and user.email
#   evidence/    files that an inject script writes for a stage (alerts, run reports)
#   .capstone-stage          the number of the stage that was injected last

if [ -z "${LAB_LIB:-}" ]; then
  . "$(cd "$(dirname "${BASH_SOURCE[0]}")/../../labs/lib" && pwd)/lab-env.sh"
fi
CAP_NAME=intent-router
CAP_HOME="$COURSE_ROOT/capstone"
CAP_DAY=86400

# cap_slug <n>: directory name of stage n, without the "stage-" prefix.
cap_slug() {
  case "$1" in
    1) echo 01-bug-in-production ;;
    2) echo 02-merge-conflict ;;
    3) echo 03-leaked-secret ;;
    4) echo 04-failed-ci ;;
    5) echo 05-lost-work ;;
    6) echo 06-deleted-branch ;;
    7) echo 07-broken-pull-request ;;
    8) echo 08-hotfix-and-backport ;;
    *) return 1 ;;
  esac
}

# cap_as <person>: switch identity. you, nandini, kabir, tanvi.
cap_as() {
  local n e
  case "$1" in
    you)     n="Lab User";     e="you@example.com" ;;
    nandini) n="Nandini Iyer"; e="nandini@example.com" ;;
    kabir)   n="Kabir Sethi";  e="kabir@example.com" ;;
    tanvi)   n="Tanvi Desai";  e="tanvi@example.com" ;;
    *) _lab_die "cap_as: unknown person '$1'" ;;
  esac
  export GIT_AUTHOR_NAME="$n" GIT_AUTHOR_EMAIL="$e" GIT_COMMITTER_NAME="$n" GIT_COMMITTER_EMAIL="$e"
}

# cap_at <day> [<minutes>]: put the lab clock at 10:00 on the given day (day 0 is Monday
# 7 September 2026) plus the given minutes. Every stage starts at a fixed time, so the commit
# IDs of a stage do not depend on how many commands the stages before it used.
cap_at() { _lab_clock=$((LAB_EPOCH_BASE + $1 * CAP_DAY + ${2:-0} * 60)); tick; }

# cap_stage_day <n>: the day on which stage n happens.
cap_stage_day() {
  case "$1" in 1) echo 7 ;; 2) echo 8 ;; 3) echo 9 ;; 4) echo 10 ;; 5) echo 11 ;; 6) echo 14 ;; 7) echo 15 ;; 8) echo 16 ;; esac
}

# _c '<message>': commit everything in the working tree with one tick of the lab clock.
_c() { quiet "git add -A && git commit -m \"$1\""; }

# _cp '<message>' <path>...: commit exactly these paths with one tick of the lab clock. The
# inject scripts use it in clones that a learner has worked in, where "git add -A" could pick
# up something that is not part of the incident.
_cp() { local m="$1"; shift; quiet "git add -f -- $* && git commit -m \"$m\" -- $*"; }

# cap_go <person>: enter that person's clone and act as that person.
cap_go() { cd "$LAB_DIR/$1" || _lab_die "no clone $1"; cap_as "$1"; }

# cap_clone <person>: clone the server for a person and store the identity in the clone.
cap_clone() {
  cd "$LAB_DIR" || return 1
  quiet "git clone server.git $1"
  quiet "git -C $1 remote set-url origin ../server.git"
  cap_as "$1"
  quiet "git -C $1 config set user.name '$GIT_AUTHOR_NAME' && git -C $1 config set user.email $GIT_AUTHOR_EMAIL"
}

# cap_pr <arguments>: run the pull-request stand-in silently, as the current person. A setup
# or inject script cannot continue when this fails, so it stops.
cap_pr() { quiet "\"\$LAB_DIR/pr\" $*" || cap_fail "the pull request step failed: pr $*"; }

# cap_fail <message>: stop a setup or inject script whose precondition does not hold.
cap_fail() {
  printf 'capstone: %s\nThe sandbox is not in the state this stage builds on. Rebuild it: capstone/setup.sh --stage N\n' "$1" >&2
  exit 3
}

# cap_attach [<sandbox path>]: point the environment at an existing capstone sandbox.
cap_attach() {
  _lab_env
  LAB_CH=capstone; LAB_DEMO=$CAP_NAME
  LAB_DIR="${1:-$LAB_ROOT/capstone/$CAP_NAME}"
  if [ ! -d "$LAB_DIR/server.git" ]; then
    printf 'No capstone sandbox at %s\nRun capstone/setup.sh first.\n' "$LAB_DIR" >&2
    exit 2
  fi
  export LAB_DIR LAB_CH LAB_DEMO
  export GIT_CONFIG_GLOBAL="$LAB_DIR/home/.gitconfig"
  export XDG_CONFIG_HOME="$LAB_DIR/home/.config"
  export GNUPGHOME="$LAB_DIR/home/.gnupg"
  cd "$LAB_DIR" || exit 2
}

# cap_inject_begin <n> [--force] [<sandbox path>]
# Standalone (a learner runs capstone/stage-NN-slug/inject.sh): attach to the sandbox, refuse
# unless the previous stage was injected and its check passes. Inside setup.sh or a replay
# (CAP_REPLAY is set) the caller has done that already.
cap_inject_begin() {
  local n="$1" force="" path="" a prev have
  shift
  for a in "$@"; do case "$a" in --force) force=1 ;; /*) path="$a" ;; esac; done
  if [ -z "${CAP_REPLAY:-}" ]; then
    cap_attach "$path"
    prev=$((n - 1))
    have=$(cat "$LAB_DIR/.capstone-stage" 2>/dev/null || echo 0)
    if [ "$have" -ge "$n" ]; then
      printf 'Stage %s is already injected in %s.\nTo retake it: capstone/setup.sh --stage %s\n' "$n" "$LAB_DIR" "$n" >&2
      exit 2
    fi
    if [ -z "$force" ]; then
      if [ "$have" -ne "$prev" ]; then
        printf 'The sandbox is at stage %s. Stage %s builds on stage %s.\nTo jump there: capstone/setup.sh --stage %s\n' "$have" "$n" "$prev" "$n" >&2
        exit 2
      fi
      if [ "$prev" -ge 1 ] && ! bash "$CAP_HOME/stage-$(cap_slug "$prev")/check.sh" "$LAB_DIR" > /dev/null 2>&1; then
        printf 'Stage %s is not finished: capstone/stage-%s/check.sh does not pass.\n' "$prev" "$(cap_slug "$prev")" >&2
        printf 'Finish it, or build stage %s from the model solutions: capstone/setup.sh --stage %s\n' "$n" "$n" >&2
        exit 2
      fi
    fi
  fi
  cap_at "$(cap_stage_day "$n")"
  cd "$LAB_DIR" || exit 2
  mkdir -p "$LAB_DIR/evidence"
}

# cap_inject_end <n>: record the stage, return to the sandbox root as yourself.
cap_inject_end() {
  cap_as you
  cd "$LAB_DIR" || exit 2
  printf '%s\n' "$1" > "$LAB_DIR/.capstone-stage"
  if [ -z "${CAP_REPLAY:-}" ]; then
    printf 'Stage %s is ready in %s\n' "$1" "$LAB_DIR"
    printf 'Read capstone/stage-%s/BRIEFING.md, then open a lab shell:\n  labs/shell "%s/you"\n' "$(cap_slug "$1")" "$LAB_DIR"
  fi
}

# cap_inject <n>: apply stage n inside setup.sh or a replay.
cap_inject() { CAP_REPLAY=1 . "$CAP_HOME/stage-$(cap_slug "$1")/inject.sh"; cd "$LAB_DIR" || exit 2; }

# cap_model <n>: apply the model solution of stage n without showing anything. The model
# solutions are the replay bodies in labs/capstone/model-NN-slug.bash; csnip and cshow_check
# (below) do nothing in silent mode.
cap_model() {
  CAP_SILENT=1
  CAP_STAGE="$1"
  . "$COURSE_ROOT/labs/capstone/model-$(cap_slug "$1").bash" > /dev/null 2>&1
  CAP_SILENT=""
  cap_as you
  cd "$LAB_DIR" || exit 2
}

# cap_build_to <n>: the company repository, then stages 1 to n-1 with their model solutions,
# then the incident of stage n. Stage 0 is the company repository alone.
cap_build_to() {
  local k
  . "$CAP_HOME/lib/base.bash"
  cap_build_base
  k=1
  while [ "$k" -le "$1" ]; do
    cap_inject "$k"
    [ "$k" -lt "$1" ] && cap_model "$k"
    k=$((k + 1))
  done
  cap_as you
  cd "$LAB_DIR" || exit 2
}

# csnip <name>: start a snippet, unless a model solution is being applied silently.
csnip() { [ -n "${CAP_SILENT:-}" ] || snip "$1"; }

# cap_check <n>: run the check of stage n against the current sandbox; exit status is the check's.
cap_check() { bash "$CAP_HOME/stage-$(cap_slug "$1")/check.sh" "$LAB_DIR"; }

# cshow_check: print the check as the learner types it (from the course root) and run it.
cshow_check() {
  [ -z "${CAP_SILENT:-}" ] || return 0
  printf '$ capstone/stage-%s/check.sh\n' "$(cap_slug "$CAP_STAGE")"
  cap_check "$CAP_STAGE"
  CAP_RC=$?
  printf '[exit status: %s]\n' "$CAP_RC"
}
