#!/usr/bin/env bash
# Stage 8: production needs a fix, and main is not releasable. Applies the incident on top of
# the state that the solution of stage 7 leaves.
# Read BRIEFING.md, not this file, before you start: the script is part of the answer.
. "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../lib/capstone-lib.bash"
cap_inject_begin 8 "$@"

# Wednesday 23 September. The VIP pull request is merged, if it can be merged.
cap_as nandini
quiet '"$LAB_DIR/pr" merge feature/vip-escalation --merge'

# The fault itself has been in the code since the first commit. What changed this morning is
# outside the repository: the embedding service started to time out, and the caller passes
# None for the embedding score when it does.
# The engineer on call writes a fix on top of main and proposes to release main.
cap_go tanvi
quiet 'git switch main'
quiet 'git pull --ff-only'
quiet 'git switch -c hotfix/embed-none'
quiet "sed -i.bak -e 's/^        score = blend(kw, emb, tenant)\$/        if emb is None:\\
            emb = 0.0  # the embedding service timed out: decide on the keywords alone\\
        score = blend(kw, emb, tenant)/' router/classify.py && rm router/classify.py.bak"
cat >> tests/test_classify.py <<'F'

    def test_a_missing_embedding_score_counts_as_zero(self):
        self.assertEqual(classify([("billing_refund", 1.0, None)]), "human_agent")
        self.assertEqual(classify([("billing_refund", 1.0, None), ("order_status", 0.8, 0.9)]), "order_status")
F
_cp 'Treat a missing embedding score as 0' router/classify.py tests/test_classify.py
quiet 'git push -u origin hotfix/embed-none'
cap_pr 'open hotfix/embed-none'
quiet 'git switch main'

cap_inject_end 8
