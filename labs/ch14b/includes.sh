#!/usr/bin/env bash
# Chapter 14B, section 14B.4: include.path and includeIf. Two identities chosen by the
# location of the repository, then by the URL of its remote, and the ways the rule can
# silently not apply.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$(dirname "$0")/fixture.bash"
lab_begin ch14b includes
sandbox_home
make_gateway "$HOME/work/inference-gateway"
hidden "git init '$HOME/oss/evalkit'"
cd "$HOME/oss/evalkit" || exit 1
commit_file README.md '# evalkit\n' 'Add README'
cd "$HOME" || exit 1
# From here on the identity comes from configuration, as on a real machine.
as config

snip 01-before
run 'git -C ~/work/inference-gateway config get --show-origin user.email'
run 'git -C ~/oss/evalkit config get --show-origin user.email'

snip 02-include-if
run "printf '[user]\n\temail = lab.user@corp.example\n' > ~/.gitconfig-work"
run "git config set --global 'includeIf.gitdir:~/work/.path' '~/.gitconfig-work'"
run 'cat ~/.gitconfig'

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
run "git log -2 --format='%h  %an <%ae>  %s'"

snip 05-includes-flag
note 'Asking one scope by name switches include processing off unless you ask for it.'
run 'git config get --global user.email'
run 'git config get --global --includes user.email'
run 'git config list --global --show-origin | grep user'
run 'git config list --global --includes --show-origin | grep user'

snip 06-no-slash
run "git config unset --global 'includeIf.gitdir:~/work/.path'"
run "git config set --global 'includeIf.gitdir:~/work.path' '~/.gitconfig-work'"
run 'git config get user.email'
run "git config unset --global 'includeIf.gitdir:~/work.path'"
run "git config set --global 'includeIf.gitdir:~/work/.path' '~/.gitconfig-work'"
run 'git config get user.email'

snip 07-order
note 'The same two sections in the other order: the conditional include first, [user] after it.'
run 'cp ~/.gitconfig ~/.gitconfig.good'
run "printf '[includeIf \"gitdir:~/work/\"]\n\tpath = ~/.gitconfig-work\n[user]\n\tname = Lab User\n\temail = you@example.com\n[init]\n\tdefaultBranch = main\n' > ~/.gitconfig"
run 'git config get --all --show-origin user.email'
run 'git config get user.email'
run 'mv ~/.gitconfig.good ~/.gitconfig'
run 'git config get user.email'

snip 08-not-in-a-repository
run 'cd ~/work'
run 'git config get user.email'
run 'git init -q rag-indexer'
run 'git -C rag-indexer config get user.email'

snip 09-missing-file
run "git config set --global 'includeIf.gitdir:~/clients/.path' '~/.gitconfig-clients'"
run 'git init -q ~/clients/acme-chatbot'
run_rc 'ls ~/.gitconfig-clients'
run 'git -C ~/clients/acme-chatbot config get --show-origin user.email'

snip 10-hasconfig
run "printf '[user]\n\temail = lab.user@corp.example\n' > ~/.gitconfig-corp-remote"
run "git config set --global 'includeIf.hasconfig:remote.*.url:git@git.corp.example:platform/**.path' '~/.gitconfig-corp-remote'"
run 'git init -q ~/tmp/prompt-library'
run 'cd ~/tmp/prompt-library'
run 'git config get --show-origin user.email'
run 'git remote add origin git@git.corp.example:platform/prompt-library.git'
run 'git config get --show-origin user.email'

snip 11-team-file
run 'cd ~/work/inference-gateway'
run "printf '[merge]\n\tconflictStyle = zdiff3\n[rebase]\n\tupdateRefs = true\n' > .gitconfig-team"
run_rc 'git config get merge.conflictStyle'
run 'git config set include.path ../.gitconfig-team'
run 'git config get --show-scope --show-origin merge.conflictStyle'
run 'git config list --local --includes --show-origin | tail -3'

lab_end
