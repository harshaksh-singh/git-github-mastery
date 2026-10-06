#!/usr/bin/env bash
# Lab 19.1 replay, the Git half: turn the practice repository files into a repository, make
# the first commit, and push it. In the lab the push goes to GitHub through
# "gh repo create --source=. --push"; here a bare repository on disk stands in for GitHub,
# and "git remote add" plus "git push -u" do what that command does on the Git side.
# Failure scenario: a first branch called master, pushed as main.
# Lab manual: lab-manual/m19-github-platform.md.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$LAB_SCRIPT_DIR/fixture.bash"
lab_begin ch15 lab-19-1-practice-repo
scenario_19_1
hidden "git init --bare '$LAB_DIR/github-stand-in/practice-repo.git'"

snip 01-files
run 'cd practice-repo'
run 'find . -type f | sort'

snip 02-init-and-check
run 'git init -b main'
run 'git config get user.name; git config get user.email'
run 'python3 -m unittest discover -s tests 2>&1 | tail -1'
run 'git status --short'

snip 03-first-commit
run 'git add .'
run 'git status --short'
run 'git commit -q -m "Add practice repository skeleton"'
run 'git log --oneline --stat --format="%h %an <%ae>%n   %s" | head -8'

snip 04-push
note 'Stand-in for: gh repo create YOUR-ORG/practice-repo --public --source=. --remote=origin --push'
run 'git remote add origin ../github-stand-in/practice-repo.git'
run 'git push -u origin main'
run 'git status -sb'

snip 05-checkpoint
run 'git ls-remote origin'
run 'git rev-parse HEAD'
run 'git ls-files | wc -l | tr -d " "'

snip 06-failure
note 'A scratch repository created without the -b option, by a Git that has no init.defaultBranch:'
run 'cd ..'
run 'git init -q --bare github-stand-in/scratch.git'
run 'git -c init.defaultBranch=master init -q scratch && cd scratch'
run 'git commit -q --allow-empty -m "First commit"'
run 'git remote add origin ../github-stand-in/scratch.git'
run_rc 'git push -u origin main'
run 'git branch'

snip 07-recovery
run 'git branch -m master main'
run 'git branch'
run 'git push -u origin main'

snip 08-verification
run 'cd ../practice-repo'
run 'git branch -vv'
run 'git ls-remote origin'

lab_end
