# labs/ch14b/fixture.bash - shared fixture for the Chapter 14B demos and the labs of
# Modules 5, 13 and 24 (local part).
#
# Sourced by the scripts in this directory right after lab-env.sh. It is not a demo:
# the file name does not end in .sh, so the build and verify tools skip it.
#
# Everything lives inside the sandbox ($LAB_DIR). No network, no agent, no real
# configuration, no key outside the sandbox.

# hidden '<command line>'
# A setup step that the transcript does not show. Unlike "quiet" from lab-env.sh, a failing
# hidden step stops the script: a setup that fails silently would make the transcript lie.
hidden() {
  tick
  eval "$1" > /dev/null 2>&1 || { printf 'fixture: hidden step failed: %s\n' "$1" >&2; exit 1; }
}

# commit_file <path> <printf format> <message>
# Write one file and commit it in the current repository, silently. Advances the clock.
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
# Make the sandbox's home directory the HOME of this script, so that "~" in configuration
# values and in includeIf patterns means $LAB_DIR/home. lab-env.sh already points
# GIT_CONFIG_GLOBAL at $LAB_DIR/home/.gitconfig, which is now also ~/.gitconfig.
# The real home directory is not read or written by anything that follows.
sandbox_home() {
  export HOME="$LAB_DIR/home"
  cd "$HOME" || exit 1
}

# make_gateway <directory>
# Create the repository "inference-gateway" (a small service that routes LLM requests)
# with three commits on main. Ends inside the repository.
make_gateway() {
  hidden "git init '$1'"
  cd "$1" || exit 1
  commit_file README.md '# inference-gateway\n\nRoutes chat-completion requests to model backends.\n' 'Add README'
  commit_file gateway/router.py 'ROUTES = {"default": "small-v1"}\n\n\ndef pick_backend(model):\n    return ROUTES.get(model, ROUTES["default"])\n' 'Add model router'
  commit_file config/limits.yaml 'requests_per_minute: 60\nmax_tokens: 2048\n' 'Add rate limits'
}

# make_server_and_clones <person>...
# A bare repository that plays the server, seeded with the three commits of make_gateway,
# and one clone per person in $LAB_DIR/<person>/inference-gateway. Each clone stores the
# server URL as a relative path, so that no transcript depends on where the sandbox lives.
# Teammates get user.name and user.email in their clone's own configuration.
# Ends in $LAB_DIR with your identity active.
make_server_and_clones() {
  local p dir
  hidden "git init --bare '$LAB_DIR/server/inference-gateway.git'"
  make_gateway "$LAB_DIR/.seed"
  hidden "git push '$LAB_DIR/server/inference-gateway.git' main"
  cd "$LAB_DIR" || exit 1
  rm -rf "$LAB_DIR/.seed"
  for p in "$@"; do
    dir="$LAB_DIR/$p/inference-gateway"
    hidden "git clone '$LAB_DIR/server/inference-gateway.git' '$dir'"
    git -C "$dir" remote set-url origin ../../server/inference-gateway.git || exit 1
    case "$p" in
      asha) git -C "$dir" config set user.name 'Asha Rao';   git -C "$dir" config set user.email asha@example.com ;;
      ravi) git -C "$dir" config set user.name 'Ravi Menon'; git -C "$dir" config set user.email ravi@example.com ;;
    esac
  done
  as you
}

# enter <person>
# Become that person and move into their clone, without printing anything.
enter() {
  case "$1" in asha|ravi) as "$1" ;; *) as you ;; esac
  cd "$LAB_DIR/$1/inference-gateway" || exit 1
}

# no_agent
# Signing demos never talk to an ssh-agent. With SSH_AUTH_SOCK unset, ssh-keygen cannot
# reach (or, on macOS, cause launchd to start) an agent and uses the key file only.
no_agent() {
  unset SSH_AUTH_SOCK SSH_AGENT_PID
}

# make_signing_key <name> <comment>
# Generate a throwaway Ed25519 key pair in $LAB_DIR/home/keys/<name> and <name>.pub.
# No passphrase, no agent, nothing under the real ~/.ssh. A demo that calls this must be
# --volatile: the key, every signature and every signed object differ on each run.
make_signing_key() {
  mkdir -p "$LAB_DIR/home/keys" || exit 1
  ssh-keygen -q -t ed25519 -N '' -C "$2" -f "$LAB_DIR/home/keys/$1" < /dev/null > /dev/null 2>&1 ||
    { printf 'fixture: ssh-keygen failed\n' >&2; exit 1; }
}

# allow_signer <principal> <key name>
# Append one line to $LAB_DIR/home/allowed_signers: the principal, the namespace restriction
# that Git signatures need, and the public key without its comment.
allow_signer() {
  printf '%s namespaces="git" %s\n' "$1" "$(cut -d' ' -f1,2 "$LAB_DIR/home/keys/$2.pub")" >> "$LAB_DIR/home/allowed_signers"
}

# ---------------------------------------------------------------- lab starting states
# Each scenario_* function builds the starting state of one hands-on lab. The lab's replay
# script (lab-<module>-<k>-*.sh) and its setup script (setup-<module>-<k>-*.sh) call the same
# function, so the commits that exist when you start typing have the same IDs as in the
# book. Every function ends in $LAB_DIR with your identity active.
#
# Layout shared by the labs:  $LAB_DIR/home  is the home directory you switch to in the
# first step of each lab (export HOME="$PWD/home"), so that "~" and "git config --global"
# stay inside the sandbox.

# Lab 5.1: one repository under ~/work.
scenario_05_1() {
  make_gateway "$LAB_DIR/home/work/inference-gateway"
  cd "$LAB_DIR" || exit 1
}

# Lab 5.2: a work repository and a personal open-source repository.
scenario_05_2() {
  make_gateway "$LAB_DIR/home/work/inference-gateway"
  hidden "git init '$LAB_DIR/home/oss/evalkit'"
  cd "$LAB_DIR/home/oss/evalkit" || exit 1
  commit_file README.md '# evalkit\n\nSmall evaluation harness for LLM outputs.\n' 'Add README'
  cd "$LAB_DIR" || exit 1
}

# Lab 5.3: a repository with a feature branch, so that a graph has something to show.
scenario_05_3() {
  make_gateway "$LAB_DIR/home/work/inference-gateway"
  hidden 'git switch -c feature/fallback-route'
  commit_file gateway/router.py 'ROUTES = {"default": "small-v1", "fallback": "tiny-v1"}\n\n\ndef pick_backend(model):\n    return ROUTES.get(model, ROUTES["default"])\n' 'Add fallback route'
  hidden 'git switch main'
  commit_file config/limits.yaml 'requests_per_minute: 120\nmax_tokens: 2048\n' 'Raise the rate limit'
  cd "$LAB_DIR" || exit 1
}

# Lab 5.4: a bare server and your clone, to try settings that act on push and fetch.
scenario_05_4() {
  make_server_and_clones you
  cd "$LAB_DIR" || exit 1
}

# Lab 13.1: three commits, no tags.
scenario_13_1() {
  make_gateway "$LAB_DIR/inference-gateway"
  cd "$LAB_DIR" || exit 1
}

# Lab 13.2: v1.2.0 is published; you and Asha both have it.
scenario_13_2() {
  make_server_and_clones you asha
  enter you
  hidden 'git tag -a v1.2.0 -m "inference-gateway 1.2.0"'
  hidden 'git push origin v1.2.0'
  enter asha
  hidden 'git fetch'
  cd "$LAB_DIR" || exit 1
  as you
}

# Lab 13.3: v1.2.0 on the third commit, then three more commits on main; the middle one is
# a bug fix. One lightweight tag marks what is on staging.
scenario_13_3() {
  make_gateway "$LAB_DIR/inference-gateway"
  hidden 'git tag -a v1.2.0 -m "inference-gateway 1.2.0"'
  commit_file gateway/stream.py 'def stream(chunks):\n    yield from chunks\n' 'Add streaming responses'
  commit_file config/limits.yaml 'requests_per_minute: 60\nmax_tokens: 4096\n' 'Fix max_tokens limit'
  hidden 'git tag on-staging'
  commit_file gateway/batch.py 'def batch(prompts):\n    return list(prompts)\n' 'Add batch endpoint'
  cd "$LAB_DIR" || exit 1
}

# Lab 24.1: one repository under ~/work; keys are generated by hand during the lab.
scenario_24_1() {
  make_gateway "$LAB_DIR/home/work/inference-gateway"
  cd "$LAB_DIR" || exit 1
}

# Lab 24.2: a server, your clone and Asha's clone. Asha has pushed one genuine commit,
# and you have pulled it.
scenario_24_2() {
  make_server_and_clones you asha
  enter asha
  commit_file gateway/health.py 'def healthy():\n    return True\n' 'Add health endpoint'
  hidden 'git push'
  enter you
  hidden 'git pull'
  cd "$LAB_DIR" || exit 1
  as you
}

# setup_done <lab number> <sandbox name> <first step>
# Printed by every setup script.
setup_done() {
  printf 'Lab %s is ready in %s\n' "$1" "$LAB_DIR"
  printf 'Open the lab shell there:  labs/shell %s\n' "$2"
  [ -z "${3:-}" ] || printf 'First step in that shell:  %s\n' "$3"
}
