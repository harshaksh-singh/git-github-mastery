#!/usr/bin/env bash
# Chapter 9, section 9.11: the anatomy of a conflict during a rebase. Shows the markers, the three index
# stages, and that "ours" is the upstream side while "theirs" is your own commit, by doing the same
# integration once as a rebase and once as a merge.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$(dirname "$0")/fixtures/fixtures.sh"
lab_begin ch09 rebase-conflict
fx_rerank_conflict
tick                      # same clock position as rebase-internals, so the replayed commit gets the same ID
quiet 'git rebase main'

snip 01-markers
note 'The rebase of section 9.4 has stopped at the same commit again.'
run 'cat app/retriever.py'

snip 02-stages
run 'git ls-files -u'
run 'git show :1:app/retriever.py | head -1'
run 'git show :2:app/retriever.py | head -1'
run 'git show :3:app/retriever.py | head -1'

snip 03-who-is-who
note 'Stage 2, "ours", is HEAD: the upstream commits plus what has been replayed so far.'
run 'git log --oneline -2 HEAD'
note 'Stage 3, "theirs", is the commit being replayed: your own work.'
run 'git log --oneline -1 REBASE_HEAD'

snip 04-as-a-merge
quiet 'git rebase --abort'
note 'The same two branches integrated with a merge instead (run from feat/rerank):'
run_rc 'git merge main'
run 'cat app/retriever.py'
run 'git show :2:app/retriever.py | head -1'
run 'git show :3:app/retriever.py | head -1'
run 'git merge --abort'

snip 05-resolve
quiet 'git rebase main'
note 'Back in the stopped rebase. Take the version of the commit being replayed (stage 3):'
run 'git restore --theirs app/retriever.py'
run 'cat app/retriever.py'
run 'git add app/retriever.py'
run 'git status --short'

snip 06-continue
run 'git rebase --continue'
run 'git log --oneline --graph --decorate --all'
run 'git reflog -5'

snip 07-strategy-option
quiet 'git reset --hard ORIG_HEAD'
note 'The same rebase, telling the merge machinery in advance to prefer "theirs" in conflicting hunks:'
run 'git rebase -X theirs main'
run 'head -1 app/retriever.py'
lab_end
