#!/usr/bin/env bash
# Chapter 14B, section 14B.12: a version derived from tags needs the tags and the history
# between them. A depth-1 clone, the default of most CI checkouts, has neither.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$(dirname "$0")/fixture.bash"
lab_begin ch14b describe-shallow
make_server_and_clones you
enter you
hidden 'git tag -a v1.0.0 -m "inference-gateway 1.0.0"'
commit_file gateway/health.py 'def healthy():\n    return True\n' 'Add health endpoint'
commit_file gateway/auth.py 'def check(token):\n    return bool(token)\n' 'Add token check'
hidden 'git push --follow-tags origin main'

snip 01-full-clone
run 'git describe'

snip 02-shallow
run 'cd ../..'
run 'git clone -q --depth 1 "file://$PWD/server/inference-gateway.git" ci/inference-gateway'
run 'cd ci/inference-gateway'
run 'git rev-parse --is-shallow-repository'
run 'git log --oneline'
run 'git tag'
run_rc 'git describe'
run 'git describe --always'

snip 03-tags-without-history
run 'git fetch -q --depth 1 origin tag v1.0.0'
run 'git tag'
run_rc 'git describe'

snip 04-unshallow
run 'git fetch --unshallow'
run 'git rev-parse --is-shallow-repository'
run 'git describe'

lab_end
