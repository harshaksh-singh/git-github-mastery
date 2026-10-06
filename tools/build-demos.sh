#!/usr/bin/env bash
# Authoring tool: run demo scripts and regenerate their transcript snippets under labs/<dir>/out/.
#   tools/build-demos.sh ch08                 all demos in labs/ch08
#   tools/build-demos.sh ch08/conflict-basic  one demo
set -u
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
[ $# -ge 1 ] || { echo "usage: tools/build-demos.sh <dir>[/<demo>] ..."; exit 2; }
fail=0
for target in "$@"; do
  case "$target" in
    */*) set_list="$ROOT/labs/$target.sh" ;;
    *)   set_list=$(ls "$ROOT/labs/$target"/*.sh 2>/dev/null) ;;
  esac
  [ -n "$set_list" ] || { echo "no demo scripts for '$target'"; fail=1; continue; }
  old_ifs="$IFS"; IFS='
'
  for s in $set_list; do
    IFS="$old_ifs"
    [ -f "$s" ] || { echo "missing: $s"; fail=1; continue; }
    bash "$s"; rc=$?
    [ $rc -eq 0 ] || { echo "!! $s exited with status $rc"; fail=1; }
  done
  IFS="$old_ifs"
done
exit $fail
