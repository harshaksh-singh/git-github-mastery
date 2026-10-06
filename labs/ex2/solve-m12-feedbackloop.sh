#!/usr/bin/env bash
# Model solution of exercise 12.11 (Level 5): the owner's clone has nothing left, so the branch
# is rebuilt from a teammate's stale remote-tracking ref and a mailed patch.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$LAB_SCRIPT_DIR/replay-lib.bash"
lab_begin ex2 solve-m12-feedbackloop
ex_load m12-feedbackloop
as config                      # each clone uses the identity in its own configuration, as in labs/shell

snip 01-ravi
run 'git -C ravi branch -a'
run 'git -C ravi reflog | wc -l'
run 'git -C ravi fsck --lost-found'
run 'git -C ravi count-objects -v | grep -E "^(count|in-pack|packs)"'
run 'git -C ravi ls-remote origin'

snip 02-inventory
run 'git -C asha branch -r -v'
run 'git -C you branch -r -v'
run 'ls asha/inbox'

snip 03-trap
run 'git -C you config list --local | grep -E "^(fetch|remote)"'
run 'git -C you fetch --dry-run'

snip 04-anchor
run 'git -C you branch rescue/dedupe-feedback origin/feature/dedupe-feedback'
run 'git -C you log --oneline main..rescue/dedupe-feedback'
run 'git -C asha log --oneline main..origin/feature/dedupe-feedback'

snip 05-patch
run 'sed -n 1,4p asha/inbox/0001-Skip-feedback-older-than-the-retention-window.patch'
run 'git -C you apply --stat ../asha/inbox/0001-Skip-feedback-older-than-the-retention-window.patch'

snip 06-rebuild
run 'cd ravi'
run 'git fetch ../you rescue/dedupe-feedback:feature/dedupe-feedback'
run 'git switch feature/dedupe-feedback'
run 'git am ../asha/inbox/0001-Skip-feedback-older-than-the-retention-window.patch'
run "git log --format='%h  author %an  committer %cn  %s' main..HEAD"

snip 07-what-is-new
orig=$(sed -n '1s/^From \([0-9a-f]*\) .*/\1/p' ../asha/inbox/0001-Skip-feedback-older-than-the-retention-window.patch)
run "git cat-file -t ${orig:0:7}"
run "git log -1 --format='%H%n author date    %ad%n' HEAD"

snip 08-publish
run 'git push -u origin feature/dedupe-feedback'
run 'git -C ../you branch -D rescue/dedupe-feedback'
run 'git -C ../you fetch'
run 'git -C ../you branch -r'
run 'cd ..'
show_check
ex_done
