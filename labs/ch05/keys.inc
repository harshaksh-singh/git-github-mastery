# labs/ch05/keys.inc - sourced by the demos that drive an interactive hunk selector.
#
# run_keys '<answers separated by spaces>' '<git command with a --patch prompt>'
#
# Shows the command as a person would type it, then plays the part of the person at the
# keyboard: the answers are fed to Git on standard input, and each answer is printed after
# the prompt it was given to, which is what a terminal shows when you type it.
# Git's own output is passed through unchanged. If the number of prompts and the number
# of answers differ, the helper stops the demo instead of printing a misleading transcript.
run_keys() {
  local keys="$1" cmd="$2" rc
  tick
  printf '$ %s\n' "$cmd"
  # shellcheck disable=SC2086
  printf '%s\n' $keys | eval "$cmd" 2>&1 | awk -v keys="$keys" '
    BEGIN { n = split(keys, k, " "); i = 0 }
    {
      line = $0
      while (match(line, /\[[^] ]*\]\? /)) {
        i++
        printf "%s%s\n", substr(line, 1, RSTART + RLENGTH - 1), (i <= n ? k[i] : "")
        line = substr(line, RSTART + RLENGTH)
      }
      print line
    }
    END { if (i != n) { printf "run_keys: %d prompt(s) but %d answer(s)\n", i, n; exit 3 } }'
  rc=$?
  [ $rc -eq 0 ] || { printf 'run_keys failed for: %s\n' "$cmd" >&2; exit 96; }
}
