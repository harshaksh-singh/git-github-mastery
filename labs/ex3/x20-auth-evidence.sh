#!/usr/bin/env bash
# Exercises 20.3, 20.4 and 20.5 (Module 20): the evidence listings that the exercises print,
# and the diagnosis and repair that the solutions print. Nothing connects anywhere: the
# credential helpers are toy scripts, and "ssh -G" prints configuration without connecting.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$LAB_SCRIPT_DIR/fixture.bash"
lab_begin ex3 x20-auth-evidence
sandbox_home
SHOW="grep -E '^(hostname|user|port|identityfile|identitiesonly) '"

# ---- Case A (Exercise 20.3): HTTPS, 403, and Git never asks.
make_helper personalstore lab-user-personal
make_helper workstore lab-user-northwind
hidden 'git config set --global credential.helper personalstore'
hidden 'git config set --global credential.https://github.com.helper workstore'
make_repo "$HOME/work/eval-reports" https://github.com/northwind-ml/eval-reports.git

snip a-evidence
run 'git remote -v'
run 'git config get --show-origin --all credential.helper'
run 'git config get --show-origin --all credential.https://github.com.helper'

snip a-diagnosis
run "printf 'protocol=https\nhost=github.com\n\n' | git credential fill"
run "printf 'protocol=https\nhost=github.com\n\n' | GIT_TRACE=1 git credential fill 2>&1 >/dev/null | grep -o \"trace: run_command: '.*\""

snip a-fix
run 'git config unset --global credential.https://github.com.helper'
run "git config set --global --append credential.https://github.com.helper ''"
run 'git config set --global --append credential.https://github.com.helper workstore'
run "printf 'protocol=https\nhost=github.com\n\n' | git credential fill"

# ---- Case B (Exercise 20.4): SSH, Permission denied (publickey).
cd "$HOME" || exit 1
make_key_files id_ed25519
put "$HOME/.ssh/config" <<'CFG'
Host github.com
  HostName github.com
  User git
  IdentityFile ~/.ssh/id_ed25519_work
  IdentitiesOnly yes
CFG
chmod 600 "$HOME/.ssh/config"
: > "$HOME/.ssh/known_hosts"
make_repo "$HOME/work/chunker" git@github.com:northwind-ml/chunker.git

snip b-evidence
run 'git remote -v'
run "ssh -T -F ~/.ssh/config -G github.com | $SHOW"
run 'ls ~/.ssh'

snip b-fix
run "sed 's/id_ed25519_work/id_ed25519/' ~/.ssh/config > ~/.ssh/config.new && mv ~/.ssh/config.new ~/.ssh/config"
run "ssh -T -F ~/.ssh/config -G github.com | $SHOW"

# ---- Case C (Exercise 20.5): the push works, the commits carry the wrong address.
cd "$HOME" || exit 1
put "$HOME/.ssh/config" <<'CFG'
Host github-work
  HostName github.com
  User git
  IdentityFile ~/.ssh/id_ed25519_northwind
  IdentitiesOnly yes

Host github.com
  HostName github.com
  User git
  IdentityFile ~/.ssh/id_ed25519
  IdentitiesOnly yes
CFG
put "$HOME/.gitconfig" <<'CFG'
[includeIf "gitdir:~/work/"]
	path = ~/.gitconfig-work
[user]
	name = Lab User
	email = lab-user@personal.example
[init]
	defaultBranch = main
[gc]
	reflogExpire = never
	reflogExpireUnreachable = never
CFG
put "$HOME/.gitconfig-work" <<'CFG'
[user]
	email = lab.user@northwind.example
[url "git@github-work:"]
	insteadOf = git@github.com:
CFG
as config
make_repo "$HOME/work/ranker-service" git@github.com:northwind-ml/ranker-service.git

snip c-evidence
run 'cat ~/.gitconfig'
run 'cat ~/.gitconfig-work'
run 'git config get remote.origin.url'
run 'git remote get-url origin'
run "git log -1 --format='%an <%ae>  %s'"

snip c-diagnosis
run 'git config get --show-origin --all user.email'
run 'git config get --show-origin --all url.git@github-work:.insteadOf'

snip c-fix
note 'Move the conditional include to the end of the file, so that it is read last.'
run "{ sed '1,2d' ~/.gitconfig; sed -n '1,2p' ~/.gitconfig; } > ~/.gitconfig.new && mv ~/.gitconfig.new ~/.gitconfig"
run 'git config get --show-origin user.email'
run "printf 'Owner: ranking team\n' > OWNERS.md && git add OWNERS.md && git commit -q -m 'Add owners file'"
run "git log -2 --format='%an <%ae>  %s'"

lab_end
