#!/usr/bin/env bash
# Lab 9.7 replay: a review fix for the bottom branch of a three-branch stack, applied from the top
# branch with --autosquash --update-refs. The failure scenario undoes the rebase with ORIG_HEAD and
# finds that only one of the three branches came back.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$(dirname "$0")/fixtures/fixtures.sh"
lab_begin ch09 lab-09-7-update-refs-stack
fx_ingest_stack

snip 01-start
run 'git log --oneline --graph --decorate --all'
run 'git for-each-ref --format="%(objectname:short) %(refname:short)" refs/heads/feat'

snip 02-fixup
note 'Review comment on the bottom branch: open the file with an explicit encoding. Edit ingest/loader.py.'
put ingest/loader.py <<'PYEOF'
def load(path):
    with open(path, encoding="utf-8") as f:
        return f.read()
PYEOF
run 'git commit -a --fixup=HEAD~3'

snip 03-rebase
run_todo '' 'git rebase -i --autosquash --update-refs main'

snip 04-result
run 'git log --oneline --graph --decorate --all'
run 'git show --stat --format="%h %s" feat/ingest-loader'

snip 05-failure
note 'You decide the rebase was premature and undo it the usual way:'
run 'git reset --hard ORIG_HEAD'
run 'git log --oneline --graph --decorate --all'

snip 06-diagnose
run 'git reflog show feat/ingest-loader -2'
run 'git reflog show feat/ingest-cleaner -2'

snip 07-recovery
run 'git branch -f feat/ingest-loader "feat/ingest-loader@{1}"'
run 'git branch -f feat/ingest-cleaner "feat/ingest-cleaner@{1}"'

snip 08-verification
run 'git log --oneline --graph --decorate --all'
run 'git for-each-ref --format="%(objectname:short) %(refname:short)" refs/heads/feat'
lab_end
