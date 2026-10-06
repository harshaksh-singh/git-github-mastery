#!/usr/bin/env bash
# Exercise 8.9 (Level 4): one bad commit that is public, one mixed commit that is not.
# Builds server.git and your clone you/ of the project "grader". Read SYMPTOMS.md, not this file,
# before you start.
. "$(dirname "${BASH_SOURCE[0]}")/../../../labs/lib/lab-env.sh"
. "$COURSE_ROOT/exercises/gen/x1-lib/gen-lib.bash"
[ -n "${LAB_REPLAY:-}" ] || sandbox_begin exercises m08-undo-mix
ex_begin m08-undo-mix

ex_server
ex_clone you
cd you || exit 1
mkdir -p grader configs
printf 'PASS_MARK = 0.7\n' > grader/threshold.py
printf 'def parse(answer):\n    return answer.strip()\n' > grader/parser.py
printf 'timeout_s: 30\n' > configs/grader.yaml
_c 'Add grader'
printf 'PASS_MARK = 0.5\n' > grader/threshold.py
_c 'Lower the pass mark to 0.5'
printf 'def load(path):\n    return open(path).read().splitlines()\n' > grader/rubric.py
_c 'Add rubric loader'
quiet 'git push -u origin main'
ex_note server_main "$(git rev-parse HEAD)"
ex_note parser_blob "$(git rev-parse HEAD:grader/parser.py)"

# Not pushed: one commit that mixes a setting that must ship with an experiment that must not.
printf 'timeout_s: 60\n' > configs/grader.yaml
printf 'import re\n\ndef parse(answer):\n    # experiment: keep only the first number in the answer\n    m = re.search(r"-?[0-9.]+", answer)\n    return m.group(0) if m else answer.strip()\n' > grader/parser.py
ex_note experiment_blob "$(git hash-object grader/parser.py)"
_c 'Update config and try new parser'

ex_end
[ -n "${LAB_REPLAY:-}" ] || printf 'Exercise ready. Open a lab shell there:\n  labs/shell "%s"\n' "$LAB_DIR"
