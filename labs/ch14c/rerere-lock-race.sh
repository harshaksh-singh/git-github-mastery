#!/usr/bin/env bash
# Chapter 14C, section 14C.3: how often does the MERGE_RR.lock race occur? The same rebase is
# run twenty times with the default configuration and twenty times with
# maintenance.rerere-gc.auto=0. The counts depend on timing, so this demo is volatile.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$LAB_SCRIPT_DIR/fixtures.bash"
lab_begin ch14c rerere-lock-race --volatile

# One trial: rebase until the first conflict, resolve it, continue into the second conflict.
# Prints "lock" if the continue died on MERGE_RR.lock, "ok" otherwise.
trial() {   # trial <default|no-rerere-gc>
  cd "$LAB_DIR" || return 1
  rm -rf trial
  if [ "$1" = default ]; then _fx_14_5_repo trial race; else _fx_14_5_repo trial; fi
  cd trial || return 1
  git config set rerere.enabled true
  git rebase main > /dev/null 2>&1
  printf 'model: bge-small\ntop_k: 50\nrerank: true\n' > retrieval.yaml
  git add retrieval.yaml
  if git rebase --continue 2>&1 | grep -q 'MERGE_RR.lock'; then echo lock; else echo ok; fi
}

count() {   # count <default|no-rerere-gc>: twenty trials, print the number of lock failures
  local n=0 i
  for i in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20; do
    [ "$(trial "$1" 2>/dev/null)" = lock ] && n=$((n + 1))
  done
  printf '%s: MERGE_RR.lock failures in 20 rebases: %s\n' "$1" "$n"
}

snip 01-counts
note 'Twenty rebases with two conflicting commits each, per configuration (labs/ch14c/rerere-lock-race.sh):'
count default
count no-rerere-gc

lab_end
