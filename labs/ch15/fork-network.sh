#!/usr/bin/env bash
# Chapter 15, section 15.7: a fork network shares Git data. A model built with Git's own
# namespaces (gitnamespaces(7)): one object database on the "platform", and one set of refs
# per repository. A commit pushed to the fork can be fetched by ID through the upstream, and
# it outlives the fork until the server prunes it.
# This is a model of the behavior that GitHub documents. It is not GitHub's implementation.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$LAB_SCRIPT_DIR/fixture.bash"
lab_begin ch15 fork-network
make_registry "$LAB_DIR/seed"
cd "$LAB_DIR" || exit 1
count_objects="find platform/network.git/objects -type f | wc -l | tr -d ' '"

snip 01-upstream
note 'The platform: one object database. The upstream repository acme-ml/prompt-registry is a namespace in it.'
run 'git init -q --bare platform/network.git'
run 'GIT_NAMESPACE=acme-ml git -C seed push -q ../platform/network.git main'
run 'git -C platform/network.git for-each-ref --format="%(refname)"'
run "$count_objects"

snip 02-fork
note 'Forking: the platform writes a ref for the fork. No object is copied.'
run 'git -C platform/network.git update-ref refs/namespaces/you/refs/heads/main refs/namespaces/acme-ml/refs/heads/main'
run 'git -C platform/network.git for-each-ref --format="%(refname)"'
run "$count_objects"

snip 03-clone-fork
run 'GIT_NAMESPACE=you git clone -q platform/network.git you/prompt-registry'
run 'cd you/prompt-registry'
run 'git branch -a'

snip 04-push-to-fork
run 'git switch -q -c debug/staging-config'
run "printf 'STAGING_API_KEY=FAKE-KEY-for-the-lab\n' > staging.env"
run 'git add -f staging.env && git commit -q -m "Add staging config for debugging"'
run 'GIT_NAMESPACE=you git push -q origin debug/staging-config'
run 'git rev-parse HEAD'
id=$(git rev-parse HEAD)
run 'cd ../..'
run "$count_objects"

snip 05-two-views
note 'What each repository lists:'
run 'GIT_NAMESPACE=acme-ml git ls-remote platform/network.git'
run 'GIT_NAMESPACE=you git ls-remote platform/network.git'

snip 06-by-id-through-upstream
note 'A visitor who only knows the upstream repository, and the commit ID:'
run 'GIT_NAMESPACE=acme-ml git clone -q platform/network.git visitor/prompt-registry'
run 'cd visitor/prompt-registry'
run "GIT_NAMESPACE=acme-ml git fetch origin $id"
run 'git show --stat --format="%h %s" FETCH_HEAD'
run 'cd ../..'

snip 07-delete-fork
note 'The fork is deleted: its refs go. The object database is not touched.'
run "git -C platform/network.git for-each-ref --format='delete %(refname)' refs/namespaces/you | git -C platform/network.git update-ref --stdin"
run 'git -C platform/network.git for-each-ref --format="%(refname)"'
run "git -C platform/network.git cat-file -t $id"

snip 08-prune
note 'Only when the server prunes unreachable objects does the commit cease to exist there:'
run 'git -C platform/network.git gc --quiet --prune=now'
run_rc "git -C platform/network.git cat-file -t $id"

lab_end
