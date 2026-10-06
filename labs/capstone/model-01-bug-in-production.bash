# Model solution of capstone stage 1 (a bug reaches production). Sourced by the replay script
# stage-01-bug-in-production.sh (with transcript capture) and by capstone/setup.sh --stage N
# (silently, to build the state for a later stage).
cd "$LAB_DIR" || exit 97
cap_as you

csnip 01-observe
run 'cd you'
run 'git status -sb'
run 'git fetch'
run 'git log --oneline --decorate v1.2.0..origin/main'
run '../pr list'

csnip 02-reproduce
note 'The sample from the alert as a script. It lives outside the repository, so that no'
note 'checkout can change it. Exit status 0 means the message went to a human agent.'
note 'First prove the script on both ends: it must fail on v1.3.0 and pass on v1.2.0.'
cat > ../repro.py <<'F'
import sys
from router.classify import classify
from router.keywords import keyword_score

routed = classify([("billing_refund", keyword_score(12), 0.10)])
print("routed to", routed)
sys.exit(0 if routed == "human_agent" else 1)
F
run 'cat ../repro.py'
run_rc 'PYTHONPATH=. python3 -B ../repro.py'
run 'git switch --quiet --detach v1.2.0'
run_rc 'PYTHONPATH=. python3 -B ../repro.py'

csnip 03-test-the-suspect
note 'Hypothesis of the engineer on call: pull request #11. Her branch reverts it. Test it.'
run 'git log --oneline -1 origin/fix/revert-embed-weight'
run 'git switch --quiet --detach origin/fix/revert-embed-weight'
run_rc 'PYTHONPATH=. python3 -B ../repro.py'
run 'git switch --quiet main'

csnip 04-bisect
run 'git bisect start v1.3.0 v1.2.0'
run 'git bisect run env PYTHONPATH=. python3 -B ../repro.py'
culprit=$(git rev-parse --short refs/bisect/bad)

csnip 05-bisect-end
run 'git bisect log'
run 'git bisect reset'

csnip 06-blame
run "git show --stat --format='%h %an, committed by %cn%n%s' $culprit"
run "git blame -s -L '/^def keyword_score/,+3' v1.3.0 -- router/keywords.py"
run "git blame -s -L '/^def keyword_score/,+3' v1.2.0 -- router/keywords.py"

csnip 07-inside-the-squash
note 'A squash merge is one commit on main. The commits it was made of are still on the'
note 'server, under the pull request ref.'
run 'git fetch origin refs/pull/8/head'
run 'git log --oneline v1.2.0..FETCH_HEAD'
inner=$(git log --format=%h -1 --grep='^Simplify keyword_score$' FETCH_HEAD)
run "git show --format='%h %s' $inner"

csnip 08-revert
run 'git switch -c fix/keyword-score-cap origin/main'
run "git revert --no-edit $culprit"
run 'git show --stat --format=%B HEAD'
run_rc 'PYTHONPATH=. python3 -B ../repro.py'
run 'bash scripts/test.sh'

csnip 09-regression-test
note '(edit tests/test_scoring.py: a test that fails on the faulty version)'
cat >> tests/test_scoring.py <<'F'

    def test_keyword_score_never_exceeds_one(self):
        self.assertEqual(keyword_score(12), 1.0)
F
tick
run 'git diff'
run 'bash scripts/test.sh'
run "git commit -q -am 'Test that the keyword score never exceeds 1'"
note 'Does the new test catch the fault? Run it against the faulty file, then put the file back.'
run 'git restore --source=v1.3.0 -- router/keywords.py'
run_rc 'bash scripts/test.sh'
run 'git restore --source=HEAD -- router/keywords.py'
run 'git status -sb'

csnip 10-pull-request
run 'git push -u origin fix/keyword-score-cap'
run "../pr open fix/keyword-score-cap --title 'Restore the cap on the keyword score'"
pr=$("$LAB_DIR/pr" list | sed -n 's/^#\([0-9]*\) .*fix\/keyword-score-cap.*/\1/p')
other=$("$LAB_DIR/pr" list | sed -n 's/^#\([0-9]*\) .*fix\/revert-embed-weight.*/\1/p')
run "../pr view $pr"
run "../pr merge $pr --merge"
run "../pr close $other"

csnip 11-release
run 'git switch main'
run 'git pull --ff-only'
run "git tag -a v1.3.1 -m 'intent-router 1.3.1: restore the cap on the keyword score'"
run 'git push origin v1.3.1'
run 'git log --oneline --graph --decorate v1.3.0..v1.3.1'

csnip 12-verify
run 'git switch --quiet --detach v1.3.1'
run_rc 'PYTHONPATH=. python3 -B ../repro.py'
run 'bash scripts/test.sh'
run 'git diff --stat v1.3.0 v1.3.1'
run 'git switch --quiet main'
run 'git fetch --prune'
run 'git branch -d fix/keyword-score-cap'
run 'cd ..'
quiet 'rm -f repro.py'
cshow_check
