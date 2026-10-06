#!/usr/bin/env bash
# Chapter 14B, section 14B.19: author and committer are assertions. You create commits that
# claim to be Asha's, on your own machine, with nothing but configuration, and the server
# accepts them. No keys are involved, so this demo is deterministic.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$(dirname "$0")/fixture.bash"
lab_begin ch14b spoof-author
make_server_and_clones you asha
enter asha
commit_file gateway/health.py 'def healthy():\n    return True\n' 'Add health endpoint'
hidden 'git push'
enter you
hidden 'git pull'
# Identity from configuration from here on, as on a real machine.
as config

snip 01-real
run "git log -2 --format='%h  author=%an <%ae>  committer=%cn <%ce>  %s'"

snip 02-author-flag
run "printf 'requests_per_minute: 6000\n' > config/limits.yaml"
run 'git commit -q -am "Raise the rate limit" --author="Asha Rao <asha@example.com>"'
run "git log -1 --format='%h  author=%an <%ae>  committer=%cn <%ce>  %s'"

snip 03-full-impersonation
run "printf 'requests_per_minute: 60000\n' > config/limits.yaml"
run 'git -c user.name="Asha Rao" -c user.email=asha@example.com commit -q -am "Raise the rate limit again"'
run "git log -3 --format='%h  author=%an <%ae>  committer=%cn <%ce>  %s'"

snip 04-objects-compared
note 'Her real commit and your forgery, header by header (tree, parent and dates differ, as for any two commits):'
run 'git cat-file -p HEAD~2 | sed -n "/^author/,/^committer/p"'
run 'git cat-file -p HEAD | sed -n "/^author/,/^committer/p"'

snip 05-server-accepts
run 'git push'
run "git -C ../../server/inference-gateway.git log -3 --format='%h  %an <%ae>  %s'"
run 'git shortlog -sne HEAD'

snip 06-what-is-signed
run "git log -3 --format='%h  %G?  %an  %s'"

lab_end
