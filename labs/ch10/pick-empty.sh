#!/usr/bin/env bash
# Chapter 10, section 10.8: cherry-picking a change that the branch already contains. The default
# stops; --empty=drop and --empty=keep choose in advance; --keep-redundant-commits is the old name.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$(dirname "$0")/fixtures/fixtures.sh"
lab_begin ch10 pick-empty
fx_gateway_fix
quiet 'git cherry-pick -x main~1'

snip 01-stop
note 'The fix is already on release/1.4. Someone picks it a second time.'
run_rc 'git cherry-pick -x main~1'

snip 02-skip
run 'git cherry-pick --skip'
run 'git log --oneline --decorate -2'

snip 03-drop
run 'git cherry-pick --empty=drop main~1'
run 'git log --oneline --decorate -2'

snip 04-keep
run 'git cherry-pick --empty=keep main~1'
run 'git show --stat --format="%h %s" HEAD'

snip 05-old-name
quiet 'git reset --hard HEAD~1'
run 'git cherry-pick --keep-redundant-commits main~1'
run 'git log --oneline --decorate -3'
lab_end
