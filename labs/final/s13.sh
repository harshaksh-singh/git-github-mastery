#!/usr/bin/env bash
# Final test, section 13 (Open source), simulated with plain Git: prediction item P1 and
# diagram item G1. "upstream.git" plays the project, "fork.git" plays your fork on GitHub.
. "$(dirname "$0")/../lib/lab-env.sh"
lab_begin final s13

mk_fork() {   # mk_fork <dir>: upstream.git, fork.git and your clone you/ (origin = fork, upstream = project)
  mkdir "$1" && cd "$1" || exit 1
  quiet 'git init -q --bare upstream.git'
  quiet 'git clone -q upstream.git seed'
  as asha
  quiet 'git -C seed commit -q --allow-empty -m "Add the parser" && git -C seed push -q origin main'
  as you
  quiet 'git clone -q --bare upstream.git fork.git'
  quiet 'git clone -q fork.git you'
  quiet 'git -C you remote set-url origin ../fork.git && git -C you remote add upstream ../upstream.git && git -C you fetch -q upstream'
}

# ---- P1: the pull request branch after a rebase onto the moved upstream
mk_fork p1
cd you || exit 1
quiet 'git switch -q -c fix/unicode-escapes'
printf 'def unescape(s):\n    return s.encode().decode("unicode_escape")\n' > escapes.py
quiet 'git add . && git commit -q -m "Decode unicode escapes" && git push -q -u origin fix/unicode-escapes'
as asha
quiet 'git -C ../seed commit -q --allow-empty -m "Add the lexer" && git -C ../seed push -q origin main'
as you
snip p1-setup
note 'origin is your fork, upstream is the project. Your branch fix/unicode-escapes has one commit'
note 'and is pushed to the fork; a pull request is open. The project then gained "Add the lexer".'
run 'git fetch -q upstream'
run 'git rebase -q upstream/main'
snip p1-answer
run 'git status -sb'
run_rc 'git push'
run_rc 'git push --force-with-lease'
run 'git log --oneline --graph fix/unicode-escapes'
cd "$LAB_DIR"

# ---- G1: two ways to bring a pull request branch up to date
mk_fork g1
cd you || exit 1
quiet 'git switch -q -c feature/comments'
quiet 'git commit -q --allow-empty -m "P1: parse line comments"'
quiet 'git commit -q --allow-empty -m "P2: parse block comments"'
quiet 'git push -q -u origin feature/comments'
as asha
quiet 'git -C ../seed commit -q --allow-empty -m "U1: add the lexer" && git -C ../seed push -q origin main'
as you
quiet 'git fetch -q upstream'
quiet 'git branch by-merge && git branch by-rebase'
snip g1-before
run 'git log --graph --oneline --decorate feature/comments upstream/main'
snip g1-setup
run 'git switch -q by-merge && git merge -q -m "Merge upstream/main into the branch" upstream/main'
run 'git switch -q by-rebase && git rebase -q upstream/main'
snip g1-answer
run 'git log --graph --oneline by-merge'
run 'git log --graph --oneline by-rebase'
run 'git merge-base --is-ancestor origin/feature/comments by-merge; echo "by-merge can be pushed without force: exit status $?"'
run 'git merge-base --is-ancestor origin/feature/comments by-rebase; echo "by-rebase can be pushed without force: exit status $?"'
run 'git log --oneline upstream/main..by-merge'
run 'git log --oneline upstream/main..by-rebase'
lab_end
