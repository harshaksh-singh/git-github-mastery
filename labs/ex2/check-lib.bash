# labs/ex2/check-lib.bash — helpers shared by the check.sh scripts of the generated exercises of
# Modules 11 to 18. Sourced, never run.
#
# A check script inspects a sandbox with read-only commands and exits 0 when the end state is
# right. It never moves a ref, never writes an object and never touches the index.
#   exercises/gen/<name>/check.sh            checks $GIT_MASTERY_LABS/exercises/<name>
#   exercises/gen/<name>/check.sh <path>     checks the sandbox at <path>

# check_begin <exercise name> <directory that must exist in the sandbox> [<sandbox path>]
check_begin() {
  . "$(cd "$(dirname "${BASH_SOURCE[0]}")/../lib" && pwd)/lab-env.sh"
  _lab_env
  EX_NAME="$1"
  EX_DIR="${3:-$LAB_ROOT/exercises/$1}"
  if [ ! -e "$EX_DIR/$2" ]; then
    printf 'No exercise sandbox at %s\nRun exercises/gen/%s/generate.sh first.\n' "$EX_DIR" "$1" >&2
    exit 2
  fi
  export GIT_CONFIG_GLOBAL="$EX_DIR/home/.gitconfig"
  export GIT_OPTIONAL_LOCKS=0            # "git status" must not refresh the index file
  unset GIT_AUTHOR_DATE GIT_COMMITTER_DATE
  cd "$EX_DIR" || exit 2
  _chk_fail=0
  printf 'Checking exercise %s\n' "$EX_NAME"
}

ok()  { printf '  ok    %s\n' "$1"; }
bad() { printf '  FAIL  %s\n' "$1"; _chk_fail=$((_chk_fail + 1)); }

# expect '<description>' <command...>: the command must succeed.
expect() { local d="$1"; shift; if "$@" > /dev/null 2>&1; then ok "$d"; else bad "$d"; fi; }
# expect_not '<description>' <command...>: the command must fail.
expect_not() { local d="$1"; shift; if "$@" > /dev/null 2>&1; then bad "$d"; else ok "$d"; fi; }
# same '<description>' <have> <want>: two strings must be equal and not empty.
same() { if [ -n "$2" ] && [ "$2" = "$3" ]; then ok "$1"; else bad "$1"; fi; }

# has_subject <repository> <revision> '<subject>': is a commit with this exact subject reachable?
has_subject() { git -C "$1" log --format=%s "$2" 2>/dev/null | grep -Fxq -- "$3"; }
# count_subject <repository> <revision> '<subject>': how many reachable commits carry the subject.
count_subject() { git -C "$1" log --format=%s "$2" 2>/dev/null | grep -Fxc -- "$3"; }
# id_of <repository> <revision range or --all> '<subject>': ID of the first commit with the subject.
id_of() { git -C "$1" log --format='%H %s' "$2" 2>/dev/null | awk -v s="$3" '{h=$1; sub(/^[^ ]+ /,""); if ($0 == s) {print h; exit}}'; }
# no_operation <repository>: no merge, rebase, cherry-pick, revert or bisect is in progress.
no_operation() {
  local g; g=$(git -C "$1" rev-parse --absolute-git-dir 2>/dev/null) || return 1
  ! ls "$g/MERGE_HEAD" "$g/CHERRY_PICK_HEAD" "$g/REVERT_HEAD" "$g/BISECT_LOG" "$g/rebase-merge" "$g/rebase-apply" 2>/dev/null | grep -q .
}

check_end() {
  if [ "$_chk_fail" -eq 0 ]; then
    printf 'PASS: exercise %s is complete.\n' "$EX_NAME"
    exit 0
  fi
  printf 'NOT YET: %s check(s) failed.\n' "$_chk_fail"
  exit 1
}
