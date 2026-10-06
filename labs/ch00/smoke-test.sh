#!/usr/bin/env bash
# Smoke test of the lab environment. Also the reference example of how a demo script is written.
. "$(dirname "$0")/../lib/lab-env.sh"
lab_begin ch00 smoke-test

snip 01-init
run 'git init shop'
run 'cd shop'
run 'git config list --show-origin --show-scope'

snip 02-first-commit
run "echo 'apples' > stock.txt"
run 'git add stock.txt'
run 'git commit -m "Add stock list"'
run 'git log --format=fuller'

snip 03-failure
note 'A failing command is shown with its exit status when the status is the lesson.'
run_rc 'git switch no-such-branch'

snip 04-rebase-todo
quiet "echo 'pears' >> stock.txt && git commit -am 'Add pears'"
quiet "echo 'plums' >> stock.txt && git commit -am 'Add plums'"
run 'git log --oneline'
LAB_MSG='Add pears and plums' run_todo '2s/^pick/squash/' 'git rebase -i HEAD~2'
run 'git log --oneline'

snip 05-reword-queue
quiet "echo 'figs' >> stock.txt && git commit -am 'add figz'"
quiet "echo 'kiwis' >> stock.txt && git commit -am 'add kiwiz'"
printf 'Add figs\n----\nAdd kiwis\n' > "$LAB_DIR/msgs"
LAB_MSG_QUEUE="$LAB_DIR/msgs" run_todo 's/^pick/reword/' 'git rebase -i HEAD~2'
run 'git log --oneline'

lab_end
