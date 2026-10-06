#!/usr/bin/env bash
# The idea of a merge queue in plain Git: each queued pull request is merged, on a temporary
# branch, with the base branch and with everything ahead of it in the queue; checks run on that
# temporary commit; a failing entry is taken out and the entries behind it are rebuilt.
# The branch names use the documented prefix gh-readonly-queue/<base>/; everything else is
# an imitation by the author. Chapter 17, section 17.11.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$(dirname "$0")/fixture.bash"
lab_begin ch17 merge-queue
make_server
new_clone you
new_clone asha
new_clone ravi
enter you
hidden 'git switch -c fix/empty-subject'
classify_empty_subject
commit_all 'Accept tickets without a subject'
hidden 'git push -u origin fix/empty-subject'
enter ravi
hidden 'git switch -c fix/threshold'
printf 'model: router-small-v1\nconfidence_threshold: 0.65\nfallback_queue: general\n' | put config/routing.yaml
commit_all 'Lower the confidence threshold to 0.65'
hidden 'git push -u origin fix/threshold'
enter asha
hidden 'git switch -c docs/run-tests'
printf '# ticket-router\n\nSends each support ticket to the queue that can answer it.\n\nRun the tests with pytest.\n' | put README.md
commit_all 'Describe how to run the tests'
hidden 'git push -u origin docs/run-tests'
hidden 'git switch main'
hidden 'git fetch'
# The pull request heads, under the names the platform would give them.
hidden 'git branch pr-1 origin/fix/empty-subject'
hidden 'git branch pr-2 origin/fix/threshold'
hidden 'git branch pr-3 origin/docs/run-tests'
as queue

snip 01-three-prs
note 'Three approved pull requests, each one commit on top of the same main:'
run 'git log --oneline --graph main pr-1 pr-2 pr-3'

snip 02-queue-builds
note 'The queue, in order 1, 2, 3. Each temporary branch contains main and everything ahead of it:'
run 'git switch -q -c gh-readonly-queue/main/pr-1 main'
run 'git merge -q --no-ff -m "Merge pull request #1" pr-1'
run 'git switch -q -c gh-readonly-queue/main/pr-2'
run 'git merge -q --no-ff -m "Merge pull request #2" pr-2'
run 'git switch -q -c gh-readonly-queue/main/pr-3'
run 'git merge -q --no-ff -m "Merge pull request #3" pr-3'
run 'git log --oneline --graph main..gh-readonly-queue/main/pr-3'

snip 03-different-ids
note 'The commits that the checks must test are none of the pull request heads:'
run 'git for-each-ref --format="%(objectname:short) %(refname:short)" refs/heads/pr-* refs/heads/gh-readonly-queue'

snip 04-entry-fails
note 'The checks fail on the group of pull request 2. It leaves the queue; number 3 is rebuilt:'
run 'git branch -q -D gh-readonly-queue/main/pr-2'
run 'git switch -q -C gh-readonly-queue/main/pr-3 gh-readonly-queue/main/pr-1'
run 'git merge -q --no-ff -m "Merge pull request #3" pr-3'
run 'git log --oneline --graph main..gh-readonly-queue/main/pr-3'

snip 05-land
note 'The checks pass. The base branch moves to the tested commit, unchanged:'
run 'git switch -q main'
run 'git merge --ff-only gh-readonly-queue/main/pr-3'
run 'git log --oneline --first-parent -3'

lab_end
