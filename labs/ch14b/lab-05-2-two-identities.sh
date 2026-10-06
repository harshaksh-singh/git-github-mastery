#!/usr/bin/env bash
# Lab 5.2 replay: two identities with includeIf. A work address for every repository under
# ~/work, a personal one everywhere else; then the pattern without its trailing slash.
# Lab manual: lab-manual/m05-configuration.md.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$(dirname "$0")/fixture.bash"
lab_begin ch14b lab-05-2-two-identities
scenario_05_2
as config

snip 01-before
run 'export HOME="$PWD/home"'
run 'export GIT_CONFIG_GLOBAL="$HOME/.gitconfig" XDG_CONFIG_HOME="$HOME/.config"'
run 'git -C ~/work/inference-gateway config get --show-origin user.email'
run 'git -C ~/oss/evalkit config get --show-origin user.email'

snip 02-include-if
run "printf '[user]\n\temail = lab.user@corp.example\n' > ~/.gitconfig-work"
run "git config set --global 'includeIf.gitdir:~/work/.path' '~/.gitconfig-work'"
run 'tail -2 ~/.gitconfig'

snip 03-effect
run 'cd ~/work/inference-gateway'
run 'git config get --all --show-scope --show-origin user.email'
run 'git var GIT_AUTHOR_IDENT'
run 'cd ~/oss/evalkit'
run 'git config get --all --show-scope --show-origin user.email'
run 'git var GIT_AUTHOR_IDENT'

snip 04-commits
run 'cd ~/work/inference-gateway'
run "printf 'timeout_seconds: 30\n' >> config/limits.yaml"
run 'git commit -q -am "Add request timeout"'
run "git log -2 --format='%an <%ae>  %s'"
run 'cd ~/oss/evalkit'
run "printf '\nRun: python -m evalkit\n' >> README.md"
run 'git commit -q -am "Document how to run"'
run "git log -2 --format='%an <%ae>  %s'"

snip 05-includes-flag
run 'cd ~/work/inference-gateway'
run 'git config get --global user.email'
run 'git config get --global --includes user.email'

snip 06-failure
note 'Someone tidies the global file and drops the trailing slash from the pattern.'
run "git config unset --global 'includeIf.gitdir:~/work/.path'"
run "git config set --global 'includeIf.gitdir:~/work.path' '~/.gitconfig-work'"
run "printf 'max_retries: 2\n' >> config/limits.yaml"
run 'git commit -q -am "Add retry limit"'
run "git log -2 --format='%an <%ae>  %s'"

snip 07-diagnose
run 'git config get --all --show-origin user.email'
run 'git config get --global --all --show-names --regexp "^includeif"'
run 'git rev-parse --absolute-git-dir'

snip 08-recovery
run "git config unset --global 'includeIf.gitdir:~/work.path'"
run "git config set --global 'includeIf.gitdir:~/work/.path' '~/.gitconfig-work'"
run 'git var GIT_AUTHOR_IDENT'
note 'The wrong commit is unpublished, so it can be replaced.'
run 'git commit -q --amend --no-edit --reset-author'
run "git log -2 --format='%an <%ae>  %s'"

snip 09-verify
run 'git -C ~/work/inference-gateway config get --show-origin user.email'
run 'git -C ~/oss/evalkit config get --show-origin user.email'
run "git -C ~/work/inference-gateway log --format='%ae' | sort | uniq -c | sed 's/^ *//'"

lab_end
