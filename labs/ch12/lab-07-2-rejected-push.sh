#!/usr/bin/env bash
# Lab 7.2 replay: a rejected push; fetch, then integrate by merge (you) and by rebase
# (Ravi); a forced push as the failure scenario and a recovery without a second force.
# Lab manual: lab-manual/m07-remotes.md.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$(dirname "$0")/fixture.bash"
lab_begin ch12 lab-07-2-rejected-push
scenario_07_2

snip 01-rejected
run 'cd you/support-bot'
run 'git status -sb'
run_rc 'git push'

snip 02-fetch-and-look
run 'git fetch'
run 'git status -sb'
run 'git log --oneline --graph --decorate --all'
run_rc 'git push'

snip 03-merge-and-push
run 'git merge origin/main'
run 'git push'
run 'git log --oneline --graph --decorate'

as ravi
snip 04-ravi-rejected
run 'cd ../../ravi/support-bot'
run_rc 'git push'
run 'git fetch'
run 'git log --oneline --graph --decorate --all'

snip 05-rebase-and-push
run 'git rebase origin/main'
run 'git push'
run 'git log --oneline --graph --decorate'

snip 06-checkpoint
run 'git rev-parse main'
run 'git ls-remote origin refs/heads/main'
run 'git -C ../../server/support-bot.git log --oneline main'

as asha
snip 07-failure-force
run 'cd ../../asha/support-bot'
run "printf 'model: small-v1\ntop_k: 6\n' > config.yaml"
run 'git commit -am "Lower top_k to 6"'
run_rc 'git push'
run 'git push --force'

snip 08-damage
run 'git -C ../../server/support-bot.git log --oneline main'

# What "git pull --rebase" would do in Ravi's position, tried on a throw-away copy of
# his clone. The lab manual does not ask for this; the answer key uses the transcript.
as ravi
cp -R "$LAB_DIR/ravi" "$LAB_DIR/ravi-copy"
snip 20-what-if-pull-rebase
note 'In a copy of the clone of Ravi, not in the lab itself:'
run 'cd ../../ravi-copy/support-bot'
run 'git pull --rebase'
run 'git log --oneline --decorate'
hidden 'cd ../../asha/support-bot'

snip 09-recovery-see
run 'cd ../../ravi/support-bot'
run 'git fetch'
run 'git status -sb'
run 'git log --oneline --graph --decorate --all'

snip 10-recovery-merge
run 'git merge origin/main'
run 'git push'
run 'git log --oneline --graph --decorate'

as asha
snip 11-asha-catches-up
run 'cd ../../asha/support-bot'
run 'git pull --ff-only'

snip 12-verification
run 'git rev-parse main'
run 'git -C ../../ravi/support-bot rev-parse main'
run 'git ls-remote origin refs/heads/main'
run 'git rev-list --count main'

lab_end
