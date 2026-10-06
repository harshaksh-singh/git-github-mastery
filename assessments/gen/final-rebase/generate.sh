#!/usr/bin/env bash
# Final test, practical lab "rebase" (section 5): the project "citecheck".
# Builds server.git and your clone you/. Your unpublished branch has five commits that must
# become three before a pull request is opened. Read TASK.md, not this file, before you start.
. "$(dirname "${BASH_SOURCE[0]}")/../../../labs/lib/lab-env.sh"
. "$COURSE_ROOT/assessments/gen/final-lib/final-lib.bash"
[ -n "${LAB_REPLAY:-}" ] || sandbox_begin final rebase
final_begin rebase

final_server
final_clone you
cd you || exit 1
mkdir -p citecheck
printf 'def cited_spans(answer):\n    return [s for s in answer.spans if s.source_id]\n' > citecheck/extract.py
_c 'Add citation extraction'
printf '# citecheck\n\nChecks that every claim in an answer cites a source.\n' > README.md
_c 'Add README'
quiet 'git push -u origin main'

quiet 'git switch -c feature/span-match'
printf 'def match(span, source):\n    treshold = 0.8\n    return overlap(span.text, source.text) >= treshold\n' > citecheck/match.py
_c 'Add span matcher'
printf 'def overlap(a, b):\n    ta, tb = set(a.split()), set(b.split())\n    return len(ta & tb) / max(len(ta), 1)\n' > citecheck/overlap.py
printf 'overlap("a b", "a c") = 0.5\noverlap("", "x") = 0.0\n' > debug.log
_c 'wip'
printf 'fuzzy_threshold: 0.8\n' > config.yaml
_c 'Add fuzzy threshold'
printf 'def match(span, source):\n    threshold = 0.8\n    return overlap(span.text, source.text) >= threshold\n' > citecheck/match.py
_c 'fixup! Add span matcher'
quiet 'git rm -q debug.log'
_c 'Remove debug log'
final_note old "$(git rev-parse HEAD)"
cd "$LAB_DIR" || exit 1

# Meanwhile Asha's pull request is merged on the server, and you fetch.
final_clone asha
cd asha || exit 1
as asha
printf 'def parse(reference):\n    author, _, rest = reference.partition(" (")\n    return author, rest.rstrip(")")\n' > citecheck/parse.py
_c 'Add citation parser'
quiet 'git push'
cd "$LAB_DIR/you" || exit 1
as you
quiet 'git fetch'
final_note base "$(git rev-parse origin/main)"
final_note tree "$(git merge-tree --write-tree origin/main feature/span-match)"

final_end
final_ready
