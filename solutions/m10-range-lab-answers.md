# Module 10 lab answers: Range notation

Answers to the "Questions" of [Lab 10.4](../lab-manual/m10-range-notation.md). Write your own answers first. Commit IDs are those of the replay (`labs/run ch14a/lab-10-4-range-notation`). Section numbers refer to [Chapter 14A](../textbook/ch14a-history-investigation.md). The answers to Labs 10.1 to 10.3 are in [m10-lab-answers.md](m10-lab-answers.md).

## The prediction table

| Command | Answer |
|---|---|
| `git log --oneline main..feat/rerank` | H, G, F |
| `git log --oneline feat/rerank..main` | E, D |
| `git log --oneline main...feat/rerank` | H, E, G, D, F: both sets, newest commit date first |
| `git diff --stat main..feat/rerank` | compares E with H: `config.yaml` (three changes), `rerank.py`, `retriever.py` |
| `git diff --stat main...feat/rerank` | compares C with H: `config.yaml` (one added line), `rerank.py`, `retriever.py` |
| `git diff --stat feat/rerank...main` | compares C with E: `config.yaml` only |

## Lab 10.4: Predict two-dot and three-dot output

1. **Three dots without dots.** `A...B` is `A B --not $(git merge-base --all A B)`: everything reachable from either tip, minus everything reachable from their merge base (section 14A.8). When A is an ancestor of B, the merge base is A itself, the A side contributes nothing, and the set equals `A..B`.
2. **Where the `top_k` change comes from.** From no commit. `git diff main..feat/rerank` compares the tree of E with the tree of H. H descends from C, where `top_k` was 5; E contains D, which raised it to 10. Going from E to H the value goes from 10 to 5. The diff describes the difference between two snapshots and knows nothing of the commits that produced them.
3. **Why it applied cleanly.** A patch applies when its context and its removed lines match the target. A two-endpoint diff whose left side is `main` was computed from the tree of `main`, so on `main` it matches by construction, every time. A patch that fails stops you and makes you look. This one succeeds and turns the tree of `main` into the tree of the branch, discarding whatever `main` had gained, without any message.
4. **When the two forms agree.** `git diff A...B` is `git diff $(git merge-base A B) B`. It equals `git diff A B` whenever the merge base is A, that is, whenever A is an ancestor of B. After `git merge main` on the branch, `main` is an ancestor of the branch tip. (More generally they agree whenever the tree of the merge base equals the tree of A.)
5. **The pull request.** GitHub's documentation describes the "Files changed" view as a three-dot comparison, from the merge base to the head of the pull request branch (section 14A.2). With a two-endpoint comparison the reviewer would also see the base branch's five newer commits, reversed, as if the pull request deleted that work.
6. **Separating the sides.** `--left-right` prefixes each commit with `<` or `>`. `--boundary` adds the excluded commit where the walk stopped, marked `o` with `--graph` and `-` without it; for two branches that is their merge base.
