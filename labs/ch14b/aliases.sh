#!/usr/bin/env bash
# Chapter 14B, section 14B.6: aliases. Five everyday aliases, each defined and run, then
# shell aliases with their two traps, and what an alias cannot do.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$(dirname "$0")/fixture.bash"
lab_begin ch14b aliases
sandbox_home
make_gateway "$HOME/work/inference-gateway"
hidden 'git switch -c feature/fallback-route'
commit_file gateway/router.py 'ROUTES = {"default": "small-v1", "fallback": "tiny-v1"}\n\n\ndef pick_backend(model):\n    return ROUTES.get(model, ROUTES["default"])\n' 'Add fallback route'
hidden 'git switch main'
commit_file config/limits.yaml 'requests_per_minute: 120\nmax_tokens: 2048\n' 'Raise the rate limit'

snip 01-define
run "git config set --global alias.st 'status -sb'"
run "git config set --global alias.lg 'log --graph --decorate --oneline --all'"
run "git config set --global alias.last 'log -1 --stat HEAD'"
run "git config set --global alias.unstage 'restore --staged --'"
run "git config set --global alias.amend 'commit --amend --no-edit'"
run 'git config get --all --show-names --regexp "^alias\."'

snip 02-st-lg-last
run 'git st'
run 'git lg'
run 'git last'

snip 03-unstage
run "printf 'burst: 20\n' >> config/limits.yaml"
run "printf 'scratch\n' > notes.txt"
run 'git add .'
run 'git st'
run 'git unstage notes.txt'
run 'git st'

snip 04-amend
run 'git log -1 --format="%h %s"'
run 'git amend'
run 'git log -1 --format="%h %s"'
run 'git show --stat --format="%h %s" HEAD'
run 'git reflog -2'

snip 05-trace
run "GIT_TRACE=1 git st 2>&1 | grep -E -o '(alias expansion|built-in): .*'"
run "GIT_TRACE=1 git lg -1 2>&1 | grep -E -o '(alias expansion|built-in): .*'"

snip 06-arguments
note 'Arguments after the alias name are appended to the expansion.'
run 'git lg -2'
run 'git last --format="%h %s" feature/fallback-route'
run "GIT_TRACE=1 git last --format='%h %s' feature/fallback-route 2>&1 | grep -E -o 'built-in: .*'"
run "git config set --global alias.last 'log -1 --stat'"
run 'git last --format="%h %s" feature/fallback-route'

snip 07-shell-alias
run "git config set --global alias.root '!pwd'"
run 'cd gateway'
run 'git root'
run "git config set --global alias.where '!echo \"prefix=\$GIT_PREFIX top=\$(pwd)\"'"
run 'git where'
run 'cd ..'

snip 08-shell-alias-arguments
run "git config set --global alias.tracked '!git ls-tree -r --name-only \$1 | head -2'"
run_rc 'git tracked HEAD'
run "GIT_TRACE=1 git tracked HEAD 2>&1 | grep -o 'start_command: .*'"
run "git config set --global alias.tracked '!f() { git ls-tree -r --name-only \"\${1:-HEAD}\" | head -2; }; f'"
run 'git tracked HEAD'
run 'git tracked feature/fallback-route'

snip 09-no-override
run "git config set --global alias.status 'status -sb'"
run 'git status'
run "GIT_TRACE=1 git status 2>&1 | grep -E -o '(alias expansion|built-in): .*'"
run 'git config unset --global alias.status'

snip 10-file
run 'sed -n "/^\[alias\]/,\$p" ~/.gitconfig'

lab_end
