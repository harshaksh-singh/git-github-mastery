# Model solution of capstone stage 2 (a merge conflict between two feature branches that was
# resolved wrongly). Sourced by the replay script and by capstone/setup.sh --stage N.
cd "$LAB_DIR" || exit 97
cap_as you
B=feature/low-confidence-penalty

csnip 01-observe
run 'cd you'
run 'git fetch'
run '../pr list'
run '../pr view 12'

csnip 02-graph
run "git log --oneline --graph origin/main origin/$B -7"
run "git diff --stat origin/main origin/$B"
run_rc 'git grep -c DISAGREEMENT origin/main -- router'
mine=$(git rev-parse --short "$B")
run "git log --oneline -1 $B"

csnip 03-what-the-merge-did
note 'A merge commit records a result. --remerge-diff repeats the merge and shows what the'
note 'person who resolved it changed, compared with what Git produced on its own.'
run "git show --remerge-diff --format='%h %an: %s' origin/$B -- router/scoring.py"

csnip 04-tests-lie
run "git switch $B"
run 'git pull --ff-only'
run 'bash scripts/test.sh'
note 'Green, although the penalty is gone. Compare the test file with my commit:'
run "git diff $mine HEAD -- tests/test_scoring.py"

csnip 05-redo
note 'Forward, without rewriting the branch: apply my commit again on top of the bad merge.'
note 'This time the conflict is resolved by reading it.'
run 'git config set merge.conflictStyle zdiff3'
run_rc "git cherry-pick $mine"
run 'git status -sb'

csnip 06-conflict
run 'git diff router/scoring.py'

csnip 07-resolve
note '(edit router/scoring.py: both constants; the signature and the weight from main;'
note ' my penalty applied to the score that is computed with that weight)'
cat > router/scoring.py <<'F'
"""Blend the keyword score and the embedding score of one candidate intent."""

EMBED_WEIGHT = 0.8
TENANT_EMBED_WEIGHT = {"acme-retail": 0.6}
DISAGREEMENT = 0.6


def blend(keyword_score, embed_score, tenant=None):
    """Both inputs are in [0, 1]; so is the result."""
    weight = TENANT_EMBED_WEIGHT.get(tenant, EMBED_WEIGHT)
    score = (1 - weight) * keyword_score + weight * embed_score
    if abs(keyword_score - embed_score) > DISAGREEMENT:
        score *= 0.5  # the two signals disagree: trust neither
    return score
F
note '(edit tests/test_scoring.py: keep both new tests, and add one for the combination)'
python3 - <<'PY'
import re
p = "tests/test_scoring.py"
s = open(p).read()
s = re.sub(r"<<<<<<< [^\n]*\n(.*?)\|\|\|\|\|\|\| [^\n]*\n.*?=======\n(.*?)>>>>>>> [^\n]*\n", r"\1\n\2", s, flags=re.S)
s += '''
    def test_penalty_uses_the_tenant_weight(self):
        self.assertAlmostEqual(blend(1.0, 0.0, "acme-retail"), 0.2)
'''
open(p, "w").write(s)
PY
tick
run 'git diff router/scoring.py'
run "grep -n 'def test_' tests/test_scoring.py"
run_rc "grep -c '^[<=>|]\\{7\\}' router/scoring.py tests/test_scoring.py"

csnip 08-conclude
run 'bash scripts/test.sh'
run 'git add router/scoring.py tests/test_scoring.py'
run "git commit -q -m 'Restore the disagreement penalty that the merge dropped' -m 'The merge of main into this branch took the version of main for all of router/scoring.py and tests/test_scoring.py. This commit applies the penalty again, on the per-tenant weight, and keeps the tests of both changes.'"
run 'git status -sb'
run 'git log --oneline --graph -4'

csnip 09-verify
note 'What the pull request will show now, and that it is my change and nothing else:'
run 'git diff --stat origin/main...HEAD'
note 'Default weight, a tenant with its own weight, and that tenant without disagreement:'
run "PYTHONPATH=. python3 -B -c 'from router.scoring import blend; print(round(blend(1.0, 0.0), 3), round(blend(1.0, 0.0, \"acme-retail\"), 3), round(blend(0.0, 0.5, \"acme-retail\"), 3))'"

csnip 10-publish
run 'git push'
run '../pr view 12'
run '../pr merge 12 --squash'

csnip 11-after
run 'git switch main'
run 'git pull --ff-only'
run 'bash scripts/test.sh'
run "git branch -D $B"
run 'git fetch --prune'
run 'git config unset merge.conflictStyle'
run 'cd ..'
cshow_check
