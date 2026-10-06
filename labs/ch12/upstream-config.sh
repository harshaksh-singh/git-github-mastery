#!/usr/bin/env bash
# The upstream of a branch: the two configuration keys, the five ways they get set,
# and the @{upstream} and @{push} shorthands. Chapter 12, section 12.5.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$(dirname "$0")/fixture.bash"
lab_begin ch12 upstream-config

# Hidden setup: Asha has published feature/reranker; you have a fresh clone.
make_server
new_clone asha
enter asha
hidden 'git switch -c feature/reranker'
commit_file app/reranker.py 'def rerank(docs):\n    return docs\n' 'Add reranker stub'
hidden 'git push -u origin feature/reranker'
new_clone you
enter you

snip 01-no-upstream
run 'git switch -c feature/eval-harness'
commit_file eval/run_eval.py 'print("eval")\n' 'Add eval harness entry point'
run 'git branch -vv'
run_rc 'git push'

snip 02-push-u
run 'git push -u origin feature/eval-harness'
run 'git config get --all --show-names --regexp "^branch\.feature/eval-harness\."'
run 'git branch -vv'

snip 03-shorthands
run 'git rev-parse --abbrev-ref @{upstream}'
run 'git rev-parse --symbolic-full-name @{u} @{push}'
commit_file eval/cases.jsonl '{"q": "reset password", "expect": "kb-17"}\n' 'Add first eval case'
run 'git log --oneline @{u}..'
run 'git status -sb'

snip 04-guess
run 'git switch feature/reranker'
run 'git config get --all --show-names --regexp "^branch\.feature/reranker\."'

snip 05-branch-u
run 'git switch -c docs/runbook main'
run_rc 'git rev-parse --abbrev-ref @{u}'
run 'git branch -u origin/main'
run 'git status -sb'
run 'git branch --unset-upstream'
run 'git status -sb'

snip 06-auto-setup-remote
run 'git config set push.autoSetupRemote true'
commit_file docs/runbook.md '# Runbook\n' 'Start the runbook'
run 'git push'
run 'git branch -vv'

snip 07-simple-name-mismatch
run 'git switch -c latency-fix origin/main'
commit_file app/settings.py 'TIMEOUT_SECONDS = 30\n' 'Set request timeout'
run 'git branch -vv'
run_rc 'git push'

snip 08-push-default-dry-runs
run 'git -c push.default=upstream push --dry-run'
run 'git -c push.default=current push --dry-run'
run_rc 'git -c push.default=nothing push --dry-run'
run 'git -c push.default=matching push --dry-run'

lab_end
