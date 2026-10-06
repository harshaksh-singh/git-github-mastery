#!/usr/bin/env bash
# Chapter 14D, section 14D.8: two experimental inspection commands of Git 2.52,
# "git last-modified" and "git repo".
. "$(dirname "$0")/../lib/lab-env.sh"
. "$LAB_SCRIPT_DIR/fixtures.bash"
lab_begin ch14d inspect
fx_gateway_server
cd dev || exit 1
quiet 'git merge fix/timeout'

snip 01-last-modified
run 'git log --oneline --graph'
note 'One line per entry of the top-level tree: the commit that last changed it.'
run 'git last-modified'
run 'git last-modified -r'

snip 02-compare
note 'The same answer for one path, the way it was asked before Git 2.52:'
run "git log -1 --format='%H' -- src/limits.yaml"
note 'A revision range limits the search:'
run 'git last-modified -r HEAD~1 -- src'

snip 03-repo-info
run 'git repo info --keys'
run 'git repo info --all'
run 'git -C ../server.git repo info layout.bare references.format'

snip 04-repo-structure
run 'git repo structure --format=lines | grep -e count -e inflated'

lab_end
