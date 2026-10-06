# Lab manual — how to use it

Every module has a lab file, `mNN-<topic>.md`. Labs are numbered `Lab NN.k`. Every lab has the same eleven parts: Objective, Prerequisites, Setup, Commands, Expected output, What happened internally, Checkpoint, Failure scenario, Recovery, Verification, Questions.

## Two ways to run a lab

**By hand, which is how you learn.** Open the lab shell and type the commands yourself:

```bash
labs/shell m06
```

Inside that shell Git uses an isolated configuration, so nothing you do reaches your real `~/.gitconfig`. The clock is real, so your commit IDs differ from the book. That is expected: the commit time is part of what a commit ID is computed from (Chapter 6).

**As an exact replay, to compare with the book.** Each lab has a replay script. It runs the same commands with a fixed identity and a fixed clock, so the output matches the "Expected output" in the manual byte for byte, including commit IDs:

```bash
labs/run ch08/lab-06-2-edit-edit-conflict
```

The sandbox it creates is left in place under `~/git-mastery-labs/` so you can inspect the repository afterwards.

## Where things are

| Path | What it is |
|---|---|
| `labs/shell` | Starts the isolated lab shell |
| `labs/run <dir>/<name>` | Replays one demo or lab and prints its transcript |
| `labs/verify-all.sh` | Re-runs every demo and lab and compares with the book; every line should say PASS |
| `labs/lib/lab-env.sh` | The lab environment: isolated configuration, fixed identity, deterministic clock |
| `~/git-mastery-labs/` | Where sandboxes are created; set `GIT_MASTERY_LABS` to use another place |
| `solutions/mNN-lab-answers.md` | Answers to each lab's Questions; read them only after you have written your own |

In transcripts, `$LAB` stands for the lab root directory.

## Rules for yourself

1. Predict before you run. Write down what you expect the working tree, the index, HEAD and the refs to be after the command. Then run it.
2. Do the "Failure scenario" and the "Recovery" of every lab. Breaking things on purpose in a sandbox is the cheapest way to learn recovery.
3. Never copy a command you cannot explain. If you cannot say what it does to the working tree, the index and the refs, go back to the chapter.
4. GitHub-side labs cannot be replayed locally. Their expected results are described from GitHub's documentation as of 1 October 2026, and the interface may have changed since.
