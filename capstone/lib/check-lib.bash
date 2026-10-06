# capstone/lib/check-lib.bash — helpers shared by the check.sh scripts of the capstone stages.
# Sourced, never run.
#
# A check script inspects the sandbox with read-only Git commands and exits 0 when the stage is
# complete. It never moves a ref, never writes an object and never touches an index. To run the
# project's tests it exports a commit into a temporary directory outside every repository and
# removes the directory again.
#   capstone/stage-NN-slug/check.sh            checks $GIT_MASTERY_LABS/capstone/intent-router
#   capstone/stage-NN-slug/check.sh <path>     checks the sandbox at <path>

check_begin() {   # check_begin <stage number> [<sandbox path>]
  . "$(cd "$(dirname "${BASH_SOURCE[0]}")/../../labs/lib" && pwd)/lab-env.sh"
  _lab_env
  CHK_STAGE="$1"
  CHK_DIR="${2:-$LAB_ROOT/capstone/intent-router}"
  if [ ! -d "$CHK_DIR/server.git" ]; then
    printf 'No capstone sandbox at %s\nRun capstone/setup.sh first.\n' "$CHK_DIR" >&2
    exit 2
  fi
  export GIT_CONFIG_GLOBAL="$CHK_DIR/home/.gitconfig"
  export GIT_OPTIONAL_LOCKS=0            # "git status" must not refresh an index file
  unset GIT_AUTHOR_DATE GIT_COMMITTER_DATE GIT_AUTHOR_NAME GIT_AUTHOR_EMAIL GIT_COMMITTER_NAME GIT_COMMITTER_EMAIL
  cd "$CHK_DIR" || exit 2
  S=server.git
  _chk_fail=0
  _chk_tmp=""
  trap '[ -n "$_chk_tmp" ] && rm -rf "$_chk_tmp"' EXIT
  have=$(cat .capstone-stage 2>/dev/null || echo 0)
  printf 'Checking capstone stage %s\n' "$CHK_STAGE"
  if [ "$have" -lt "$CHK_STAGE" ]; then
    printf '  FAIL  the incident of stage %s has not been applied to this sandbox (it is at stage %s)\n' "$CHK_STAGE" "$have"
    printf 'NOT YET: run the inject script of the stage first.\n'
    exit 1
  fi
}

ok()  { printf '  ok    %s\n' "$1"; }
bad() { printf '  FAIL  %s\n' "$1"; _chk_fail=$((_chk_fail + 1)); }

# expect '<description>' <command...>: the command must succeed.
expect() { local d="$1"; shift; if "$@" > /dev/null 2>&1; then ok "$d"; else bad "$d"; fi; }
# expect_not '<description>' <command...>: the command must fail.
expect_not() { local d="$1"; shift; if "$@" > /dev/null 2>&1; then bad "$d"; else ok "$d"; fi; }

# has_subject <repository> <revision range> '<subject>': is there a commit with this exact subject?
has_subject() { git -C "$1" log --format=%s "$2" 2>/dev/null | grep -Fxq -- "$3"; }
# count_subject <repository> <revision range> '<subject>': how many commits have this subject?
count_subject() { git -C "$1" log --format=%s "$2" 2>/dev/null | grep -Fxc -- "$3"; }
# once '<description>' <repository> <range> '<subject>': exactly one such commit.
once() {
  local n; n=$(count_subject "$2" "$3" "$4")
  if [ "$n" = 1 ]; then ok "$1"; else bad "$1 (found $n times, expected once)"; fi
}

# export_tree <repository> <revision>: print a temporary directory that holds the files of that
# commit. Fails when the revision does not exist.
export_tree() {
  local d
  git -C "$1" rev-parse -q --verify "$2^{commit}" > /dev/null 2>&1 || return 1
  [ -n "$_chk_tmp" ] || _chk_tmp=$(mktemp -d "${TMPDIR:-/tmp}/capstone-check.XXXXXX") || return 1
  d="$_chk_tmp/$(printf '%s' "$1-$2" | tr -c 'A-Za-z0-9.-' '_')"
  if [ ! -d "$d" ]; then
    mkdir -p "$d" && git -C "$1" archive "$2" | tar -x -C "$d" || return 1
  fi
  printf '%s\n' "$d"
}

# tests_pass <repository> <revision>: the project's own test script passes on that commit.
tests_pass() { local d; d=$(export_tree "$1" "$2") || return 1; bash "$d/scripts/test.sh" > /dev/null 2>&1; }

# py_true <repository> <revision> '<python expression>': the expression is true in that commit.
py_true() {
  local d; d=$(export_tree "$1" "$2") || return 1
  ( cd "$d" && PYTHONDONTWRITEBYTECODE=1 python3 -c "import sys
from router.keywords import *
from router.scoring import *
from router.classify import *
sys.exit(0 if ($3) else 1)" ) > /dev/null 2>&1
}

# pr_state <number>: open, merged or closed, as the pull-request stand-in recorded it.
pr_state() { sed -n 's/^state=//p' "$S/pulls/$1" 2>/dev/null; }
# pr_of <head branch>: the number of the newest pull request with that head branch.
pr_of() {
  local n
  for n in $(ls "$S/pulls" 2>/dev/null | grep -E '^[0-9]+$' | sort -rn); do
    [ "$(sed -n 's/^head=//p' "$S/pulls/$n")" = "$1" ] && { echo "$n"; return 0; }
  done
  return 1
}

# in_progress <clone>: is a merge, rebase, cherry-pick, revert or bisect unfinished there?
in_progress() {
  local g="$1/.git"
  [ -e "$g/MERGE_HEAD" ] || [ -e "$g/CHERRY_PICK_HEAD" ] || [ -e "$g/REVERT_HEAD" ] || [ -e "$g/BISECT_LOG" ] \
    || [ -d "$g/rebase-merge" ] || [ -d "$g/rebase-apply" ]
}

check_end() {
  if [ "$_chk_fail" -eq 0 ]; then
    printf 'PASS: the Git state of stage %s is as required. The written deliverables are judged separately.\n' "$CHK_STAGE"
    exit 0
  fi
  printf 'NOT YET: %s check(s) failed.\n' "$_chk_fail"
  exit 1
}
