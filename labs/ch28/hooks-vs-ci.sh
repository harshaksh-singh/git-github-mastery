#!/usr/bin/env bash
# Chapter 28, section 28.10: a local hook fails open. The same checks run from a shared hook
# and from the CI entry point; the hook is skipped with one flag and is absent from a fresh
# clone; the CI run over the pushed range catches both.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$(dirname "$0")/fixture.bash"
lab_begin ch28 hooks-vs-ci
fx_docqa 7
hidden 'git init --bare ../server.git && git remote add origin ../server.git && git push -u origin main'

snip 01-hook-blocks
run 'cat hooks/pre-commit'
run 'git config get core.hooksPath'
run 'git switch -q -c feature/deploy-script'
run "mkdir deploy && printf -- '-----BEGIN OPENSSH PRIVATE KEY-----\nnot-a-real-key\n-----END OPENSSH PRIVATE KEY-----\n' > deploy/id_deploy"
run 'git add deploy'
run_rc 'git commit -m "Add deploy key for the staging box"'

snip 02-no-verify
note 'One flag skips the hook:'
run_rc 'git commit -q --no-verify -m "Add deploy key for the staging box"'
run 'git push -q -u origin feature/deploy-script'

snip 03-clone-has-no-hook
run 'git clone -q ../server.git ../docqa-asha && cd ../docqa-asha'
run_rc 'git config get core.hooksPath'
run 'git switch -q -c feature/eval-dump'
python3 -c "import sys; sys.stdout.write('{\"rows\": [' + ', '.join(['\"ticket text\"'] * 60000) + ']}\n')" > evals/dump.json
run 'wc -c < evals/dump.json'
run 'git add evals/dump.json && git commit -q -m "Add evaluation dump for debugging"'
run 'git push -q -u origin feature/eval-dump'

snip 04-ci
note 'CI checks out each pushed branch and runs the same script over the range it adds:'
run 'cat ci/check.sh'
run_rc 'sh ci/check.sh origin/main'
run 'git switch -q feature/deploy-script'
run_rc 'sh ci/check.sh origin/main'
run 'git switch -q main'
run_rc 'sh ci/check.sh origin/main~3'
lab_end
