#!/usr/bin/env bash
# Lab 11.4 replay: regression 2, by hand. token_f1 gives 0.889 for one known pair at v0.1.0 and
# 0.444 on main. The failure scenario marks one commit wrongly and repairs the session with
# git bisect log and git bisect replay.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$LAB_SCRIPT_DIR/fixtures/scorekit.sh"
lab_begin ch14a lab-11-4-manual-bisect
fx_scorekit || exit 1

snip 01-test
run "check() { python3 -B -c 'from scorekit.metrics import token_f1; print(round(token_f1(\"new york new york\", \"new york new york city\"), 3))'; }"
run 'check'
run 'git switch --quiet --detach v0.1.0 && check && git switch --quiet main'

snip 02-start
run 'git bisect start'
run 'git bisect bad main'
run 'git bisect good v0.1.0'

snip 03-step-1
run 'check'
run 'git bisect good'

snip 04-step-2
run 'check'
run 'git bisect good'

snip 05-step-3
run 'check'
run 'git bisect bad'

snip 06-step-4
run 'check'
run 'git bisect bad'

snip 07-result
run 'git show --format="%h %an %ad%n%n    %s%n%n    %b" --date=short refs/bisect/bad'

snip 08-log
run 'git bisect log'
run 'git bisect reset'

snip 09-failure
note 'A second attempt. At the second step the output is read carelessly and the commit is marked bad:'
run 'git bisect start main v0.1.0'
run 'check'
run 'git bisect good'
run 'check'
run 'git bisect bad'

snip 10-failure-result
run 'check'
run 'git bisect good'
run 'check'
run 'git bisect good'

snip 11-diagnose
note 'The commit that Git names adds a data file. It cannot change what token_f1 returns for two strings.'
run 'git show --stat --format="%h %s" refs/bisect/bad'
run 'git grep -c token_f1 refs/bisect/bad -- data'

snip 12-recovery
run 'git bisect log > ../bisect.log'
run 'grep -n "^git bisect" ../bisect.log'
note 'Keep the start line and the first, correct mark. Delete everything from the wrong mark on.'
run "sed -n '1,/^git bisect good/p' ../bisect.log > ../bisect-fixed.log"
run 'cat ../bisect-fixed.log'

snip 13-replay
run 'git bisect reset'
run 'git bisect replay ../bisect-fixed.log'
run 'check'
run 'git bisect good'

snip 14-finish
run 'check'
run 'git bisect bad'
run 'check'
run 'git bisect bad'

snip 15-verification
run 'git bisect reset'
run 'git status --short --branch'
culprit=$(git rev-parse --short 'main^{/^Simplify token overlap}')
run "git switch --quiet --detach $culprit~1 && check"
run "git switch --quiet --detach $culprit && check"
run 'git switch --quiet main'
lab_end
