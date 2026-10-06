#!/usr/bin/env bash
# Chapter 11, section 11.3: every form of "git restore" run from the identical starting state
# (HEAD, index and working tree each hold a different version of one file), the old
# "git checkout <commit> -- <path>" form for comparison, and "git restore -p" on two hunks.
. "$(dirname "$0")/../lib/lab-env.sh"
lab_begin ch11 restore-variants

quiet 'git init ranker'
cd ranker || exit 1
quiet "printf 'threshold: 0.50\n' > eval.yaml && git add eval.yaml && git commit -m 'Add eval config'"
quiet "printf 'threshold: 0.60\n' > eval.yaml && git commit -am 'Raise threshold to 0.60'"
quiet "printf 'threshold: 0.70\n' > eval.yaml && git commit -am 'Raise threshold to 0.70'"
quiet "printf 'threshold: 0.80\n' > eval.yaml && git add eval.yaml"
quiet "printf 'threshold: 0.90\n' > eval.yaml"

cd "$LAB_DIR" || exit 1
for m in staged resetpath both source source-both checkout; do
  cp -R ranker "ranker-$m"
  git -C "ranker-$m" status > /dev/null 2>&1
done
cd "$LAB_DIR/ranker" || exit 1

snip 01-before
run 'git log --oneline'
run 'git show HEAD:eval.yaml'
run 'git show :eval.yaml'
run 'cat eval.yaml'
run 'git status -s'

snip 02-worktree
run 'git restore eval.yaml'
run 'git show :eval.yaml'
run 'cat eval.yaml'
run 'git status -s'

cd "$LAB_DIR/ranker-staged" || exit 1
snip 03-staged
run 'git restore --staged eval.yaml'
run 'git show :eval.yaml'
run 'cat eval.yaml'
run 'git status -s'

cd "$LAB_DIR/ranker-resetpath" || exit 1
snip 03b-reset-path
run 'git reset -- eval.yaml'
run 'git show :eval.yaml'
run 'cat eval.yaml'
run 'git status -s'

cd "$LAB_DIR/ranker-both" || exit 1
snip 04-staged-worktree
run 'git restore --staged --worktree eval.yaml'
run 'git show :eval.yaml'
run 'cat eval.yaml'
run 'git status -s'

cd "$LAB_DIR/ranker-source" || exit 1
snip 05-source
run 'git restore --source=HEAD~2 eval.yaml'
run 'git show :eval.yaml'
run 'cat eval.yaml'
run 'git status -s'

cd "$LAB_DIR/ranker-source-both" || exit 1
snip 06-source-staged-worktree
run 'git restore --source=HEAD~2 --staged --worktree eval.yaml'
run 'git show :eval.yaml'
run 'cat eval.yaml'
run 'git status -s'
run 'git log --oneline -1'

cd "$LAB_DIR/ranker-checkout" || exit 1
snip 07-checkout-equivalent
run 'git checkout HEAD~2 -- eval.yaml'
run 'git show :eval.yaml'
run 'cat eval.yaml'
run 'git status -s'

# ---------------------------------------------------------------- restore -p
cd "$LAB_DIR" || exit 1
quiet 'git init scorer'
cd scorer || exit 1
cat > score.py <<'PY'
import json


def load(path):
    with open(path) as f:
        return [json.loads(line) for line in f]


def normalize(text):
    return text.strip()


def exact_match(pred, gold):
    return normalize(pred) == normalize(gold)


def accuracy(rows):
    hits = sum(exact_match(r["pred"], r["gold"]) for r in rows)
    return hits / len(rows)


if __name__ == "__main__":
    print(accuracy(load("preds.jsonl")))
PY
quiet "git add score.py && git commit -m 'Add exact-match scorer'"
cat > score.py <<'PY'
import json


def load(path):
    print("DEBUG loading", path)
    with open(path) as f:
        return [json.loads(line) for line in f]


def normalize(text):
    return text.strip()


def exact_match(pred, gold):
    return normalize(pred) == normalize(gold)


def accuracy(rows):
    hits = sum(exact_match(r["pred"], r["gold"]) for r in rows)
    return hits / max(len(rows), 1)


if __name__ == "__main__":
    print(accuracy(load("preds.jsonl")))
PY

snip 08-patch
run "printf 'y\nn\n' | git restore -p score.py"

snip 09-patch-result
run 'git diff'

lab_end
