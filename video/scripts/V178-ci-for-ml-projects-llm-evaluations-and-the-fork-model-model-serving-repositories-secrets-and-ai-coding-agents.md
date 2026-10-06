# V178: CI for ML projects, LLM evaluations and the fork model, model-serving repositories, secrets, and AI coding agents

- **Part.** 8, Professional practice
- **Module.** 33
- **Planned minutes.** 22
- **Prerequisites.** V157, V160, V177
- **Textbook sections.** [Chapter 28](../../textbook/ch28-ai-ml-workflows.md), sections 28.11 and 28.13 to 28.18
- **Demo scripts.** `labs/ch28/lab-33-1-ai-project-repo.sh` (snippets `03-checks`, `06-eval`, `07-serving`, `08-result`); the exercise file [`exercises/workflows/x29-gpu-eval.yml`](../../exercises/workflows/x29-gpu-eval.yml), read and never run

## HOOK

**[ON SCREEN]** "Our evaluation job fails on every pull request from a fork. Can we switch the trigger so that it gets the API key?"

An open-source LLM project evaluates every prompt change against a model provider. The job needs an API key. For pull requests from the team it works. For pull requests from outside contributors, which are exactly the contributions the project most wants to evaluate, it fails. Somebody finds a trigger under which the job does receive the secrets, and proposes a two-line change.

That change runs a stranger's code with your API keys and your token. The course's research identifies the pattern behind several compromises, some of them in ML projects. Today you learn to describe the collision, to refuse the workaround with reasons, and to offer designs you can defend. Hold on to one question for the whole video: whose code runs, with whose credentials? It sorts every design we look at.

## INTRODUCTION

Welcome back to Git and GitHub Deep Mastery. Pull up a chair. Four words first. CI is the automation that runs checks on every change, and on GitHub it is called GitHub Actions. A workflow is the file that says which jobs run when an event happens. A fork is an outside contributor's own copy of the repository on GitHub. And a secret is a value, such as an API key, that GitHub stores and hands to a job.

This is the last content video of Chapter 28. It has no new Git commands. It takes what you learned in Part 6 and Part 7, about fork pull requests in video 157 and about secrets and self-hosted runners in video 160, and applies it to the three things an ML repository needs from CI that an ordinary service does not: a GPU, a multi-gigabyte model, and a paid API key. Each of the three collides with a default of GitHub Actions.

Then three shorter subjects: what a model-serving repository records about the model it serves, the leak paths that are specific to AI repositories, and AI coding agents as contributors.

Layer label for most of this video: **GitHub Actions** and **GitHub**. The facts about them come from the course's research report, as the textbook gives them. Nothing here was run on GitHub.

## LEARNING OBJECTIVES

Here's what you'll walk away with.

After this video you can:

1. Design CI for a Python ML project with a matrix and caches.
2. Explain why LLM evaluations on fork pull requests collide with the fork security model and name the safe design.
3. Make the case for and against self-hosted GPU runners.
4. Say what a model-serving repository records about the model it serves.
5. State which controls still hold when an AI coding agent opens pull requests.

## CONCEPT

**CI for ML, in one sentence.** The CI of an ML repository is ordinary until it needs a GPU, a multi-gigabyte model or a paid API key, and each of those three collides with a default of GitHub Actions.

**The ordinary part.** A Python version matrix, installs driven by the lock file, and a dependency cache. A matrix runs the same job once for each version you list. uv's guide pins its setup action to a full commit SHA and installs with `uv sync --locked`. The course's workflow 4, Python tests, is that job. Video 147 went through it line by line. For `docqa`, one more step runs `sh ci/check.sh` with the base of the pull request, and the checkout needs `fetch-depth: 0` so that the range exists.

**GPU capacity.** A runner is the machine that runs one job. GitHub-hosted GPU runners come in one shape: a 4-vCPU machine with a single T4. Larger runners, GPU included, are available only to organizations on Team and Enterprise Cloud plans and are always billed per minute, with no included minutes. That's enough for a smoke test of a small model, not for training. Teams that need more run self-hosted GPU runners, on machines they operate themselves, which is a security decision before it is a capacity decision.

**Caches.** A cache is a stored directory that a later run can restore. Caches are free up to 10 gigabytes per repository, and anyone who can open a pull request can read them, so a cache isn't a place for anything sensitive. They suit package caches and small test models, not multi-gigabyte checkpoints. Fetch large models by pinned reference from the model store inside the job, or bake them into a runner image.

**LLM evaluations.** An evaluation scores a model's answers on a set of examples. An evaluation that calls a model provider needs an API key in CI. The textbook names the maintained tools: promptfoo's GitHub Action runs a before-and-after evaluation of edited prompts on pull requests. DeepEval integrates with pytest and fails the build when a metric falls below a threshold. Inspect AI, Ragas and the LangSmith SDK are also maintained. CML, once the usual way to post model metrics on pull requests, has had no release since October 2024. The report infers from repository activity that it is dormant, and no official statement says so.

Such evaluations differ from unit tests in three ways: they're non-deterministic, they cost money per run, and they need secrets.

| Property | Consequence for the workflow |
|---|---|
| Non-deterministic | compare against a threshold or a baseline with a tolerance, never for equality; record model version, prompt version and seed with the result |
| Costs money per run | trigger on paths that matter (`prompts/**`, `configs/**`, `evals/**`), cap the data set for pull requests, run the full suite on a schedule or on `main` |
| Needs secrets | the collision with the fork model |

**The collision.** If this is new to you, slow down here, because it's the center of the video. Secrets aren't passed to workflows triggered by `pull_request` from a fork. So the evaluation job fails on exactly the contributions an open-source LLM project most wants to evaluate. The tempting repair is to switch the trigger, the event that starts the workflow, to `pull_request_target`, which runs with the base repository's secrets, and then check out the contributor's code. That combination executes untrusted code with your API keys and your token. The report identifies it as the pattern behind several compromises, some of them in ML projects: PyTorch's self-hosted runners, Ultralytics, LiteLLM. Chapter 21A takes it apart.

**Defensible designs,** from least to most machinery.

One: don't evaluate fork pull requests automatically. Run cheap, secret-free checks on `pull_request`: lint, unit tests, `ci/check.sh`, evaluation against a local stub or recorded responses. A maintainer triggers the paid evaluation after reading the diff.

Two: evaluate after merge. Run the evaluation on `main` and alert or revert on regression.

Three: separate data from code. If the change is only to prompts or configuration, a trusted workflow can read those files as data and run the base repository's own evaluation code on them. This is safe only if nothing from the pull request is executed, which includes test files, `conftest.py`, package scripts and anything a prompt template can make the harness import.

**Self-hosted GPU runners.** They concentrate risk because they're expensive, long-lived and hold cached models and cloud credentials. The configuration the report calls defensible: private repositories or approval for all outside contributors. Ephemeral runners that perform one job. Runner groups scoped to named repositories. And OIDC, where a job asks for a short-lived credential, instead of long-lived keys on the host. GitHub's own guidance is that self-hosted runners should almost never be used for public repositories. That's the case against. The case for is the first pressure point: a single T4 doesn't train a model.

And one production rule for the key itself: give the evaluation job its own provider key with a spend cap, separate from production's. When that key leaks through a log or a compromised action, the damage is a bill with a ceiling, not production traffic.

**Model-serving repositories.** The report found no authoritative layout. It found three sourced building blocks.

Secrets never enter the image through build arguments or environment variables. Docker's documentation says both persist in the final image, and provides secret mounts for the purpose.

Weights are fetched by pinned reference, never committed. At build or start time the image downloads the revision or checksum recorded in the repository.

The base image is pinned by digest, and `.dockerignore` keeps `.git`, `.env`, data and run outputs out of the build context. It's the Docker analogue of `.gitignore` and matters for the same reason: a `COPY . .` with a credential file in the context bakes it into a layer.

The link back to Git is the image label. Record the commit in the image and tag images by commit ID or release tag, so that "which code is serving" has one answer. One caveat: the textbook names the OCI annotation `org.opencontainers.image.revision` for this and marks the name as unverified. It's given from the author's knowledge of the specification and isn't in the research report or its notes. Confirm it in the specification before you depend on it.

**The Java and backend side.** An ML platform is rarely Python alone. Three facts. GitHub's ignore templates treat the two build wrappers differently: the Maven wrapper JAR is ignored, while the Gradle template explicitly un-ignores `gradle-wrapper.jar`, which Gradle's documentation says is expected to be committed. The committed JAR is a review blind spot: the one place in a typical Java repository where a pull request can change executable code that a reviewer can't read in a diff, which is why wrapper validation exists. And Dependabot needs one entry per ecosystem. `uv` has had version updates since the thirteenth of March 2025 and security updates since the sixteenth of December 2025, and `docker` and `pre-commit` receive version updates only. One more unverified note from the textbook: Maven's own documentation on distributing the wrapper wasn't fetched. The statement rests on GitHub's template.

**Secrets in AI repositories.** AI repositories leak the same way as others, and through three extra paths: notebook outputs, agent and tool configuration files, and evaluation logs.

The scale, from the report: GitGuardian counted 28,649,024 new secrets on public GitHub in 2025, of which 1,275,105 were tied to AI services, up 81 percent. It counted 24,008 unique secrets in MCP configuration files. And commits co-authored by Claude Code leaked secrets at roughly twice the baseline rate. These are one vendor's measurements of public repositories.

**[ON SCREEN]** The leak paths of section 28.14.

| Leak path specific to AI work | Mechanism | Control |
|---|---|---|
| Notebook outputs | a cell prints a key or a data frame; the file stores it | strip outputs; verify in CI |
| `.env` files | created for local runs, added by `git add .` | ignore rule; `.env.example` without values; push protection |
| Agent and tool configuration (MCP server files, editor agent settings) | a token pasted into a JSON or YAML file that looks like configuration, not like a credential | keep tokens in the environment or a secret manager; scan these paths |
| Evaluation logs and traces | request headers or full prompts logged and committed as "results" | keep run outputs out of Git; redact at the source |
| Prompts and fixtures | real customer text pasted into a test case | review `prompts/` and `tests/` like code; synthetic fixtures |
| CI | a key printed by a debugging step, or exfiltrated by untrusted code | least privilege, spend caps, no secrets on fork pull requests |

The rule that doesn't change: revoke or rotate first, then find out what the key could reach, then clean up. `git rm --cached .env` followed by a commit isn't a response to a leak.

**AI coding agents.** An agent that writes commits is a contributor with a different Git client, unusual speed and no memory of your conventions, so the controls that matter are the ones that don't depend on the contributor.

What the report establishes: by October 2026 agents are first-class actors on GitHub. Copilot can review pull requests and, in preview, approve them, and the Copilot cloud agent opens pull requests and signs its commits. DORA's 2025 research describes AI as an amplifier of an organization's existing strengths and weaknesses, and recommends small, frequent commits for AI-generated code.

**[ON SCREEN]** The table of section 28.15, which the textbook presents as the report's inference.

| Property of an agent | Consequence | Control |
|---|---|---|
| It may use its own Git client or the API | local hooks do not run | every hook that matters is also a required check |
| It produces large changes quickly | review becomes the bottleneck, or stops being real | small pull requests; a human approval that an automated approval cannot replace, enforced by a ruleset |
| It reads whatever is in the repository and in the task | text in an issue, a pull request title or a file can steer it (prompt injection) | do not run agents automatically on untrusted contributions; no write token unless required |
| It holds credentials while it works | whatever it can read, an attacker who steers it can read | a dedicated low-privilege, spend-capped key; narrowly scoped tokens |
| It does not know your conventions | inconsistent branch names, messages, generated files committed | conventions in a committed instruction file, and checks that enforce them anyway |

Two incidents from the report show that the third and fourth rows aren't hypothetical. An automated account ran a campaign in February and March 2026 that combined `pull_request_target` abuse, injection through branch names and filenames, and prompt injection against an AI reviewer. And researchers reported in April 2026 that AI coding agents run as GitHub Actions could be steered by text in pull-request titles, issue bodies or comments into revealing CI secrets. Unverified: the April 2026 research was verified for the report only through one secondary article.

Attribution: decide how agent-written commits are marked, with a `Co-authored-by` trailer, a dedicated bot account, or a signature. Then "which changes did an agent write" is a `git log` query.

The practical conclusion, in the textbook's words: nothing in this chapter becomes less important when an agent writes the commits, and most of it becomes more important, because the volume goes up and the author can't be asked what it meant.

## MENTAL MODEL

Hold one question in front of every design in this video: **whose code runs, with whose credentials?**

Quick quiz, before I answer it myself. A `pull_request_target` job checks out the fork's code. Whose code runs, with whose credentials? A, the team's code with the team's credentials. B, a stranger's code with no credentials. C, a stranger's code with the team's credentials. Your answer?

**[PAUSE]**

C. Now the whole list, one case at a time.

An ordinary CI job on a team pull request: the team's code, with the team's credentials. Fine. A `pull_request` job from a fork: a stranger's code, with no credentials. Safe, and unable to call the provider. A `pull_request_target` job that checks out the fork: a stranger's code, with the team's credentials. That's the collision. A self-hosted GPU runner on a public repository: a stranger's code, on a machine that keeps state and holds cached models and cloud credentials. An agent triggered by an issue comment: instructions from a stranger, executed by something that holds a token.

Each defensible design changes one of the two halves. Either the stranger's code doesn't run in the privileged job, or the job that runs it holds nothing worth taking.

Where this model is too coarse: "code" has to be read widely. A test file, a `conftest.py`, a package script and a prompt template that the harness imports are all code for this purpose, and for an agent, text is code.

Try it now, on paper, for thirty seconds. Think of one automated job you know, at work or in a project you follow. Write one line: whose code runs, with whose credentials? I'll wait.

**[PAUSE]**

If your line says "anyone's code" and "our credentials" together, you have found something worth raising with your team. If you couldn't tell, that's worth knowing too.

## DIAGRAM

**[DIAGRAM]** The diagram of section 28.11: two boxes side by side. Left, what GitHub does by default for a pull request from a fork. Right, the tempting repair.

```text
   pull_request from a fork            pull_request_target + checkout of the fork's code
  +---------------------------+       +------------------------------------------------+
  | contributor's code runs   |       | contributor's code runs                        |
  | no secrets, read-only     |       | WITH the base repository's secrets and token   |
  | token                     |       |                                                |
  | -> evaluation cannot call |       | -> evaluation works, and so does               |
  |    the model provider     |       |    "print the API key" in a changed test file  |
  +---------------------------+       +------------------------------------------------+
```

Start with the left box, and stop at its last line: the evaluation can't call the provider. That's the contributor's complaint. Then the right box, and its last line, slowly. The evaluation works. So does a changed test file that prints the key. That's the two-line change from the opening, and our question has answered it: a stranger's code, with your credentials.

## LIVE TERMINAL DEMO

**[TERMINAL]** Replay `labs/run ch28/lab-33-1-ai-project-repo`. It is the lab replay of V177's practical exercise; we look at four snippets, for what CI will run and what a serving repository records. The commands are those of V175 to V177.

Into the lab, for four snippets. Nothing here touches GitHub: it's the local repository of video 177.

**Step 1: the checks, the hook and the CI entry point arrive together.**

<!-- snippet: ch28/lab-33-1-ai-project-repo/03-checks -->
```text
$ mkdir tools && cp ../kit/tools/checks.py tools/ && cp -R ../kit/hooks ../kit/ci .
$ git config set core.hooksPath hooks
$ git add . && git commit -q -m "Add repository checks, shared hook and CI entry point"
checks: 3 file version(s) examined, 0 problem(s)
```
<!-- /snippet -->

One script, a hook that calls it, and `ci/check.sh`. The `checks:` line at the commit is the hook. In a workflow, the same script runs as a step, with the base of the pull request as its argument. This is the secret-free part of CI: it needs no key, so it runs on every pull request, forks included.

**Step 2: the evaluation writes a record.**

<!-- snippet: ch28/lab-33-1-ai-project-repo/06-eval -->
```text
$ cp ../kit/tools/runinfo.py tools/ && cp -R ../kit/evals ../kit/configs ../kit/prompts .
$ git add . && git commit -q -m "Add evaluation config, prompt and run recorder"
checks: 4 file version(s) examined, 0 problem(s)
$ python3 evals/run_eval.py baseline
run baseline: accuracy 0.8000 on 10 examples (commit de800cc)
```
<!-- /snippet -->

The evaluation here is local and deterministic. An LLM evaluation is neither. Predict: which of the three properties, non-deterministic, paid, needing secrets, would change this step, and how? Say it out loud.

**[PAUSE]**

The answer is the table of the concept section. Compare against a threshold with a tolerance, not for equality. Trigger on the paths that matter. And decide where the key lives.

**Step 3: the serving definition and the model pointer.**

<!-- snippet: ch28/lab-33-1-ai-project-repo/07-serving -->
```text
$ cp -R ../kit/Dockerfile ../kit/.dockerignore ../kit/models .
$ python3 tools/dataref.py add models/embedder.bin
stored models/embedder.bin as sha256:7daca2095d04 (65536 bytes)
commit the pointer: git add models/embedder.bin.ref
$ git add . && git commit -q -m "Add serving image definition and model pointer"
checks: 4 file version(s) examined, 0 problem(s)
$ git tag -a v0.1.0 -m "docqa 0.1.0"
```
<!-- /snippet -->

The weights aren't committed. The pointer is: a checksum and a size. The `Dockerfile` and the `.dockerignore` arrive in the same commit, and the commit is tagged. A serving repository pins the model by an immutable identifier, and the tag names the code.

**Step 4: the result.**

<!-- snippet: ch28/lab-33-1-ai-project-repo/08-result -->
```text
$ git log --oneline --decorate
849080a (HEAD -> main, tag: v0.1.0) Add serving image definition and model pointer
de800cc Add evaluation config, prompt and run recorder
6a39a54 Version the ticket data set by reference
e9e2df6 Add notebook filter and the error-analysis notebook
af3a06e Add repository checks, shared hook and CI entry point
05a1465 Add package skeleton, lock file and tests
426268a Add ignore rules and attributes before any content
$ git status --short --ignored
!! data/raw/tickets.csv
!! models/embedder.bin
!! runs/
$ git ls-files | wc -l
      24
$ sh ci/check.sh "$(git rev-list --max-parents=0 HEAD)"
checks: 22 file version(s) examined, 0 problem(s)
checks: 24 file version(s) examined, 0 problem(s)
tests: ok
```
<!-- /snippet -->

Seven commits, three ignored paths, and `ci/check.sh` over the whole history from the root commit: no problems, tests ok. That last command is what a required check would run.

**[ON SCREEN]** Now a workflow to criticize. Open [`exercises/workflows/x29-gpu-eval.yml`](../../exercises/workflows/x29-gpu-eval.yml) in an editor. Do not run it.

Read its header first. It says four things. It's teaching material. Don't use this workflow in a real repository. It contains deliberately planted security weaknesses. And it was parse-checked and never executed on GitHub. It describes itself: in a public repository, it runs the model evaluation for every pull request on the team's own GPU machine, which is registered as a persistent self-hosted runner.

Then read it top to bottom: the trigger, the permissions block, the `runs-on` line, the checkout with its pinned commit, a step named "Debug", and the step that runs the evaluation. Stop the video here and read it once, slowly.

**[PAUSE]**

The weaknesses are the subject of an exercise, and this video doesn't name them. Take the review checklist of section 21A.19, the one from the Gate 8 briefing, and go down its eleven headings with this file in front of you. For each heading, write "fine", "not applicable" or a finding with one sentence of blast radius. Use the question of this video: whose code runs here, on which machine, with what in reach? Then compare with the exercise's solution, not before.

## COMMON MISTAKES

Five mistakes to watch for. Each one usually starts as a wish to be helpful.

1. **Switching to `pull_request_target` so that fork pull requests get the key.** Root cause: the trigger supplies the base repository's secrets and token, and the checkout then executes the contributor's code with them.
2. **Treating "we only read the prompts" as safe.** Root cause: test files, `conftest.py`, package scripts and templates that the harness imports are executed, so data from the pull request becomes code.
3. **Putting models or anything sensitive in the Actions cache.** Root cause: anyone who can open a pull request can read caches, and the size limit suits package caches.
4. **Using the production provider key for evaluation.** Root cause: one key then carries both the evaluation's exposure and production's reach, with no spend ceiling.
5. **Exempting an agent's pull requests from review or checks.** Root cause: local hooks never ran for it, so required checks and a human approval are the only controls left.

## PRODUCTION EXAMPLE

Now, out of the lab. An open-source project that maintains an LLM evaluation harness receives most of its prompt improvements from outside contributors. Its evaluation job fails on every one of them. A contributor proposes the two-line change from the opening.

The maintainer answers with the two boxes of the diagram and then with a design. On `pull_request`, every contribution gets the secret-free checks: lint, unit tests, the repository's own check script, and the evaluation against recorded responses. The paid evaluation runs in a separate workflow that a maintainer triggers after reading the diff, with a provider key that belongs to the evaluation alone and has a spend cap. The full suite runs on `main` on a schedule. The project's GPU machine isn't registered as a runner for the public repository at all.

The same maintainers later add an AI coding agent. They apply the table: the agent's pull requests are small by instruction and by a size check, they pass the same required checks, a human approval is required by ruleset, the agent's token can't write to workflows, and its commits carry a `Co-authored-by` trailer so that they can be listed with one `git log` query.

## PRACTICE EXERCISE

Your turn. Do Exercise 33.6, Level 3, "Evaluate prompts in CI", in [`exercises/m32-m34-practice.md`](../../exercises/m32-m34-practice.md).

Before you design anything, predict: for a pull request from a fork, which of your jobs will have secrets and which will not, and what each job is therefore able to do. Write the answer to "whose code runs, with whose credentials" for every job in your design. Then compare with the solution.

The challenge is Exercise 29.7, Level 3, "Benchmark scores on fork pull requests", in [`exercises/m26-m31-actions-security.md`](../../exercises/m26-m31-actions-security.md).

## INTERVIEW QUESTION

**[ON SCREEN]** Q374: "An open-source LLM project wants evaluations on pull requests from forks. Describe the collision, the dangerous workaround, and two designs you would defend."

**[PAUSE]**

Answer out loud. The question gives you its own outline. For the collision, name the two defaults that meet: what an evaluation needs and what a fork run is given. For the workaround, name the trigger and the second ingredient that makes it dangerous, and say in one sentence what an attacker's pull request would contain. For the designs, give two that differ in kind, and for each say what it costs the contributor or the maintainer, because a design without a cost hasn't been thought through. If you add what you would do to the key itself, you have covered blast radius as well as prevention.

## RECAP

Let's land this, in your own words.

- ML CI is ordinary until it needs a GPU, a large model or a paid key, and each collides with a default of GitHub Actions.
- Fork pull requests get no secrets; `pull_request_target` plus a checkout of the fork's code runs untrusted code with your secrets and token.
- Defensible designs: secret-free checks for everyone and a maintainer-triggered evaluation; evaluation after merge; or prompts read strictly as data.
- A serving repository records the model by a pinned reference, the base image by digest, and the commit in the image; secrets enter a build only through secret mounts.
- An agent is a contributor whose local hooks never run, so required checks, a human approval by ruleset and narrow tokens are the controls that still hold.

## HOMEWORK

Read sections 28.11 and 28.13 to 28.18, and do the Practice section, 28.20.

That completes the four videos on AI and ML repositories. You can now look at any automated job and ask whose code runs, with whose credentials, and that one question will serve you for years. The next video is the briefing for the design review that closes Level 8: you'll design the branching model, governance, CI and security policy for a described company, and defend it. Until then, look at the state first and type second. See you in the next one.
