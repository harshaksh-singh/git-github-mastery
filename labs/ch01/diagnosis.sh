#!/usr/bin/env bash
# Chapter 1, sections "The ten-command diagnosis" and "Worked example".
# A repository with a real problem: a fix was committed and pushed, the pipeline still fails,
# and the tests pass on the developer's machine. The ritual collects the evidence; the
# root-cause framework turns it into a fix.
. "$(dirname "$0")/../lib/lab-env.sh"
lab_begin ch01 diagnosis

# ---- hidden setup: a local bare repository plays the server -------------------------------
quiet 'git init --bare origin.git'
quiet 'git init rag-eval'
cd rag-eval || exit 1
mkdir -p configs eval
echo '# rag-eval' > README.md
printf 'model: small-v2\ntimeout_s: 60\ntop_k: 5\n' > configs/eval.yaml
cat > eval/runner.py <<'PY'
"""Run one evaluation batch against the retrieval service."""

MAX_TIMEOUT_S = 60


def effective_timeout(cfg):
    return min(cfg["timeout_s"], MAX_TIMEOUT_S)
PY
quiet 'git add . && git commit -m "Add evaluation runner and config"'
quiet 'git remote add origin "$LAB_DIR/origin.git"'
quiet 'git push -u origin main'
quiet 'git switch -c feature/cache'
printf 'cache_dir: .cache/embeddings\n' >> configs/eval.yaml
quiet 'git commit -am "Cache embeddings between runs"'
quiet 'git switch main'
# The faulty change: two files edited, one staged.
printf 'model: small-v2\ntimeout_s: 120\ntop_k: 5\n' > configs/eval.yaml
sed 's/^MAX_TIMEOUT_S = 60$/MAX_TIMEOUT_S = 120/' eval/runner.py > eval/runner.py.new && mv eval/runner.py.new eval/runner.py
quiet 'git add configs/'
quiet 'git commit -m "Raise eval timeout to 120s"'
quiet 'git push'
echo 'batch 17: 50 questions, 0 timeouts' > run.log

# ---- the ritual ---------------------------------------------------------------------------
snip 01-status
run 'git status'

snip 02-branch
run 'git branch -vv'

snip 03-remote
run 'git remote -v'

snip 04-log
run 'git log --graph --decorate --oneline --all'

snip 05-reflog
run 'git reflog'

snip 06-rev-parse
run 'git rev-parse HEAD origin/main'
run 'git rev-parse --abbrev-ref HEAD'
run 'git rev-parse --show-toplevel'

snip 07-show
run 'git show --stat HEAD'

snip 08-diff
run 'git diff'
run 'git diff --cached'

snip 09-config
run 'git config list --show-origin --show-scope'

snip 10-ls-files
run 'git ls-files'

# ---- testing the hypotheses -----------------------------------------------------------------
snip 11-test
run 'git log --oneline --all -- eval/runner.py'
run "git show HEAD:eval/runner.py | grep '^MAX_TIMEOUT_S'"
run "grep '^MAX_TIMEOUT_S' eval/runner.py"

# ---- the lowest-risk fix: a new commit ------------------------------------------------------
snip 12-fix
run 'git add eval/runner.py'
run 'git diff --cached --stat'
run 'git commit -m "Raise runner timeout cap to 120s"'
run 'git push --dry-run'
run 'git push'

snip 13-verify
run 'git status'
run 'git log --oneline -3'
run 'git rev-parse HEAD origin/main'
run "git show HEAD:eval/runner.py | grep '^MAX_TIMEOUT_S'"

lab_end
