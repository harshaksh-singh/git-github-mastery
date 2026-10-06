#!/usr/bin/env bash
# Lab 7.1 replay: build a bare server and two clones by hand and watch every ref
# before and after each operation. Lab manual: lab-manual/m07-remotes.md.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$(dirname "$0")/fixture.bash"
lab_begin ch12 lab-07-1-bare-server-two-clones

# In this lab the identity comes from configuration, exactly as when you type it by hand:
# "Lab User" from the global file, "Asha Rao" from the configuration of Asha's clone.
as config

snip 01-server
run 'git init --bare server/support-bot.git'
run 'ls -F server/support-bot.git'
run_rc 'git -C server/support-bot.git show-ref'

snip 02-first-clone
run 'git clone server/support-bot.git you/support-bot'
run 'cd you/support-bot'
run 'git config get --all --show-names --regexp "^(remote|branch)\."'
run_rc 'git show-ref'

snip 03-first-commit
run "printf '# support-bot\n' > README.md"
run 'git add README.md'
run 'git commit -m "Add README"'
note 'Refs in your clone, then refs on the server:'
run 'git show-ref --abbrev'
run_rc 'git -C ../../server/support-bot.git show-ref --abbrev'

snip 04-first-push
run 'git push'
note 'Refs in your clone, then refs on the server:'
run 'git show-ref --abbrev'
run 'git -C ../../server/support-bot.git show-ref --abbrev'

snip 05-second-clone
run 'cd ../..'
run 'git clone server/support-bot.git asha/support-bot'
run 'cd asha/support-bot'
run 'git config set user.name "Asha Rao"'
run 'git config set user.email asha@example.com'
run 'git show-ref --abbrev'

snip 06-asha-pushes
run "printf 'model: small-v1\ntop_k: 5\n' > config.yaml"
run 'git add config.yaml'
run 'git commit -m "Add retrieval config"'
run 'git push'

snip 07-three-views
note 'Asha:'
run 'git show-ref --abbrev'
note 'The server:'
run 'git -C ../../server/support-bot.git show-ref --abbrev'
note 'You:'
run 'git -C ../../you/support-bot show-ref --abbrev'

snip 08-you-fetch
run 'cd ../../you/support-bot'
run 'git status'
run 'git fetch'
run 'git show-ref --abbrev'
run 'git status -sb'

snip 09-you-integrate
run 'git merge --ff-only origin/main'
run 'git show-ref --abbrev'
run 'git log --format="%h %an: %s"'

snip 10-failure
run 'git update-ref -d refs/remotes/origin/main'
run 'git show-ref --abbrev'
run 'git status'
run_rc 'git rev-parse origin/main'

snip 11-recovery
run 'git fetch'
run 'git show-ref --abbrev'
run 'git status -sb'

snip 12-verification
run 'git rev-parse main origin/main'
run 'git ls-remote origin refs/heads/main'
run 'git -C ../../asha/support-bot rev-parse main'

lab_end
