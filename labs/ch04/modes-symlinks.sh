#!/usr/bin/env bash
# File modes and symbolic links: what Git records about a file besides its content.
# Chapter 4, section 4.10.
. "$(dirname "$0")/../lib/lab-env.sh"
lab_begin ch04 modes-symlinks

git init -q support-bot
cd support-bot || exit 1
mkdir -p scripts config
printf '#!/bin/sh\npython -m evals.run "$@"\n' > scripts/run_eval.sh
printf '#!/bin/sh\necho deploying\n' > scripts/deploy.sh
printf 'model: small-v1\ntop_k: 5\n' > config/settings.yaml
quiet 'git add . && git commit -m "Add scripts and settings"'

snip 01-executable-bit
run 'git ls-files --stage scripts/run_eval.sh'
run 'chmod +x scripts/run_eval.sh'
run 'git status --short'
run 'git diff'
run 'git add scripts/run_eval.sh'
run 'git ls-files --stage scripts/run_eval.sh'
note 'The blob ID did not change. The mode is stored in the index entry, and later in the tree.'

snip 02-only-the-x-bit
note 'Other permission bits are not recorded at all.'
run 'chmod 600 config/settings.yaml'
run 'git status --short'
run 'chmod 644 config/settings.yaml'

snip 03-chmod-in-index
note 'Set the bit in the index without touching the file on disk.'
run 'git add --chmod=+x scripts/deploy.sh'
run 'git ls-files --stage scripts/deploy.sh'
run 'test -x scripts/deploy.sh && echo "executable on disk" || echo "not executable on disk"'
run 'git status --short'
note 'With core.fileMode=false Git stops comparing the bit on disk with the index.'
run 'git -c core.fileMode=false status --short'
quiet 'chmod +x scripts/deploy.sh && git commit -m "Make scripts executable"'

snip 04-symlink
run 'ln -s settings.yaml config/current.yaml'
run 'git add config/current.yaml'
run 'git ls-files --stage config'
note 'The blob of a symbolic link holds the link text, not the content of the target.'
run 'git cat-file -p :config/current.yaml; echo'
run 'git cat-file -s :config/current.yaml'

lab_end
