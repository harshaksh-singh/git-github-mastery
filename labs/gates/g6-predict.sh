#!/usr/bin/env bash
# Gate 6 (GitHub), prediction part: the Git side of what GitHub does, in plain Git. No GitHub
# command is run. The pN-setup snippets are printed in the gate file, the pN-answer snippets
# only in the answer key.
. "$(dirname "$0")/../lib/lab-env.sh"
lab_begin gates g6-predict

# ---- P1: what a squash merge leaves behind
snip p1-setup
note 'main plays the base branch on GitHub. The last two commands do what "Squash and merge" does.'
run 'git init -q billing'
run 'cd billing'
run "printf 'rate: 1\n' > plan.yaml && git add . && git commit -q -m 'Add plan'"
run 'git switch -q -c feature/proration'
run "printf 'def prorate(days):\n    return days / 30\n' > prorate.py && git add . && git commit -q -m 'Add proration'"
run "printf 'def prorate(days, month=30):\n    return days / month\n' > prorate.py && git commit -q -am 'Use the real month length'"
run "printf 'rate: 1\nprorate: true\n' > plan.yaml && git commit -q -am 'Enable proration in the plan'"
run 'git switch -q main'
run 'git merge -q --squash feature/proration'
run 'git commit -q -m "Add proration (#12)"'
snip p1-answer
run 'git log --oneline main | wc -l | tr -d " "'
run 'git show -s --format=%p main | wc -w | tr -d " "'
run 'git diff --stat main feature/proration'
run 'git branch --merged main'
run 'git log --oneline main..feature/proration | wc -l | tr -d " "'
run_rc 'git branch -d feature/proration'
run 'git cherry main feature/proration | cut -c1'
cd "$LAB_DIR"

# ---- P2: a second pull request on top of a squashed one
snip p2-setup
note 'Two branches, the second built on the first. The first is squash-merged; the second is not touched.'
run 'git init -q router'
run 'cd router'
run "printf 'routes: []\n' > routes.yaml && git add . && git commit -q -m 'Add routes file'"
run 'git switch -q -c feature/priority'
run "printf 'P = 1\n' > priority.py && git add . && git commit -q -m 'Add priority'"
run "printf 'P = 2\n' > priority.py && git commit -q -am 'Raise priority'"
run 'git switch -q -c feature/escalation'
run "printf 'E = True\n' > escalation.py && git add . && git commit -q -m 'Add escalation'"
run 'git switch -q main'
run 'git merge -q --squash feature/priority && git commit -q -m "Add priority (#7)"'
snip p2-answer-a
note 'What a pull request from feature/escalation into main would show:'
run 'git log --format=%s main..feature/escalation'
run 'git diff --stat main...feature/escalation'
run 'git merge-base main feature/escalation | xargs git log -1 --format=%s'
snip p2-setup-b
run 'git rebase -q --onto main feature/priority feature/escalation'
snip p2-answer-b
run 'git log --format=%s main..feature/escalation'
run 'git diff --stat main...feature/escalation'
cd "$LAB_DIR"

# ---- P3: gitignore matching is not CODEOWNERS matching
snip p3-setup
note 'The patterns are written into a .gitignore file so that the matcher of Git can be asked.'
run 'git init -q patterns'
run 'cd patterns'
run "printf '*\ndocs/*\n*.tf\n/services/billing/\n' > .gitignore"
run 'cat -n .gitignore'
snip p3-answer
run 'git check-ignore -v --no-index docs/index.md docs/api/auth.md infra/prod.tf services/billing/api/handler.py README.md'
cd "$LAB_DIR"

# ---- P4: what an author field proves
as config
snip p4-setup
run 'git init -q ledger'
run 'cd ledger'
run "git commit -q --allow-empty --author='Asha Rao <asha@example.com>' -m 'Approve the ledger migration'"
snip p4-answer
run "git log -1 --format='author:    %an <%ae>%ncommitter: %cn <%ce>%nsignature: %G?'"
run_rc 'git verify-commit HEAD'
run 'git cat-file -p HEAD | grep -c "^gpgsig"'
lab_end
