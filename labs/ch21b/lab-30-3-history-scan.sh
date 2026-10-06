#!/usr/bin/env bash
# Lab 30.3 replay: find every planted dummy secret in a repository with built-in commands:
# the tip, the history of every ref, and the commits that only the reflog still reaches.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$LAB_SCRIPT_DIR/fixture.bash"
lab_begin ch21b lab-30-3-history-scan
fx_ragdesk
fx_ragdesk_notebook
fx_ragdesk_amended

snip 01-tip
run 'cd ragdesk'
run 'git status -sb'
run "git grep -n -E 'DUMMY-(KEY|TOKEN)-[a-z-]+-[0-9]+'"

snip 02-when-and-who
run "git log --format='%h %ad %an: %s' --date=iso-local -S'DUMMY-KEY-not-a-real-secret-12345'"
run 'first=$(git log --format=%h --diff-filter=A -- .env); echo $first'
run 'git show --stat --format="%h %s" $first'

snip 03-every-ref
run "git log --oneline --all -G'DUMMY-(KEY|TOKEN)-[a-z-]+-[0-9]+'"
run "git grep -l -E 'DUMMY-(KEY|TOKEN)-[a-z-]+-[0-9]+' \$(git rev-list --all) | cut -d: -f2 | sort | uniq -c"
run "git grep -h -o -E 'DUMMY-(KEY|TOKEN)-[a-z-]+-[0-9]+' \$(git rev-list --all) | sort | uniq -c"

snip 04-scope
run 'git branch -a --contains $first'
run 'git tag --contains $first'
run 'nb=$(git log --all --format=%h -1 -- notebooks/rerank-debug.ipynb); echo $nb'
run 'git branch -a --contains $nb'

snip 05-failure
note 'The scan above looked at every ref. Is that every commit in this clone?'
run 'git reflog -3'
run "git log --oneline --all -S'24680'"
run "git log --oneline --reflog -S'24680'"

snip 06-recovery
run "git grep -h -o -E 'DUMMY-(KEY|TOKEN)-[a-z-]+-[0-9]+' \$(git rev-list --all --reflog) | sort | uniq -c"
run 'old=$(git rev-parse --short "HEAD@{1}"); echo $old'
run 'git show $old:smoke_test.py | head -1'
note 'Was that commit ever pushed? Ask which remote-tracking branches contain it:'
run 'git branch -r --contains $old'
run 'git -C ../server.git cat-file -t $old 2>&1'

snip 07-verification
run 'git rev-list --all | wc -l'
run 'git rev-list --all --reflog | wc -l'
lab_end
