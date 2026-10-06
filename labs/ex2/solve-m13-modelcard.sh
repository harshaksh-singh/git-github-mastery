#!/usr/bin/env bash
# Model solution of exercise 13.9 (Level 4): a release tag that was deleted and re-created as a
# lightweight tag on a later commit. The published tag object is found as a dangling object.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$LAB_SCRIPT_DIR/replay-lib.bash"
lab_begin ex2 solve-m13-modelcard
ex_load m13-modelcard
cd you || exit 1

snip 01-observe
run 'git log --oneline --decorate'
run '(cd ../ci && scripts/version.sh)'
run 'git ls-remote --tags origin'

snip 02-what-it-is-now
run "git for-each-ref refs/tags --format='%(refname:short) %(objecttype) %(objectname:short) %(taggername)'"
run 'git cat-file -t v1.4.0'
run 'git reflog show refs/tags/v1.4.0'

snip 03-find-the-original
run 'git fsck'
t=$(git fsck 2>/dev/null | awk '$1=="dangling" && $2=="tag"{print $3}')
run "git cat-file -p ${t:0:7}"

snip 04-restore
run "git update-ref refs/tags/v1.4.0 ${t:0:7}"
run 'git cat-file -t v1.4.0'
run 'git log --oneline --decorate -2'
run_rc 'git push origin v1.4.0'
run 'git push --force origin v1.4.0'

snip 05-release-the-fix
run "git tag -a v1.4.1 -m 'modelcard 1.4.1: say so when a card has no metrics' main"
run 'git push origin v1.4.1'
run 'git ls-remote --tags origin'

snip 06-other-clones
run 'cd ../ci'
run_rc 'git fetch --tags'
run 'git fetch --tags --force'
run 'scripts/version.sh'
run 'git describe v1.4.0'
run 'cd ..'
show_check
ex_done
