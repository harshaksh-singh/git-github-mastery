#!/usr/bin/env bash
# Chapter 14C, section 14C.7: merge drivers. The built-in "union" driver for a changelog, a
# custom driver for a lock file, the attribute without the driver, and "-merge".
. "$(dirname "$0")/../lib/lab-env.sh"
lab_begin ch14c attr-merge

quiet 'git init svc'
cd svc || exit 1
quiet "printf '# Changelog\n\n- Add retrieval endpoint\n' > CHANGELOG.md && printf 'torch==2.4.0\n' > requirements.lock && git add . && git commit -m 'Start changelog and lock file'"
quiet 'git switch -c feat/cache'
quiet "printf '# Changelog\n\n- Add retrieval endpoint\n- Cache embeddings on disk\n' > CHANGELOG.md && printf 'torch==2.4.0\ndiskcache==5.6.3\n' > requirements.lock && git commit -am 'Cache embeddings on disk'"
quiet 'git switch main'
quiet "printf '# Changelog\n\n- Add retrieval endpoint\n- Add rate limiting\n' > CHANGELOG.md && printf 'torch==2.4.0\nlimits==3.13.0\n' > requirements.lock && git commit -am 'Add rate limiting'"

snip 01-two-conflicts
run_rc 'git merge feat/cache'
run 'git merge --abort'

snip 02-attributes
run "printf 'CHANGELOG.md      merge=union\nrequirements.lock merge=keep-ours\n' > .gitattributes"
run 'git add .gitattributes && git commit -q -m "Add merge attributes"'
run_rc 'git merge feat/cache'
run 'git status -s'
run 'cat CHANGELOG.md'
run 'git merge --abort'

snip 03-driver
note 'A merge driver is a command that leaves its result in %A and reports success with exit status 0.'
note '"true" changes nothing, so the version of the current branch stays:'
run "git config set merge.keep-ours.name 'keep our version of generated files'"
run 'git config set merge.keep-ours.driver true'
run_rc 'git merge feat/cache'
run 'cat requirements.lock'
run 'git show --stat --format=%s HEAD'

quiet 'git reset --hard HEAD^'

snip 04-unset
run "printf 'CHANGELOG.md      merge=union\nrequirements.lock -merge\n' > .gitattributes"
run 'git commit -q -am "Lock file: never merge by content"'
run_rc 'git merge feat/cache'
run 'git status -s'
run 'cat requirements.lock'
run 'git ls-files -u'

lab_end
