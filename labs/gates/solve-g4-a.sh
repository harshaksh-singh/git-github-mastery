#!/usr/bin/env bash
# Gate 4, hands-on variant A (modelcard-gen): the model diagnosis and recovery as real
# transcripts for answer-keys/gate-4-recovery.md.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$LAB_SCRIPT_DIR/replay-lib.bash"
lab_begin gates solve-g4-a
gate_load gate-4-recovery/variant-a
as config

snip 01-observe
run 'cd modelcard-gen'
run 'git status -sb'
run 'git branch'
run 'git tag'
run 'git stash list'
run 'git reflog'
run 'git log --oneline --all'

snip 02-fsck
run 'git fsck'
tagid=$(git fsck 2>/dev/null | awk '/dangling tag/ {print $3}')
blob=$(git fsck 2>/dev/null | awk '/dangling blob/ {print $3}')
stash=""; other=""
for c in $(git fsck 2>/dev/null | awk '/dangling commit/ {print $3}'); do
  if [ "$(git rev-list --parents -n 1 "$c" | wc -w)" -gt 2 ]; then stash=$c; else other=$c; fi
done

snip 03-identify-tag
run "git cat-file -p ${tagid:0:7}"
run "git log --oneline main..${tagid:0:7}"

snip 04-identify-commits
run "git show -s --format='%h parents: %p%n  %s' ${stash:0:7} ${other:0:7}"
note 'The first one has three parents: a stash made with -u. What does it hold?'
run "git show --stat --format=%s ${stash:0:7}"
run "git show --stat --format=%s '${stash:0:7}^3'"
note 'The second one: a commit that an amend replaced. main has its successor.'
run "git diff --stat ${other:0:7} main"

snip 05-identify-blob
run "git cat-file -p ${blob:0:7} | tail -3"
run "git show ${stash:0:7}:cards/template.md | tail -3"

snip 06-restore-release
run "git tag v0.9.0 ${tagid:0:7}"
run 'git cat-file -t v0.9.0'
run "git branch release/0.9 'v0.9.0^{commit}'"
run 'git log --oneline --decorate main..release/0.9'

snip 07-restore-stash
run "git stash apply ${stash:0:7}"
run 'git status -sb'
run 'git diff --stat'
run 'git fsck'
run 'cd ..'
show_check
gate_done
