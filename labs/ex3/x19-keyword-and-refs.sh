#!/usr/bin/env bash
# Exercise 19.4 (Module 19): what a fresh clone receives, and where a closing keyword travels.
# A bare repository plays the platform. "Pull request 7" is imitated by refs/pull/7/head and by
# a --no-ff merge into release/1.2; the cherry-pick onto main is ordinary Git.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$LAB_SCRIPT_DIR/fixture.bash"
lab_begin ex3 x19-keyword-and-refs
make_server
new_clone you
new_clone asha
enter asha
hidden 'git switch -c release/1.2'
hidden 'git push -u origin release/1.2'
hidden 'git switch main'
enter you
hidden 'git fetch'
hidden 'git switch -c fix/empty-doc origin/release/1.2 --no-track'
put chunker/split.py <<'PY'
def split(text, size=200):
    """Split text into chunks of at most `size` characters."""
    if not text:
        return []
    return [text[i:i + size] for i in range(0, len(text), size)]
PY
tick
{ git add -A && git commit -q -m 'Return no chunks for empty text' -m 'Fixes #41'; } > /dev/null 2>&1 || exit 1
hidden 'git push -u origin fix/empty-doc'
server_open_pr 7 fix/empty-doc

snip 01-the-commit
run 'git log -1 --format="%h %s%n%n%b" fix/empty-doc'

# Asha merges pull request 7 into release/1.2, then carries the fix to main with a cherry-pick.
enter asha
hidden 'git fetch'
hidden 'git switch release/1.2'
hidden 'git merge --no-ff -m "Merge pull request #7 from fix/empty-doc" origin/fix/empty-doc'
hidden 'git push origin release/1.2'
hidden 'git switch main'
hidden 'git cherry-pick origin/fix/empty-doc'
hidden 'git push origin main'
hidden 'git push origin --delete fix/empty-doc'

cd "$LAB_DIR" || exit 1
as you
snip 02-fresh-clone
run 'git clone -q server/chunker.git fresh'
run 'cd fresh'
run 'git for-each-ref --format="%(refname)"'
run 'git ls-remote origin'

snip 03-keyword
run 'git log --all --format="%h %s" --grep="Fixes #41"'
run 'git log --format="%h %s" origin/release/1.2 -3'
run 'git log --format="%h %s" origin/main -2'

snip 04-pull-ref
run 'git fetch -q origin pull/7/head:pr-7'
run 'git log --oneline -1 pr-7'
run 'git branch -a --contains pr-7'

lab_end
