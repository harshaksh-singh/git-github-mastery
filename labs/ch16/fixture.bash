# labs/ch16/fixture.bash - shared fixture for the Chapter 16 demos and the Module 20 labs.
#
# Sourced by the scripts in this directory right after lab-env.sh. It is not a demo:
# the file name does not end in .sh, so the build and verify tools skip it.
#
# Everything lives inside the sandbox ($LAB_DIR). Nothing here contacts GitHub, an
# ssh-agent, the keychain, the real ~/.ssh or the real Git configuration:
#   * HOME is the sandbox home, so "~" in a shell command or a Git setting stays inside;
#   * ssh itself does NOT use $HOME (it asks the system for the account's home directory),
#     so every ssh and ssh-keygen command in these scripts names its files explicitly
#     (-F <config>, -f <file>) and no command opens a connection to a real host;
#   * the "credential helper" is a 20-line shell script that keeps one credential in a
#     plain file inside the sandbox. It exists to make the protocol visible. It is not a
#     helper to use for real.
#
# Fake secrets in these scripts are spelled so that no scanner can mistake them for real
# tokens (no ghp_ or github_pat_ prefix).

FAKE_TOKEN='FAKE-TOKEN-not-a-real-credential'

# hidden '<command line>'
# A setup step that the transcript does not show. A failing hidden step stops the script:
# a setup that fails silently would make the transcript lie.
hidden() {
  tick
  eval "$1" > /dev/null 2>&1 || { printf 'fixture: hidden step failed: %s\n' "$1" >&2; exit 1; }
}

# commit_file <path> <printf format> <message>
commit_file() {
  tick
  {
    mkdir -p "$(dirname "$1")" &&
      printf "$2" > "$1" &&
      git add "$1" &&
      git commit -q -m "$3"
  } > /dev/null 2>&1 || { printf 'fixture: commit_file failed: %s\n' "$1" >&2; exit 1; }
}

# sandbox_home
# Make the sandbox's home directory the HOME of this script and put ~/lab-bin on PATH.
sandbox_home() {
  export HOME="$LAB_DIR/home"
  mkdir -p "$HOME/lab-bin" "$HOME/.ssh" || exit 1
  chmod 700 "$HOME/.ssh"
  export PATH="$HOME/lab-bin:$PATH"
  unset SSH_AUTH_SOCK SSH_AGENT_PID SSH_ASKPASS
  # A second lock on the door: Git may use the file and ssh transports only. Even a typing
  # mistake in a script cannot make Git open an HTTPS connection.
  export GIT_ALLOW_PROTOCOL=file:ssh
  cd "$HOME" || exit 1
}

# make_helper [<name>]
# Install the toy credential helper as ~/lab-bin/git-credential-<name> (default: labstore).
# It keeps one credential in ~/.<name>-credentials and writes one line per call to
# ~/helper.log, with the secret replaced.
make_helper() {
  local name="${1:-labstore}"
  cat > "$HOME/lab-bin/git-credential-$name" <<HELPER
#!/bin/sh
# git-credential-$name: a toy credential helper for the lab. Do not use it for real secrets.
# Git runs it as "git credential-$name <operation>" and writes key=value lines on its stdin.
store="\$HOME/.$name-credentials"
input=\$(cat)
printf '%s %-5s <- %s\n' "$name" "\$1" "\$(printf '%s' "\$input" | sed 's/^password=.*/password=<hidden>/' | tr '\n' ' ')" >> "\$HOME/helper.log"
case "\$1" in
  get)   [ -f "\$store" ] && cat "\$store" ;;
  store) printf '%s\n' "\$input" | grep -E '^(username|password)=' > "\$store" ;;
  erase) rm -f "\$store" ;;
esac
exit 0
HELPER
  chmod +x "$HOME/lab-bin/git-credential-$name"
}

# make_askpass
# A stand-in for the person at the keyboard: prints the prompt it was given and answers.
make_askpass() {
  cat > "$HOME/lab-bin/askpass" <<'ASK'
#!/bin/sh
echo "Git asked: $1" >&2
case "$1" in
  Username*) echo lab-user ;;
  *)         echo typed-at-the-prompt ;;
esac
ASK
  chmod +x "$HOME/lab-bin/askpass"
}

# make_ssh_standin
# ~/lab-bin/fake-ssh prints the arguments Git gave it and fails. Nothing connects.
make_ssh_standin() {
  printf '#!/bin/sh\necho "ssh was asked to run:" "$@" >&2\nexit 255\n' > "$HOME/lab-bin/fake-ssh"
  chmod +x "$HOME/lab-bin/fake-ssh"
}

# write_ssh_config
# The ~/.ssh/config used by the demos: a personal identity for github.com, a work identity
# behind the alias github-work, the port-443 fallback, and defaults at the end.
write_ssh_config() {
  cat > "$HOME/.ssh/config" <<'CFG'
# Personal account: plain github.com URLs
Host github.com
  HostName github.com
  User git
  IdentityFile ~/.ssh/id_ed25519_personal
  IdentitiesOnly yes

# Work account: URLs written with the alias, git@github-work:ORG/REPO.git
Host github-work
  HostName github.com
  User git
  IdentityFile ~/.ssh/id_ed25519_work
  IdentitiesOnly yes

# Port 22 blocked: SSH over the HTTPS port
Host github-443
  HostName ssh.github.com
  Port 443
  User git
  IdentityFile ~/.ssh/id_ed25519_personal
  IdentitiesOnly yes

# Defaults for every host come last
Host *
  AddKeysToAgent yes
CFG
  chmod 600 "$HOME/.ssh/config"
}

# make_repo <directory> <remote url>
# A one-commit repository with an origin. Ends inside it.
make_repo() {
  hidden "git init '$1'"
  cd "$1" || exit 1
  commit_file README.md "# $(basename "$1")\n" 'Add README'
  hidden "git remote add origin '$2'"
}

# setup_done <lab number> <sandbox name> <first command>
setup_done() {
  printf 'Lab %s is ready in %s\n' "$1" "$LAB_DIR"
  printf 'Open the lab shell there:  labs/shell %s\n' "$2"
  printf 'First command of the lab:  %s\n' "$3"
}

# ---------------------------------------------------------------- lab starting states
# Each scenario_* function builds the starting state of the local rehearsal of one lab. The
# replay script and the setup script call the same function. Every function ends in $LAB_DIR.
# $LAB_DIR/home is the home directory the learner switches to in the first step.

# Lab 20.1: an empty home with an .ssh directory and GitHub's published known_hosts lines.
scenario_20_1() {
  mkdir -p "$LAB_DIR/home/.ssh" && chmod 700 "$LAB_DIR/home/.ssh" || exit 1
  cp "$LAB_SCRIPT_DIR/github-known-hosts.txt" "$LAB_DIR/home/github-known-hosts.txt" || exit 1
  cd "$LAB_DIR" || exit 1
}

# Lab 20.2: the toy helper installed, not yet configured; a repository with an HTTPS remote.
scenario_20_2() {
  local keep="$HOME"
  export HOME="$LAB_DIR/home"; mkdir -p "$HOME/lab-bin" || exit 1
  make_helper labstore
  make_helper workstore
  make_repo "$HOME/work/billing-api" https://github.com/acme-pay/billing-api.git
  export HOME="$keep"
  cd "$LAB_DIR" || exit 1
}

# Lab 20.3: the stand-in ssh, GitHub's known_hosts lines, and a repository with an SSH remote.
scenario_20_3() {
  local keep="$HOME"
  export HOME="$LAB_DIR/home"; mkdir -p "$HOME/lab-bin" "$HOME/.ssh" || exit 1
  chmod 700 "$HOME/.ssh"
  make_ssh_standin
  make_helper labstore
  cp "$LAB_SCRIPT_DIR/github-known-hosts.txt" "$HOME/.ssh/known_hosts" || exit 1
  cp "$LAB_SCRIPT_DIR/github-known-hosts.txt" "$HOME/github-known-hosts.txt" || exit 1
  cp "$LAB_SCRIPT_DIR/stale-host-key.pub" "$HOME/stale-host-key.pub" || exit 1
  printf 'username=lab-user\npassword=%s\n' "$FAKE_TOKEN" > "$HOME/.labstore-credentials"
  make_repo "$HOME/work/billing-api" git@github.com:acme-pay/billing-api.git
  hidden 'git config set --file "$HOME/.gitconfig" credential.helper labstore'
  export HOME="$keep"
  cd "$LAB_DIR" || exit 1
}

# Lab 20.4: one personal and one work repository, both with canonical github.com URLs.
scenario_20_4() {
  local keep="$HOME"
  export HOME="$LAB_DIR/home"; mkdir -p "$HOME/lab-bin" "$HOME/.ssh" || exit 1
  chmod 700 "$HOME/.ssh"
  make_ssh_standin
  make_repo "$HOME/personal/notes-app" git@github.com:lab-user/notes-app.git
  make_repo "$HOME/work/billing-api" git@github.com:acme-pay/billing-api.git
  export HOME="$keep"
  cd "$LAB_DIR" || exit 1
}
