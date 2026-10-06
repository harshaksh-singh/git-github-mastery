#!/usr/bin/env bash
# Model solution of exercise 11.9 (Level 4): a bisect whose culprit sits among untestable commits.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$LAB_SCRIPT_DIR/replay-lib.bash"
lab_begin ex2 solve-m11-judgekit
ex_load m11-judgekit
cd judgekit || exit 1

snip 01-observe
run 'git status -sb'
run 'git rev-list --count v1.0.0..v1.1.0'
run 'python3 -B check_agreement.py; echo "exit status: $?"'
run 'git switch --detach -q v1.0.0 && python3 -B check_agreement.py; git switch -q main'

snip 02-script
cat > ../test-agreement.sh <<'SH'
#!/bin/sh
# good (0): agreement of at least 0.90; bad (1): lower; 125: the check cannot run on this commit
out=$(python3 -B check_agreement.py 2>/dev/null) || exit 125
case "$out" in
  "agreement 0.9"*|"agreement 1.0"*) exit 0 ;;
  "agreement "*)                     exit 1 ;;
  *)                                 exit 125 ;;
esac
SH
chmod +x ../test-agreement.sh
run 'cat ../test-agreement.sh'

snip 03-bisect
run 'git bisect start v1.1.0 v1.0.0'
run 'git bisect run ../test-agreement.sh'

snip 04-why
run 'git bisect log | grep "^# "'
run 'git bisect reset'
fix=$(sid 'Fix import after the verdict module move')
run "git show --format='%h %s' $fix"

snip 05-hotfix-script
cat > ../test-with-fix.sh <<SH
#!/bin/sh
# Same verdicts, but first apply the import fix $fix where it is missing, and remove it afterwards.
if ! python3 -B -c 'import judgekit.agree' 2>/dev/null; then
  git cherry-pick --no-commit $fix >/dev/null 2>&1 || { git reset -q --hard; exit 125; }
fi
../test-agreement.sh
rc=\$?
git reset -q --hard
exit \$rc
SH
chmod +x ../test-with-fix.sh
run 'cat ../test-with-fix.sh'

snip 06-bisect-again
run 'git bisect start v1.1.0 v1.0.0'
run 'git bisect run ../test-with-fix.sh'

snip 07-mark
bad=$(git rev-parse --short refs/bisect/bad)
run 'git bisect reset'
run "git tag answer/first-bad $bad"
run "git show --format='%h %an: %s' answer/first-bad"

snip 08-fix
run 'git revert --no-edit answer/first-bad'
run 'python3 -B check_agreement.py'
run 'git log --oneline -3'
run 'git status -sb'
run 'cd ..'
show_check
ex_done
