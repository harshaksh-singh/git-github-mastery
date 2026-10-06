#!/usr/bin/env bash
# Which integration step does git pull choose? Every combination of pull.rebase and pull.ff
# tried from the same diverged state, then the command-line flags. Chapter 12, section 12.6.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$(dirname "$0")/fixture.bash"
lab_begin ch12 pull-matrix

# Hidden setup: a diverged main. Asha has published one commit, you have one local commit,
# and you have already fetched.
make_server
new_clone you
new_clone asha
enter asha
commit_file config.yaml 'model: small-v1\ntop_k: 8\n' 'Raise top_k to 8'
hidden 'git push'
enter you
commit_file requirements-dev.txt 'pytest\n' 'Add dev requirements'
hidden 'git fetch'

# The experiment itself is a small shell script that the transcript prints before running it.
cat > "$LAB_DIR/try-pull.sh" <<'SCRIPT'
#!/bin/sh
# Run "git pull" under every combination of pull.rebase and pull.ff, always starting
# from the same diverged state, and report what Git did. Usage: sh try-pull.sh [pull flags]
start=$(git rev-parse HEAD)
for rebase in unset false true; do
  for ff in unset only false true; do
    git config unset pull.rebase 2>/dev/null
    git config unset pull.ff 2>/dev/null
    [ "$rebase" = unset ] || git config set pull.rebase "$rebase"
    [ "$ff" = unset ] || git config set pull.ff "$ff"
    if out=$(git pull --quiet --no-edit "$@" 2>&1); then
      if [ "$(git rev-list --count --merges @{u}..HEAD)" = 1 ]; then
        result="merge commit"
      else
        result="rebase"
      fi
    else
      result=$(printf '%s\n' "$out" | grep '^fatal')
    fi
    printf 'pull.rebase=%-5s pull.ff=%-5s -> %s\n' "$rebase" "$ff" "$result"
    git reset --quiet --hard "$start"
  done
done
git config unset pull.rebase 2>/dev/null
git config unset pull.ff 2>/dev/null
SCRIPT

snip 01-script
run 'git status -sb'
run 'cat ../../try-pull.sh'

snip 02-config-only
run 'sh ../../try-pull.sh'

snip 03-flags
run "sh ../../try-pull.sh --rebase | cut -d'>' -f2 | sort | uniq -c"
run "sh ../../try-pull.sh --no-rebase | cut -d'>' -f2 | sort | uniq -c"
run "sh ../../try-pull.sh --ff-only | cut -d'>' -f2 | sort | uniq -c"

lab_end
