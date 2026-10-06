# labs/ch14c/fixtures.bash — starting states shared by the Chapter 14C demos and the Module 14
# labs (Lab 14.2 to Lab 14.6).
#
# This file is sourced, never run:   . "$LAB_SCRIPT_DIR/fixtures.bash"
# Each function builds one starting state inside the current sandbox ($LAB_DIR) and returns with
# the current directory set back to $LAB_DIR. A hands-on setup script (setup-14-k-*.sh) and the
# replay script of the same lab (lab-14-k-*.sh) call the same function at the same point of the
# lab clock, so the commits that the fixture creates have the same IDs in your hands-on sandbox
# as in the book.

# ------------------------------------------------------------------ rerere demos
# Every rerere repository of this chapter sets maintenance.rerere-gc.auto=0. On Git 2.55.0 the
# automatic maintenance that follows a commit runs "git rerere gc" in the background, and that
# task holds .git/MERGE_RR.lock for a moment. A rebase that reaches its next conflict in that
# moment dies with "Unable to create ... MERGE_RR.lock" (measured by the demo rerere-lock-race:
# a few runs in twenty). With the setting the replays are reproducible; section 14C.3 of the
# chapter explains the cause and the recovery.
_fx_no_rerere_gc() { quiet 'git config set maintenance.rerere-gc.auto 0'; }

# ranker: main and the long-lived branch feature/rerank changed the same two lines of
# retrieval.yaml, so every integration of the two conflicts in the same way.
fx_rerere_repo() {
  quiet 'git init ranker'
  cd ranker || return 1
  _fx_no_rerere_gc
  quiet "printf 'model: bge-small\ntop_k: 10\nrerank: false\n' > retrieval.yaml && printf '# ranker\n' > README.md && git add . && git commit -m 'Add retrieval config'"
  quiet 'git switch -c feature/rerank'
  quiet "printf 'model: bge-small\ntop_k: 50\nrerank: true\n' > retrieval.yaml && git commit -am 'Enable reranking over the top 50 candidates'"
  quiet "printf 'def rerank(query, candidates):\n    return sorted(candidates, key=lambda c: -c.score)\n' > rerank.py && git add rerank.py && git commit -m 'Add reranker module'"
  quiet 'git switch main'
  quiet "printf 'model: bge-small\ntop_k: 20\nrerank: false\n' > retrieval.yaml && git commit -am 'Raise top_k to 20'"
  cd "$LAB_DIR" || return 1
}

# The same repository after one test merge of main into feature/rerank was resolved with rerere
# enabled and then thrown away. $1 is the text of the resolution that was recorded.
fx_rerere_recorded() {
  fx_rerere_repo
  cd ranker || return 1
  quiet 'git config set rerere.enabled true'
  quiet 'git switch feature/rerank'
  quiet 'git merge main'
  quiet "printf '$1' > retrieval.yaml && git commit -am 'Test merge of main'"
  quiet 'git reset --hard HEAD^'
  quiet 'git switch main'
  cd "$LAB_DIR" || return 1
}

# ------------------------------------------------------------------ Lab 14.2
# evalkit: main and feat/f1 have diverged by one commit each, so merging the branch creates a
# merge commit. hooks/ (next to the repository) holds the commit-msg hook of the lab and the
# corrected version that the Recovery installs.
fx_14_2() {
  quiet 'git init evalkit'
  cd evalkit || return 1
  quiet "printf 'def exact(pred, gold):\n    return pred == gold\n' > metrics.py && git add . && git commit -m 'feat(metrics): add exact match'"
  quiet 'git switch -c feat/f1'
  quiet "printf 'def f1(tp, fp, fn):\n    return 2 * tp / (2 * tp + fp + fn)\n' > f1.py && git add . && git commit -m 'feat(metrics): add F1'"
  quiet 'git switch main'
  quiet "printf '# evalkit\n\nMetrics for the evaluation harness.\n' > README.md && git add . && git commit -m 'docs: describe the metrics module'"
  cd "$LAB_DIR" || return 1
  mkdir -p hooks
  cp "$LAB_SCRIPT_DIR/files/commit-msg" hooks/commit-msg
  cp "$LAB_SCRIPT_DIR/files/commit-msg.v2" hooks/commit-msg.v2
}

# ------------------------------------------------------------------ Lab 14.3
# server.git (bare, plays origin), your clone "gateway" and a teammate's clone "asha".
# gateway has the branch feature/limits with two commits, the second one a WIP commit.
# hooks/ holds the pre-push hook of the lab and the pre-receive hook that the Recovery installs.
fx_14_3() {
  quiet 'git init --bare server.git'
  quiet 'git clone server.git gateway'
  cd gateway || return 1
  quiet "printf 'def route(request):\n    return upstream(request.model)\n' > router.py && printf 'requests_per_minute: 60\n' > limits.yaml && git add . && git commit -m 'Add request router and rate limits' && git push -u origin main"
  quiet 'git switch -c feature/limits'
  quiet "printf 'requests_per_minute: 60\nburst: 10\n' > limits.yaml && git commit -am 'Add a burst allowance'"
  quiet "printf 'requests_per_minute: 60\nburst: 10\nper_tenant: true\n' > limits.yaml && git commit -am 'WIP: per-tenant limits, quota still undecided'"
  cd "$LAB_DIR" || return 1
  quiet 'git clone server.git asha'
  quiet 'git -C asha config set user.name "Asha Rao" && git -C asha config set user.email asha@example.com'
  mkdir -p hooks
  cp "$LAB_SCRIPT_DIR/files/pre-push" hooks/pre-push
  cp "$LAB_SCRIPT_DIR/files/pre-receive" hooks/pre-receive
}

# ------------------------------------------------------------------ Lab 14.4
# server.git (bare, plays origin) and your clone "modelhub" with the two filter scripts tracked
# in tools/. The directory "ptr-store", created next to the clones by the clean filter, stands in
# for the storage server of a real large-file system.
fx_14_4() {
  quiet 'git init --bare server.git'
  quiet 'git clone server.git modelhub'
  cd modelhub || return 1
  mkdir -p tools weights
  cp "$LAB_SCRIPT_DIR/files/ptr-clean" tools/ptr-clean
  cp "$LAB_SCRIPT_DIR/files/ptr-smudge" tools/ptr-smudge
  chmod +x tools/ptr-clean tools/ptr-smudge
  quiet "printf '# modelhub\n\nEncoder weights live in weights/.\n' > README.md && git add . && git commit -m 'Add pointer filter scripts' && git push -u origin main"
  cd "$LAB_DIR" || return 1
}

# ------------------------------------------------------------------ Lab 14.5
# ranker: feature/hybrid (three commits) and main (two commits) changed the same lines of
# retrieval.yaml and of scoring.py, so a rebase of the branch stops twice.
# ranker-wrong: the same repository with rerere and rerere.autoUpdate switched on and two
# resolutions already recorded, the one for retrieval.yaml being wrong (top_k stays 20 although
# the reranker needs 50 candidates).
_fx_14_5_repo() {   # _fx_14_5_repo <directory> [race]   ("race" leaves automatic rerere gc on)
  quiet "git init $1"
  cd "$1" || return 1
  [ "${2:-}" = race ] || _fx_no_rerere_gc
  quiet "printf 'model: bge-small\ntop_k: 10\nrerank: false\n' > retrieval.yaml && printf 'def score(q, d):\n    return bm25(q, d)\n' > scoring.py && printf '# ranker\n' > README.md && git add . && git commit -m 'Add retrieval config and BM25 scoring'"
  quiet 'git switch -c feature/hybrid'
  quiet "printf 'model: bge-small\ntop_k: 50\nrerank: true\n' > retrieval.yaml && git commit -am 'Enable reranking over the top 50 candidates'"
  quiet "printf 'def score(q, d):\n    return 0.7 * bm25(q, d) + 0.3 * dense(q, d)\n' > scoring.py && git commit -am 'Blend dense scores into the ranking'"
  quiet "printf '# ranker\n\nHybrid ranking: BM25 plus dense scores, then a reranker.\n' > README.md && git commit -am 'Describe hybrid ranking'"
  quiet 'git switch main'
  quiet "printf 'model: bge-small\ntop_k: 20\nrerank: false\n' > retrieval.yaml && git commit -am 'Raise top_k to 20'"
  quiet "printf 'def score(q, d):\n    return bm25(q, d) / max_bm25\n' > scoring.py && git commit -am 'Normalize BM25 scores'"
  quiet 'git switch feature/hybrid'
  cd "$LAB_DIR" || return 1
}

fx_14_5() {
  _fx_14_5_repo ranker
  _fx_14_5_repo ranker-wrong
  cd ranker-wrong || return 1
  quiet 'git config set rerere.enabled true && git config set rerere.autoUpdate true'
  quiet 'git merge main'
  quiet "printf 'model: bge-small\ntop_k: 20\nrerank: true\n' > retrieval.yaml && printf 'def score(q, d):\n    return 0.7 * bm25(q, d) / max_bm25 + 0.3 * dense(q, d)\n' > scoring.py && git commit -am 'Test merge of main'"
  quiet 'git reset --hard HEAD^'
  cd "$LAB_DIR" || return 1
}

# ------------------------------------------------------------------ Lab 14.6
# evalkit: one commit, then work in three forms: a staged change to score.py (reviewed, ready),
# an unstaged experiment in config.yaml, and an untracked notes.md.
fx_14_6() {
  quiet 'git init evalkit'
  cd evalkit || return 1
  quiet "printf 'def score(pred, gold):\n    return pred == gold\n' > score.py && printf 'threshold: 0.5\nmetric: exact\n' > config.yaml && git add . && git commit -m 'Add scorer and config'"
  quiet "printf 'def score(pred, gold):\n    return pred.strip() == gold.strip()\n' > score.py && git add score.py"
  quiet "printf 'threshold: 0.7\nmetric: exact\n' > config.yaml"
  quiet "printf 'Try threshold 0.6 and 0.8 before deciding.\n' > notes.md"
  cd "$LAB_DIR" || return 1
}
