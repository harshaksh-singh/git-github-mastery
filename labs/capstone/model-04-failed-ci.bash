# Model solution of capstone stage 4 (a failed CI run on a pull request). The workflow cannot be
# run here; the diagnosis is made from the provided files, and the Git-side cause is reproduced
# with plain Git. Sourced by the replay script and by capstone/setup.sh --stage N.
cd "$LAB_DIR" || exit 97
cap_as you
B=feature/batch-endpoint
pr=$("$LAB_DIR/pr" list | sed -n 's/^#\([0-9]*\) .*feature\/batch-endpoint.*/\1/p')

csnip 01-report
run 'cd you'
run "sed -n '/^## Log excerpts/,/^## Other/p' ../evidence/stage-04/RUN-REPORT.md"

csnip 02-workflow
run "grep -n -A3 'actions/checkout' ../evidence/stage-04/ci.yml"
run "grep -n -B1 -A3 '^on:' ../evidence/stage-04/ci.yml"
run 'git fetch'
run 'git log --oneline -2 origin/main -- .github/workflows/ci.yml'

csnip 03-locally
note 'The author says it passes locally. In her clone, on her branch, it does:'
run 'git -C ../tanvi status -sb'
run 'git -C ../tanvi log --oneline -2'
run 'bash ../tanvi/scripts/test.sh'

csnip 04-which-commit
note 'Which commit did the run test? The report names it. Compare it with the branch:'
run "git rev-parse origin/$B"
run "git ls-remote origin 'refs/pull/$pr/*'"

csnip 05-reproduce
note 'The runner fetched refs/pull/N/merge. So can I:'
run "git fetch origin refs/pull/$pr/merge"
run "git log -1 --format='%h %an: %s%nparents: %p' FETCH_HEAD"
run 'git switch --quiet --detach FETCH_HEAD'
run_rc 'bash scripts/test.sh'
run 'PYTHONPATH=. python3 -B -c "import router.batch" 2>&1 | tail -n 1 | cut -d"(" -f1'

csnip 06-cause
note 'The second parent is the branch, the first is main. What does main have that the'
note 'branch was not written against?'
run "git log --oneline origin/$B..origin/main"
run "git log --oneline -S'FALLBACK = ' origin/$B..origin/main -- router/classify.py"
run "git diff --stat origin/$B...origin/main"
run "git diff --stat origin/main...origin/$B"
run 'git switch --quiet main'

csnip 07-fix
run "git switch $B"
run 'git merge --no-edit origin/main'
run_rc 'bash scripts/test.sh'
note '(edit router/batch.py: ask classify.py for the fallback intent of the tenant)'
cat > router/batch.py <<'F'
"""Classify a batch of messages in one call."""

from router.classify import classify, fallback_for


def classify_batch(batch, tenant=None):
    """batch: one candidate list per message. Returns the intents and how many fell back."""
    fallback = fallback_for(tenant)
    intents = [classify(candidates, tenant) for candidates in batch]
    return intents, sum(1 for intent in intents if intent == fallback)
F
tick
run 'git diff'

csnip 08-test-and-push
note '(edit tests/test_batch.py: one more test, for a tenant with its own fallback intent)'
cat >> tests/test_batch.py <<'F'

    def test_batch_counts_the_fallback_of_the_tenant(self):
        self.assertEqual(classify_batch([[("order_status", 0.1, 0.2)]], "acme-retail"), (["store_support"], 1))
F
tick
run 'bash scripts/test.sh'
run "git commit -q -am 'Use the fallback intent of the tenant in the batch count'"
run 'git push'

csnip 09-what-ci-will-test
note 'The push made the server build a new test merge. Test exactly that commit:'
run "git ls-remote origin 'refs/pull/$pr/*'"
run "git fetch --quiet origin refs/pull/$pr/merge"
run 'git switch --quiet --detach FETCH_HEAD'
run 'bash scripts/test.sh'
run "git switch --quiet $B"

csnip 10-merge
run "../pr view $pr"
run "../pr merge $pr --squash"
run 'git switch main'
run 'git pull --ff-only'
run "git branch -D $B"
run 'git fetch --prune'

csnip 11-teammate
note 'What Tanvi runs in her clone. Her branch is merged; her local copy lacks my two commits.'
cap_as tanvi
run 'cd ../tanvi'
run 'git switch main'
run 'git pull --ff-only --prune'
run "git branch -D $B"
run 'bash scripts/test.sh'
cap_as you
run 'cd ..'
cshow_check
