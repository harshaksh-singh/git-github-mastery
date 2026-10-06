#!/usr/bin/env bash
# Chapter 6, section 6.4: the commit ID is the hash of the commit object. The same inputs
# give the same ID; changing any single field gives a different ID.
. "$(dirname "$0")/../lib/lab-env.sh"
lab_begin ch06 commit-id

quiet 'git init evalkit'
cd evalkit || exit 1
mkdir -p evalkit
printf '# evalkit\n\nSmall evaluation harness for LLM outputs.\n' > README.md
printf 'def exact_match(pred, gold):\n    return float(pred.strip() == gold.strip())\n' > evalkit/metrics.py
quiet 'git add . && git commit -m "Add exact-match metric"'
printf '\n\ndef f1(pred, gold):\n    return 0.0  # placeholder until the tokenizer lands\n' >> evalkit/metrics.py
quiet 'git commit -am "Add F1 metric"'

snip 01-hash-by-hand
run 'git rev-parse HEAD'
run 'git cat-file -s HEAD'
run "(printf 'commit %s\\0' \"\$(git cat-file -s HEAD)\"; git cat-file commit HEAD) | shasum"
run 'git cat-file commit HEAD | git hash-object -t commit --stdin'

snip 02-same-inputs
d=$(git log -1 --format=%ad --date=raw)      # for example "1788755640 +0530"
secs=${d% *}
run 'git cat-file -p HEAD'
run "mk() { GIT_AUTHOR_DATE=\"\$1\" GIT_COMMITTER_DATE=\"\$2\" git commit-tree -p \"\$3\" -m \"\$4\" \"\$5\"; }"
run "T='@$secs +0530'"
run "mk \"\$T\" \"\$T\" HEAD~1 'Add F1 metric' 'HEAD^{tree}'"

snip 03-one-field-changes
note 'Each call changes exactly one input of the call above.'
run "mk \"\$T\" \"\$T\" HEAD~1 'Add F1 metric.' 'HEAD^{tree}'                 # message: one more character"
run "mk '@$((secs + 1)) +0530' \"\$T\" HEAD~1 'Add F1 metric' 'HEAD^{tree}'   # author date: one second later"
run "mk \"\$T\" '@$((secs + 1)) +0530' HEAD~1 'Add F1 metric' 'HEAD^{tree}'   # committer date: one second later"
run "mk '@$secs +0000' \"\$T\" HEAD~1 'Add F1 metric' 'HEAD^{tree}'   # author time zone: same instant, other offset"
run "mk \"\$T\" \"\$T\" HEAD 'Add F1 metric' 'HEAD^{tree}'                    # parent: HEAD instead of HEAD~1"
run "mk \"\$T\" \"\$T\" HEAD~1 'Add F1 metric' 'HEAD~1^{tree}'                # tree: the previous snapshot"
run "GIT_AUTHOR_EMAIL=You@example.com mk \"\$T\" \"\$T\" HEAD~1 'Add F1 metric' 'HEAD^{tree}'   # author email: capital Y"

lab_end
