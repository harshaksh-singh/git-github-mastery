#!/usr/bin/env bash
# Gate 6 (GitHub), hands-on variant B, case 3: the evidence listing. "ssh -G" prints how ssh
# reads a configuration file and connects to nothing. The file is given with -F, so neither the
# user's own ~/.ssh/config nor the system file is read.
. "$(dirname "$0")/../lib/lab-env.sh"
lab_begin gates g6-evidence

cat > ssh_config <<'CFG'
Host github-work
  HostName github.com
  User git
  IdentityFile ~/.ssh/id_ed25519_acme
  IdentitiesOnly yes

Host *
  IdentityFile ~/.ssh/id_rsa_2019
  IdentitiesOnly yes
CFG
show() { grep -E '^(hostname|user|identityfile|identitiesonly) ' | sed "s#$HOME#~#"; }

snip 01-config
run 'cat ssh_config'
snip 02-resolved
note 'What ssh would use for the host name in the remote URL, and for the alias (-T: no terminal):'
run 'ssh -T -F ssh_config -G git@github.com | show'
run 'ssh -T -F ssh_config -G git@github-work | show'
lab_end
