#!/usr/bin/env bash
# Final test, lab "recovery" (chunkstore): the model solution as real transcripts for
# answer-keys/final-test-answers.md.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$LAB_SCRIPT_DIR/replay-lib.bash"
lab_begin final solve-recovery
final_load recovery

snip 01-observe
run 'cd chunkstore'
run 'git status -sb'
run 'git branch -a'
run 'git stash list'
run 'git reflog'
run 'git count-objects | cut -d, -f1'

snip 02-search
run 'git fsck --dangling'
note 'Two dangling commits. One line each: parents and subject.'
for c in $(git fsck --dangling 2>/dev/null | awk '$2 == "commit" {print $3}'); do
  run "git log -1 --format='%h parents: %p%n  %s' ${c:0:7}"
  case "$(git log -1 --format=%s "$c")" in
    'On main:'*) stash=${c:0:7} ;;
    *)           spike=${c:0:7} ;;
  esac
done

snip 03-recover
run "git log --oneline $spike"
run "git branch spike/semantic-overlap $spike"
run "git stash apply $stash"
run 'git diff'

snip 04-verify
run 'git log --oneline --graph --all'
run 'git status --short'
run 'git fsck --dangling'
run 'cd ..'
show_check
final_done
