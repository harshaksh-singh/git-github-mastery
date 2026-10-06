#!/usr/bin/env bash
# pr — a stand-in for the pull-request side of GitHub, for the capstone sandbox.
#
# GitHub is not Git. A bare repository has no pull requests, so this script keeps the few facts
# the simulation needs, with plain Git, next to server.git:
#   server.git/pulls/<n>          one small text file per pull request (head, base, title, state)
#   refs/pull/<n>/head            the head commit of the pull request (Chapter 17, section 17.2)
#   refs/pull/<n>/merge           a test merge of head into base, when they merge without conflict
# setup.sh copies this file to the sandbox root. Run it from any clone as ../pr.
#
#   ../pr open <head branch> [--base <branch>] [--title '<title>']
#   ../pr list [--all]
#   ../pr view <number>
#   ../pr merge <number> [--squash | --merge]      squash is the default; the head branch is deleted
#   ../pr close <number>                           close without merging; the head branch stays
#   ../pr reopen <number>                          only when the head branch exists again
#   ../pr sync                                     run by the server's post-receive hook after a push
#
# These are plain Git commands chosen to imitate documented GitHub behavior. GitHub does not
# publish the commands it runs. Bash 3.2.
set -u

ROOT="$(cd "$(dirname "$0")" && pwd)"
S="$ROOT/server.git"
[ -d "$S" ] || { echo "pr: no server.git next to this script" >&2; exit 2; }

# Who is acting: the environment identity if there is one, else the identity of the clone you
# are standing in.
ACT_NAME="${GIT_AUTHOR_NAME:-}"; ACT_EMAIL="${GIT_AUTHOR_EMAIL:-}"
if [ -z "$ACT_NAME" ] && [ -z "${GIT_DIR:-}" ]; then
  ACT_NAME="$(git config get user.name 2>/dev/null)"; ACT_EMAIL="$(git config get user.email 2>/dev/null)"
fi
[ -n "$ACT_NAME" ] || { ACT_NAME="Lab User"; ACT_EMAIL="you@example.com"; }

unset GIT_DIR GIT_WORK_TREE GIT_INDEX_FILE GIT_OBJECT_DIRECTORY GIT_ALTERNATE_OBJECT_DIRECTORIES GIT_QUARANTINE_PATH
export GIT_CONFIG_NOSYSTEM=1 GIT_CONFIG_GLOBAL="$ROOT/home/.gitconfig"
g() { git --git-dir="$S" "$@"; }
P="$S/pulls"
mkdir -p "$P"
die() { echo "pr: $*" >&2; exit 1; }

field() { sed -n "s/^$2=//p" "$P/$1" 2>/dev/null | head -n 1; }
set_state() { sed -e "s/^state=.*/state=$2/" "$P/$1" > "$P/$1.new" && mv "$P/$1.new" "$P/$1"; }
numbers() { ls "$P" 2>/dev/null | grep -E '^[0-9]+$' | sort -n; }
tip() { g rev-parse -q --verify "refs/heads/$1^{commit}" 2>/dev/null; }

# commit_as <author name> <author email> <committer name> <committer email> <commit-tree args...>
commit_as() {
  local an="$1" ae="$2" cn="$3" ce="$4"; shift 4
  GIT_AUTHOR_NAME="$an" GIT_AUTHOR_EMAIL="$ae" GIT_COMMITTER_NAME="$cn" GIT_COMMITTER_EMAIL="$ce" g commit-tree "$@"
}

# sync_one <n>: bring the refs of one open pull request in line with its branches.
sync_one() {
  local n="$1" head base h b tree old
  [ "$(field "$n" state)" = open ] || return 0
  head=$(field "$n" head); base=$(field "$n" base)
  h=$(tip "$head"); b=$(tip "$base")
  if [ -z "$h" ] || [ -z "$b" ]; then        # a pull request whose head branch is deleted is closed;
    set_state "$n" closed                    # refs/pull/<n>/head keeps the last head commit
    g update-ref -d "refs/pull/$n/merge" 2>/dev/null
    return 0
  fi
  g update-ref "refs/pull/$n/head" "$h"
  if tree=$(g merge-tree --write-tree "$b" "$h" 2>/dev/null); then
    old=$(g rev-parse -q --verify "refs/pull/$n/merge" 2>/dev/null)
    if [ -z "$old" ] || [ "$(g rev-parse "$old^1" "$old^2" 2>/dev/null | tr '\n' ' ')" != "$b $h " ]; then
      g update-ref "refs/pull/$n/merge" \
        "$(commit_as GitHub noreply@github.com GitHub noreply@github.com "$tree" -p "$b" -p "$h" -m "Merge $h into $b")"
    fi
  else
    g update-ref -d "refs/pull/$n/merge" 2>/dev/null      # conflicts: no test merge
  fi
}
sync_all() { local n; for n in $(numbers); do sync_one "$n"; done; }

# find_pr <number or head branch>: print the number.
find_pr() {
  local n
  case "$1" in ''|*[!0-9]*) ;; *) [ -f "$P/$1" ] && { echo "$1"; return 0; } ;; esac
  for n in $(numbers); do
    [ "$(field "$n" head)" = "$1" ] && [ "$(field "$n" state)" = open ] && { echo "$n"; return 0; }
  done
  return 1
}

mergeable() {   # mergeable <n>: clean, conflicts, or nothing (not open)
  [ "$(field "$1" state)" = open ] || return 0
  if g rev-parse -q --verify "refs/pull/$1/merge" > /dev/null; then echo clean; else echo conflicts; fi
}

cmd="${1:-}"; [ $# -gt 0 ] && shift
case "$cmd" in
  sync)
    sync_all ;;

  open)
    head=""; base=main; title=""
    while [ $# -gt 0 ]; do
      case "$1" in
        --base) base="$2"; shift 2 ;;
        --title) title="$2"; shift 2 ;;
        -*) die "unknown option $1" ;;
        *) head="$1"; shift ;;
      esac
    done
    [ -n "$head" ] || die "usage: pr open <head branch> [--base <branch>] [--title '<title>']"
    h=$(tip "$head") || die "the server has no branch '$head'. Push it first."
    b=$(tip "$base") || die "the server has no branch '$base'."
    [ "$(g rev-list --count "$b..$h")" -gt 0 ] || die "there are no commits between $base and $head."
    for n in $(numbers); do
      [ "$(field "$n" state)" = open ] && [ "$(field "$n" head)" = "$head" ] && die "pull request #$n is already open for $head."
    done
    first=$(g rev-list --reverse "$b..$h" | head -n 1)
    [ -n "$title" ] || title=$(g log -1 --format=%s "$first")
    n=$(cat "$P/next" 2>/dev/null || echo 1)
    echo $((n + 1)) > "$P/next"
    {
      echo "head=$head"; echo "base=$base"; echo "title=$title"; echo "state=open"
      echo "author_name=$(g log -1 --format=%an "$first")"; echo "author_email=$(g log -1 --format=%ae "$first")"
    } > "$P/$n"
    sync_one "$n"
    echo "Opened pull request #$n: $title ($head -> $base)" ;;

  list)
    for n in $(numbers); do
      st=$(field "$n" state)
      [ "$st" = open ] || [ "${1:-}" = "--all" ] || continue
      m=$(mergeable "$n")
      printf '#%-3s %-7s %-9s %s -> %s   %s\n' "$n" "$st" "${m:--}" "$(field "$n" head)" "$(field "$n" base)" "$(field "$n" title)"
    done ;;

  view)
    n=$(find_pr "${1:-}") || die "no such pull request: ${1:-}"
    st=$(field "$n" state); head=$(field "$n" head); base=$(field "$n" base)
    echo "#$n $(field "$n" title)"
    echo "state: $st   $head -> $base   author: $(field "$n" author_name)"
    if [ "$st" = open ]; then
      echo "merge check: $(mergeable "$n")"
      echo "Commits:"
      g log --format='  %h %an: %s' "refs/heads/$base..refs/pull/$n/head"
      echo "Files changed:"
      g diff --stat "refs/heads/$base...refs/pull/$n/head"
    else
      echo "head commit when it was $st: $(g rev-parse --short "refs/pull/$n/head" 2>/dev/null)"
    fi ;;

  merge)
    method=squash; who=""
    while [ $# -gt 0 ]; do
      case "$1" in --squash) method=squash; shift ;; --merge) method=merge; shift ;; -*) die "unknown option $1" ;; *) who="$1"; shift ;; esac
    done
    n=$(find_pr "$who") || die "no such pull request: $who"
    [ "$(field "$n" state)" = open ] || die "pull request #$n is $(field "$n" state)."
    sync_one "$n"
    [ "$(field "$n" state)" = open ] || die "pull request #$n was closed: its head branch is gone."
    head=$(field "$n" head); base=$(field "$n" base); title=$(field "$n" title)
    h=$(tip "$head"); b=$(tip "$base")
    tree=$(g merge-tree --write-tree "$b" "$h" 2> /dev/null) \
      || die "pull request #$n cannot be merged: $head has conflicts with $base that must be resolved."
    if [ "$method" = merge ]; then
      new=$(commit_as "$ACT_NAME" "$ACT_EMAIL" "$ACT_NAME" "$ACT_EMAIL" "$tree" -p "$b" -p "$h" \
            -m "Merge pull request #$n from $head" -m "$title")
    else
      if [ "$(g rev-list --count "$b..$h")" = 1 ]; then
        body=$(g log -1 --format=%b "$h")
      else
        body=$(g log --reverse --format='* %s' "$b..$h")
      fi
      new=$(commit_as "$(field "$n" author_name)" "$(field "$n" author_email)" "$ACT_NAME" "$ACT_EMAIL" "$tree" -p "$b" \
            -m "$title (#$n)" ${body:+-m "$body"})
    fi
    g update-ref "refs/heads/$base" "$new" "$b" || die "could not update $base"
    g update-ref "refs/pull/$n/head" "$h"
    g update-ref -d "refs/pull/$n/merge" 2>/dev/null
    set_state "$n" merged
    case "$head" in
      main|release/*) echo "Merged pull request #$n into $base as $(g rev-parse --short "$new") ($method)." ;;
      *) g update-ref -d "refs/heads/$head"
         echo "Merged pull request #$n into $base as $(g rev-parse --short "$new") ($method). Deleted the branch $head on the server." ;;
    esac
    sync_all ;;

  close)
    n=$(find_pr "${1:-}") || die "no such pull request: ${1:-}"
    [ "$(field "$n" state)" = open ] || die "pull request #$n is $(field "$n" state)."
    set_state "$n" closed
    g update-ref -d "refs/pull/$n/merge" 2>/dev/null
    echo "Closed pull request #$n without merging. The branch $(field "$n" head) still exists." ;;

  reopen)
    n=$(find_pr "${1:-}") || die "no such pull request: ${1:-}"
    [ "$(field "$n" state)" = closed ] || die "pull request #$n is $(field "$n" state), not closed."
    head=$(field "$n" head)
    tip "$head" > /dev/null || die "the head branch $head does not exist on the server. Restore it first."
    set_state "$n" open
    sync_one "$n"
    echo "Reopened pull request #$n ($head -> $(field "$n" base))" ;;

  *)
    sed -n '2,/^# These are/p' "$0" | sed -e 's/^# \{0,1\}//' -e '$d'
    exit 2 ;;
esac
