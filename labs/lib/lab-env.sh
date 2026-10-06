#!/usr/bin/env bash
# labs/lib/lab-env.sh — Git Mastery lab environment
#
# Source this file from a demo script:
#     . "$(dirname "$0")/../lib/lab-env.sh"
#
# What it gives every demo:
#   * an isolated Git configuration: your real ~/.gitconfig and the system config are never read or written
#   * a fixed identity and a deterministic clock, so commit IDs are identical on every machine
#   * transcript capture into labs/<chapter>/out/<demo>/<snippet>.txt
#
# Compatible with the bash 3.2 that ships with macOS. It does not use "set -e":
# demos run failing commands on purpose.
#
# Why the clock is in the past and reflog expiry is switched off in the lab configuration:
#   * Commit dates are fixed so that commit IDs are reproducible. Reflog entries carry the same
#     fixed dates, but two parts of Git compare them with the REAL clock:
#       - "git fsck" (Git 2.53.0 and later, git/git commit f6b262581a "fsck: snapshot default refs
#         before object walk") skips reflog entries dated later than the real "now";
#       - "git gc" and "git reflog expire" drop entries older than 90 days (30 if unreachable).
#   * A fixed date in the future would trip the first rule; a fixed date in the past trips the
#     second one once it is more than 30 days old. So the lab clock is in the past, and the lab
#     configuration sets gc.reflogExpire and gc.reflogExpireUnreachable to "never". In the lab your
#     commits therefore always behave like fresh work, on whatever day you run a demo.
#   * Real repositories use the defaults (Chapter 13). Only explicit expiry (--expire=now) is
#     demonstrated in the labs.

_LAB_LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LAB_LIB="$_LAB_LIB_DIR"
# Absolute directory of the script that sourced this file. Use it for fixtures instead of
# "$(dirname "$0")", which stops working after lab_begin has changed directory.
LAB_SCRIPT_DIR="$(cd "$(dirname "$0")" 2>/dev/null && pwd)"
COURSE_ROOT="$(cd "$_LAB_LIB_DIR/../.." && pwd)"

# Where sandboxes are created. Override with the GIT_MASTERY_LABS environment variable.
if [ -z "${GIT_MASTERY_LABS:-}" ] && [ -f "$COURSE_ROOT/tools/.labroot" ]; then
  GIT_MASTERY_LABS="$(cat "$COURSE_ROOT/tools/.labroot")"
fi
LAB_ROOT="${GIT_MASTERY_LABS:-$HOME/git-mastery-labs}"

LAB_EPOCH_BASE=1788755400        # 2026-09-07 10:00:00 +05:30 (a Monday; must stay in the past, see the header)
LAB_TZ_OFFSET="+0530"
_lab_clock=$LAB_EPOCH_BASE
_LAB_SNIP=""

_lab_die() { printf 'lab-env: %s\n' "$*" >&2; exit 97; }

# ---------------------------------------------------------------- environment
_lab_env() {
  # Refuse dangerous roots.
  case "$LAB_ROOT" in
    /*) : ;;
    *) _lab_die "LAB_ROOT must be an absolute path (got '$LAB_ROOT')" ;;
  esac
  [ "$LAB_ROOT" != "/" ] || _lab_die "LAB_ROOT must not be /"
  [ "$LAB_ROOT" != "$HOME" ] || _lab_die "LAB_ROOT must not be your home directory"
  mkdir -p "$LAB_ROOT" || _lab_die "cannot create $LAB_ROOT"
  : > "$LAB_ROOT/.git-mastery-lab-root"
  LAB_ROOT_REAL="$(cd "$LAB_ROOT" && pwd -P)"

  # Git must never look at the real machine configuration, a parent repository, or a terminal.
  unset GIT_DIR GIT_WORK_TREE GIT_INDEX_FILE GIT_OBJECT_DIRECTORY GIT_NAMESPACE GIT_SSH_COMMAND
  # Drop every other GIT_* variable inherited from the caller's shell (GIT_TRACE, GIT_CONFIG_COUNT,
  # GIT_ASKPASS, prompt settings, ...) so that a replay cannot be altered by it.
  local _v
  for _v in $(env | sed -n 's/^\(GIT_[A-Za-z0-9_]*\)=.*/\1/p'); do
    case "$_v" in GIT_MASTERY_LABS) ;; *) unset "$_v" ;; esac
  done
  unset SSH_AUTH_SOCK            # replays never talk to the user's ssh-agent
  export GIT_CONFIG_NOSYSTEM=1
  export GIT_CEILING_DIRECTORIES="$LAB_ROOT:$LAB_ROOT_REAL"
  export GIT_TERMINAL_PROMPT=0
  export GIT_PAGER=cat PAGER=cat
  export GIT_EDITOR=true
  export GIT_MERGE_AUTOEDIT=no
  export LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8
  export TZ=Asia/Kolkata
  export LAB_ROOT LAB_ROOT_REAL LAB_LIB COURSE_ROOT
}

# Write the per-sandbox "global" Git configuration.
_lab_gitconfig() {
  mkdir -p "$LAB_DIR/home/.config"
  export GIT_CONFIG_GLOBAL="$LAB_DIR/home/.gitconfig"
  export XDG_CONFIG_HOME="$LAB_DIR/home/.config"
  export GNUPGHOME="$LAB_DIR/home/.gnupg"
  cat > "$GIT_CONFIG_GLOBAL" <<'CFG'
[user]
	name = Lab User
	email = you@example.com
[init]
	defaultBranch = main
[gc]
	reflogExpire = never
	reflogExpireUnreachable = never
CFG
}

# ---------------------------------------------------------------- clock and identity
# tick: advance the lab clock by one minute and pin both commit dates to it.
tick() {
  _lab_clock=$((_lab_clock + 60))
  export GIT_AUTHOR_DATE="@$_lab_clock $LAB_TZ_OFFSET"
  export GIT_COMMITTER_DATE="@$_lab_clock $LAB_TZ_OFFSET"
  # Git's own test suite uses this variable to fix "now" for date arithmetic, so that relative
  # dates ("2 minutes ago") and time-based selectors (HEAD@{5.minutes.ago}) are reproducible.
  export GIT_TEST_DATE_NOW="$_lab_clock"
}

# as <who>: switch identity. Known people: you, asha, ravi. "as config" removes the
# environment identity so that Git falls back to user.name / user.email from configuration.
as() {
  local n e
  case "${1:-you}" in
    you)   n="Lab User";   e="you@example.com" ;;
    asha)  n="Asha Rao";   e="asha@example.com" ;;
    ravi)  n="Ravi Menon"; e="ravi@example.com" ;;
    config) unset GIT_AUTHOR_NAME GIT_AUTHOR_EMAIL GIT_COMMITTER_NAME GIT_COMMITTER_EMAIL; return 0 ;;
    *)     n="$1";         e="$1@example.com" ;;
  esac
  export GIT_AUTHOR_NAME="$n" GIT_AUTHOR_EMAIL="$e" GIT_COMMITTER_NAME="$n" GIT_COMMITTER_EMAIL="$e"
}

# ---------------------------------------------------------------- sandboxes
# sandbox_begin <group> <name>: fresh, isolated sandbox without transcript capture.
# Used by exercise and incident generators.
sandbox_begin() {
  [ $# -ge 2 ] || _lab_die "usage: sandbox_begin <group> <name>"
  case "$1$2" in *[!A-Za-z0-9._-]*) _lab_die "group and name may contain only letters, digits, dot, underscore, dash" ;; esac
  _lab_env
  LAB_CH="$1"; LAB_DEMO="$2"
  LAB_DIR="$LAB_ROOT/$LAB_CH/$LAB_DEMO"
  case "$LAB_DIR" in "$LAB_ROOT"/*/*) : ;; *) _lab_die "refusing to use sandbox path $LAB_DIR" ;; esac
  [ -f "$LAB_ROOT/.git-mastery-lab-root" ] || _lab_die "lab root marker missing in $LAB_ROOT"
  if [ -e "$LAB_DIR" ]; then chmod -R u+w "$LAB_DIR" 2>/dev/null; rm -rf "$LAB_DIR"; fi
  mkdir -p "$LAB_DIR" || _lab_die "cannot create $LAB_DIR"
  _lab_gitconfig
  cd "$LAB_DIR" || _lab_die "cannot enter $LAB_DIR"
  _lab_clock=$LAB_EPOCH_BASE
  as you
  tick
  export LAB_DIR LAB_CH LAB_DEMO
}

# lab_begin <chapter-dir> <demo-name> [--volatile]: sandbox plus transcript capture.
# --volatile marks a demo whose output legitimately differs between runs (for example
# freshly generated keys); labs/verify-all.sh then only checks that it runs.
lab_begin() {
  sandbox_begin "$1" "$2"
  LAB_OUT="${LAB_OUT_ROOT:-$COURSE_ROOT/labs}/$LAB_CH/out/$LAB_DEMO"
  mkdir -p "$LAB_OUT" || _lab_die "cannot create $LAB_OUT"
  rm -f "$LAB_OUT"/*.txt "$LAB_OUT"/*.raw "$LAB_OUT/.volatile"
  [ "${3:-}" = "--volatile" ] && : > "$LAB_OUT/.volatile"
  exec 3>&1 4>&2
  _LAB_SNIP=""
}

_lab_filter() {   # replace the machine-specific lab root by the literal text $LAB
  # Carriage returns (progress lines such as "Rebasing (1/2)") become line breaks first.
  local line rep='$LAB'
  tr '\r' '\n' | while IFS= read -r line || [ -n "$line" ]; do
    line="${line//"$LAB_ROOT_REAL"/$rep}"
    line="${line//"$LAB_ROOT"/$rep}"
    line="${line//"$COURSE_ROOT"/\$COURSE}"
    printf '%s\n' "$line"
  done
}

_lab_flush() {
  if [ -n "$_LAB_SNIP" ]; then
    exec 1>&3 2>&4
    _lab_filter < "$LAB_OUT/$_LAB_SNIP.raw" > "$LAB_OUT/$_LAB_SNIP.txt"
    rm -f "$LAB_OUT/$_LAB_SNIP.raw"
    _LAB_SNIP=""
  fi
}

# snip <name>: everything shown from here on goes into the snippet <name>.
snip() {
  [ -n "${LAB_OUT:-}" ] || _lab_die "snip used outside lab_begin"
  case "$1" in *[!A-Za-z0-9._-]*|"") _lab_die "bad snippet name '$1'" ;; esac
  _lab_flush
  _LAB_SNIP="$1"
  exec > "$LAB_OUT/$1.raw" 2>&1
}

# snip_end: stop capturing (output goes back to the terminal).
snip_end() { _lab_flush; }

# lab_end: close the demo.
lab_end() {
  _lab_flush
  local n
  n=$(ls "$LAB_OUT" 2>/dev/null | grep -c '\.txt$')
  printf 'ok: %s/%s (%s snippets)\n' "$LAB_CH" "$LAB_DEMO" "$n" >&3
  exec 3>&- 4>&-
}

# ---------------------------------------------------------------- transcript helpers
# run '<command line>': show the command with a "$ " prompt, run it, show its output.
run() {
  tick
  printf '$ %s\n' "$1"
  eval "$1"
}

# run_rc '<command line>': like run, then show the exit status. Use it when the status is the lesson.
run_rc() {
  run "$1"
  local rc=$?
  printf '[exit status: %s]\n' "$rc"
  return 0
}

# quiet '<command line>': run a setup step without showing anything.
quiet() {
  tick
  eval "$1" > /dev/null 2>&1
}

# note <text>: a comment line inside the transcript.
note() { printf '# %s\n' "$*"; }

# blank: an empty line inside the transcript.
blank() { printf '\n'; }

# ---------------------------------------------------------------- scripted editors
# Git runs editors through the shell, so the helper paths are single-quoted to survive spaces.
_LAB_TODO_EDITOR="'$LAB_LIB/todo-editor.sh'"
_LAB_MSG_EDITOR="'$LAB_LIB/msg-editor.sh'"

# run_todo '<sed program>' '<git command that opens a todo list>'
# Shows the command exactly as a person would type it, then plays the part of the person in the
# editor: the todo list is printed, the sed program is applied to it, and the result is printed.
# To also replace commit messages opened during the rebase, set LAB_MSG or LAB_MSG_QUEUE first.
run_todo() {
  tick
  printf '$ %s\n' "$2"
  if [ -n "${LAB_MSG:-}${LAB_MSG_QUEUE:-}" ]; then
    LAB_TODO_SED="$1" LAB_TODO_CMD="" GIT_SEQUENCE_EDITOR="$_LAB_TODO_EDITOR" GIT_EDITOR="$_LAB_MSG_EDITOR" eval "$2"
  else
    LAB_TODO_SED="$1" LAB_TODO_CMD="" GIT_SEQUENCE_EDITOR="$_LAB_TODO_EDITOR" eval "$2"
  fi
}

# run_todo_cmd '<shell command; the todo file is $f>' '<git command that opens a todo list>'
# For edits sed cannot express, such as reordering lines.
run_todo_cmd() {
  tick
  printf '$ %s\n' "$2"
  if [ -n "${LAB_MSG:-}${LAB_MSG_QUEUE:-}" ]; then
    LAB_TODO_SED="" LAB_TODO_CMD="$1" GIT_SEQUENCE_EDITOR="$_LAB_TODO_EDITOR" GIT_EDITOR="$_LAB_MSG_EDITOR" eval "$2"
  else
    LAB_TODO_SED="" LAB_TODO_CMD="$1" GIT_SEQUENCE_EDITOR="$_LAB_TODO_EDITOR" eval "$2"
  fi
}

# run_msg '<message>' '<git command that opens the message editor>'
# Plays the part of a person who replaces the proposed commit message with <message>.
run_msg() {
  tick
  printf '$ %s\n' "$2"
  LAB_MSG="$1" GIT_EDITOR="$_LAB_MSG_EDITOR" eval "$2"
}
