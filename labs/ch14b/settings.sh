#!/usr/bin/env bash
# Chapter 14B, section 14B.5: three settings from the "decide deliberately" table whose
# effect is not shown in another chapter: init.defaultBranch, help.autocorrect, diff.algorithm.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$(dirname "$0")/fixture.bash"
lab_begin ch14b settings
sandbox_home
make_gateway "$HOME/work/inference-gateway"
tick
cat > gateway/retry.py <<'PY'
def call_small(prompt):
    for attempt in range(3):
        try:
            return small.complete(prompt)
        except Timeout:
            continue
    raise Unavailable("small")


def call_large(prompt):
    for attempt in range(3):
        try:
            return large.complete(prompt)
        except Timeout:
            continue
    raise Unavailable("large")
PY
hidden 'git add gateway/retry.py && git commit -m "Add retry wrappers"'
# The edit: call_large moves to the top and gets five attempts with a backoff.
cat > gateway/retry.py <<'PY'
def call_large(prompt):
    for attempt in range(5):
        try:
            return large.complete(prompt)
        except Timeout:
            backoff(attempt)
    raise Unavailable("large")


def call_small(prompt):
    for attempt in range(3):
        try:
            return small.complete(prompt)
        except Timeout:
            continue
    raise Unavailable("small")
PY

snip 01-default-branch
run 'git var GIT_DEFAULT_BRANCH'
run 'git config get --show-origin init.defaultBranch'
note 'The same question with no global file at all, which is how unconfigured Git 2.55 answers:'
run 'GIT_CONFIG_GLOBAL=/dev/null git var GIT_DEFAULT_BRANCH'

snip 02-autocorrect
run_rc 'git stauts -sb'
run_rc 'git -c help.autocorrect=never stauts -sb'
run_rc 'git -c help.autocorrect=immediate stauts -sb'

snip 03-diff-myers
run 'git diff --stat'
run 'git diff | tail -n +5'

snip 04-diff-histogram
run 'git config set diff.algorithm histogram'
run 'git diff --stat'
run 'git diff | tail -n +5'

lab_end
