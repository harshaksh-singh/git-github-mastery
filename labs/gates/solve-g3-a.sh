#!/usr/bin/env bash
# Gate 3, hands-on variant A (chunker): the model diagnosis and repair as real transcripts for
# answer-keys/gate-3-merge-and-rebase.md.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$LAB_SCRIPT_DIR/replay-lib.bash"
lab_begin gates solve-g3-a
gate_load gate-3-merge-and-rebase/variant-a
as config

snip 01-observe
run 'cd you'
run 'git status -sb'
run 'git log --oneline --graph --all'
run 'cat .git/rebase-merge/head-name'
run 'git log --oneline main..ORIG_HEAD'

snip 02-stages
run 'git ls-files -u'
note 'Stage 2, "ours": in a rebase this is the commit being built on, here main.'
run 'git show :2:chunker/split.py | head -2'
note 'Stage 3, "theirs": the commit being replayed, here your own.'
run 'git show :3:chunker/split.py | head -2'
run 'git log -1 --oneline REBASE_HEAD'
run 'git diff'

snip 03-resolve
cat > chunker/split.py <<'PY'
def split(text, max_len=512, overlap=0):
    """Split text into chunks of at most max_len characters."""
    chunks = []
    start = 0
    while start < len(text):
        chunks.append(text[start:start + max_len])
        start += max_len - overlap
    return chunks
PY
note 'chunker/split.py edited by hand to the agreed function'
run 'git diff --stat'
run 'git add chunker/split.py'
run 'git rebase --continue'
run 'git log --oneline main..feature/overlap'

snip 04-autosquash
note 'A name for the state before the second rewrite.'
run 'git branch backup/overlap-before-squash'
run 'git rebase --autosquash main'
run 'git log --oneline --stat main..feature/overlap'

snip 05-prove
run 'git diff --stat backup/overlap-before-squash feature/overlap'
run 'git range-diff main backup/overlap-before-squash feature/overlap'
run 'git show feature/overlap:chunker/split.py'

snip 06-backport
run 'git switch release/1.2'
run 'git cherry-pick -x feature/overlap'
run 'git log -1 --format=%B'
run 'git log --oneline origin/release/1.2..release/1.2'
run 'git diff --stat origin/release/1.2 release/1.2'
run 'git cherry -v release/1.2 feature/overlap'

snip 07-finish
run 'git switch feature/overlap'
run 'git branch -D backup/overlap-before-squash'
run 'git status -sb'
run 'cd ..'
show_check
gate_done
