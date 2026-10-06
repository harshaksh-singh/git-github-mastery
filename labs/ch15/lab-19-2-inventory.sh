#!/usr/bin/env bash
# Lab 19.2 replay, the Git half of the inventory: every ref and object a clone and a mirror
# receive from a server, the platform configuration that is tracked files, and a closing
# keyword that is text. A bare repository on disk stands in for GitHub.
# Failure scenario: the server is lost; what a mirror brings back, and what it cannot.
# Lab manual: lab-manual/m19-github-platform.md.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$LAB_SCRIPT_DIR/fixture.bash"
lab_begin ch15 lab-19-2-inventory
scenario_19_2

snip 01-refs
run 'cd you/practice-repo'
run 'git ls-remote origin'
run 'git for-each-ref --format="%(objecttype) %(refname)"'

snip 02-objects
run 'git rev-list --all --objects | wc -l | tr -d " "'
run 'git cat-file -p v0.1.0'

snip 03-tracked-platform-files
run 'git ls-files .github'
run 'git log -1 --format="%h %an%n%n%B" origin/feature/list-names'

snip 04-local-only
note 'Things in your .git that the server never had and no clone receives:'
run 'git config list --local --name-only'
run 'git reflog -2'

snip 05-mirror
run 'cd ../..'
run 'git clone --mirror server/practice-repo.git backup/practice-repo.git'
run 'git -C backup/practice-repo.git for-each-ref --format="%(objecttype) %(refname)"'

snip 06-checkpoint
run 'git -C backup/practice-repo.git rev-list --all --objects | wc -l | tr -d " "'
run 'git -C server/practice-repo.git rev-list --all --objects | wc -l | tr -d " "'

snip 07-failure
note 'The server is gone: deleted by mistake, or the organization lost access.'
run 'rm -rf server/practice-repo.git'
run_rc 'git -C you/practice-repo fetch origin'

snip 08-recovery
run 'git init -q --bare server/practice-repo.git'
run 'git -C backup/practice-repo.git push --mirror ../../server/practice-repo.git'
run 'git -C you/practice-repo fetch origin'

snip 09-verification
run 'git -C server/practice-repo.git for-each-ref --format="%(objecttype) %(refname)"'
run 'git -C you/practice-repo status -sb'

lab_end
