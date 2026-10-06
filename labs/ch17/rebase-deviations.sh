#!/usr/bin/env bash
# Two documented differences between the "Rebase and merge" button and a local git rebase:
# the button always writes new commits with a new committer, and it drops commits that were
# empty to begin with. Local Git needs options to behave that way. Chapter 17, section 17.8.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$(dirname "$0")/fixture.bash"
lab_begin ch17 rebase-deviations
make_server
new_clone you
new_clone asha
feature_priority_routing
hidden 'git commit --allow-empty -m "Trigger CI again"'
hidden 'git push'
enter asha
hidden 'git fetch'

snip 01-already-on-top
note 'Asha, the maintainer. Nothing has landed on main since the branch was created:'
run 'git switch -q -c pr-1 origin/feature/priority-routing'
run 'git log --format="%h author=%an committer=%cn %s" main..pr-1'
run 'git rebase main'
run 'git log --format="%h author=%an committer=%cn %s" main..pr-1'

snip 02-force-new-commits
note 'What the documentation describes for the button: always new commits, new committer.'
run 'git rebase --no-ff main'
run 'git log --format="%h author=%an committer=%cn %s" main..pr-1'

snip 03-drop-empty
note 'And originally empty commits are dropped:'
run 'git rebase --no-ff --no-keep-empty main'
run 'git log --format="%h author=%an committer=%cn %s" main..pr-1'

lab_end
