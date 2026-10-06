#!/usr/bin/env bash
# Lab 11.5 replay: let git bisect run do the search. First the token_f1 regression of Lab 11.4 with
# a one-line test, then the exact-match regression with a script that knows the exit-code protocol.
# The failure scenario uses the runner's own exit status as the test and gets a wrong answer.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$LAB_SCRIPT_DIR/fixtures/scorekit.sh"
lab_begin ch14a lab-11-5-bisect-run
fx_scorekit || exit 1

snip 01-f1-script
cat > ../check-f1.sh <<'SH'
#!/bin/sh
# good (0) when token_f1 counts repeated tokens, bad (1) when it does not
python3 -B -c '
import sys
from scorekit.metrics import token_f1
sys.exit(0 if token_f1("new york new york", "new york new york city") > 0.8 else 1)'
SH
chmod +x ../check-f1.sh
run 'cat ../check-f1.sh'
run '../check-f1.sh; echo "exit status: $?"'

snip 02-f1-run
run 'git bisect start main v0.1.0'
run 'git bisect run ../check-f1.sh'
run 'git bisect reset'

snip 03-em-script
sk_check_script ../check-em.sh
run 'python3 -B -m scorekit.runner data/smoke.jsonl; echo "exit status: $?"'
run 'cat ../check-em.sh'

snip 04-em-run
run 'git rev-list --count v0.1.0..main'
run 'git bisect start main v0.1.0'
run 'git bisect run ../check-em.sh'

snip 05-em-log
run 'git bisect log | grep -v "^#"'
run 'git bisect reset'

snip 06-failure
printf '#!/bin/sh\npython3 -B -m scorekit.runner data/smoke.jsonl 2>/dev/null\n' > ../naive.sh
chmod +x ../naive.sh
note 'The shortcut: the runner already exits with 1 when the score is too low. Use it as the test.'
run 'cat ../naive.sh'
run 'git bisect start main v0.1.0'
run 'git bisect run ../naive.sh'

snip 07-diagnose
run 'git bisect log | grep -v "^#"'
run 'git show --stat --format="%h %s" refs/bisect/bad'
first=$(git bisect log | sed -n 's/^git bisect bad //p' | sed -n 1p | cut -c1-7)
note "The first verdict was 'bad', for $first. Ask that commit the question the script asked:"
run "git worktree add --detach --quiet ../probe $first"
run '(cd ../probe && python3 -B -m scorekit.runner data/smoke.jsonl 2>&1 | tail -n 1)'
run '(cd ../probe && ../naive.sh; echo "exit status of naive.sh: $?")'
run 'git worktree remove ../probe'

snip 08-recovery
run 'git bisect reset'
run 'git bisect start main v0.1.0'
run 'git bisect run ../check-em.sh | tail -n 12'

snip 09-verification
run 'git bisect log | grep -c "^git bisect skip"'
run 'git bisect reset'
run 'git status --short --branch'
run 'git for-each-ref refs/bisect | wc -l'
lab_end
