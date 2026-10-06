# V155: Gate briefing: Actions

- **Part.** 6: CI/CD with GitHub Actions
- **Module.** 28
- **Planned minutes.** 10
- **Prerequisites.** V154
- **Textbook sections.** [Chapter 20A](../../textbook/ch20a-actions-fundamentals.md), section 20A.8; [Chapter 20B](../../textbook/ch20b-actions-delivery-debugging.md), section 20B.11; the rules in [`assessments/README.md`](../../assessments/README.md)
- **Demo scripts.** `labs/ch20a/merge-ref.sh` (snippets `runner-checkout`, `what-is-checked-out`, `tests-on-the-merge`)

## HOOK

**[ON SCREEN]** One line: "The run was green. Which commit was tested?"

A commit is one saved snapshot of a project, and a run is one execution of a workflow file on GitHub Actions. If you can answer that question for any run, from a workflow file and a description of the event, you're ready for Gate 7. If your first instinct is still to ask for the log, do the exercises at the end of this video first.

Gate 7 gives you workflow files, described runs and Git evidence. It gives you no GitHub, no run page and no log to scroll. Everything you need has to come from reading the file in order and knowing the defaults. Keep the question on the slide. The warm-up answers it.

## INTRODUCTION

Welcome back to Git and GitHub Deep Mastery. Pull up a chair. This is the briefing for the Actions gate, the mastery test of Part 6. It tells you what the gate covers, how its hands-on part works, which two procedures to prepare with, and what form an answer should take. It doesn't open the gate file or the case files, and you shouldn't open them before you sit the gate.

## LEARNING OBJECTIVES

Here's what you'll walk away with.

After this video you can:

- state what Gate 7 covers and its threshold of 85;
- explain the paper format of the hands-on part and the rule never to copy or run its workflow files;
- prepare with the reading order for a workflow and the investigation order for a failure;
- answer every question with the commit, the ref, the event and the permissions.

## CONCEPT

**What the gate covers.** Gate 7 is taken after Module 28. It covers the workflow model, the first eleven workflows, runners, and CI debugging. It passes at 85. Security of workflows isn't in this gate. That is Part 7 and Gate 8.

**[ANIMATION]** bars: id=parts bars=Concepts:30|Prediction:20|Hands-on_diagnosis:30|Oral_interview:20 unit=points max=40 title=Gate_7:_four_parts say_4=Pass:_85_overall,_and_at_least_70_percent_in_every_part at_1=15 at_2=38 at_3=50 at_4=62

**The four parts** are the same as in every gate. Concepts: 30 points, six written questions, closed book, no terminal. Prediction: 20 points, four items. Hands-on diagnosis: 30 points. Oral interview: 20 points, six questions with follow-ups, spoken, without notes. The pass rule is the threshold overall and at least 70 percent in every part.

**[ANIMATION]** end

**The hands-on part is on paper.** Three cases, built from workflow files, described runs and real Git evidence.

**[ON SCREEN]** The rule for paper cases from `assessments/README.md`.

The rule says three things. These gates run nothing on GitHub. No GitHub output appears anywhere in them. And the only `gh` invocation you need is `gh` with a command and `--help`. Then two sentences that you must take literally. The workflow files in these directories are teaching material with faults on purpose. Never copy them into a repository, and never run them.

**[ANIMATION]** cards: id=paper question=The_rule_for_paper_cases cards=nothing_runs_on_GitHub|no_GitHub_output_appears|only_gh_<command>_--help|never_copy_the_workflow_files|never_run_them marks=4:lock,5:lock pace=quick

Why so strict? A file with a deliberate fault in its trigger, its permissions or its checkout is the kind of file Part 7 teaches you to fear. On paper it teaches. In a repository with a token, it acts.

**[ANIMATION]** cards: id=strong question=Every_answer_about_a_run_states_four_things_first cards=the_event|the_ref_and_commit|the_permissions_of_the_token|the_runner|then_the_finding numbered=on at_1=45 at_2=52 at_3=62 at_4=75 at_5=85

**What a strong answer contains.** A strong answer names which commit was tested. More generally, every answer about a run states four things before it states a finding: the event, the ref and commit, the permissions of the token, and the runner. Then the finding.

## MENTAL MODEL

You prepare with two orders, and each answers a different question.

**[ANIMATION]** stores: id=orders boxes=the_reading_order:a_file_you_have_not_run|the_investigation_order:steps_1_to_4|still_above_the_log:steps_5_to_8|the_log_and_after:steps_9_to_12 rows=1:A:trigger|1:A:permissions|1:A:job_and_runner|1:A:checkout|1:A:commands|2:B:workflow|2:B:event|2:B:permissions|2:B:runner|2:C:environment|2:C:dependencies|2:C:secrets|2:C:action_versions|2:D:logs|2:D:artifacts|2:D:cache|2:D:concurrency|3:D:on_paper:_no_log@bad arrows=3:A>B:on_a_real_run title=Two_orders at_1=20

**[ANIMATION]** step: 1

The reading order is for a file you haven't run: trigger, permissions, job and runner, checkout, commands. It tells you when a run exists, with what authority, on what machine, with what code, and what the check is.

**[ANIMATION]** step: 2

The investigation order is for a run that happened: workflow, event, permissions, runner, environment, dependencies, secrets, action versions, logs, artifacts, cache, concurrency.

Quick quiz. A paper case has no log. Which steps of the investigation order can you still use? A, none. B, the eight above the log. C, all twelve. Your answer?

**[PAUSE]**

**[ANIMATION]** step: 3

B. The two orders overlap on purpose. The first four steps of the investigation are the reading order applied to a concrete run. In a paper case you have no log at all, so everything you can conclude comes from the steps above the log. That's the gate's way of testing whether you have understood why the log is ninth.

Where this breaks down in the gate: you can't observe. On your practice repository you could check a prediction by looking at a run. On paper, a claim such as "this job would be skipped" must be justified by a documented rule, stated in a sentence. "I think it would" earns nothing.

## DIAGRAM

**[ANIMATION]** stores: id=frame boxes=four_lines_first:before_any_finding|then:the_finding rows=1:A:event:_pull__request_(synchronize),_pull_request_7|4:A:ref,_commit:_refs/pull/7/merge_->_the_test_merge_d04ef31@hl|4:A:detached_HEAD,_one_commit,_no_tags@hl|4:A:the_author's_commit_is_80c9cfa;_main_is_at_29b222b|2:A:permissions:_contents:_read;_every_other_permission_none|3:A:runner:_ubuntu-24.04,_GitHub-hosted,_fresh_machine|5:B:finding:_the_run_tested_the_merge_of_the_head_into_the_current_base,_not_the_head|5:B:main_changed_behavior_the_new_code_relies_on;_the_merge_is_clean_and_wrong|6:B:next_action:_merge_the_base_into_a_detached_copy_of_the_branch;_fix;_push|6:B:not_proven:_anything_about_a_base_that_has_moved_since_this_test_merge@ref title=The_answer_frame at_1=30 at_2=55 at_3=62 at_5=0 at_6=40

**[DIAGRAM]** An answer frame of four lines and a finding. Fill it in for the case you will replay in a moment: a pull request whose tests pass on the author's machine and fail in the run.

```text
  event        : pull_request (synchronize), pull request 7
  ref, commit  : refs/pull/7/merge -> the test merge d04ef31, detached HEAD, one commit, no tags
                 (the author's commit is 80c9cfa; main is at 29b222b)
  permissions  : contents: read; every other permission none
  runner       : ubuntu-24.04, GitHub-hosted, fresh machine

  finding      : the run tested the merge of the head into the current base, not the head.
                 main changed behavior that the new code relies on; the merge is clean and wrong.
  next action  : merge the base into a detached copy of the branch to reproduce; fix; push.
  not proven   : anything about a base that has moved since this test merge was made.
```

**[ANIMATION]** step: 3

Here's the answer frame for the case you'll replay next. Four lines first: the event, the ref and commit, the permissions, the runner. Line two stays empty for now: you'll fill it in. Then the finding, the next action, and what isn't proven.

**[DIAGRAM]** The last line is not decoration. Saying what a result does not prove is half of the interview question for this video.

## LIVE TERMINAL DEMO

**[TERMINAL]** A warm-up: Git evidence of the kind the paper cases contain. Replay with `labs/run ch20a/merge-ref`. You saw it in V145; now read it as a case. A bare repository stands in for GitHub; the IDs equal the book's.

**Step 1: the runner's checkout for a pull request.**

```bash
git fetch --no-tags --depth=1 origin +refs/pull/7/merge:refs/remotes/pull/7/merge
git checkout --detach refs/remotes/pull/7/merge
```

`git fetch` is 🟢 SAFE.

Try it now, on paper. Thirty seconds. Fill in line two of the answer frame from these two commands alone. Which ref, how many commits, what kind of HEAD?

**[PAUSE]**

<!-- snippet: ch20a/merge-ref/03-runner-checkout -->
```text
# The runner: fetch one commit, the one refs/pull/7/merge names, and detach HEAD on it.
$ git init --quiet runner && cd runner
$ git remote add origin "$HUB"
$ git fetch --no-tags --depth=1 origin +refs/pull/7/merge:refs/remotes/pull/7/merge
From file://$LAB/ch20a/merge-ref/hub/inventory-api
 * [new ref]         refs/pull/7/merge -> pull/7/merge
$ git checkout --detach refs/remotes/pull/7/merge
HEAD is now at d04ef31 Merge 80c9cfa3a369de2fb126f79a0e34f6139c858a76 into 29b222ba49c3886f27c205a7ec4c982d141052c3
```
<!-- /snippet -->

One ref, `refs/pull/7/merge`, one commit, and a detached HEAD at `d04ef31`.

**[ANIMATION]** step: frame.4

The subject of that commit names its two parents in full: your commit, merged into the tip of `main`.

**[ANIMATION]** end

**Step 2: what is checked out.**

```bash
git status --short --branch
git log -1 --format="GITHUB_SHA would be %H%n%an: %s"
git rev-list --count HEAD
git branch --show-current
```

<!-- snippet: ch20a/merge-ref/04-what-is-checked-out -->
```text
$ git status --short --branch
## HEAD (no branch)
$ git log -1 --format="GITHUB_SHA would be %H%n%an: %s"
GITHUB_SHA would be d04ef31e3ed5a74c9a89af11e2cbb441599e84c7
GitHub: Merge 80c9cfa3a369de2fb126f79a0e34f6139c858a76 into 29b222ba49c3886f27c205a7ec4c982d141052c3
$ git rev-list --count HEAD
1
$ git branch --show-current
$ grep LOW_STOCK_THRESHOLD src/inventory_api/stock.py
LOW_STOCK_THRESHOLD = 10
def low_stock(stock, threshold=LOW_STOCK_THRESHOLD):
$ ls src/inventory_api
__init__.py
report.py
stock.py
```
<!-- /snippet -->

"HEAD (no branch)". The author of the commit is GitHub. One commit. No current branch. And the threshold in the source file is 10, the value from `main`.

**[ANIMATION]** shallow: id=merge 29b222b main; 29b222b-d04ef31 special:refs/pull/7/merge; ^80c9cfa-d04ef31; HEAD=none; absent:29b222b,80c9cfa; note:80c9cfa:the_author's_commit; note:d04ef31:HEAD_(no_branch),_author_GitHub; title:What_the_runner_holds; say:One_commit:_the_test_merge => + pass:80c9cfa; fail:d04ef31; name:tested; say:They_tested_different_commits dx=330 at_state_1=10 at_tested=0

**[ANIMATION]** step: state-1

In a paper case, evidence like these lines is printed for you. Your job is to say what it means for the commands that follow.

Predict the last step. The author's branch passes its tests. Will this merge pass them too? Say it out loud.

**[PAUSE]**

**[ANIMATION]** end

**Step 3: the tests on the merge.**

<!-- snippet: ch20a/merge-ref/05-tests-on-the-merge -->
```text
# The merged code is what CI tests. main changed the threshold; the new test assumed 5.
$ PYTHONPATH=src python3 -m unittest discover -s tests 2>/dev/null
[exit status: 1]
$ PYTHONPATH=src python3 -m unittest discover -s tests 2>&1 | tail -1
FAILED (failures=1)
```
<!-- /snippet -->

Exit status 1, one failure. The author's branch passes, and the merge fails.

**[ANIMATION]** step: merge.tested

Both results are correct, and they tested different commits.

**[ANIMATION]** step: frame.6

That sentence, with the two commit IDs in it, is what a case answer needs. And it answers the opening slide: the commit tested was `d04ef31`.

**[ANIMATION]** end

## COMMON MISTAKES

Five mistakes to watch for.

1. **Describing a finding without saying which commit was tested.** Root cause: for `pull_request` the run is about the test merge, so a statement about "the commit" is ambiguous until you name it.
2. **Reasoning from a log you do not have.** Root cause: the paper cases contain files, descriptions and Git evidence; what you can conclude comes from the steps of the order that precede the log.
3. **Copying a case's workflow file to try it.** Root cause: those files have faults on purpose and would run with a real token.
4. **Reading the test command first.** Root cause: whether a run exists, and for which commit, is decided by the trigger and the event before any step runs.
5. **Claiming a behavior without the rule behind it.** Root cause: on paper nothing can be observed, so only a documented rule supports a prediction.

## PRODUCTION EXAMPLE

Now, out of the lab. Picture an incident review at a company that serves models. A change reached production and broke a nightly job. The pull request had been green. The question in the review is the one from the hook: the run was green, so which commit was tested?

**[ANIMATION]** walk: id=review columns=-,the_incident_review rows=event:pull__request|ref_and_commit:the_test_merge_made_on_Tuesday_afternoon|permissions:read|runner:hosted|finding:three_merges_reached_main_before_the_merge_on_Wednesday;_one_changed_a_function_the_pull_request_calls|control:the_branch_was_not_required_to_be_up_to_date marks=5.2:bad,6.2:wait mono=off title=The_run_was_green._Which_commit_was_tested? at_1=10 at_2=16 at_3=30 at_4=35 at_5=42 at_6=80

**[ANIMATION]** step: 6

The engineer who answers uses the frame. Event: `pull_request`. Ref and commit: the test merge made on Tuesday afternoon. Permissions: read. Runner: hosted. Then the finding: three merges reached `main` between that test merge and the click on the merge button on Wednesday, and one of them changed a function the pull request calls. And then the control: the branch wasn't required to be up to date.

Nobody in the room needs the log. The review ends with a decision about a rule, which is what a review is for.

## PRACTICE EXERCISE

Your turn. Redo four exercises in [`exercises/m26-m31-actions-security.md`](../../exercises/m26-m31-actions-security.md). Exercise 26.6, "Caches and artifacts". Exercise 27.2, "A deployment with five flaws". Exercise 28.5, "Green here, red in a fresh clone". And Exercise 28.7, "Every pull request is waiting".

For each, write the four-line frame before anything else: event, ref and commit, permissions, runner. Predict in which line the fault will be found.

When you're ready, take Gate 7: [`assessments/gate-7-actions.md`](../../assessments/gate-7-actions.md). One sitting, parts in order.

## INTERVIEW QUESTION

**[ON SCREEN]** Q297: "A pull request's required checks went green yesterday afternoon. Since then `main` has received several merges, nothing was pushed to the pull request, and this morning an engineer re-ran the checks and they are green again. What exactly has been proven, and what closes the gap before merging?"

**[PAUSE]**

Answer out loud. A strong answer separates the two green results and asks of each: which commit? Use what you know about what a re-run reuses. Then state precisely what has been proven and about which combination of head and base, and what hasn't. For the second half, name the controls that close the gap and what each costs. The follow-up adopts a merge queue to close that gap, and the queue then stalls with every entry waiting for a check. You met that in the last video.

## RECAP

Let's land this.

You should now be able to say:

- Gate 7 covers the workflow model, the first eleven workflows, runners and CI debugging, and passes at 85 with at least 70 percent in every part.
- Its hands-on part is three cases on paper; the workflow files there have faults on purpose and are never copied or run.
- You prepare with the reading order for a file and the investigation order for a run.
- Every answer states the event, the ref and commit, the permissions and the runner, and then the finding, including what the result does not prove.

## HOMEWORK

Before the gate: answer the "Interview questions" sections of Chapters 20A and 20B aloud.

You can now name the commit behind any green tick. Sit the gate when the four-line frame comes without effort. Next time: the Actions security model in five parts, the job token and permissions. Until then, look at the state first and type second. See you in the next one.
