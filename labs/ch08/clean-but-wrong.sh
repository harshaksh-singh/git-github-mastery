#!/usr/bin/env bash
# A merge with no conflict that still breaks the build: a rename on one branch, a new caller of the
# old name on the other. Chapter 8, section 8.15.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$(dirname "$0")/fixtures/evalkit.sh"
lab_begin ch08 clean-but-wrong

quiet 'ek_base'
cat > evalkit/report.py <<'PY'
from evalkit.metrics import accuracy, exact_match


def summarize(rows):
    scores = [exact_match(r["pred"], r["gold"]) for r in rows]
    return {"accuracy": accuracy(scores)}
PY
quiet 'ek_check_imports && ek_commit "Add the report module and the import check"'

# Ravi renames accuracy() to mean_score() and updates the only caller he can see.
quiet 'git switch -c refactor/mean-score'
as ravi
quiet "sed -e 's/def accuracy(/def mean_score(/' evalkit/metrics.py > m && mv m evalkit/metrics.py"
quiet "sed -e 's/accuracy, exact_match/exact_match, mean_score/' -e 's/accuracy(scores)/mean_score(scores)/' evalkit/report.py > r && mv r evalkit/report.py"
quiet 'ek_commit "Rename accuracy() to mean_score()"'

# Asha, starting from the same commit, adds a new module that calls accuracy().
quiet 'git switch -c feature/leaderboard main'
as asha
cat > evalkit/leaderboard.py <<'PY'
from evalkit.metrics import accuracy


def rank(runs):
    return sorted(runs, key=lambda run: accuracy(run["scores"]), reverse=True)
PY
quiet 'ek_commit "Add a leaderboard ranked by accuracy"'
as you
quiet 'git switch main'

snip 01-both-merge-cleanly
run 'git log --oneline --graph --all'
run 'git merge -q refactor/mean-score'
run 'git merge feature/leaderboard'

snip 02-check-fails
run_rc 'sh ci/check_imports.sh'

snip 03-parents-pass
note 'The same check on each parent of the merge commit:'
run 'git switch -q --detach main^1 && sh ci/check_imports.sh'
run 'git switch -q --detach main^2 && sh ci/check_imports.sh'
run 'git switch -q main'

snip 04-no-path-in-common
note 'Paths each side changed since the merge base:'
run 'git diff --name-only main^2...main^1'
run 'git diff --name-only main^1...main^2'

snip 05-fix
note 'The repair is a normal, reviewable commit on top of the merge.'
quiet "sed -e 's/accuracy/mean_score/g' evalkit/leaderboard.py > l && mv l evalkit/leaderboard.py"
run 'git diff --stat'
run 'git commit -q -a -m "Use mean_score() in the leaderboard"'
run 'sh ci/check_imports.sh'

lab_end
