#!/usr/bin/env bash
# Chapter 14D, section 14D.4: safe.bareRepository. What "explicit" refuses, what it still allows,
# and the case it was made for: a directory inside a cloned working tree that is shaped like a
# bare repository and carries its own configuration.
. "$(dirname "$0")/../lib/lab-env.sh"
lab_begin ch14d safe-bare

quiet 'git init --bare server.git'
quiet 'git clone server.git svc'
quiet "cd svc && printf 'app = FastAPI()\n' > app.py && git add . && git commit -m 'Add service' && git push -u origin main && cd .."

snip 01-explicit
run 'cd server.git'
run 'git log --oneline'
run 'git config set --global safe.bareRepository explicit'
run_rc 'git log --oneline'
note 'Naming the repository is what "explicit" asks for:'
run 'git --git-dir=. log --oneline'
run 'cd ..'

snip 02-still-works
note 'Fetch, push and clone name the repository, and a .git directory is not "bare":'
run 'git -C svc fetch origin'
run 'git clone -q server.git svc2'
run 'cd svc/.git && git rev-parse --is-inside-git-dir && cd ../..'

quiet 'git config unset --global safe.bareRepository'
# Somebody commits a directory that is shaped like a bare repository: HEAD, config, objects/, refs/.
quiet 'git clone server.git attacker'
quiet "cd attacker && mkdir -p vendor/cache.git/objects vendor/cache.git/refs && printf 'ref: refs/heads/main\n' > vendor/cache.git/HEAD && printf '[core]\n\tbare = true\n\tfsmonitor = \"echo this-would-run\"\n' > vendor/cache.git/config && : > vendor/cache.git/objects/.keep && : > vendor/cache.git/refs/.keep && git add . && git commit -m 'Vendor the cache' && git push && cd .."

snip 03-embedded
note 'You clone a project and step into one of its directories:'
run 'git clone -q server.git victim'
run 'cd victim/vendor/cache.git'
run 'ls'
note 'With the default (safe.bareRepository=all) Git takes this directory for a repository and reads'
note 'the configuration file that arrived with the clone:'
run 'git rev-parse --git-dir --is-bare-repository'
run 'git config get core.fsmonitor'

snip 04-refused
run 'git config set --global safe.bareRepository explicit'
run_rc 'git rev-parse --git-dir'
run_rc 'git config get core.fsmonitor'
run 'cd ../..'
run 'git status -sb'

lab_end
