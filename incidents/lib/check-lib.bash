# incidents/lib/check-lib.bash — helpers shared by the check.sh scripts. Sourced, never run.
#
# A check script inspects a sandbox with read-only commands and exits 0 when the recovery is
# complete. It never moves a ref, never writes an object and never touches the index.
#   incidents/NN-slug/check.sh            checks $GIT_MASTERY_LABS/incidents/NN-slug
#   incidents/NN-slug/check.sh <path>     checks the sandbox at <path>

check_begin() {   # check_begin <incident name> [<sandbox path>]
  . "$(cd "$(dirname "${BASH_SOURCE[0]}")/../../labs/lib" && pwd)/lab-env.sh"
  _lab_env
  INC_NAME="$1"
  INC_DIR="${2:-$LAB_ROOT/incidents/$1}"
  if [ ! -d "$INC_DIR/server.git" ]; then
    printf 'No incident sandbox at %s\nRun incidents/%s/generate.sh first.\n' "$INC_DIR" "$1" >&2
    exit 2
  fi
  export GIT_CONFIG_GLOBAL="$INC_DIR/home/.gitconfig"
  export GIT_OPTIONAL_LOCKS=0            # "git status" must not refresh the index file
  unset GIT_AUTHOR_DATE GIT_COMMITTER_DATE
  cd "$INC_DIR" || exit 2
  _chk_fail=0
  printf 'Checking incident %s\n' "$INC_NAME"
}

ok()  { printf '  ok    %s\n' "$1"; }
bad() { printf '  FAIL  %s\n' "$1"; _chk_fail=$((_chk_fail + 1)); }

# expect '<description>' <command...>: the command must succeed.
expect() { local d="$1"; shift; if "$@" > /dev/null 2>&1; then ok "$d"; else bad "$d"; fi; }
# expect_not '<description>' <command...>: the command must fail.
expect_not() { local d="$1"; shift; if "$@" > /dev/null 2>&1; then bad "$d"; else ok "$d"; fi; }

# has_subject <git dir or work tree> <revision> '<subject>': is a commit with this exact subject
# reachable from the revision?
has_subject() { git -C "$1" log --format=%s "$2" 2>/dev/null | grep -Fxq -- "$3"; }

check_end() {
  if [ "$_chk_fail" -eq 0 ]; then
    printf 'PASS: the recovery of incident %s is complete.\n' "$INC_NAME"
    exit 0
  fi
  printf 'NOT YET: %s check(s) failed.\n' "$_chk_fail"
  exit 1
}
