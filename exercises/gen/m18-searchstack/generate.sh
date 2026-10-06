#!/usr/bin/env bash
# Exercise 18.9 (Level 4): a clone on the build machine that cannot see a branch, a tag or the
# history, although "git fetch" reports nothing to do. Builds server.git and the clone build/
# of the monorepo "searchstack". Read SYMPTOMS.md, not this file: the script is the answer.
. "$(dirname "${BASH_SOURCE[0]}")/../../../labs/lib/lab-env.sh"
. "$COURSE_ROOT/labs/ex2/gen-lib.bash"
. "$COURSE_ROOT/labs/ex2/m18-fixture.bash"
ex_begin m18-searchstack

m18_server
quiet "git clone --depth 1 --no-tags --single-branch \"file://\$PWD/server.git\" build"

ex_end build
