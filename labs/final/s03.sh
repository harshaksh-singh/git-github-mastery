#!/usr/bin/env bash
# Final test, section 3 (Branching): prediction items P1 and P2, diagram items G1 and G2 and
# interpretation item I1.
. "$(dirname "$0")/../lib/lab-env.sh"
lab_begin final s03

# ---- P1: merged, not merged, contains
snip p1-setup
run 'git init -q slotfill'
run 'cd slotfill'
run 'git commit -q --allow-empty -m "Add the slot schema"'
run 'git commit -q --allow-empty -m "Add the slot parser"'
run 'git branch docs/schema HEAD~1'
run 'git switch -q -c parser-v2'
run 'git commit -q --allow-empty -m "Rewrite the parser"'
run 'git switch -q main'
snip p1-answer
run 'git branch --merged main'
run 'git branch --no-merged main'
run 'git branch --contains docs/schema'
run_rc 'git branch -d parser-v2'
cd "$LAB_DIR"

# ---- P2: a name and a prefix
snip p2-setup
run 'git init -q notifier'
run 'cd notifier'
run 'git commit -q --allow-empty -m "Add the notifier"'
run 'git branch feature'
snip p2-answer
run_rc 'git branch feature/retry'
run_rc 'git branch -m feature feature/retry'
run 'git branch --list'
cd "$LAB_DIR"

# ---- G1: draw the graph
snip g1-setup
run 'git init -q embedjob'
run 'cd embedjob'
run 'git commit -q --allow-empty -m "A: add the job runner"'
run 'git commit -q --allow-empty -m "B: add the retry policy"'
run 'git switch -q -c feature/batching'
run 'git commit -q --allow-empty -m "C: batch the requests"'
run 'git switch -q main'
run 'git commit -q --allow-empty -m "D: log the job duration"'
run 'git switch -q -c hotfix/timeout HEAD~1'
run 'git commit -q --allow-empty -m "E: raise the timeout"'
run 'git switch -q feature/batching'
run 'git commit -q --allow-empty -m "F: flush partial batches"'
run 'git tag v0.2 main'
snip g1-answer
run 'git log --graph --oneline --all --decorate'
run 'git branch --show-current'
run 'git merge-base feature/batching hotfix/timeout | xargs git log -1 --format=%s'
cd "$LAB_DIR"

# ---- G2: read the graph
quiet 'git init -q rerankd'
cd rerankd || exit 1
quiet 'git commit -q --allow-empty -m "A: add the candidate fetcher"'
quiet 'git commit -q --allow-empty -m "B: add the scorer"'
quiet 'git switch -q -c feature/rerank'
quiet 'git commit -q --allow-empty -m "C: add the cross-encoder"'
quiet 'git commit -q --allow-empty -m "D: cache the scores"'
quiet 'git switch -q main'
quiet 'git commit -q --allow-empty -m "E: add request tracing"'
quiet 'git tag v1.0'
quiet 'git merge -q --no-ff feature/rerank -m "M: merge feature/rerank"'
quiet 'git switch -q feature/rerank'
quiet 'git commit -q --allow-empty -m "F: tune the batch size"'
quiet 'git switch -q main'
quiet 'git commit -q --allow-empty -m "G: document the tracing headers"'
snip g2-graph
run 'git log --graph --oneline --all --decorate'
snip g2-answer
run 'git merge-base main feature/rerank | xargs git log -1 --format=%s'
run 'git log --format=%s main..feature/rerank'
run 'git log --format=%s feature/rerank..main'
run 'git log -1 --format=%s main~2'
run 'git log -1 --format=%s main~1^2'
run_rc 'git rev-parse --verify --quiet main^2'
run_rc 'git merge-base --is-ancestor v1.0 feature/rerank'
run 'git log --first-parent --format=%s main'
cd "$LAB_DIR"

# ---- I1: one branch, one worktree
quiet 'git init -q edgeproxy'
cd edgeproxy || exit 1
quiet 'git commit -q --allow-empty -m "Add the proxy"'
quiet 'git commit -q --allow-empty -m "Add connection pooling"'
quiet 'git branch feature/http3'
snip i1-transcript
run 'git worktree add -q ../edgeproxy-hotfix -b hotfix/tls-reload'
run 'git branch -vv'
run_rc 'git switch hotfix/tls-reload'
run_rc 'git branch -d hotfix/tls-reload'
run 'git -C ../edgeproxy-hotfix commit -q --allow-empty -m "Reload certificates without a restart"'
run 'git log --oneline -1 hotfix/tls-reload'
lab_end
