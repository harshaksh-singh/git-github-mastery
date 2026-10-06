#!/usr/bin/env bash
# Exercises of Module 5 (configuration; Chapter 14B, sections 14B.2 to 14B.7): the model runs
# behind exercises/m01-m05-foundations.md and solutions/exercises-m01-m05.md.
# Snippet names start with the exercise number: e04-... belongs to Exercise 5.4.
. "$(dirname "$0")/../lib/lab-env.sh"
lab_begin ex1 ex-m05
as config        # no identity in the environment: user.name and user.email decide

# m5_home <dir>: a fresh directory with a home of its own, in the state that the "Module 5
# preamble" of the exercise file creates by hand.
m5_home() {
  mkdir -p "$LAB_DIR/$1/home"
  cd "$LAB_DIR/$1" || exit 1
  export HOME="$PWD/home"
  export GIT_CONFIG_GLOBAL="$HOME/.gitconfig" XDG_CONFIG_HOME="$HOME/.config"
  printf '[user]\n\tname = Lab User\n\temail = you@example.com\n[init]\n\tdefaultBranch = main\n' > "$GIT_CONFIG_GLOBAL"
}

# ---- The preamble itself, once, as the learner types it
mkdir -p "$LAB_DIR/m05-ex0" && cd "$LAB_DIR/m05-ex0"
snip e00-preamble
run 'mkdir -p home'
run 'export HOME="$PWD/home"'
run 'export GIT_CONFIG_GLOBAL="$HOME/.gitconfig" XDG_CONFIG_HOME="$HOME/.config"'
run 'git config set --global user.name "Lab User"'
run 'git config set --global user.email you@example.com'
run 'git config set --global init.defaultBranch main'
run 'git config list --show-scope --show-origin'

# ---- Exercise 5.1 (Level 1): one key in the local file
m5_home m05-ex1
snip e01-local
run 'git init -q svc'
run 'cd svc'
run 'git config set pull.ff only'
run 'git config get pull.ff'
run 'cat .git/config'
run 'git config unset pull.ff'
run_rc 'git config get pull.ff'
run_rc 'git config unset pull.ff'
run 'cat .git/config'

# ---- Exercise 5.2 (Level 1): scope and origin of one key
m5_home m05-ex2
snip e02-scope
run 'git init -q svc'
run 'cd svc'
run 'git config set --global merge.conflictStyle zdiff3'
run 'git config set merge.conflictStyle diff3'
run 'git config get --all --show-scope --show-origin merge.conflictStyle'
run 'git config get merge.conflictStyle'
run 'git -c merge.conflictStyle=merge config get --show-scope merge.conflictStyle'
run 'cd ..'
run 'git config get --show-scope merge.conflictStyle'

# ---- Exercise 5.3 (Level 1): typed values
m5_home m05-ex3
snip e03-types
run 'git init -q svc'
run 'cd svc'
run 'git config set core.bigFileThreshold 1m'
run 'git config get core.bigFileThreshold'
run 'git config get --type=int core.bigFileThreshold'
run 'git config set fetch.prune yes'
run 'git config get --type=bool fetch.prune'
run_rc 'git config get --type=bool core.bigFileThreshold'
run_rc 'git config get --type=int fetch.prune'
run "git config set --global core.excludesFile '~/.gitignore-global'"
run 'git config get core.excludesFile'
run 'git config get --type=path core.excludesFile'

# ---- Exercise 5.4 (Level 2, prediction): four sources for one identity
m5_home m05-ex4
snip e04-setup
run 'git config set --global user.email global@example.com'
run 'git init -q who'
run 'cd who'
run 'git config set user.email local@example.com'
run 'git commit -q --allow-empty -m one'
run 'GIT_AUTHOR_EMAIL=env@example.com git -c user.email=cli@example.com commit -q --allow-empty -m two'
snip e04-answer
run "git log --format='%s: author %ae, committer %ce'"
run 'git config get --all --show-scope user.email'

# ---- Exercise 5.5 (Level 2, prediction): unset, and the position of an include
m5_home m05-ex5
snip e05-setup-a
run 'git config set --global pull.rebase true'
run 'git init -q scopes'
run 'cd scopes'
run 'git config set pull.rebase false'
run 'git config unset pull.rebase'
snip e05-answer-a
run 'git config get --show-scope pull.rebase'
run_rc 'git config unset pull.rebase'
run 'git config get --show-scope pull.rebase'
snip e05-setup-b
run "printf '[core]\n\teditor = nano\n' > ~/extra.gitconfig"
run 'git config set --global core.editor vim'
run "git config set --global include.path '~/extra.gitconfig'"
snip e05-answer-b
run 'cat ~/.gitconfig'
run 'git config get --all --show-origin core.editor'
run 'git config get core.editor'

# ---- Exercise 5.6 (Level 2): two aliases
m5_home m05-ex6
quiet 'git init branches'
cd branches
export GIT_AUTHOR_NAME="Lab User" GIT_AUTHOR_EMAIL=you@example.com GIT_COMMITTER_NAME="Lab User" GIT_COMMITTER_EMAIL=you@example.com
quiet 'mkdir -p src/router && printf "x\n" > src/router/a.py && git add . && git commit -m "Add router"'
for i in 1 2 3; do tick; done
quiet 'git switch -c feature/fallback && git commit --allow-empty -m "Add fallback"'
quiet 'git switch -c fix/timeout main && git commit --allow-empty -m "Fix timeout"'
quiet 'git switch main'
as config
snip e06-aliases
run "git config set --global alias.recent \"branch --sort=-committerdate --format='%(committerdate:relative) %(refname:short)'\""
run 'git recent'
run "git config set --global alias.where '!echo \"\$(git branch --show-current) at \$(git rev-parse --short HEAD) in \$PWD\"'"
run 'cd src/router'
run 'git where'
run 'git config get --all --show-names --regexp "^alias\."'

# ---- Exercise 5.7 (Level 3): the include is there and the work address is not used
m5_home m05-ex7
printf '[user]\n\temail = lab.user@corp.example\n' > "$HOME/.gitconfig-work"
printf '[includeIf "gitdir:~/work/"]\n\tpath = ~/.gitconfig-work\n[user]\n\tname = Lab User\n\temail = lab.user@personal.example\n[init]\n\tdefaultBranch = main\n' > "$GIT_CONFIG_GLOBAL"
quiet 'git init ~/work/billing-llm'
cd "$HOME/work/billing-llm"
quiet 'printf "x\n" > a.txt && git add a.txt && git commit -m "Add invoice prompt"'
snip e07-evidence
run 'cat ~/.gitconfig'
run 'cat ~/.gitconfig-work'
run 'git rev-parse --absolute-git-dir'
run "git log -1 --format='%an <%ae>  %s'"
snip e07-diagnosis
run 'git config get --all --show-origin user.email'
run 'git config get user.email'
snip e07-fix
run "printf '[user]\n\tname = Lab User\n\temail = lab.user@personal.example\n[init]\n\tdefaultBranch = main\n[includeIf \"gitdir:~/work/\"]\n\tpath = ~/.gitconfig-work\n' > ~/.gitconfig"
run 'git config get --all --show-origin user.email'
run 'git commit -q --amend --no-edit --reset-author'
run "git log -1 --format='%an <%ae>  %s'"

# ---- Exercise 5.8 (Level 3): the configuration is right and the commit is wrong
m5_home m05-ex8
quiet 'git config set --global user.email lab.user@corp.example'
quiet 'git init ~/work/invoice-ocr'
cd "$HOME/work/invoice-ocr"
export GIT_AUTHOR_EMAIL=lab.user@old-startup.example GIT_COMMITTER_EMAIL=lab.user@old-startup.example
quiet 'printf "x\n" > a.txt && git add a.txt && git commit -m "Add OCR client"'
snip e08-evidence
run 'git config get --all --show-scope --show-origin user.email'
run "git log -1 --format='author %an <%ae>, committer %cn <%ce>'"
snip e08-diagnosis
run 'git var GIT_AUTHOR_IDENT'
run 'git var GIT_COMMITTER_IDENT'
run "env | grep -E '^GIT_(AUTHOR|COMMITTER)_(NAME|EMAIL)' | sort"
snip e08-fix
run 'unset GIT_AUTHOR_EMAIL GIT_COMMITTER_EMAIL'
run 'git var GIT_AUTHOR_IDENT'
run 'git commit -q --amend --no-edit --reset-author'
run "git log -1 --format='author %an <%ae>, committer %cn <%ce>'"

lab_end
