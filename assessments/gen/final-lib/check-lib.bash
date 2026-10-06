# assessments/gen/final-lib/check-lib.bash — helpers shared by the check.sh scripts of the final
# test's practical labs. Sourced, never run.
#
# A check script inspects a lab sandbox with read-only commands and exits 0 when the end state is
# right. It never moves a ref, never writes an object and never touches the index.
#   assessments/gen/final-<name>/check.sh            checks $GIT_MASTERY_LABS/final/<name>
#   assessments/gen/final-<name>/check.sh <path>     checks the sandbox at <path>

check_begin() {   # check_begin <sandbox name> [<sandbox path>]
  . "$(cd "$(dirname "${BASH_SOURCE[0]}")/../../../labs/lib" && pwd)/lab-env.sh"
  _lab_env
  F_NAME="$1"
  F_DIR="${2:-$LAB_ROOT/final/$1}"
  if [ "$(cat "$F_DIR/.final/name" 2>/dev/null)" != "$1" ]; then
    printf 'No sandbox of %s at %s\nRun assessments/gen/final-%s/generate.sh first.\n' "$1" "$F_DIR" "$1" >&2
    exit 2
  fi
  F_DIR="$(cd "$F_DIR" && pwd)"
  export GIT_CONFIG_GLOBAL="$F_DIR/home/.gitconfig"
  export GIT_OPTIONAL_LOCKS=0            # "git status" must not refresh the index file
  unset GIT_AUTHOR_DATE GIT_COMMITTER_DATE GIT_AUTHOR_NAME GIT_AUTHOR_EMAIL GIT_COMMITTER_NAME GIT_COMMITTER_EMAIL
  cd "$F_DIR" || exit 2
  _chk_fail=0
  printf 'Checking final-test lab %s\n' "$F_NAME"
}

ok()  { printf '  ok    %s\n' "$1"; }
bad() { printf '  FAIL  %s\n' "$1"; _chk_fail=$((_chk_fail + 1)); }

# expect '<description>' <command...>: the command must succeed.
expect() { local d="$1"; shift; if "$@" > /dev/null 2>&1; then ok "$d"; else bad "$d"; fi; }
# expect_not '<description>' <command...>: the command must fail.
expect_not() { local d="$1"; shift; if "$@" > /dev/null 2>&1; then bad "$d"; else ok "$d"; fi; }
# expect_eq '<description>' <have> <want>: two strings must be equal (and not empty).
expect_eq() { if [ -n "$2" ] && [ "$2" = "$3" ]; then ok "$1"; else bad "$1"; fi; }

# noted <key>: print a value that the generator recorded with final_note.
noted() { cat "$F_DIR/.final/$1" 2>/dev/null; }

# rev <repository> <revision>: the full ID a revision resolves to, or nothing.
rev() { git -C "$1" rev-parse -q --verify "$2" 2>/dev/null; }
# has_subject <repository> <revision> '<subject>': is a commit with this exact subject reachable?
has_subject() { git -C "$1" log --format=%s "$2" 2>/dev/null | grep -Fxq -- "$3"; }
# count_subject <repository> <revision> '<subject>': how many reachable commits have this subject?
count_subject() { git -C "$1" log --format=%s "$2" 2>/dev/null | grep -Fxc -- "$3"; }
# subjects <repository> <range>: the subjects of a range, oldest first, joined with " | ".
subjects() { git -C "$1" log --reverse --format=%s "$2" 2>/dev/null | paste -sd'|' - | sed 's/|/ | /g'; }
# is_ancestor <repository> <A> <B>: is A an ancestor of B (or equal to it)?
is_ancestor() { git -C "$1" merge-base --is-ancestor "$2" "$3" 2>/dev/null; }
# clean_tree <repository>: no staged, unstaged or untracked change.
clean_tree() { [ -z "$(git -C "$1" status --porcelain --untracked-files=all 2>/dev/null)" ]; }
# on_branch <repository> <branch>: HEAD is attached to this branch.
on_branch() { [ "$(git -C "$1" symbolic-ref -q --short HEAD 2>/dev/null)" = "$2" ]; }
# in_progress <repository>: is a merge, rebase, cherry-pick, revert or bisect unfinished?
in_progress() {
  local g; g="$(git -C "$1" rev-parse --absolute-git-dir 2>/dev/null)" || return 1
  [ -e "$g/MERGE_HEAD" ] || [ -e "$g/CHERRY_PICK_HEAD" ] || [ -e "$g/REVERT_HEAD" ] || [ -d "$g/rebase-merge" ] || [ -d "$g/rebase-apply" ] || [ -d "$g/sequencer" ] || [ -e "$g/BISECT_LOG" ]
}

check_end() {
  if [ "$_chk_fail" -eq 0 ]; then
    printf 'PASS: the end state of %s is right.\n' "$F_NAME"
    exit 0
  fi
  printf 'NOT YET: %s check(s) failed.\n' "$_chk_fail"
  exit 1
}
