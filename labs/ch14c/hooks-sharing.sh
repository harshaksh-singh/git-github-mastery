#!/usr/bin/env bash
# Chapter 14C, section 14C.11: hooks are not cloned. Three ways to share them: a tracked
# directory plus core.hooksPath, hooks defined in configuration (Git 2.54), and "git hook".
# Also: which switch turns off which kind of hook.
. "$(dirname "$0")/../lib/lab-env.sh"
lab_begin ch14c hooks-sharing

quiet 'git init --bare server.git'
quiet 'git clone server.git you'
cd you || exit 1
quiet "printf 'def infer(batch):\n    return model(batch)\n' > infer.py && git add . && git commit -m 'Add inference entry point' && git push -u origin main"
quiet "cp '$LAB_SCRIPT_DIR/files/check-marker' .git/hooks/pre-commit && chmod +x .git/hooks/pre-commit"

snip 01-not-cloned
run 'cat .git/hooks/pre-commit'
run "printf 'def infer(batch):\n    print(batch)  # NOCOMMIT\n    return model(batch)\n' > infer.py"
run_rc 'git commit -am "Debug inference"'
quiet 'git restore infer.py'
note 'A teammate clones the same repository:'
run 'git clone -q ../server.git ../asha'
run 'ls ../asha/.git/hooks | grep -v sample'
run "printf 'def infer(batch):\n    print(batch)  # NOCOMMIT\n    return model(batch)\n' > ../asha/infer.py"
run_rc 'git -C ../asha commit -q -am "Debug inference"'
run 'git -C ../asha log --oneline -1'
quiet 'git -C ../asha reset --hard HEAD^'

snip 02-hookspath
note 'Put the hook into a tracked directory and point core.hooksPath at it:'
run 'mkdir .githooks && mv .git/hooks/pre-commit .githooks/pre-commit'
run 'git add .githooks && git commit -q -m "Share hooks through .githooks" && git push -q'
run 'git config set core.hooksPath .githooks'
run 'git rev-parse --git-path hooks'
note 'The directory arrives with a pull. The setting does not: every clone must make it once.'
run 'git -C ../asha pull -q'
run 'ls ../asha/.githooks'
run_rc 'git -C ../asha config get core.hooksPath'
run 'git -C ../asha config set core.hooksPath .githooks'
run "printf 'def infer(batch):\n    print(batch)  # NOCOMMIT\n    return model(batch)\n' > ../asha/infer.py"
run_rc 'git -C ../asha commit -q -am "Debug inference"'

snip 03-config-hooks
note 'Since Git 2.54 a hook can be a configuration entry: a name, a command, and one or more events.'
run 'git config unset core.hooksPath'
run 'git config set hook.marker.command .githooks/pre-commit'
run 'git config set --append hook.marker.event pre-commit'
run "git config set --global hook.whoami.command 'echo \"committing as \$(git config get user.email)\"'"
run 'git config set --global hook.whoami.event pre-commit'
run "printf '#!/bin/sh\necho \"hook file in .git/hooks ran\"\n' > .git/hooks/pre-commit && chmod +x .git/hooks/pre-commit"
run 'git hook list --show-scope pre-commit'
run 'git commit --allow-empty -m "Empty commit to watch the hooks"'

snip 04-switches
note 'core.hooksPath=/dev/null silences the hooks directory, not the configured hooks:'
run 'git -c core.hooksPath=/dev/null commit --allow-empty -m "Second empty commit"'
note '--no-verify skips every pre-commit hook, wherever it is defined:'
run 'git commit --no-verify --allow-empty -m "Third empty commit"'
note 'One named hook off, in this repository only:'
run 'git config set hook.whoami.enabled false'
run 'git hook list --show-scope pre-commit'

snip 05-hook-run
note 'Run the hooks of an event by hand, for example from a CI job:'
run_rc 'git hook run pre-commit'
run_rc 'git hook list commit-msg'

lab_end
