# Authoring style guide — Git and GitHub Deep Mastery

Read this whole file before writing anything. It is short on purpose and every rule in it is binding.

## 1. Who you are writing for

One specific reader: a working Software Engineer in AI/ML (LLM applications, model evaluation, data pipelines, Python, Java, backend services, Docker, CI/CD, open source) on a Mac with **Git 2.55.0**. Their goal is not to know commands. It is to sit with a CTO, investigate a Git or GitHub problem from first principles, explain the root cause, choose the lowest-risk fix, verify it, and prevent recurrence.

Write as a principal engineer who is also a good professor: direct, precise, causal. Second person. No hype, no filler, no fake enthusiasm. Never write "simply", "just", "obviously", "powerful", "easy". Never oversimplify: a branch is a ref, a commit is a snapshot plus metadata, GitHub is not Git.

## 2. Accuracy rules (the no-hallucination protocol)

These override everything else, including length targets.

1. **Local Git output is never typed by hand.** Every transcript comes from a demo script that you write and run, and is placed in the Markdown through a snippet marker (section 6). If you did not run it, you may not show output for it.
2. **Commands shown without output must still be real.** Before you print a command or flag, run it in a sandbox or confirm it in the local manual: `git help -m <command> | col -b`, `git <command> -h`, `gh <command> --help`. The local Git is 2.55.0 and the local GitHub CLI is 2.88.1.
3. **Version-sensitive facts need a source.** Versions, dates, defaults, limits, prices, plan gates, user-interface labels and action versions may come only from: (a) the Phase 0 report `reports/Git and GitHub mastery research.md` or the notes in `research_notes/` (both carry source links: copy the link), (b) the local man pages for Git 2.55, or (c) an official page you fetch now (git-scm.com, docs.github.com, github.blog/changelog, cli.github.com, the tool's own repository). If you cannot source a fact, either leave it out or write that it is unverified.
4. **Git 2.56-only features cannot be run here.** Mention them as "added in Git 2.56 (not run here)", with the source.
5. **GitHub-side behavior cannot be captured here.** No network calls with the user's credentials, no `gh` calls except `--help`. Show GitHub commands in `bash` blocks without output. If you describe what GitHub will display, say it is described from the documentation and link the page.
6. **No invented statistics, quotes, incidents, people, or URLs.** Every URL must come from the report or notes, or be one you fetched and saw return a real page.
7. **Label the layer.** Say whether a behavior belongs to Git, to GitHub, or to GitHub Actions whenever confusion is possible.
8. **When your own knowledge and a real run disagree, the run wins.** Report the surprise in your hand-back.

## 3. How a concept is taught

For every important concept use this ladder, in this order, with these bold lead-ins. Keep each rung tight.

- **In one sentence.** The plain explanation.
- **Analogy.** One short paragraph, and say where the analogy breaks.
- **Precisely.** The technical explanation with correct terminology.
- **Inside `.git`.** What changes in objects, refs, HEAD, the index, reflogs, and other files.
- **See it.** A real transcript (snippet).
- **Picture.** An ASCII diagram.
- **In production.** A realistic case from a backend or AI/ML team.

For every command or operation that changes state, add a **state table** with these columns: Working tree, Index, HEAD, Current branch ref, Other refs and files in `.git`, Remote, GitHub. Write "unchanged" where nothing changes.

Each chapter must also cover, for its main operations: what can go wrong, how to diagnose it, how to fix it, how to prevent it (a four-column table works well), when not to use the technique, dangerous edge cases, and production implications.

Surprising behavior is explained in a **root-cause box**:

```text
Observed behavior : ...
Git state         : ...
Mechanism         : ...
Root cause        : ...
Why Git does this : ...
Correct fix       : ...
Prevention        : ...
```

## 4. Callouts and labels

Use blockquote callouts with these exact lead-ins:

- `> **Version note.** Older behavior: ... Current behavior: ... Since: Git X.Y. Recommended: ...`
- `> **GitHub, not Git.** ...` for platform behavior, and `> **Git, not GitHub.** ...` for the reverse.
- `> **Outdated advice.** ...` for things older tutorials teach.
- `> **Unverified.** ...` for anything you could not confirm.
- `> **Root cause.** ...` for a one-line cause when a full box is too much.

Command risk labels, used the first time a state-changing command appears in a chapter and in the chapter's "Command safety" table:

- 🟢 SAFE: reads state or only adds objects.
- 🟡 CAUTION: moves refs or rewrites local history; recoverable through the reflog if you know how.
- 🔴 DANGEROUS: can destroy uncommitted work, remote history, or the safety net itself.

For every 🔴 command state: what it changes, what it can destroy, how to preview it, how to recover, when it is appropriate.

## 5. Chapter structure

```markdown
# Chapter N: Title

> **Baseline.** Git 2.55.0 on macOS; GitHub facts as of 1 October 2026. Transcripts are real output from `labs/chNN/`.

## N.1 Why this matters            (a production hook: the question a CTO would ask)
## N.2 ... N.k                     (the concepts, each taught with the ladder)
## N.x What can go wrong           (symptom, diagnosis, fix, prevention)
## N.x When not to use it, and dangerous edge cases
## N.x Command safety              (table: command, label, what it changes, preview, recovery)
## N.x Version notes               (older, current, since, recommended)
## N.x Practice                    (which labs and exercises to do next)
## N.x Interview questions         (8 to 12 questions a CTO could ask; no answers here)
## N.x Sources                     (Primary sources, Secondary sources, Videos, Further reading)
```

Number sections `N.1`, `N.2`. Use tables for comparisons. Relative links between course files. No HTML except snippet comments. Emoji only for the three risk labels. Videos in "Sources" come only from the Phase 0 report tables, with their caveats.

## 6. Demo scripts and snippets

A demo is a bash script in `labs/<dir>/<name>.sh`. `<dir>` is your chapter directory, for example `ch08`. Look at `labs/ch00/smoke-test.sh` and its output in `labs/ch00/out/smoke-test/` before writing your first one.

```bash
#!/usr/bin/env bash
# What this demo shows, and the chapter section it belongs to.
. "$(dirname "$0")/../lib/lab-env.sh"
lab_begin ch08 conflict-basic        # fresh sandbox; cd into it; clock and identity reset

snip 01-setup                        # everything shown from here goes to out/conflict-basic/01-setup.txt
run 'git init shop'
run 'cd shop'
quiet "printf 'a\nb\n' > list.txt && git add list.txt && git commit -m 'Add list'"   # hidden setup step
snip 02-merge
run_rc 'git merge feature'           # run and also print the exit status
lab_end
```

Helpers: `run`, `run_rc`, `quiet`, `note`, `blank`, `snip`, `snip_end`, `tick`, `as you|asha|ravi|config`, `run_todo '<sed>' '<git rebase -i ...>'`, `run_todo_cmd`, `run_msg '<message>' '<git command>'`. Read `labs/lib/lab-env.sh` for their exact behavior.

Rules for scripts:

- **Deterministic.** No wall-clock time, no `date`, no `ls -l`, no `sleep`, no random data, no byte sizes of directories, no process IDs. The library pins identity and clock, so commit IDs are identical on every run and every machine. If a demo cannot be deterministic (freshly generated keys), call `lab_begin <dir> <name> --volatile` and say so in the text.
- **Contained.** Never touch anything outside the sandbox (`$LAB_DIR`). No network. No daemons, schedulers or `git maintenance start`. No package installs. No `sudo`. Never read or write the user's real Git configuration: the library isolates it, so do not work around the library.
- **Portable.** bash 3.2 and the BSD userland of macOS: no associative arrays, no `mapfile`, no `sed -i` without a suffix, `printf` instead of `echo -e`.
- **Readable.** Each snippet at most about 40 lines. Realistic file names and commit messages from a backend or AI/ML project. Create long files quietly and show them with `run 'cat file'`.
- **Names.** Demos: any descriptive name. Lab replays: `lab-<module>-<k>-<slug>.sh`. Hands-on setup scripts: `setup-<module>-<k>-<slug>.sh`, using `sandbox_begin hands-on m<module>-<k>` and printing where to `cd`.

Build and inject:

```bash
tools/build-demos.sh ch08                 # run every demo in labs/ch08 and regenerate out/
python3 tools/inject.py textbook/ch08-merge.md lab-manual/m06-merge.md
labs/verify-all.sh ch08                   # must print PASS for every demo
python3 tools/check_course.py textbook/ch08-merge.md lab-manual/m06-merge.md
```

In Markdown, a snippet is placed like this. The fenced block between the comments is filled by `tools/inject.py`. Never edit it by hand.

````markdown
<!-- snippet: ch08/conflict-basic/02-merge -->
```text
```
<!-- /snippet -->
````

In transcripts, `$LAB` stands for the lab root (`~/git-mastery-labs` by default). Introduce the text around a snippet so the reader knows what to look for, then explain the output line by line where it teaches something.

## 7. Diagrams

ASCII only, inside `text` fences. Time flows left to right. Use the real abbreviated commit IDs from your transcript when the diagram illustrates that transcript, otherwise capital letters.

```text
            A---B---C   feature
           /
  D---E---F---G         main          (HEAD -> main)
```

Draw refs as labels beside commits. Show HEAD explicitly. For the three trees use three boxes side by side. For remotes show each repository as its own box.

## 8. Labs (the lab manual)

Labs live in `lab-manual/mNN-<slug>.md`, one file per module, labs numbered `Lab NN.k`. Every lab has exactly these eleven parts, as `###` headings in this order:

Objective, Prerequisites, Setup, Commands, Expected output, What happened internally, Checkpoint, Failure scenario, Recovery, Verification, Questions.

- "Commands" are what the learner types by hand inside `labs/shell`.
- "Expected output" is a snippet from the lab's replay script `labs/<dir>/lab-<module>-<k>-<slug>.sh`, so it is real.
- "Failure scenario" makes the learner break something on purpose; "Recovery" fixes it; both must have been run by you.
- "Questions" has no answers. Put the answers in `solutions/mNN-lab-answers.md`.
- GitHub-side labs cannot be replayed locally. Describe expected results from the documentation, link it, and say so.

## 9. Terminology

Use: commit ID or object ID (not "SHA" alone); the index, also called the staging area; working tree (not working directory); ref; branch; remote-tracking branch (`origin/main`); upstream branch; fast-forward; merge base; reflog; HEAD in capitals; `main` as the example default branch (the lab configuration sets `init.defaultBranch=main`; unconfigured Git 2.55 still creates `master`). Prefer `git switch` and `git restore`; show the `git checkout` equivalent once so the reader can read older scripts. Use the `git config get|set|list` subcommands and mention they need Git 2.46 or later.

## 10. Hand-back

End your work with a short report (not a file): files written, approximate word counts, number of demos and snippets, the `labs/verify-all.sh` result for your directories, the `tools/check_course.py` result for your files, every statement you marked unverified, and anything in your brief you could not do and why. Do not claim something was verified if it was not.

## 11. Work in resumable increments

Authors can be interrupted without warning. Work so that nothing is lost and a successor can continue.

1. **Look before you write.** List what already exists for your work package: `ls textbook lab-manual solutions labs/<your dirs>`. A previous author may have written scripts, snippets or whole chapters. Keep what exists and passes its checks. Read existing demo scripts and their snippets to learn what was demonstrated, and build the text on them. Do not rewrite a finished file; fix only what the checks or your review show to be wrong.
2. **Order of work.** Scripts first, built and verified. Then the chapter. Then the labs. Then the lab answers.
3. **Save as you go.** Write a chapter to disk section by section, appending to the file, and run `python3 tools/inject.py <file>` after each batch of sections. Never hold a whole chapter in your head and write it in one step at the end.
4. **A chapter is complete** when it has every section of the chapter structure through "Sources", every snippet marker resolves, and `tools/check_course.py` reports no problem other than links to files that another author has not written yet.
5. **Lengths are ranges, not goals.** Stay inside the range in your brief, counting your own prose and not the injected transcripts. If the existing scripts produced more snippets than the text needs, use the ones that teach and leave the rest for the labs.

## 12. The lab clock, and rules that follow from it

- The lab clock starts on **Monday 7 September 2026, 10:00 +05:30** and advances one minute per `run` or `quiet`. It is deliberately in the past. The sandbox configuration sets `gc.reflogExpire=never` and `gc.reflogExpireUnreachable=never`, and the environment pins `GIT_TEST_DATE_NOW` to the lab clock. The header of `labs/lib/lab-env.sh` and Chapter 1, section 1.7 explain why: `git fsck` and reflog expiry compare reflog dates with the real clock, so without these settings a transcript would depend on the day it was produced.
- Consequences for your demos: relative dates ("2 minutes ago") and selectors such as `HEAD@{5.minutes.ago}` are reproducible and may be shown. Expiry may be demonstrated only with cut-offs that do not depend on a clock: `--expire=now`, `--prune=now`, `never`, `all`. Never use a relative cut-off such as `--expire=1.hour.ago`, and never build a lesson on how old an object file is.
- When you teach the default retention periods (90 days, 30 days, two weeks), state them from the manual and say that the lab configuration overrides the first two.
- **Object IDs in prose must come from a transcript.** `tools/check_course.py` verifies that every object ID you quote exists in a snippet somewhere in the course. Copy IDs from your snippets, never from memory. If you must quote an ID that no transcript prints (for example the hash of a file the learner creates), verify it with `git hash-object` and add it to `authoring/id-whitelist.txt` with the reason.
- **Scripts must be self-contained.** A demo or lab replay may not depend on another script having been run before it, or on a sandbox left by a setup script. Share code through a fixture file that each script sources via `. "$LAB_SCRIPT_DIR/<fixture>"` (the library sets `LAB_SCRIPT_DIR` to the absolute directory of your script). Check with a fresh lab root: `GIT_MASTERY_LABS="$(mktemp -d)" labs/verify-all.sh <dir>`.
- Do not hardcode commit IDs in scripts. Capture them: `id=$(git rev-parse HEAD)`.
- The `git fsck` rule about future-dated reflog entries exists in Git 2.53.0 and later (git/git commit `f6b262581a`); Chapter 3 cites the source. `labs/shell` writes the same two `gc.reflogExpire*` settings into the hands-on configuration, so hands-on sandboxes and replays behave alike.

## 13. Lessons from earlier chapters (read before writing scripts)

- **rerere and background maintenance race on Git 2.55.** With `rerere.enabled`, a rebase or a series of commits can die with "Unable to create ... MERGE_RR.lock", because the automatic maintenance started after each commit runs the `rerere-gc` task. Any script that enables rerere must also set `maintenance.rerere-gc.auto=0` in the sandbox repository. Chapter 14C, section 14C.3 explains it.
- **Replays never reach the user's agents.** The library unsets `SSH_AUTH_SOCK`. Do not start `ssh-agent` or `gpg-agent`.
- **Commands that read standard input when it is not a terminal** (for example `git shortlog` without a revision) hang a script. Always pass the revision.
- **Labs that change global settings** have the learner point `GIT_CONFIG_GLOBAL` (and where needed `HOME`) at a per-lab file inside the hands-on sandbox as their first step, because `labs/shell` shares one global file across all hands-on labs.
- **GitHub-side labs run in the learner's normal shell, not in `labs/shell`.** The lab shell switches off the system configuration, which is where the credential helper is configured, so it cannot authenticate to GitHub. Say this at the top of every GitHub-side lab file.
- **Project names already used by fixtures:** `evalkit` (Chapters 6 to 8), `scorekit` (14A), `searchsvc` (13), `inference-service` (3), `support-bot` (4, 5). Pick a different name for a new fixture with different content.
