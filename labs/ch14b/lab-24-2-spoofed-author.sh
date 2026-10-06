#!/usr/bin/env bash
# Lab 24.2 replay, deterministic part: commits that claim another author, made with nothing
# but an option and two configuration values, accepted by the server.
# The part with signatures is in lab-24-2-spoofed-author-volatile.sh.
# Lab manual: lab-manual/m24-signing-local.md.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$(dirname "$0")/fixture.bash"
lab_begin ch14b lab-24-2-spoofed-author
scenario_24_2
as config

snip 01-start
run 'cd you/inference-gateway'
run "git log -2 --format='%h  author=%an <%ae>  committer=%cn <%ce>  %s'"

snip 02-author-flag
run "printf 'requests_per_minute: 6000\n' > config/limits.yaml"
run 'git commit -q -am "Raise the rate limit" --author="Asha Rao <asha@example.com>"'
run "git log -1 --format='%h  author=%an <%ae>  committer=%cn <%ce>  %s'"

snip 03-both-fields
run "printf 'requests_per_minute: 60000\n' > config/limits.yaml"
run 'git -c user.name="Asha Rao" -c user.email=asha@example.com commit -q -am "Raise the rate limit again"'
run "git log -3 --format='%h  author=%an <%ae>  committer=%cn <%ce>  %s'"

snip 04-compare
run 'git cat-file -p HEAD~2 | sed -n "/^author/,/^committer/p"'
run 'git cat-file -p HEAD | sed -n "/^author/,/^committer/p"'
run "git log -3 --format='%h  %G?  %an'"

snip 05-push
run 'git push'
run 'cd ../../asha/inference-gateway'
run 'git pull -q'
run 'git shortlog -sne HEAD'
run "git log -2 --format='%h  %an <%ae>  %s'"

lab_end
