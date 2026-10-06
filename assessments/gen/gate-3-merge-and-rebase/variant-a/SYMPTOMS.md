# Gate 3, hands-on, variant A: what was reported

**Project:** `chunker`. **Sandbox:** `server.git` (the server), `you/` (your clone), `asha/` (Asha's clone). You work in `you/`. Your branch `feature/overlap` has never been pushed.

Your own notes, before you went to lunch:

> `feature/overlap` had three commits on top of an old `main`: the overlap parameter, the off-by-one fix in the window helper, and a `fixup!` commit with the test I forgot. Asha merged her rename of `size` to `max_len` into `main` this morning. I updated `main` and typed `git rebase main`. It stopped with a conflict in `chunker/split.py` and I left it there.
>
> Things I must not forget:
>
> - The reviewers want two commits in the pull request, "Add overlap to the splitter" (with the test in it) and "Fix off-by-one in window end". No `fixup!` commit.
> - Support wants the off-by-one fix on `release/1.2` as well. Only that fix: 1.2 does not get the overlap feature. Prepare it locally on `release/1.2`; the release manager pushes. The commit on the release branch has to say where it came from, pointing at the commit as it will be in the pull request.

Asha, about the conflict:

> Both changes are wanted. The parameter is called `max_len` everywhere now, default 512. Yours adds `overlap`.

So the resolved function reads:

```python
def split(text, max_len=512, overlap=0):
    """Split text into chunks of at most max_len characters."""
    chunks = []
    start = 0
    while start < len(text):
        chunks.append(text[start:start + max_len])
        start += max_len - overlap
    return chunks
```

## The end state you are asked for

1. No operation is in progress. `HEAD` is on `feature/overlap`, which starts at the current tip of `main` and has exactly the two commits the reviewers asked for, in that order. The test file is part of the first one.
2. `chunker/split.py` on the branch is the function above.
3. Your local `release/1.2` is one commit ahead of `origin/release/1.2`: the off-by-one fix, with a line in its message that names the commit on `feature/overlap` it was copied from.
4. Nothing is pushed. `main` is untouched.
5. `git status` is clean.

## Rules

- Before you resolve the conflict, write down what stage 1, stage 2 and stage 3 of `chunker/split.py` hold in this operation, and which of them is "ours". Check your statement with a command.
- Before you rewrite the branch a second time, make sure you can return to the state before it, and say how.
- After the clean-up, prove with one command that the two final commits carry the same changes as the three you started with.

When you think you are done, run this from the course root:

```bash
assessments/gen/gate-3-merge-and-rebase/variant-a/check.sh
```
