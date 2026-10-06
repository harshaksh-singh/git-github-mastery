# Gate 1, hands-on, variant A: what was reported

**Project:** `tokmeter`, a small tool that counts tokens and prices a request. **Sandbox:** one repository, `tokmeter/`. It is Asha's clone and you are sitting at her machine; the repository's own configuration carries her name and email. The repository has no remote: nothing has been published.

Asha:

> Three things are wrong and I think they are connected, because all three are about Git not seeing what is on my disk.
>
> 1. My commit "Update rate table for September" was supposed to lower both rates. I typed both numbers before I committed, I am sure of it. The packaging script builds from the commit, and the package still charges 1.50 for output. Since then I have also added a third rate for cached input, which belongs in the same commit.
> 2. `reports/last-run.json` shows up as modified after every run. `reports/` has been in `.gitignore` for weeks. Is `.gitignore` broken?
> 3. I wrote `tokmeter/cache.py` this morning. `git status` does not list it at all, so it must be ignored as well, but I cannot find the rule that does it.

## The end state you are asked for

1. There is exactly one commit called "Update rate table for September". Its author is Asha, its parent is the commit it has now, and it contains `rates.yaml` exactly as the file is on disk now, with all three rates. The three older commits are untouched.
2. In a later commit, `reports/last-run.json` stops being part of the project. The file stays on Asha's disk with the result of her last run.
3. `tokmeter/cache.py` is committed.
4. In this repository, a new untracked file is listed by plain `git status` again.
5. `HEAD` is on `main` and `git status` reports nothing to commit and nothing untracked.

## Rules

- Collect evidence with read-only commands before you change anything, and write down what each of the three trees holds for `rates.yaml` before your first state-changing command.
- For each of the three complaints, write the root cause in the form of the root-cause box of Chapter 1, section 1.10. "Git did not see it" is not a cause.
- Say for every state-changing command you run which of the working tree, the index, `HEAD` and the branch ref it changes.

When you think you are done, run this from the course root:

```bash
assessments/gen/gate-1-fundamentals/variant-a/check.sh
```
