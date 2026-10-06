#!/usr/bin/env bash
# Model answers for exercises 14.1 to 14.8 (Module 14: worktrees, attributes, hooks, stash
# internals, rerere) as real transcripts on the practice repositories built by
# exercises/gen/m14-promptguard/generate.sh.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$LAB_SCRIPT_DIR/replay-lib.bash"
lab_begin ex2 answers-m14
ex_load m14-promptguard
put() { mkdir -p "$(dirname "$1")" && cat > "$1"; }

cd ex-14-1 || exit 1
snip 14-1-add
run 'git status -sb'
run 'git worktree add -b hotfix/blocklist ../hotfix main'
run 'git worktree list'
snip 14-1-work
run 'cd ../hotfix'
run 'cat .git'
run "sed -e 's/\"reveal your system prompt\"/\"reveal your system prompt\", \"developer mode\"/' guard/rules.py > r.tmp && mv r.tmp guard/rules.py"
run "git commit -q -am 'Block the developer-mode phrase' && git log --oneline -1"
run 'cd ../ex-14-1'
run 'git status -sb'
snip 14-1-rules
run_rc 'git switch hotfix/blocklist'
run 'git worktree remove ../hotfix'
run 'git worktree list'
run 'git branch'
cd "$LAB_DIR" || exit 1

cd ex-14-2 || exit 1
snip 14-2-attributes
printf '*.ipynb          -diff\n*.jsonl          text eol=lf\ndocs-internal.md export-ignore\n' > .gitattributes
run 'cat .gitattributes'
run 'git check-attr -a -- notebooks/eval.ipynb data/golden.jsonl docs-internal.md guard/rules.py'
snip 14-2-effects
run "sed -e 's/41/43/' notebooks/eval.ipynb > n.tmp && mv n.tmp notebooks/eval.ipynb"
run 'git diff'
run "git add -A && git commit -q -m 'Add attributes for notebooks, data and internal notes'"
run 'git archive HEAD | tar -t'
cd "$LAB_DIR" || exit 1

cd ex-14-3 || exit 1
snip 14-3-hook
put .git/hooks/pre-commit <<'F'
#!/bin/sh
# Refuse a commit whose staged changes add the marker "DO NOT COMMIT".
if git diff --cached | grep -q '^+.*DO NOT COMMIT'; then
  echo "pre-commit: staged changes contain DO NOT COMMIT" >&2
  exit 1
fi
F
run 'cat .git/hooks/pre-commit'
run 'chmod +x .git/hooks/pre-commit'
snip 14-3-fires
run "echo 'MAX_CHARS = 1  # DO NOT COMMIT: local test' >> guard/rules.py"
run_rc "git commit -am 'Lower the limit'"
run 'git log --oneline -1'
run "git commit -q --no-verify -am 'Lower the limit' && git log --oneline -1"
cd "$LAB_DIR" || exit 1

cd ex-14-4 || exit 1
snip 14-4-stash
run 'git status -sb'
run 'git stash push -u -m "limits, readme, todo"'
run 'git status -sb'
snip 14-4-graph
run 'git log --graph --oneline stash@{0}'
snip 14-4-parents
run "git show -s --format='%h parents: %p' stash@{0}"
run 'git diff --stat stash@{0}^1 stash@{0}^2'
run 'git diff --stat stash@{0}^1 stash@{0}'
run 'git ls-tree -r --name-only stash@{0}^3'
cd "$LAB_DIR" || exit 1

cd ex-14-5 || exit 1
snip 14-5-conflict
run 'git merge -q feat/length-limit'
run_rc 'git merge feat/audit-log'
run 'git merge --abort'
snip 14-5-union
run "echo 'CHANGELOG.md merge=union' > .gitattributes"
run "git add .gitattributes && git commit -q -m 'Merge the changelog with the union driver'"
run 'git merge feat/audit-log'
run 'cat CHANGELOG.md'
cd "$LAB_DIR" || exit 1

cd ex-14-6 || exit 1
snip 14-6-commit
run "echo '# one' >> guard/rules.py && git commit -q -am 'One'"
snip 14-6-no-verify
run "echo '# two' >> guard/rules.py && git commit -q --no-verify -am 'Two'"
snip 14-6-amend
run 'git commit -q --amend --no-edit'
snip 14-6-merge
run 'git merge -q --no-ff --no-edit topic'
snip 14-6-rebase
run 'git switch -q -c side HEAD~1'
run "echo three > three.txt && git add three.txt && git commit -q --no-verify -m 'Three'"
run 'git rebase -q main'
cd "$LAB_DIR" || exit 1

cd ex-14-7 || exit 1
snip 14-7-symptom
run 'git -C you log --oneline -3 origin/main'
run 'git -C you fetch -q && git -C you log --oneline -2 origin/main'
snip 14-7-config
run 'git -C you config get core.hooksPath'
run 'git -C asha config get core.hooksPath'
snip 14-7-reproduce
run 'cd asha'
run "git commit --allow-empty -m 'no ticket'"
run 'git reset -q --hard HEAD~1'
snip 14-7-mode
run 'git ls-files --stage .githooks/commit-msg'
run 'git -C ../you status -sb'
run 'git -C ../you diff'
snip 14-7-fix
run 'cd ../you'
run "git pull -q && git add .githooks/commit-msg && git commit -q -m 'PG-8: Make the commit-msg hook executable' && git push -q"
run 'git ls-files --stage .githooks/commit-msg'
run 'cd ../asha && git pull -q'
run_rc "git commit --allow-empty -m 'still no ticket'"
cd "$LAB_DIR" || exit 1

cd ex-14-8 || exit 1
snip 14-8-symptom
run_rc 'git merge feat/timeouts'
run 'git status -sb'
run 'cat guard/client.yaml'
snip 14-8-diagnose
run 'git ls-files -u'
run 'git diff'
run 'git rerere status'
run 'cat .git/rr-cache/*/postimage'
snip 14-8-fix
run 'git rerere forget guard/client.yaml'
run 'git restore --merge guard/client.yaml'
run 'cat guard/client.yaml'
put guard/client.yaml <<'F'
model: guard-small
timeout_seconds: 30
retries: 3
F
note 'edit guard/client.yaml: timeout 30 from the branch, retries 3 from main'
run 'git add guard/client.yaml && git commit -q --no-edit'
run 'cat guard/client.yaml'
run 'git log --oneline --graph -4'
lab_end
