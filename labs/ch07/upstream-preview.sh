#!/usr/bin/env bash
# Chapter 7, section 7.10: remote-tracking branches and upstream, as a preview of chapter 12.
# origin/main is a ref in your own repository; the upstream of a branch is two lines of
# configuration; and neither changes until you fetch.
# The remote is a bare repository on disk; no network is used.
. "$(dirname "$0")/../lib/lab-env.sh"
lab_begin ch07 upstream-preview

quiet 'git init --bare origin.git'
quiet 'git clone origin.git evalkit'
cd evalkit || exit 1
mkdir -p evalkit
printf '# evalkit\n\nSmall evaluation harness for LLM outputs.\n' > README.md
quiet 'git add . && git commit -m "Add README"'
printf 'def exact_match(pred, gold):\n    return float(pred.strip() == gold.strip())\n' > evalkit/metrics.py
quiet 'git add . && git commit -m "Add exact-match metric"'
quiet 'git push -u origin main'
quiet 'git clone ../origin.git ../asha-evalkit'

snip 01-refs
run "git for-each-ref --format='%(objectname:short) %(refname)'"
run 'git branch -vv'

snip 02-upstream
run "git rev-parse --abbrev-ref '@{upstream}'"
run "git rev-parse --symbolic-full-name '@{u}'"
run 'git config get branch.main.remote'
run 'git config get branch.main.merge'
run 'git status -sb'

snip 03-last-known-state
as asha
printf 'name: ci\n' > ../asha-evalkit/ci.yaml
quiet 'git -C ../asha-evalkit add . && git -C ../asha-evalkit commit -m "Add CI workflow" && git -C ../asha-evalkit push origin main'
as you
note 'Asha has pushed one commit to the server. Your repository has not been told.'
run 'git status -sb'
run 'git rev-parse --short origin/main'
run 'git fetch'
run 'git rev-parse --short origin/main'
run 'git status -sb'

snip 04-setting-upstream
run 'git switch -c feature/rouge'
run_rc "git rev-parse --abbrev-ref '@{upstream}'"
run 'git switch -c hotfix/ci origin/main'
run 'git branch -vv'

lab_end
