#!/usr/bin/env bash
# Gate 1 (Fundamentals), hands-on part, variant A: the project "tokmeter".
# Builds one repository whose working tree, index and last commit disagree in three ways.
# Read SYMPTOMS.md, not this file, before you start: the script is the answer to "what happened".
. "$(dirname "${BASH_SOURCE[0]}")/../../../../labs/lib/lab-env.sh"
. "$COURSE_ROOT/assessments/gen/lib/gate-lib.bash"
[ -n "${LAB_REPLAY:-}" ] || sandbox_begin gates g1-a
gate_begin g1-a

quiet 'git init tokmeter'
cd tokmeter || exit 1
quiet "git config set user.name 'Asha Rao' && git config set user.email asha@example.com"
as asha
mkdir -p tokmeter reports
printf 'def count(text, encoding):\n    return len(encoding.encode(text))\n' > tokmeter/count.py
printf 'input_per_1k: 0.50\noutput_per_1k: 1.50\n' > rates.yaml
printf '{"tokens": 0}\n' > reports/last-run.json
_c 'Add token counter and rate table'
printf 'reports/\n__pycache__/\n' > .gitignore
_c 'Ignore generated reports'
printf 'import sys\nfrom tokmeter.count import count\n\nif __name__ == "__main__":\n    print(count(sys.stdin.read(), None))\n' > tokmeter/cli.py
_c 'Add command-line entry point'

# The rate update: staged once, edited again, then committed without staging again.
printf 'input_per_1k: 0.40\noutput_per_1k: 1.50\n' > rates.yaml
quiet 'git add rates.yaml'
printf 'input_per_1k: 0.40\noutput_per_1k: 1.20\n' > rates.yaml
quiet 'git commit -m "Update rate table for September"'
gate_note parent "$(git rev-parse HEAD~1)"
# Later: staged again, and edited once more.
quiet 'git add rates.yaml'
printf 'input_per_1k: 0.40\noutput_per_1k: 1.20\ncached_input_per_1k: 0.10\n' > rates.yaml
# A run rewrote the report; a new module was written; a setting was copied from a wiki page.
printf '{"tokens": 18234}\n' > reports/last-run.json
printf 'CACHE = {}\n\ndef cached_count(text, encoding):\n    key = (text, id(encoding))\n    if key not in CACHE:\n        CACHE[key] = len(encoding.encode(text))\n    return CACHE[key]\n' > tokmeter/cache.py
quiet 'git config set status.showUntrackedFiles no'

gate_end
gate_ready
