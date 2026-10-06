#!/usr/bin/env bash
# Lab 16.2 setup: an evaluation harness whose test-case file exists in six versions.
#
#   bash labs/ch03/setup-16-2-delta-history.sh
#
# builds the repository in $GIT_MASTERY_LABS/hands-on/m16-2/eval-harness (default root:
# ~/git-mastery-labs). The lab replay and the chapter demo source this file with LAB_REPLAY=1,
# so they build exactly the same repository, with the same object IDs, in their own sandbox.
if [ -z "${LAB_REPLAY:-}" ]; then
  . "$(dirname "${BASH_SOURCE[0]}")/../lib/lab-env.sh"
  sandbox_begin hands-on m16-2
fi

quiet 'git init eval-harness'
cd eval-harness || exit 1
quiet 'mkdir -p eval'
# 200 evaluation cases, one JSON document per line (about 16 KiB).
_i=1
while [ "$_i" -le 200 ]; do
  printf '{"id": %d, "prompt": "Summarise ticket %d in one sentence", "expected_tokens": %d}\n' \
    "$_i" "$_i" $((_i * 7 % 50 + 20))
  _i=$((_i + 1))
done > eval/cases.jsonl
quiet "printf 'threshold = 0.80\n' > eval/config.toml"
quiet 'git add eval && git commit -m "Add evaluation cases"'
# Five commits, each changing one line of the 200.
for _line in 30 60 90 120 150; do
  quiet "sed -e '${_line}s/one sentence/two sentences/' eval/cases.jsonl > eval/cases.tmp && mv eval/cases.tmp eval/cases.jsonl"
  quiet "git commit -am 'Relax case ${_line} to two sentences'"
done
unset _i _line

if [ -z "${LAB_REPLAY:-}" ]; then
  printf 'Lab 16.2 sandbox ready. Open a lab shell there:\n  labs/shell m16-2\n  cd eval-harness\n'
fi
