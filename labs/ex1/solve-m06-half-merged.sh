#!/usr/bin/env bash
# Replay of Exercise 6.9 (Level 4, a merge left half done): diagnosis and resolution as real
# transcripts for solutions/exercises-m06-m10.md.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$LAB_SCRIPT_DIR/replay-lib.bash"
lab_begin ex1 solve-m06-half-merged
exercise_load m06-half-merged

snip 01-state
run 'cd hybrid-search'
run 'git status'
run 'git log --oneline --graph main feature/rerank'

snip 02-both-sides
run 'git log --oneline --stat MERGE_HEAD..HEAD'
run 'git log --oneline --stat HEAD..MERGE_HEAD'
run 'git ls-files -u'

snip 03-conflict-1
run 'git diff search/retrieve.py'

snip 04-resolve-1
run "printf 'def retrieve(query, limit=10, rerank=False):\n    hits = index.search(query, limit)\n    if rerank:\n        hits = reranker.sort(query, hits)\n    return hits\n' > search/retrieve.py"
run 'git add search/retrieve.py'

snip 05-conflict-2
note 'Three versions of the weights: the base, theirs (stage 3, under the old name), ours (renamed).'
run 'git show :1:configs/legacy_weights.yaml'
run 'git show :3:configs/legacy_weights.yaml'
run 'git show HEAD:configs/weights.yaml'
run 'ls configs'

snip 06-resolve-2
run 'git rm -q configs/legacy_weights.yaml'
run "printf 'weights:\n  bm25_weight: 0.5\n  dense_weight: 0.7\n' > configs/weights.yaml"
run 'git add configs/weights.yaml'
run 'git status --short'
run_rc 'git diff --cached --check'

snip 07-commit
MSG='Merge feature/rerank: optional reranking in retrieve()

Conflicts:
- search/retrieve.py: kept the rename top_k -> limit (default 10) from main
  and added the rerank option of the feature.
- configs/legacy_weights.yaml: main replaced the file by configs/weights.yaml,
  the feature raised bm25_weight to 0.5 in the old file. The old file stays
  deleted; the new weight was carried into configs/weights.yaml by hand.'
run_msg "$MSG" 'git commit'
run 'git log --graph --oneline'

snip 08-audit
run 'git show --remerge-diff --format="%h %s" HEAD'

snip 09-check
run 'cd ..'
show_check
exercise_done
