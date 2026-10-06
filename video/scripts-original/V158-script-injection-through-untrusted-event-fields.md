# V158: Script injection through untrusted event fields

- **Part.** 7: Security
- **Module.** 29
- **Planned minutes.** 20
- **Prerequisites.** V144, V157
- **Textbook sections.** [Chapter 21A](../../textbook/ch21a-actions-security.md), section 21A.6
- **Demo scripts.** `labs/ch21a/lab-29-1-fixes.sh` (snippets `stat`, `diff-v1`, `verify-patterns`, `verify-scope`, `commit`), with one snippet of `labs/ch21a/lab-29-1-inventory.sh`

## HOOK

**[ON SCREEN]** One step of a workflow. Its name: "Record the issue in the job summary". Its body: one `echo`.

A step that prints a title. It does not build anything, it does not deploy anything, it does not touch a secret. A reviewer's eye passes over it in a second, and the reviewer approves.

That line is one of the planted weaknesses of the lab, and its class began a real compromise: in the Nx incident, the first step was a pull request title echoed in a privileged workflow. The textbook's root-cause box describes what the team observes afterwards: a step that only prints a title runs commands nobody wrote.

To see why, you need one fact about timing that you already know from V143.

## INTRODUCTION

This is part four of the model: expression injection.

You know the mechanism. In V143 you learned that an expression is evaluated before the shell starts, and that the difference between an expression inside `run` and a value passed through `env` is a security boundary. In V144 you learned how the runner executes a `run` step: it writes the text to a temporary script file and starts a shell on it. This video puts those two facts together.

The video is defensive. You will see the unsafe step as GitHub's documentation prints it, and the documented fix, and a real diff that applies the fix to a lab file. You will not see a crafted input. The documentation's own demonstration is described in one sentence, as the textbook describes it.

## LEARNING OBJECTIVES

After this video you can:

- explain why an expression inside `run:` is code generation and not variable passing;
- list event fields an outsider controls;
- fix an injection by passing the value through `env` and explain why the same value is then harmless;
- find candidate injections in a set of workflows with a local search;
- write the review comment a security engineer would write.

## CONCEPT

**[ON SCREEN]** Lower third: GitHub Actions.

**In one sentence.** An expression in dollar sign and double braces is replaced by its value in the text of the script before the shell starts, so a value that an outsider controls becomes part of your program.

**Precisely.** The documentation: "The `run` command executes within a temporary shell script on the runner. Before the shell script is run, the expressions inside are evaluated and then substituted with the resulting values, which can make it vulnerable to shell command injection."

The order is the whole mechanism. Four steps. One: GitHub Actions evaluates the expression. Two: it pastes the value into the script text. Three: the runner writes that text to a temporary script file. Four: the runner starts the shell on the file.

The shell never sees the expression. It sees whatever the value contained, as source code.

That is why the right phrase is code generation. The workflow file is a template, and each run generates a new program from it. If part of the input to the generator comes from an outsider, the outsider is a co-author of the program.

**Which values are attacker-controlled?** The documentation: "Attackers can add their own malicious content to the `github` context, which should be treated as potentially untrusted input. These contexts typically end with `body`, `default_branch`, `email`, `head_ref`, `label`, `message`, `name`, `page_name`, `ref`, and `title`."

Go through that list with Git in mind. `head_ref` is a branch name, and Git allows characters in a branch name that a shell treats as syntax. `message` is a commit message. `name` and `email` are author fields, and you proved in V138 that anyone can set those to anything. Titles and bodies of issues, pull requests and comments are GitHub data that any account can write.

**The unsafe step, as the documentation prints it.**

```yaml
- name: Check PR title
  run: |
    title="${{ github.event.pull_request.title }}"
    if [[ $title =~ ^octocat ]]; then
    echo "PR title starts with 'octocat'"
    exit 0
    else
    echo "PR title did not start with 'octocat'"
    exit 1
    fi
```

The author put the expression in double quotes, and that looks careful. The quotes do not help, because the value arrives before the shell parses anything. A title that contains a double quote closes the string, and what follows it is parsed as commands. The documentation's own demonstration uses a title that closes the quote and lists the workspace directory. That is all I will say about inputs.

What an attacker achieves is arbitrary commands in that job, with that job's token and secrets.

**Where that matters.** On `pull_request` from a fork it is contained by the fork model of the last video: read-only token, no secrets. On `pull_request_target`, `issues`, `issue_comment` or `discussion`, it is not contained. Those run with the base repository's token.

**The fixed step,** with the documented mitigation, an intermediate environment variable.

```yaml
- name: Check PR title
  env:
    TITLE: ${{ github.event.pull_request.title }}
  run: |
    if [[ "$TITLE" =~ ^octocat ]]; then
    echo "PR title starts with 'octocat'"
    exit 0
    else
    echo "PR title did not start with 'octocat'"
    exit 1
    fi
```

**Why this form is safe.** The expression is still evaluated. But its value no longer goes into the script text. In the documentation's words, the value "is stored in memory and used as a variable, and doesn't interact with the script generation process".

Follow the consequences. The script that the shell parses is now a constant. It is identical for every pull request, and you can review it once. The title reaches the shell as the value of a variable, after parsing is over. And the shell does not re-parse the value of a variable as commands when it expands it.

The double quotes around the variable are still needed, for the ordinary shell reason: an unquoted expansion is split into words and glob-expanded. The documentation tells you to quote for that reason.

**A second mitigation,** which the same reference prefers when available: use an action instead of an inline script, and pass the value through `with`.

**Two notes for review,** both from the textbook.

The rule is about where the value lands, not which context it comes from. A pull request number cannot carry code. But a reviewer who decides case by case will eventually decide wrongly. So many teams adopt the mechanical rule: no expression inside `run` at all. The course workflows follow it, including for values that are not attacker-controlled.

And `env` does not make later misuse safe. Passing the variable to `eval`, or writing the value unvalidated into `GITHUB_ENV`, brings the problem back one layer down.

## MENTAL MODEL

**Analogy,** from the textbook. Mail merge. You write "Dear, name, your order shipped", and the software pastes the name in. If the letter is then read aloud by someone who obeys every sentence, a customer whose "name" contains a sentence gets it obeyed.

The textbook says the analogy is close, and breaks only in one respect: a shell is far more obedient than any reader, and treats quotes and separators in the pasted text as structure.

Now the two forms in that picture. With the expression inside `run`, the name is pasted into the letter before it is handed to the reader. The reader cannot tell which words were yours and which came from the customer. With `env`, the letter says "read out the content of the envelope marked TITLE". The letter is always the same. The envelope's content is read out as a name, never obeyed as a sentence.

That is the difference between code and data, and the whole fix is to keep the outsider's text on the data side.

## DIAGRAM

**[DIAGRAM]** The picture of section 21A.6. Three columns: the workflow file, GitHub Actions, the runner. Draw the two numbered steps in the middle, then the two on the right, then the sentence underneath.

```text
  workflow file            GitHub Actions                     runner
  -------------            --------------                     ------
  run: |                   1. evaluate ${{ ... }}             3. write the text to a
    title="${{ X }}"  -->  2. paste the VALUE of X     -->       temporary script file
                              into the script text            4. start the shell on it

  The shell never sees "${{ X }}". It sees whatever X contained, as source code.
```

**[ON SCREEN]** The root-cause box of section 21A.6, one line at a time. Observed behavior: a step that only prints a pull request title runs commands nobody wrote. Git state: irrelevant; the title is GitHub data, a branch name or commit message is Git data. Mechanism: the expression is substituted into the script text before the shell starts. Root cause: attacker-controlled text was placed where the shell expects source code. Why Actions does this: expressions are a templating layer over the whole workflow file; the template engine does not know that the result will be parsed by a shell. Correct fix: pass the value through `env`, or as an action input with `with`, and use the quoted variable. Prevention: treat every expression inside `run` as a finding until proven constant; run CodeQL for workflows, zizmor or actionlint in CI.

## LIVE TERMINAL DEMO

**[TERMINAL]** Two replays. Plain Git and `grep` on files in the sandbox. Nothing is executed on GitHub, and the vulnerable files are never run.

**Step 1: find the candidate.** One snippet from `labs/run ch21a/lab-29-1-inventory`, which you saw at the end of the last video.

<!-- snippet: ch21a/lab-29-1-inventory/08-run-blocks -->
```text
# The lines of every multi-line script (from "run: |" to the next step or job).
$ awk '/run: \|/ {inrun=1; next} /^ *- name:|^ *- uses:|^  [a-z-]*:$/ {inrun=0} inrun && /\$\{\{/ {print FILENAME ":" FNR ":" $0}' v*.yml
v1-issue-triage.yml:32:          echo "Labelled issue #${{ github.event.issue.number }}: ${{ github.event.issue.title }}" >> "$GITHUB_STEP_SUMMARY"
```
<!-- /snippet -->

One line, in file 1, line 32, inside a multi-line script. Two expressions on it: the issue number and the issue title. **[PAUSE]** Classify each. Which of the two can carry text that an outsider wrote? And which trigger did file 1 have: is this job in the contained lane or not?

The number cannot carry code. The title is on the documentation's list. And file 1 runs on an opened issue, with the base repository's token and `issues: write`. So: an outsider's text, placed where the shell expects source code, in a job with a write scope.

**Step 2: the fix.** Replay `labs/run ch21a/lab-29-1-fixes`. It applies the reference fix to each of the five lab files and shows the diffs.

A word before it runs. The replay contains the fixes for all five files. Four of them belong to other videos and to your own work in Lab 29.1. This video shows the summary and the one diff that is its subject. If you have not done the lab yet, do not read the other four.

```bash
git diff --stat
```

<!-- snippet: ch21a/lab-29-1-fixes/01-stat -->
```text
$ git diff --stat
 .github/workflows/v1-issue-triage.yml     |  9 +++++----
 .github/workflows/v2-pr-test-report.yml   | 22 +++++++---------------
 .github/workflows/v3-nightly-check.yml    |  9 +++++----
 .github/workflows/v4-format-check.yml     |  6 ++----
 .github/workflows/v5-build-and-deploy.yml | 11 +++++------
 5 files changed, 24 insertions(+), 33 deletions(-)
```
<!-- /snippet -->

Five files changed, 24 insertions and 33 deletions. The fixes remove more than they add. That is typical: securing a workflow mostly means taking things away.

```bash
git diff -U2 -- v1-issue-triage.yml
```

**[PAUSE]** Before the diff appears, write the fix yourself. You need two new lines above `run`, and one changed line below it.

<!-- snippet: ch21a/lab-29-1-fixes/11-diff-v1 -->
```text
$ git diff -U2 -- v1-issue-triage.yml | grep -v '^index '
diff --git a/.github/workflows/v1-issue-triage.yml b/.github/workflows/v1-issue-triage.yml
--- a/.github/workflows/v1-issue-triage.yml
+++ b/.github/workflows/v1-issue-triage.yml
@@ -1,5 +1,3 @@
-# TEACHING MATERIAL. DO NOT USE THIS WORKFLOW IN A REAL REPOSITORY.
-# It contains one deliberately planted security weakness for Lab 29.1 (Module 29).
-# Find it, name its class, and fix it. The analysis is in solutions/m29-vulnerable-workflows.md.
+# Reference fix for Lab 29.1 (see solutions/m29-vulnerable-workflows.md).
 # Assembled from documented syntax and parse-checked with PyYAML; never executed on GitHub.
 #
@@ -29,4 +27,7 @@ jobs:
 
       - name: Record the issue in the job summary
+        env:
+          ISSUE_NUMBER: ${{ github.event.issue.number }}
+          ISSUE_TITLE: ${{ github.event.issue.title }}
         run: |
-          echo "Labelled issue #${{ github.event.issue.number }}: ${{ github.event.issue.title }}" >> "$GITHUB_STEP_SUMMARY"
+          echo "Labelled issue #$ISSUE_NUMBER: $ISSUE_TITLE" >> "$GITHUB_STEP_SUMMARY"
```
<!-- /snippet -->

Read the second hunk. Three added lines: an `env` mapping with two variables, each set from an expression. One removed line and one added line in the script: the two expressions are gone, and in their place are two shell variables.

Now apply the test from the concept section. Is the script text a constant? Yes: it is the same for every issue. Where do the two values arrive? In the environment, after parsing. The number was moved too, although it cannot carry code. That is the mechanical rule: no expression inside `run`, without case-by-case judgment.

**Step 3: verify with the scans.**

<!-- snippet: ch21a/lab-29-1-fixes/20-verify-patterns -->
```text
# After your fixes, each of these scans must come back empty (exit status 1 from grep).
$ grep -n 'pull_request_target\|allow-unsafe\|write-all' v*.yml
[exit status: 1]
$ grep -n 'uses:' v*.yml | grep -vE '@[0-9a-f]{40}( |$)'
[exit status: 1]
$ awk '/run: \|/ {inrun=1; next} /^ *- name:|^ *- uses:|^  [a-z-]*:$/ {inrun=0} inrun && /\$\{\{/ {print FILENAME ":" FNR ":" $0}' v*.yml
$ grep -n 'run:.*${{' v*.yml
[exit status: 1]
```
<!-- /snippet -->

Four scans, and each must come back empty. The third is the `awk` program for multi-line scripts, and it prints nothing. The fourth is the single-line form. The other two belong to the last video and the next: no privileged trigger, no opt-out flag, no `write-all`, and no action reference that is not a 40-character ID.

<!-- snippet: ch21a/lab-29-1-fixes/21-verify-scope -->
```text
# Every workflow declares permissions, and the one secret is named in one step.
$ grep -c '^permissions:' v*.yml
v1-issue-triage.yml:1
v2-pr-test-report.yml:1
v3-nightly-check.yml:1
v4-format-check.yml:1
v5-build-and-deploy.yml:1
$ grep -n -B2 'secrets\.' v*.yml
v5-build-and-deploy.yml-61-      - name: Deploy (simulated)
v5-build-and-deploy.yml-62-        env:
v5-build-and-deploy.yml:63:          DEPLOY_TOKEN: ${{ secrets.STAGING_DEPLOY_TOKEN }}
```
<!-- /snippet -->

Every file declares `permissions` once. And the one secret is named in one step.

<!-- snippet: ch21a/lab-29-1-fixes/22-commit -->
```text
$ git add .
$ git commit -q -m "Fix one weakness in each of five workflows"
$ git status --short
```
<!-- /snippet -->

`git commit` is 🟢 SAFE: it adds an object and moves the branch. The status is clean. In your own run of the lab you make one commit per file, with a message that says what you fixed.

**The review comment.** Here is the form a security engineer would use for that line, and you can adapt it. Name the line. Name the class: script injection through an event field. State what is substituted and when: the issue title is pasted into the script text before the shell starts. State the condition: the workflow runs on `issues`, so anyone who can open an issue supplies that text, and the job's token can write issues. State the smallest change: move both expressions to `env` and reference the quoted variables. And cite the documentation's page on script injections. Five sentences, no drama, and the author can act on it without a meeting.

## COMMON MISTAKES

1. **Believing that quotes around the expression make it safe.** Root cause: the value is pasted into the script text before the shell parses anything, so a quote character in the value ends your string.
2. **Scanning only lines that contain both `run:` and an expression.** Root cause: in a multi-line script the expression is on a later line than `run:`, and the narrow scan returns nothing.
3. **Deciding case by case which contexts are harmless.** Root cause: the rule is about where the value lands; a reviewer who judges each case will eventually judge wrongly, which is why teams forbid expressions in `run` altogether.
4. **Moving the value to `env` and then using it as code anyway.** Root cause: `eval` on the variable, or writing it unvalidated into `GITHUB_ENV`, brings the problem back one layer down.
5. **Leaving the variable unquoted.** Root cause: an unquoted expansion is split into words and glob-expanded.

## PRODUCTION EXAMPLE

The textbook's case. A prompt-evaluation workflow prints the pull request title in a job that holds a provider API key, because it runs on `pull_request_target`. The textbook's comment: that one line is the Nx pattern.

The fix is two edits, and they are from two different videos. The `env` form, from this one, so that the title is data. And removing the privileged trigger, from the last one, so that the key is not in the job at all.

Notice that either edit alone would have left something. With only the first, an outsider's pull request still starts a job that holds a key. With only the second, the injectable line is still in the file, waiting for the next person who changes the trigger. A review that finds one weakness in a workflow should finish reading the file.

## PRACTICE EXERCISE

Do Lab 29.1, "Find and fix five planted weaknesses", in [`lab-manual/m29-actions-security.md`](../../lab-manual/m29-actions-security.md), if you have not finished it. For the file with the injectable line, write the review comment in the five-sentence form before you edit the file.

Before you run the verification scans on your own fixes, predict the exit status of each.

The challenge is Exercise 29.3, "The release workflow", in [`exercises/m26-m31-actions-security.md`](../../exercises/m26-m31-actions-security.md).

## INTERVIEW QUESTION

**[ON SCREEN]** Q279: "Explain the difference between `run: echo "${{ github.event.pull_request.title }}"` and passing the title through `env`. When is each evaluated, and by what?"

A strong answer is about timing and about who does the evaluating. For the first form: what evaluates the expression, where the result goes, and what the shell then parses. For the second: what is evaluated by Actions, what the shell parses, and at which moment the value reaches the shell and in what role. It ends with the consequence for review. The follow-up is about gating a step on whether a secret is set with an `if` that reads the `secrets` context; recall from V143 which contexts an `if` can read and what timing has to do with it.

## RECAP

You should now be able to say:

- An expression inside `run` is pasted into the script text before the shell starts: it generates code.
- Titles, bodies, labels, branch names, commit messages, author names and addresses are text an outsider controls.
- Through `env` the script is a constant, and the value arrives as data in a variable that the shell does not re-parse as commands.
- The mechanical rule is no expression inside `run` at all; and `env` does not protect against `eval` or an unvalidated write to `GITHUB_ENV`.
- A single-line scan misses multi-line scripts; scan the lines inside each `run` block.

## HOMEWORK

Read section 21A.6 of [Chapter 21A](../../textbook/ch21a-actions-security.md).
