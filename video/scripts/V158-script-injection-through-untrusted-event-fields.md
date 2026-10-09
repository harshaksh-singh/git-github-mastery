# V158: Script injection through untrusted event fields

- **Part.** 7: Security
- **Module.** 29
- **Planned minutes.** 20
- **Prerequisites.** V144, V157
- **Textbook sections.** [Chapter 21A](../../textbook/ch21a-actions-security.md), section 21A.6
- **Demo scripts.** `labs/ch21a/lab-29-1-fixes.sh` (snippets `stat`, `diff-v1`, `verify-patterns`, `verify-scope`, `commit`), with one snippet of `labs/ch21a/lab-29-1-inventory.sh`

## HOOK

**[ON SCREEN]** One step of a workflow. Its name: "Record the issue in the job summary". Its body: one `echo`.

A step that prints a title. It doesn't build anything, it doesn't deploy anything, it doesn't touch a secret. A reviewer's eye passes over it in a second, and the reviewer approves.

That line is one of the planted weaknesses of the lab, and its class began a real compromise: in the Nx incident, the first step was a pull request title echoed in a privileged workflow. The textbook's root-cause box describes what the team observes afterwards: a step that only prints a title runs commands nobody wrote.

To see why, you need one fact about timing that you already know from video 143. Hold on to that one `echo`. You'll fix it yourself before this video ends.

## INTRODUCTION

Welcome back to Git and GitHub Deep Mastery. Pull up a chair. This is part four of the model: expression injection.

Three words first. A `run` step is one entry of a workflow job: a shell command. The shell is the program that reads text and carries it out as commands. And an expression is a formula, written with a dollar sign and double braces, that GitHub Actions replaces with its value.

You know the mechanism. In video 143 you learned that an expression is evaluated before the shell starts, and that the difference between an expression inside `run` and a value passed through `env` is a security boundary. In video 144 you learned how the runner, the machine that runs the job, executes a `run` step: it writes the text to a temporary script file and starts a shell on it. This video puts those two facts together.

The video is defensive. You'll see the unsafe step as GitHub's documentation prints it, and the documented fix, and a real diff that applies the fix to a lab file. You won't see a crafted input. The documentation's own demonstration is described in one sentence, as the textbook describes it.

## LEARNING OBJECTIVES

Here's what you'll walk away with.

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

**[ANIMATION]** flow: actors=workflow_file,*GitHub_Actions,runner subs=a_run_step,-,- msgs=1>1:title="${{_X_}}"|1>2:1._evaluate_${{_..._}}|2>2:2._paste_the_VALUE_of_X_into_the_script_text|2>3:the_script_text|3>3:3._write_the_text_to_a_temporary_script_file|3>3:4._start_the_shell_on_it mono=off title=The_order_is_the_whole_mechanism id=mech at_1=6 at_2=22 at_3=40 at_4=58 at_5=62 at_6=82

**[ANIMATION]** step: mech.6

The order is the whole mechanism. Four steps. One: GitHub Actions evaluates the expression. Two: it pastes the value into the script text. Three: the runner writes that text to a temporary script file. Four: the runner starts the shell on the file.

**[ANIMATION]** say: The_shell_never_sees_"${{_X_}}"._It_sees_whatever_X_contained,_as_source_code

The shell never sees the expression. It sees whatever the value contained, as source code.

**[ANIMATION]** say: Code_generation:_the_workflow_file_is_a_template,_each_run_a_new_program

That's why the right phrase is code generation. The workflow file is a template, and each run generates a new program from it. If part of the input to the generator comes from an outsider, the outsider is a co-author of the program.

**Which values are attacker-controlled?** A context is a named object of facts about a run, and the documentation says: "Attackers can add their own malicious content to the `github` context, which should be treated as potentially untrusted input. These contexts typically end with `body`, `default_branch`, `email`, `head_ref`, `label`, `message`, `name`, `page_name`, `ref`, and `title`."

**[ANIMATION]** walk: columns=the_context_ends_with,what_it_is,whose_data rows=head__ref:a_branch_name:Git_data|message:a_commit_message:Git_data|name,_email:author_fields:Git_data|title,_body:of_issues,_pull_requests_and_comments:GitHub_data_that_any_account_can_write title=Text_an_outsider_controls id=fields

Go through that list with Git in mind. `head_ref` is a branch name, and Git allows characters in a branch name that a shell treats as syntax. `message` is a commit message. `name` and `email` are author fields, and you proved in video 138 that anyone can set those to anything. Titles and bodies of issues, pull requests and comments are GitHub data that any account can write.

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

Quick quiz. The author put the expression in double quotes. Does that make the step safe? A, yes. B, no. Your answer?

**[PAUSE]**

B. The quotes look careful, and they don't help, because the value arrives before the shell parses anything. A title that contains a double quote closes the string, and what follows it is parsed as commands. The documentation's own demonstration uses a title that closes the quote and lists the workspace directory. That's all I'll say about inputs.

What an attacker achieves is arbitrary commands in that job, with that job's token and secrets: its credential for the repository, and the encrypted values it was given.

**[ANIMATION]** stores: boxes=contained:read-only_token,_no_secrets|not_contained:the_base_repository's_token rows=1:A:pull__request_from_a_fork@ok|2:B:pull__request__target|2:B:issues|2:B:issue__comment|2:B:discussion|3:B:v1-issue-triage.yml:_on_issues,_with_issues:_write@bad title=Where_an_injection_matters id=where mono=on at_1=15 at_2=55

**[ANIMATION]** step: where.2

**Where that matters.** On `pull_request` from a fork, a second repository made from yours, it's contained by the fork model of the last video: read-only token, no secrets. On `pull_request_target`, `issues`, `issue_comment` or `discussion`, it isn't contained. Those run with the base repository's token.

**The fixed step,** with the documented mitigation, an intermediate environment variable. An environment variable is a named value that a program receives when it starts.

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

**[ANIMATION]** walk: columns=,expression_inside_run,through_env rows=the_value_goes:into_the_script_text:into_memory,_as_a_variable|the_script_the_shell_parses:a_new_program_for_every_run:a_constant,_reviewed_once|the_value_reaches_the_shell:as_source_code:as_the_value_of_a_variable,_after_parsing|the_shell:parses_it_as_commands:does_not_re-parse_it_as_commands marks=1.2:bad,2.2:bad,3.2:bad,4.2:bad,1.3:ok,2.3:ok,3.3:ok,4.3:ok mono=off title=Code,_or_data id=forms

**[ANIMATION]** step: forms.1

**Why this form is safe.** The expression is still evaluated. But its value no longer goes into the script text. In the documentation's words, the value "is stored in memory and used as a variable, and doesn't interact with the script generation process".

**[ANIMATION]** step: forms.4

Follow the consequences. The script that the shell parses is now a constant. It's identical for every pull request, and you can review it once. The title reaches the shell as the value of a variable, after parsing is over. And the shell doesn't re-parse the value of a variable as commands when it expands it.

**[ANIMATION]** say: Still_quote_the_variable:_an_unquoted_expansion_is_split_and_glob-expanded

The double quotes around the variable are still needed, for the ordinary shell reason: an unquoted expansion is split into words and glob-expanded, meaning its wildcard characters are matched against file names. The documentation tells you to quote for that reason.

**[ANIMATION]** end

**A second mitigation,** which the same reference prefers when available: use an action instead of an inline script, and pass the value through `with`.

**Two notes for review,** both from the textbook.

The rule is about where the value lands, not which context it comes from. A pull request number can't carry code. But a reviewer who decides case by case will eventually decide wrongly. So many teams adopt the mechanical rule: no expression inside `run` at all. The course workflows follow it, including for values that aren't attacker-controlled.

And `env` doesn't make later misuse safe. Passing the variable to `eval`, the shell command that runs a string as code, or writing the value unvalidated into `GITHUB_ENV`, brings the problem back one layer down.

## MENTAL MODEL

**Analogy,** from the textbook. Mail merge. You write "Dear, name, your order shipped", and the software pastes the name in. If the letter is then read aloud by someone who obeys every sentence, a customer whose "name" contains a sentence gets it obeyed.

The textbook says the analogy is close, and breaks only in one respect: a shell is far more obedient than any reader, and treats quotes and separators in the pasted text as structure.

**[ANIMATION]** replay: forms

Now the two forms in that picture. With the expression inside `run`, the name is pasted into the letter before it's handed to the reader. The reader can't tell which words were yours and which came from the customer. With `env`, the letter says "read out the content of the envelope marked TITLE". The letter is always the same. The envelope's content is read out as a name, never obeyed as a sentence.

**[ANIMATION]** say: Keep_the_outsider's_text_on_the_data_side

That's the difference between code and data, and the whole fix is to keep the outsider's text on the data side.

## DIAGRAM

Try it now, thirty seconds, on paper. Write the four steps in order, from the workflow file to the running shell, and mark the step where an outsider's text enters. Say it out loud.

**[PAUSE]**

**[ANIMATION]** flow: actors=workflow_file,*GitHub_Actions,runner subs=a_run_step,-,- msgs=1>1:title="${{_X_}}"|1>2:1._evaluate_${{_..._}}|2>2:2._paste_the_VALUE_of_X_into_the_script_text|2>3:the_script_text|3>3:3._write_the_text_to_a_temporary_script_file|3>3:4._start_the_shell_on_it mono=off title=The_order_is_the_whole_mechanism id=order say_6=The_shell_never_sees_"${{_X_}}"._It_sees_whatever_X_contained,_as_source_code at_2=12 at_3=30 at_4=36 at_5=42 at_6=56

**[ANIMATION]** step: order.1

**[DIAGRAM]** The picture of section 21A.6. Three columns: the workflow file, GitHub Actions, the runner. Draw the two numbered steps in the middle, then the two on the right, then the sentence underneath.

```text
  workflow file            GitHub Actions                     runner
  -------------            --------------                     ------
  run: |                   1. evaluate ${{ ... }}             3. write the text to a
    title="${{ X }}"  -->  2. paste the VALUE of X     -->       temporary script file
                              into the script text            4. start the shell on it

  The shell never sees "${{ X }}". It sees whatever X contained, as source code.
```

**[ANIMATION]** step: order.6

Check your order. Evaluate, paste, write the file, start the shell. The outsider's text enters at step two, and the shell only arrives at step four. So the shell never sees the expression. It sees whatever the value contained, as source code.

**[ON SCREEN]** The root-cause box of section 21A.6, one line at a time. Observed behavior: a step that only prints a pull request title runs commands nobody wrote. Git state: irrelevant; the title is GitHub data, a branch name or commit message is Git data. Mechanism: the expression is substituted into the script text before the shell starts. Root cause: attacker-controlled text was placed where the shell expects source code. Why Actions does this: expressions are a templating layer over the whole workflow file; the template engine does not know that the result will be parsed by a shell. Correct fix: pass the value through `env`, or as an action input with `with`, and use the quoted variable. Prevention: treat every expression inside `run` as a finding until proven constant; run CodeQL for workflows, zizmor or actionlint in CI.

Read the root-cause line: attacker-controlled text was placed where the shell expects source code.

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

One line, in file 1, line 32, inside a multi-line script. There's the `echo` from the opening. Two expressions on it: the issue number and the issue title. Classify each. Which of the two can carry text that an outsider wrote? And which trigger did file 1 have: is this job in the contained lane or not? Say it out loud.

**[PAUSE]**

**[ANIMATION]** step: where.3

The number can't carry code. The title is on the documentation's list. And file 1 runs on an opened issue, with the base repository's token and `issues: write`. So: an outsider's text, placed where the shell expects source code, in a job with a write scope.

**[ANIMATION]** end

**Step 2: the fix.** Replay `labs/run ch21a/lab-29-1-fixes`. It applies the reference fix to each of the five lab files and shows the diffs.

A word before it runs. The replay contains the fixes for all five files. Four of them belong to other videos and to your own work in Lab 29.1. This video shows the summary and the one diff that is its subject. If you haven't done the lab yet, don't read the other four.

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

Five files changed, 24 insertions and 33 deletions. The fixes remove more than they add. That's typical: securing a workflow mostly means taking things away.

```bash
git diff -U2 -- v1-issue-triage.yml
```

Before the diff appears, write the fix yourself. You need three new lines above `run`, an `env` line and two variables, and one changed line below it. Make your prediction on paper.

**[PAUSE]**

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

Now apply the test from the concept section. Is the script text a constant? Yes: it's the same for every issue. Where do the two values arrive? In the environment, after parsing. The number was moved too, although it can't carry code. That's the mechanical rule: no expression inside `run`, without case-by-case judgment.

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

Four scans, and each must come back empty. The third is the `awk` program for multi-line scripts, and it prints nothing. The fourth is the single-line form. The other two belong to the last video and the next: no privileged trigger, no opt-out flag, no `write-all`, and no action reference that isn't a 40-character ID.

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

**[ANIMATION]** cards: cards=Name_the_line|Name_the_class:script_injection_through_an_event_field|State_what_is_substituted_and_when:pasted_into_the_script_text_before_the_shell_starts|State_the_condition:who_supplies_the_text,_what_the_token_can_write|State_the_smallest_change:move_both_expressions_to_env,_quote_the_variables|Cite_the_documentation:its_page_on_script_injections title=The_review_comment numbered=on id=comment

**[ANIMATION]** step: comment.3

**The review comment.** Here's the form a security engineer would use for that line, and you can adapt it. Name the line. Name the class: script injection through an event field. State what is substituted and when: the issue title is pasted into the script text before the shell starts.

**[ANIMATION]** step: comment.6

State the condition: the workflow runs on `issues`, so anyone who can open an issue supplies that text, and the job's token can write issues. State the smallest change: move both expressions to `env` and reference the quoted variables. And cite the documentation's page on script injections. Five sentences, no drama, and the author can act on it without a meeting.

## COMMON MISTAKES

Five mistakes to watch for.

1. **Believing that quotes around the expression make it safe.** Root cause: the value is pasted into the script text before the shell parses anything, so a quote character in the value ends your string.
2. **Scanning only lines that contain both `run:` and an expression.** Root cause: in a multi-line script the expression is on a later line than `run:`, and the narrow scan returns nothing.
3. **Deciding case by case which contexts are harmless.** Root cause: the rule is about where the value lands; a reviewer who judges each case will eventually judge wrongly, which is why teams forbid expressions in `run` altogether.
4. **Moving the value to `env` and then using it as code anyway.** Root cause: `eval` on the variable, or writing it unvalidated into `GITHUB_ENV`, brings the problem back one layer down.
5. **Leaving the variable unquoted.** Root cause: an unquoted expansion is split into words and glob-expanded.

## PRODUCTION EXAMPLE

Now, out of the lab. The textbook's case. A prompt-evaluation workflow prints the pull request title in a job that holds a provider API key, because it runs on `pull_request_target`. The textbook's comment: that one line is the Nx pattern.

The fix is two edits, and they're from two different videos. The `env` form, from this one, so that the title is data. And removing the privileged trigger, from the last one, so that the key isn't in the job at all.

**[ANIMATION]** walk: columns=the_edit,what_it_does,with_this_edit_alone rows=the_env_form:the_title_is_data:a_job_that_still_holds_a_key,_started_by_an_outsider|removing_the_privileged_trigger:the_key_is_not_in_the_job_at_all:the_injectable_line,_still_in_the_file mono=off title=Two_edits,_from_two_videos id=two

Notice that either edit alone would have left something. With only the first, an outsider's pull request still starts a job that holds a key. With only the second, the injectable line is still in the file, waiting for the next person who changes the trigger. A review that finds one weakness in a workflow should finish reading the file.

## PRACTICE EXERCISE

Your turn. Do Lab 29.1, "Find and fix five planted weaknesses", in [`lab-manual/m29-actions-security.md`](../../lab-manual/m29-actions-security.md), if you haven't finished it. For the file with the injectable line, write the review comment in the five-sentence form before you edit the file.

Before you run the verification scans on your own fixes, predict the exit status of each.

The challenge is Exercise 29.3, "The release workflow", in [`exercises/m26-m31-actions-security.md`](../../exercises/m26-m31-actions-security.md).

## INTERVIEW QUESTION

**[ON SCREEN]** Q279: "Explain the difference between `run: echo "${{ github.event.pull_request.title }}"` and passing the title through `env`. When is each evaluated, and by what?"

Read the question on screen. Say your answer out loud.

**[PAUSE]**

A strong answer is about timing and about who does the evaluating. For the first form: what evaluates the expression, where the result goes, and what the shell then parses. For the second: what is evaluated by Actions, what the shell parses, and at which moment the value reaches the shell and in what role. It ends with the consequence for review. The follow-up is about gating a step on whether a secret is set with an `if` that reads the `secrets` context. Recall from video 143 which contexts an `if` can read and what timing has to do with it.

## RECAP

Let's land this.

You should now be able to say:

- An expression inside `run` is pasted into the script text before the shell starts: it generates code.
- Titles, bodies, labels, branch names, commit messages, author names and addresses are text an outsider controls.
- Through `env` the script is a constant, and the value arrives as data in a variable that the shell does not re-parse as commands.
- The mechanical rule is no expression inside `run` at all; and `env` does not protect against `eval` or an unvalidated write to `GITHUB_ENV`.
- A single-line scan misses multi-line scripts; scan the lines inside each `run` block.

## HOMEWORK

Read section 21A.6 of [Chapter 21A](../../textbook/ch21a-actions-security.md).

Today you turned a line that looked harmless into a finding, a fix and a review comment. Write that comment once yourself in the lab. Next time: third-party actions, mutable tags, commit pinning and organization policies. Until then, look at the state first and type second. See you in the next one.
