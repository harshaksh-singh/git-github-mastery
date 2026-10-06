#!/usr/bin/env bash
# Re-run every demo script and compare its output with the snippets printed in the book.
#   labs/verify-all.sh            verify everything
#   labs/verify-all.sh ch08       verify one directory
# PASS      output is byte-for-byte identical to the stored snippets
# VOLATILE  the demo is marked as legitimately different on every run (for example new keys); it only has to run
# FAIL      output differs or the script failed
set -u
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
. "$ROOT/labs/lib/lab-env.sh"
_lab_env
TMP_OUT="$LAB_ROOT/.verify-out.$$"      # unique per run, so parallel verifications do not collide
rm -rf "$TMP_OUT"; mkdir -p "$TMP_OUT"
trap 'rm -rf "$TMP_OUT"' EXIT
pass=0; fail=0; vol=0
for dir in "$ROOT"/labs/*/; do
  d="$(basename "$dir")"
  [ "$d" = "lib" ] && continue
  [ $# -ge 1 ] && [ "$1" != "$d" ] && continue
  for s in "$dir"*.sh; do
    [ -f "$s" ] || continue
    demo="$(basename "$s" .sh)"
    case "$demo" in
      setup-*)   # setup scripts only prepare a hands-on sandbox; they produce no snippets
        bash "$s" > /dev/null 2>&1; rc=$?
        if [ $rc -eq 0 ]; then echo "SETUP-OK  $d/$demo"; pass=$((pass+1)); else echo "FAIL      $d/$demo (exit $rc)"; fail=$((fail+1)); fi
        continue ;;
    esac
    LAB_OUT_ROOT="$TMP_OUT" bash "$s" > /dev/null 2>&1; rc=$?
    if [ -f "$ROOT/labs/$d/out/$demo/.volatile" ]; then
      if [ $rc -eq 0 ]; then echo "VOLATILE  $d/$demo"; vol=$((vol+1)); else echo "FAIL      $d/$demo (exit $rc)"; fail=$((fail+1)); fi
      continue
    fi
    if [ $rc -ne 0 ]; then echo "FAIL      $d/$demo (exit $rc)"; fail=$((fail+1)); continue; fi
    if diff -r -x .volatile "$TMP_OUT/$d/out/$demo" "$ROOT/labs/$d/out/$demo" > /dev/null 2>&1; then
      echo "PASS      $d/$demo"; pass=$((pass+1))
    else
      echo "FAIL      $d/$demo (output differs from stored snippets)"; fail=$((fail+1))
    fi
  done
done
echo "----"
echo "pass=$pass volatile=$vol fail=$fail  (git $(git --version | awk '{print $3}'))"
[ $fail -eq 0 ]
