#!/usr/bin/env bash
# Final test, section 10 (Pull requests), simulated with plain Git: prediction item P1, diagram
# items G1 and G2 and interpretation item I1. Nothing here talks to GitHub.
. "$(dirname "$0")/../lib/lab-env.sh"
lab_begin final s10

# ---- P1: two dots, three dots
snip p1-setup
run 'git init -q invoicer'
run 'cd invoicer'
run "printf 'standard: 19\nreduced: 7\n' > rates.yaml"
run "printf '# invoicer\n' > README.md"
run 'git add . && git commit -q -m "Add tax rates"'
run 'git switch -q -c feature/vat-id'
run "printf 'pattern: \"[A-Z]{2}[0-9]{9}\"\n' > vat_id.yaml"
run 'git add . && git commit -q -m "Validate VAT IDs"'
run 'git switch -q main'
run "printf 'retention_days: 3650\n' > audit.yaml"
run "printf '# invoicer\n\nCreates invoices.\n' > README.md"
run 'git add . && git commit -q -m "Add audit retention"'
snip p1-answer
run 'git diff --stat main..feature/vat-id'
run 'git diff --stat main...feature/vat-id'
run 'git log --oneline main..feature/vat-id'
cd "$LAB_DIR"

# ---- G1: the three merge methods, as plain Git
snip g1-setup
run 'git init -q geocoder'
run 'cd geocoder'
run 'git commit -q --allow-empty -m "A: add the geocoder"'
run 'git switch -q -c feature/cache'
run 'git commit -q --allow-empty -m "X: add a result cache"'
run 'git commit -q --allow-empty -m "Y: expire cache entries"'
run 'git switch -q main'
run 'git commit -q --allow-empty -m "N: add rate limiting"'
note 'Three copies of main, one per merge method:'
run 'git branch main-merge && git branch main-squash && git branch main-rebase'
snip g1-answer
run 'git switch -q main-merge && git merge -q --no-ff -m "Merge pull request #7" feature/cache'
run 'git switch -q main-squash && git merge -q --squash feature/cache && git commit -q --allow-empty -m "Add a result cache (#7)"'
run 'git switch -q main-rebase && git cherry-pick --allow-empty main..feature/cache > /dev/null'
run 'git log --graph --oneline main-merge'
run 'git log --graph --oneline main-squash'
run 'git log --graph --oneline main-rebase'
run 'git branch --merged main-merge --list "feature/*"'
run 'git branch --merged main-squash --list "feature/*"'
run 'git branch --merged main-rebase --list "feature/*"'
cd "$LAB_DIR"

# ---- G2 and I1: a branch that lives on after its squash merge
quiet 'git init -q alerting'
cd alerting || exit 1
printf 'channels: [email]\n' > alerts.yaml
quiet 'git add . && git commit -q -m "Add alert channels"'
quiet 'git switch -q -c feature/paging'
printf 'channels: [email, pager]\n' > alerts.yaml
quiet 'git commit -q -a -m "Add the pager channel"'
printf 'primary: asha\nsecondary: ravi\n' > rota.yaml
quiet 'git add . && git commit -q -m "Add the on-call rota"'
quiet 'git switch -q main'
printf 'quiet_hours: "22-06"\n' > quiet.yaml
quiet 'git add . && git commit -q -m "Add quiet hours"'
snip i1-transcript
run 'git merge --squash feature/paging'
run 'git commit -q -m "Add paging (#31)"'
run_rc 'git branch -d feature/paging'
run 'git log --oneline main..feature/paging'
run 'git cherry -v main feature/paging'
run 'git diff --stat main...feature/paging'
run 'git merge-tree --write-tree main feature/paging'
run "git rev-parse 'main^{tree}'"
quiet 'git switch -q feature/paging'
printf 'primary: asha\nsecondary: ravi\nescalate_after_min: 15\n' > rota.yaml
quiet 'git commit -q -a -m "Escalate after fifteen minutes"'
quiet 'git switch -q main'
snip g2-graph
run 'git log --graph --oneline --all --decorate'
snip g2-answer
run 'git merge-base main feature/paging | xargs git log -1 --format=%s'
run 'git log --oneline main..feature/paging'
run 'git rebase -q --onto main feature/paging~1 feature/paging'
run 'git log --oneline main..feature/paging'
run 'git log --graph --oneline --all --decorate'
lab_end
