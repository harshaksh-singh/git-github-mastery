#!/usr/bin/env bash
# The Git side of CODEOWNERS: which of the three documented locations exists on the base branch,
# what the file says there, how large it is, which paths a pull request changes, and why a pull
# request that edits the file is still judged by the old version. Chapter 19, sections 19.3 and 19.7.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$(dirname "$0")/fixture.bash"
lab_begin ch18 codeowners-base
scenario_codeowners

snip 01-which-file
note 'The documented search order, applied to the base branch of the pull request:'
run 'for p in .github/CODEOWNERS CODEOWNERS docs/CODEOWNERS; do git cat-file -e origin/main:$p 2>/dev/null && echo "exists on main: $p"; done'
note 'The first one found is used. Its size in bytes (the documented limit is 3 MB):'
run 'git cat-file -s origin/main:.github/CODEOWNERS'

snip 02-base-version
run 'git show origin/main:.github/CODEOWNERS'

snip 03-changed-paths
note 'The paths this pull request changes (three dots, as on the Files changed tab):'
run 'git diff --name-only origin/main...HEAD'

snip 04-pr-edits-the-file
note 'The pull request also edits CODEOWNERS. On its own branch the docs line is gone:'
run 'git diff origin/main...HEAD -- .github/CODEOWNERS'
note 'Review requests come from the base version, which still has it:'
run_rc 'git show origin/main:.github/CODEOWNERS | grep -n "^docs"'
run_rc 'git show HEAD:.github/CODEOWNERS | grep -n "^docs"'

lab_end
