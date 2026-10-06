#!/usr/bin/env bash
# Chapter 26, sections 26.10 to 26.13: one repository cloned five ways (full, single-branch,
# shallow, blobless, treeless) and what each clone holds. Object counts only.
. "$(dirname "$0")/../lib/lab-env.sh"
lab_begin ch26 clone-shapes
. "$LAB_SCRIPT_DIR/../ch24/fixture-orbit.bash"
orbit_build || exit 1
orbit_server || exit 1

snip 01-full
run 'git clone "file://$PWD/server/orbit.git" full'
run "git -C full cat-file --batch-all-objects --batch-check='%(objecttype)' | sort | uniq -c"
run 'git -C full for-each-ref --format="%(refname)" | wc -l'

snip 02-single-branch
run 'git clone --single-branch "file://$PWD/server/orbit.git" single'
run "git -C single cat-file --batch-all-objects --batch-check='%(objecttype)' | sort | uniq -c"
run 'git -C single branch -r'

snip 03-shallow
run 'git clone --depth 1 "file://$PWD/server/orbit.git" shallow'
run "git -C shallow cat-file --batch-all-objects --batch-check='%(objecttype)' | sort | uniq -c"
run 'git -C shallow log --oneline'
run 'git -C shallow tag -l | wc -l'

snip 04-blobless
run 'git clone --filter=blob:none "file://$PWD/server/orbit.git" blobless'
run "git -C blobless cat-file --batch-all-objects --batch-check='%(objecttype)' | sort | uniq -c"
run 'git -C blobless rev-list --count --all'
run 'git -C blobless ls-files | wc -l'

snip 05-treeless
run 'git clone --filter=tree:0 "file://$PWD/server/orbit.git" treeless'
run "git -C treeless cat-file --batch-all-objects --batch-check='%(objecttype)' 2>/dev/null | sort | uniq -c"
run 'git -C treeless rev-list --count --all'
note 'A path-limited log needs the trees of every commit, and asks for them one commit at a time:'
run "GIT_TRACE=1 git -C treeless log --oneline -- services/ranker 2>&1 >/dev/null | grep -c 'run_command: git .*fetch'"
run 'ls treeless/.git/objects/pack/*.pack | wc -l'

snip 06-filter-ignored
note 'A path instead of a URL: the local transport copies files and ignores the filter.'
run 'git clone --filter=blob:none server/orbit.git by-path'
run "git -C by-path cat-file --batch-all-objects --batch-check='%(objecttype)' 2>/dev/null | sort | uniq -c"
note 'A server that does not allow filters (uploadpack.allowFilter is false unless set):'
run 'git -C server/orbit.git config set uploadpack.allowFilter false'
run 'git clone --filter=blob:none "file://$PWD/server/orbit.git" refused'
run "git -C refused cat-file --batch-all-objects --batch-check='%(objecttype)' 2>/dev/null | sort | uniq -c"
note 'Both clones are complete, and both are nevertheless configured as partial clones:'
run 'git -C refused config get remote.origin.partialclonefilter'
run 'git -C server/orbit.git config set uploadpack.allowFilter true'

lab_end
