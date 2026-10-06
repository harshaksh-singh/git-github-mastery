#!/usr/bin/env bash
# Replay of incident 4 (the production branch was rewritten): what changed, the restore, and the
# realignment of every clone, as real transcripts for Chapter 30 and the solution file.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$LAB_SCRIPT_DIR/replay-lib.bash"
lab_begin incidents solve-04-production-history-rewritten
incident_load 04-production-history-rewritten

snip 01-observe
run 'cd you'
run 'git fetch'
run 'git branch -vv'
run 'git log --oneline --graph production origin/production'

snip 02-witnesses
note 'Three independent records of the old tip: my branch, the reflog of origin/production, the tag.'
run "git rev-parse production 'origin/production@{1}' 'deploy-2026-09-07^{commit}'"
run_rc 'git merge-base --is-ancestor deploy-2026-09-07 origin/production'
run "git log --format='%h %an, committed by %cn: %s' production..origin/production"

snip 03-what-changed
run 'git range-diff production...origin/production'

snip 04-tree-diff
note '"Same code, fewer commits" is a claim about trees. Compare the trees:'
run 'git diff --stat production origin/production'
run 'git diff production origin/production -- billing/tax.py'

snip 05-how
run 'git -C ../ravi reflog show production'
run "git -C ../ravi reflog | grep rebase"

snip 06-restore
bad=$(git rev-parse --short origin/production)
run 'git branch --no-track rescue/production-rewritten origin/production'
run 'git switch production'
note "One commit was shipped on top of the rewritten history. Copy it onto the real history:"
run 'git cherry-pick origin/production'
run 'git log --oneline main..production'
run "git push --force-with-lease=production:$bad origin production"

snip 07-realign
run 'cd ../asha'
run 'git fetch'
run 'git status -sb'
note 'Is anything of mine missing from the server? "-" means the server has an equivalent change.'
run 'git cherry -v origin/production production'
run 'git reset --keep origin/production'
run 'cd ../ravi'
run 'git fetch'
run 'git cherry -v origin/production production'
run 'git reset --keep origin/production'

snip 08-verify
run 'cd ../you'
run_rc 'git merge-base --is-ancestor deploy-2026-09-07 origin/production'
run 'git show origin/production:billing/tax.py'
run 'git diff --stat rescue/production-rewritten origin/production'
run 'git branch -D rescue/production-rewritten'
run 'cd ..'
show_check
incident_done
