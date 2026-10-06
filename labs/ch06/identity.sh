#!/usr/bin/env bash
# Chapter 6, section 6.13 (what can go wrong): a commit recorded under the wrong identity.
# Git copies name and email into the commit from the environment or the configuration and
# never checks them. "git var GIT_AUTHOR_IDENT" previews the identity before you commit,
# "git commit --amend --reset-author" repairs the last unpublished commit, and
# user.useConfigOnly stops Git from guessing an identity when none is configured.
# The lab's fixed identity variables are removed first ("as config"), so that Git reads the
# configuration the way it does in an ordinary shell.
. "$(dirname "$0")/../lib/lab-env.sh"
lab_begin ch06 identity

quiet 'git init evalkit'
cd evalkit || exit 1
mkdir -p evalkit
printf '# evalkit\n\nSmall evaluation harness for LLM outputs.\n' > README.md
quiet 'git add . && git commit -m "Add README"'
as config
# A repository-local email left over from a side project.
quiet 'git config set user.email lab.user@personal.example'
printf 'def call_judge(client, prompt):\n    return client.post(prompt)\n' > evalkit/judge.py

snip 01-wrong-email
run 'git add evalkit/judge.py'
run 'git commit -q -m "Add judge client"'
run "git log --format='%h  %an <%ae>  %s'"

snip 02-diagnose
run 'git var GIT_AUTHOR_IDENT'
run 'git config get --show-scope --show-origin --all user.email'

snip 03-fix
run 'git config unset user.email'
run 'git var GIT_AUTHOR_IDENT'
run 'git commit --amend --no-edit --reset-author'
run "git log --format='%h  %an <%ae>  %s'"

snip 04-no-guessing
quiet 'git config unset --global user.email'
note 'In this sandbox user.email is now configured nowhere.'
run_rc 'git -c user.useConfigOnly=true commit --allow-empty -m "Re-run the nightly evaluation"'

lab_end
