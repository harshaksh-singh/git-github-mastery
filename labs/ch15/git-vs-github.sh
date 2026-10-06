#!/usr/bin/env bash
# Chapter 15, section 15.2: what is Git data. Everything a clone or a mirror receives is a
# ref or an object. Files that configure the platform are tracked files. A closing keyword
# is text in a commit message. A bare repository on disk plays the server.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$LAB_SCRIPT_DIR/fixture.bash"
lab_begin ch15 git-vs-github
scenario_19_2
rm -rf "$LAB_DIR/you"

snip 01-clone
run 'git clone server/practice-repo.git you/practice-repo'
run 'cd you/practice-repo'
run 'git for-each-ref --format="%(objecttype) %(refname)"'

snip 02-platform-files
note 'Files that GitHub reads are ordinary tracked files:'
run 'git ls-files .github README.md CONTRIBUTING.md SECURITY.md'

snip 03-message
run 'git log -1 --format=%B origin/feature/list-names'
run 'git log --all --oneline --grep="#12"'

snip 04-mirror
run 'cd ../..'
run 'git clone --mirror server/practice-repo.git backup/practice-repo.git'
run 'git -C backup/practice-repo.git for-each-ref --format="%(objecttype) %(refname)"'
run 'git -C backup/practice-repo.git rev-list --all --objects | wc -l | tr -d " "'

lab_end
