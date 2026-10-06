#!/usr/bin/env bash
# Lab 25.1 replay, the Git half of a feature cycle that the lab drives with gh: branch,
# commit, push, a second commit after review, and the local clean-up after a squash merge.
# A bare repository on disk stands in for GitHub. The squash merge itself is done by a
# scratch clone with plain Git (fixture function platform_squash_merge); a note in the
# transcript marks that step.
# Failure scenario: "git branch -D" as a habit, used on a branch that was never merged.
# Lab manual: lab-manual/m25-github-cli-api.md.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$LAB_SCRIPT_DIR/fixture.bash"
lab_begin ch15 lab-25-1-feature-cycle
scenario_25_1

snip 01-branch
run 'cd you/practice-repo'
run 'git switch -c feature/list-names'
run "printf '\n    def names(self):\n        \"\"\"Return the registered prompt names, sorted.\"\"\"\n        return sorted(self._versions)\n' >> src/prompt_registry/registry.py"
run 'git diff --stat'
run 'python3 -m unittest discover -s tests 2>&1 | tail -1'
run 'git commit -q -am "Add names() to list registered prompts"'

snip 02-push
run 'git push -u origin feature/list-names'
run 'git status -sb'

snip 03-second-commit
note 'The pull request is open. A review comment asks for documentation:'
run "printf '\nnames() returns the registered prompt names in sorted order.\n' >> docs/architecture.md"
run 'git commit -q -am "Document names()"'
run 'git status -sb'
run 'git push'
run 'git log --oneline main..origin/feature/list-names'

platform_squash_merge practice-repo feature/list-names 'Add names() to list registered prompts (#2)'

snip 04-after-merge
note 'The pull request was merged on the platform with "Squash and merge", and the branch deleted there.'
run 'git switch main'
run 'git pull --ff-only'
run 'git log --oneline -3'

hidden "cp -R '$LAB_DIR/you' '$LAB_DIR/you-copy'"

snip 05-cleanup
run 'git fetch --prune'
run 'git branch -vv'
run_rc 'git branch -d feature/list-names'
run 'git diff --quiet main feature/list-names && echo "same content"'
run 'git branch -D feature/list-names'

snip 06-checkpoint
run 'git branch -a'
run 'git status -sb'
run 'python3 -m unittest discover -s tests 2>&1 | tail -1'

snip 07-failure
note 'New work, committed and never pushed. Then the clean-up habit strikes the wrong branch.'
run 'git switch -q -c docs/usage'
run "printf '\n## Usage\n\nRegister a template, then render it with values.\n' >> README.md"
run 'git commit -q -am "Add usage section to README"'
run 'git switch -q main'
run 'git branch -D docs/usage'
run 'git branch -a'

snip 08-recovery
run 'git reflog -3'
run "git branch docs/usage 'HEAD@{1}'"
run 'git log --oneline -1 docs/usage'

snip 09-verification
run 'git branch -vv'
run 'git log --oneline main..docs/usage'
run 'git diff --stat main docs/usage'

snip 20-what-if-d-before-prune
note 'In a copy of your clone, made before the clean-up: the same deletion without pruning first.'
run 'cd ../../you-copy/practice-repo'
run 'git branch -vv'
run_rc 'git branch -d feature/list-names'

lab_end
