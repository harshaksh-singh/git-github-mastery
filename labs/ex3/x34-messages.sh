#!/usr/bin/env bash
# Exercise 34.3 (Module 34): commit messages as data. A regular prefix and trailers can be
# queried; neither makes a message true.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$LAB_SCRIPT_DIR/fixture.bash"
lab_begin ex3 x34-messages
hidden 'git init ragbench'
cd ragbench || exit 1
printf 'top_k: 5\nrate_limit: 60\n' | put configs/eval.yaml
commit_all 'feat: add evaluation config'
printf 'def score(hits, k):\n    return sum(hits[:k]) / k\n' | put src/ragbench/metrics.py
tick; { git add -A && git commit -q -m 'feat: add recall metric' -m 'Co-authored-by: eval-agent <agent@example.com>'; } > /dev/null 2>&1
printf '# ragbench\n\nEvaluates retrieval quality.\n' | put README.md
commit_all 'docs: add README'
printf 'top_k: 5\nrate_limit: 6000\n' | put configs/eval.yaml
tick; { git add -A && git commit -q -m 'fix: typo' -m 'Co-authored-by: eval-agent <agent@example.com>'; } > /dev/null 2>&1
printf 'def score(hits, k):\n    if k <= 0:\n        raise ValueError("k must be positive")\n    return sum(hits[:k]) / k\n' | put src/ragbench/metrics.py
tick; { git add -A && git commit -q -m 'fix: reject k that is not positive' -m 'A k of 0 divided by zero in nightly run 412.' -m 'Reviewed-by: Asha Rao <asha@example.com>'; } > /dev/null 2>&1
printf 'wip\n' | put notes.txt
commit_all 'wip'

snip 01-log
run 'git log --oneline'

snip 02-by-type
run "git log --format=%s | sed -n 's/^\\([a-z]*\\): .*/\\1/p' | sort | uniq -c"
run "git log --oneline --invert-grep --grep='^[a-z]*: '"

snip 03-agent-commits
run "git log --format='%h %s' --grep='Co-authored-by: eval-agent'"
run "git log -1 --format='%(trailers:key=Reviewed-by,valueonly)' HEAD~1"

snip 04-does-the-message-match
run "git log --stat --format='%h %s' --grep='^fix'"
run "git log -p --format='%h %s' -1 --grep='^fix: typo' | grep -E '^[-+][a-z]'"

lab_end
