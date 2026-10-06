#!/usr/bin/env bash
# Lab 0.1: verify the toolchain and build the sandbox.
# VOLATILE: this transcript depends on the machine (PATH order, installed versions, build
# options), so labs/verify-all.sh only checks that the script runs.
. "$(dirname "$0")/../lib/lab-env.sh"
lab_begin ch01 lab-00-1-toolchain --volatile

snip 01-which
run 'which -a git'
run 'git --version'
run '/usr/bin/git --version'

snip 02-build-options
run 'git version --build-options'

snip 03-smoke-test
# The nested run gets its own lab root inside this sandbox, so nothing outside it is touched.
export GIT_MASTERY_LABS="$LAB_DIR/nested-lab-root"
cd "$COURSE_ROOT" || exit 1
note 'Run from the course folder.'
run 'labs/verify-all.sh ch00'
cd "$LAB_DIR" || exit 1
unset GIT_MASTERY_LABS

snip 04-sandbox
note 'Typed inside the lab shell. The replay prints the paths of its own sandbox.'
run 'echo "$GIT_CONFIG_GLOBAL"'
run 'git config list --show-origin --show-scope'
run 'git config get user.email'
run 'git config set --global alias.lab-probe "status --short --branch"'
run 'git config get --show-origin --show-scope alias.lab-probe'

snip 05-wrong-git
note 'Failure scenario: a shell whose PATH finds the Apple Git first.'
run 'PATH="/usr/bin:$PATH"'
run 'which git'
run 'git --version'
run_rc 'git history -h'

snip 06-recover
note 'Recovery: put the Homebrew directory back in front.'
run 'PATH="/opt/homebrew/bin:$PATH"'
run 'which git'

snip 07-verify
run 'git --version'
run_rc 'git history -h'

lab_end
