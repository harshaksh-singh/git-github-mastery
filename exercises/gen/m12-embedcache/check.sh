#!/usr/bin/env bash
# Read-only verification of exercise 12.10. Exit status 0 means recovered.
. "$(dirname "${BASH_SOURCE[0]}")/../../../labs/ex2/check-lib.bash"
check_begin m12-embedcache asha/.git "${1:-}"
R=asha; B=feature/lru-cache
for s in 'Add cache key builder' 'Add cache key test' 'Normalize the model name in the key' 'Add LRU eviction'; do
  same "the commit \"$s\" is on $B exactly once" "$(count_subject $R main..$B "$s")" 1
done
same 'the branch has exactly four commits on top of main' "$(git -C $R rev-list --count main..$B 2>/dev/null)" 4
expect 'the key builder commit itself has the version prefix' sh -c "git -C $R show \"\$(git -C $R log --format=%H --grep='^Add cache key builder\$' main..$B)\":embedcache/key.py | grep -q 'KEY_VERSION + \":\" + model + \":\"'"
expect 'the final key has the version prefix and the lower-cased model name' sh -c "git -C $R show $B:embedcache/key.py | grep -Fq 'return KEY_VERSION + \":\" + model.lower() + \":\" + digest(text)'"
expect 'no conflict marker is left in the key module' sh -c "! git -C $R show $B:embedcache/key.py | grep -q '^[<=>]\\{7\\}'"
expect 'the test file is back' git -C $R cat-file -e $B:tests/test_key.py
expect 'the LRU module is still there' git -C $R cat-file -e $B:embedcache/lru.py
same 'HEAD is on the branch' "$(git -C $R symbolic-ref -q --short HEAD)" $B
same 'the working tree is clean' "$(git -C $R status --porcelain | wc -l | tr -d ' ')" 0
expect 'no operation is left in progress' no_operation $R
check_end
