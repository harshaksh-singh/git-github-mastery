#!/usr/bin/env bash
# Lab 23.2 replay (the Git half): everything about a CODEOWNERS decision that can be read from
# the repository itself: which file is used, the version on the base branch, the changed
# paths. Then the tempting shortcut of asking git check-ignore, and why it gives wrong answers.
# Lab manual: lab-manual/m23-governance.md.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$(dirname "$0")/fixture.bash"
lab_begin ch18 lab-23-2-codeowners
scenario_codeowners
cd "$LAB_DIR" || exit 1

snip 01-observe
run 'cd you/ticket-router'
run 'git status -sb'
run 'git log --oneline origin/main..HEAD'

snip 02-which-file
run 'for p in .github/CODEOWNERS CODEOWNERS docs/CODEOWNERS; do git cat-file -e origin/main:$p 2>/dev/null && echo "exists on main: $p"; done'

snip 03-base-version
run 'git show origin/main:.github/CODEOWNERS | grep -n "^[^#]"'

snip 04-changed-paths
run 'git diff --name-only origin/main...HEAD'

snip 05-checkpoint
note 'The version on your branch differs. It does not decide this pull request:'
run 'git diff --stat origin/main...HEAD -- .github/CODEOWNERS'
run_rc 'git show HEAD:.github/CODEOWNERS | grep -n "^docs"'

snip 06-failure
note 'The shortcut: strip the owners and let Git match the patterns as if they were ignore rules.'
run "git show origin/main:.github/CODEOWNERS | sed -E 's/[[:space:]]+@.*//' > ../patterns"
run 'git -c core.excludesFile=../patterns check-ignore -v --no-index config/routing.yaml docs/README.md docs/runbooks/escalation.md .github/CODEOWNERS'

snip 07-recovery
note 'Isolate the mechanism. A catch-all line followed by *.yaml, asked about two paths:'
run "printf '*\n*.yaml\n' > ../two"
run 'git -c core.excludesFile=../two check-ignore -v --no-index routing.yaml config/routing.yaml'
note 'Git decided config/routing.yaml at the directory config/, which line 1 matches.'
note 'And docs/* on a nested file, which the CODEOWNERS documentation says it does not match:'
run "printf 'docs/*\n' > ../two"
run 'git -c core.excludesFile=../two check-ignore -v --no-index docs/runbooks/escalation.md'
run 'rm ../two ../patterns'

snip 08-verification
run 'git status -sb'
run 'git diff --name-only origin/main...HEAD | grep -c .'

lab_end
