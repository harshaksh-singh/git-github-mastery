#!/usr/bin/env bash
# Model answers for exercises 13.1 to 13.8 (Module 13, tags and versions) as real transcripts on
# the practice repositories built by exercises/gen/m13-quotad/generate.sh.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$LAB_SCRIPT_DIR/replay-lib.bash"
lab_begin ex2 answers-m13
ex_load m13-quotad

cd ex-13-1 || exit 1
snip 13-1-two-kinds
run 'git count-objects'
run 'git tag staging-ok'
run 'git count-objects'
run "git tag -a v0.2.0 -m 'quotad 0.2.0' HEAD~1"
run 'git count-objects'
snip 13-1-inspect
run 'git cat-file -t staging-ok'
run 'git cat-file -t v0.2.0'
run 'git cat-file -p v0.2.0'
run "git for-each-ref refs/tags --format='%(refname:short) %(objecttype) %(objectname:short) -> %(*objectname:short)'"
cd "$LAB_DIR" || exit 1

cd ex-13-2 || exit 1
snip 13-2-sorting
run 'git tag'
run 'git tag --sort=version:refname'
run 'git -c versionsort.suffix=-rc tag --sort=version:refname'
snip 13-2-questions
run "git tag -n1 -l 'v0.1*'"
f=$(sid 'Fix burst allowance for the free tier')
run "git tag --contains $f"
run 'git tag --merged v0.9.0'
run 'git tag --points-at HEAD'
run 'git describe'
cd "$LAB_DIR" || exit 1

cd ex-13-3/work || exit 1
snip 13-3-push
run "git tag -a v0.3.0 -m 'quotad 0.3.0'"
run 'git tag tmp/debug HEAD~1'
run 'git push'
run 'git ls-remote --tags origin'
snip 13-3-follow
run "echo '# Add enterprise tier' >> quota.py && git commit -q -am 'Add enterprise tier'"
run 'git push --follow-tags'
run 'git ls-remote --tags origin'
snip 13-3-single
run 'git push origin tmp/debug'
run 'git push origin --delete tmp/debug'
run 'git tag -l'
run 'git ls-remote --tags origin'
cd "$LAB_DIR" || exit 1

cd ex-13-4 || exit 1
snip 13-4-setup
run 'git log --oneline --decorate'
snip 13-4-describe
run 'git describe'
run 'git describe --tags'
run 'git describe --abbrev=0'
run 'git describe --long v1.0.0'
run 'git describe HEAD~4'
run_rc 'git describe --exact-match'
run_rc 'git describe HEAD~5'
run 'git describe --always HEAD~5'
snip 13-5-resolve
run 'git cat-file -t v1.0.0'
run 'git cat-file -t staging-ok'
run 'git rev-parse v1.0.0'
run "git rev-parse 'v1.0.0^{}'"
run 'git rev-parse staging-ok HEAD~2'
run 'git show-ref --tags --dereference'
cd "$LAB_DIR" || exit 1

cd ex-13-6 || exit 1
snip 13-6-commands
run 'git log --oneline --decorate'
fix=$(sid 'Fix negative usage after a refund')
run 'git switch -c release/1.0 v1.0.0'
run "git cherry-pick -x $fix"
run "git tag -a v1.0.1 -m 'quotad 1.0.1: fix negative usage after a refund'"
run 'git switch main'
snip 13-6-graph
run 'git log --graph --oneline --decorate --all'
snip 13-6-describe
run 'git describe main'
run 'git describe release/1.0'
run "git tag --contains $fix"
run 'git log -1 --format=%b v1.0.1'
cd "$LAB_DIR" || exit 1

cd ex-13-7 || exit 1
snip 13-7-symptom
run 'git -C dev log --oneline --decorate -3'
run 'git -C dev tag'
run '(cd dev && scripts/version.sh)'
run '(cd ci && scripts/version.sh)'
snip 13-7-diagnose
run 'git -C ci cat-file -t v1.1.0'
run 'git -C ci cat-file -t v1.0.0'
run "git -C ci for-each-ref refs/tags --format='%(refname:short) %(objecttype)'"
run 'git -C ci describe --tags'
run "git -C ci describe --tags --match 'v[0-9]*'"
cd "$LAB_DIR" || exit 1

cd ex-13-8/work || exit 1
snip 13-8-symptom
run 'git log --oneline --decorate --all'
run 'git rev-parse --short v1.0'
run_rc 'git push origin v1.0'
run 'git switch v1.0'
run 'git log --oneline -1'
snip 13-8-diagnose
run "git for-each-ref --format='%(refname) %(objecttype)' | grep 'v1.0'"
run "git rev-parse refs/heads/v1.0 'refs/tags/v1.0^{commit}'"
snip 13-8-fix
run 'git branch -m v1.0 release/1.0'
run 'git rev-parse --short v1.0'
run 'git push -u origin release/1.0'
run 'git log --oneline --decorate --all'
lab_end
