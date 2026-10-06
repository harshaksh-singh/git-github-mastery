# Model solution of capstone stage 8 (a production hotfix from a release tag, with a backport).
# Sourced by the replay script and by capstone/setup.sh --stage N.
cd "$LAB_DIR" || exit 97
cap_as you
pr=$("$LAB_DIR/pr" list | sed -n 's/^#\([0-9]*\) .*hotfix\/embed-none.*/\1/p')
REPRO="PYTHONPATH=. python3 -B -c 'from router.classify import classify; print(classify([(\"billing_refund\", 1.0, None)]))' 2>&1 | tail -n 1"

csnip 01-observe
run 'cd you'
run 'git switch main'
run 'git pull --ff-only --prune'
run 'git describe origin/main'
run 'git log --oneline --first-parent v1.3.1..origin/main'
run '../pr list'

csnip 02-reproduce
note 'Production runs v1.3.1. The failing input from the alert, on that tag:'
run 'git switch --quiet --detach v1.3.1'
run "$REPRO"
note 'Would a rollback to v1.3.0 help? Is this a regression at all?'
run 'git switch --quiet --detach v1.3.0'
run "$REPRO"
run "git blame -s -L '/for intent, kw, emb/,+1' v1.3.1 -- router/classify.py"
run 'git log --oneline v1.0.0..v1.3.1 -- router/classify.py'
run 'git switch --quiet main'

csnip 03-why-not-main
note 'The proposal is to merge the fix and tag main. What would that release?'
run 'git diff --shortstat v1.3.1 origin/main'
run 'git diff --stat v1.3.1 origin/main -- router | tail -n 12'

csnip 04-review-the-fix
run "../pr view $pr"
run 'git diff origin/main...origin/hotfix/embed-none -- router'
run 'git switch --quiet --detach origin/hotfix/embed-none'
run 'bash scripts/test.sh'
run "$REPRO"
run 'git switch --quiet main'

csnip 05-fix-on-main
run "../pr merge $pr --squash"
run 'git pull --ff-only'
fix=$(git rev-parse --short HEAD)
run 'git log --oneline -1'

csnip 06-release-branch
note 'The maintenance line starts at the tag that production runs.'
run 'git switch -c release/1.3 v1.3.1'
run 'git push -u origin release/1.3'
run 'git switch -c backport/embed-none-1.3'
run_rc "git cherry-pick -x $fix"
run 'git status -sb'

csnip 07-conflict
run 'git diff router/classify.py'

csnip 08-resolve
note '(edit router/classify.py: the guard from the fix, the call as the release has it)'
python3 - <<'PY'
import re
p = "router/classify.py"
s = open(p).read()
s = re.sub(r"<<<<<<< [^\n]*\n.*?>>>>>>> [^\n]*\n",
           "        if emb is None:\n            emb = 0.0  # the embedding service timed out: decide on the keywords alone\n        score = blend(kw, emb)\n",
           s, flags=re.S)
open(p, "w").write(s)
p = "tests/test_classify.py"
s = open(p).read()
m = re.search(r"<<<<<<< [^\n]*\n(.*?)=======\n(.*?)>>>>>>> [^\n]*\n", s, flags=re.S)
theirs = m.group(2)
new = theirs[theirs.index("    def test_a_missing_embedding_score_counts_as_zero"):]
s = s[:m.start()] + m.group(1) + ("\n" if m.group(1).strip() else "") + new + s[m.end():]
open(p, "w").write(s)
PY
tick
note '(edit tests/test_classify.py: the new test only; the tenant test belongs to main)'
run 'git diff'

csnip 09-conclude
run 'bash scripts/test.sh'
run 'git add router/classify.py tests/test_classify.py'
run 'git -c core.editor=true cherry-pick --continue'
run 'git show --stat --format=%B HEAD'

csnip 10-compare
note 'The backport next to the original. By default range-diff does not pair two commits'
note 'whose diffs differ this much; --creation-factor=100 makes it pair them and show how.'
run "git range-diff $fix~1..$fix HEAD~1..HEAD"
run "git range-diff --creation-factor=100 $fix~1..$fix HEAD~1..HEAD"

csnip 11-publish
run 'git push -u origin backport/embed-none-1.3'
run '../pr open backport/embed-none-1.3 --base release/1.3'
bp=$("$LAB_DIR/pr" list | sed -n 's/^#\([0-9]*\) .*backport\/embed-none-1.3.*/\1/p')
run "../pr view $bp"
run "../pr merge $bp --squash"
run 'git switch release/1.3'
run 'git pull --ff-only'
run 'git log -1 --format=%B'

csnip 12-tag
run 'bash scripts/test.sh'
run "$REPRO"
run "git tag -a v1.3.2 -m 'intent-router 1.3.2: treat a missing embedding score as 0'"
run 'git push origin v1.3.2'
run 'git describe'
run 'git log --oneline --graph --decorate --simplify-by-decoration v1.3.0..v1.3.2 origin/main -6'

csnip 13-verify
run 'git diff --stat v1.3.1 v1.3.2'
note 'Is the fix of the release also on main? Patch comparison says no, because the copy was'
note 'adapted. The line that -x wrote says yes.'
run 'git cherry -v origin/main release/1.3'
orig=$(git log -1 --format=%B release/1.3 | sed -n 's/^(cherry picked from commit \([0-9a-f]*\))$/\1/p')
run "git log -1 --format=%B release/1.3 | grep 'cherry picked'"
run_rc "git merge-base --is-ancestor $orig origin/main"
run "git tag --contains $orig"
run 'git tag --contains release/1.3'

csnip 14-cleanup
run 'git switch main'
run 'git branch -D backport/embed-none-1.3'
run 'git fetch --prune'
run 'git branch -vv'
run 'cd ..'
cshow_check
