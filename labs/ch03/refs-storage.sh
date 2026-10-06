#!/usr/bin/env bash
# Chapter 3, sections 3.9 and 3.11: refs in the "files" backend (loose refs, packed-refs,
# symbolic refs), the plumbing that reads and writes them, and reflog storage under logs/.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$LAB_SCRIPT_DIR/common/inference-service.sh" || exit 1
lab_begin ch03 refs-storage
build_inference_service

# A bare repository plays the server; one stash entry gives refs/stash something to hold.
quiet 'git init --bare ../server.git'
quiet 'git remote add origin ../server.git'
quiet 'git push -u origin main'
quiet 'git fetch origin'
quiet "printf 'log_level = \"debug\"\n' >> config.toml && git stash push -m 'debug logging'"

snip 01-loose-refs
run 'find .git/refs -type f | sort'
run 'cat .git/refs/heads/main'
run 'cat .git/refs/tags/v1.0.0'
note 'Two symbolic refs. They hold a ref name, not an object ID:'
run 'cat .git/HEAD'
run 'cat .git/refs/remotes/origin/HEAD'

snip 02-list
run 'git for-each-ref'
run "git for-each-ref --format='%(refname:short) -> %(objectname:short) %(upstream:short)' refs/heads"
note 'show-ref can peel annotated tags (the ^{} lines) and test for existence:'
run 'git show-ref --tags --dereference'
run_rc 'git show-ref --verify refs/heads/main'
run_rc 'git show-ref --exists refs/heads/no-such-branch'

snip 03-update-ref
note 'A branch is a ref, so plumbing can create one: name, new value, reflog message.'
run 'git update-ref -m "experiment: start at the release candidate" refs/heads/experiment v1.0.0-rc1'
run 'git branch --list --verbose experiment'
note 'With a third argument the update happens only if the ref still has that old value.'
# The expected old value is the ID of the root commit, captured here so that no commit ID is hardcoded.
root=$(git rev-parse HEAD~2)
run_rc "git update-ref refs/heads/experiment main $root"
run_rc 'git update-ref refs/heads/experiment main v1.0.0-rc1'
run 'git reflog show experiment'
note 'Two refusals: an object that does not exist, and a branch that would not name a commit.'
run_rc 'git update-ref refs/heads/broken 1234567890123456789012345678901234567890'
run_rc 'git update-ref refs/heads/broken HEAD:config.toml'
run 'git update-ref -d refs/heads/experiment'

snip 04-symbolic-ref
run 'git symbolic-ref HEAD'
run 'git symbolic-ref --short HEAD'
run 'git symbolic-ref refs/remotes/origin/HEAD'
note 'Any ref can be symbolic. This one makes "latest" another name for main:'
run 'git symbolic-ref refs/heads/latest refs/heads/main'
run 'cat .git/refs/heads/latest'
run 'git rev-parse latest main'
run 'git symbolic-ref --delete refs/heads/latest'
note 'Detached HEAD: the file holds an object ID, so there is no symbolic ref to read.'
run 'git switch --quiet --detach v1.0.0-rc1'
run 'cat .git/HEAD'
run_rc 'git symbolic-ref HEAD'
run 'git switch --quiet main'

snip 05-reflog-files
run 'find .git/logs -type f | sort'
run 'cat .git/logs/refs/heads/feature/batching'
run 'git reflog show feature/batching'
note 'Tags get no reflog by default. A deleted branch loses its reflog with it:'
run_rc 'git reflog exists refs/tags/v1.0.0'
run 'git branch -d feature/batching'
run 'find .git/logs -type f | sort'

snip 06-packed-refs
run 'git pack-refs --all'
run 'cat .git/packed-refs'
note 'The loose files are gone, except the symbolic ref, which cannot be packed:'
run 'find .git/refs -type f | sort'
note 'The next update writes a loose file again. It wins over the stale packed line:'
run "printf 'max_tokens = 256\\n' >> config.toml"
run 'git commit --quiet -am "Add token limit"'
run 'find .git/refs -type f | sort'
run 'grep refs/heads/main .git/packed-refs'
run 'git rev-parse main'

lab_end
