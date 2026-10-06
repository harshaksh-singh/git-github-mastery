#!/usr/bin/env bash
# Chapter 26, section 26.5: where unreachable objects go under the geometric strategy and under
# the gc task. Cut-offs are "now" and "never" or Git's own defaults applied to objects that are
# seconds old, so nothing here depends on the clock.
. "$(dirname "$0")/../lib/lab-env.sh"
lab_begin ch26 cruft-packs
. "$LAB_SCRIPT_DIR/../ch24/fixture-orbit.bash"
orbit_build || exit 1
orbit_pack || exit 1
cd orbit || exit 1
quiet 'git config set maintenance.auto false'

snip 01-make-garbage
note 'One pack, everything reachable:'
run 'for p in .git/objects/pack/pack-*.idx; do git show-index < "$p" | wc -l; done | sort -rn'
run 'git fsck --unreachable --no-reflogs | wc -l'
note 'Delete the unmerged feature branch. Its two commits were made on that branch, so its reflog'
note 'went with it, but the HEAD reflog still names them:'
run 'git branch -D feature/rerank-cache'
run 'git fsck --unreachable | wc -l'
note 'Remove that protection too (Chapter 13). Now the objects are unreachable:'
run 'git reflog expire --expire=now --all'
run 'git fsck --unreachable | sort'

snip 02-geometric-keeps
note 'One new commit, then a maintenance run of the default strategy. It packs the new loose'
note 'objects and deletes nothing:'
run "printf '\\nSee docs/runbooks for the on-call procedures.\\n' >> README.md"
run "git commit -q -am 'readme: point to the runbooks'"
run 'git maintenance run'
run 'for p in .git/objects/pack/pack-*.idx; do git show-index < "$p" | wc -l; done | sort -rn'
run 'ls .git/objects/pack | cut -d. -f2 | sort | uniq -c'
run 'git fsck --unreachable | wc -l'

snip 03-gc-cruft
note 'The gc task repacks everything into one pack and separates the unreachable objects:'
run 'git maintenance run --task=gc'
run 'for p in .git/objects/pack/pack-*.idx; do git show-index < "$p" | wc -l; done | sort -rn'
run 'ls .git/objects/pack | cut -d. -f2 | sort | uniq -c'
note 'The pack that has an .mtimes file is the cruft pack. Its objects are still readable:'
run 'git cat-file -t 88222b7'
run 'git log --oneline -2 88222b7'

snip 04-prune
note 'The cruft pack waits for the grace period (two weeks by default). With no grace period:'
run 'git gc --prune=now'
run 'ls .git/objects/pack | cut -d. -f2 | sort | uniq -c'
run_rc 'git cat-file -t 88222b7'
run 'git fsck --unreachable | wc -l'

lab_end
