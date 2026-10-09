# V162: Case studies in Actions security: what happened, root cause, lesson

- **Part.** 7: Security
- **Module.** 29
- **Planned minutes.** 20
- **Prerequisites.** V161
- **Textbook sections.** [Chapter 21A](../../textbook/ch21a-actions-security.md), section 21A.18
- **Demo scripts.** `labs/ch21a/mutable-tag.sh` (snippets `move`, `after`), as the local model of the first pattern. Everything else is a walk through the table of section 21A.18 with its source links on screen.

## HOOK

**[ON SCREEN]** The sentence from the start of this part: "No password was stolen. How?"

On the eleventh of May 2026, 84 malicious versions of 42 packages were published through a project's own trusted-publisher identity. No registry token was stolen. The project had read-only workflow permissions. It published through OIDC. By the standards of most checklists, it had followed best practice.

**[ANIMATION]** cards: cards=A_privileged_trigger|A_build_of_fork_code|A_shared_cache|A_release_job_that_restored_it|An_identity_that_any_code_in_the_job_could_ask_for title=You_now_know_every_mechanism_that_was_involved id=mech at_1=12 at_2=20 at_3=27 at_4=33 at_5=40

You now know every mechanism that was involved. A privileged trigger. A build of fork code. A shared cache. A release job that restored it. An identity that any code in the job could ask for. In this video you put the links in order, for this case and seven others, and for each you name the control that would have broken the chain. Hold on to the question on screen. You'll answer it yourself, link by link.

## INTRODUCTION

Welcome back to Git and GitHub Deep Mastery. Pull up a chair. This video is a walk through one table: the case studies of section 21A.18. Each case is given in the same three parts: what happened, root cause, lesson. The cases come from the Phase 0 report and its sources, and every row has a source link, which is on screen while I talk about it.

A reminder of five words from this part. A workflow is a file that tells GitHub Actions which jobs to run. A tag is a movable name for a commit, and pinning means naming the commit ID instead. A privileged trigger is an event whose run holds the repository's token and secrets. A cache is a stored directory that a later run can restore. And OIDC gives a job a short-lived credential in place of a stored key.

Three rules for this video, and they're the textbook's rules.

No attack detail beyond the published summaries is reproduced. This is a defensive course.

Dates and figures are quoted only as the cited sources give them. Where the sources disagree, I say so. The table has a column called "Flags" for exactly that, and I read the flag aloud for every row.

And no embellishment. You'll use these cases to argue for controls in design reviews. An argument that rests on an exaggerated number fails the first time someone checks it.

## LEARNING OBJECTIVES

Here's what you'll walk away with.

After this video you can:

- retell each case of the section as what happened, root cause and lesson, with its flags;
- assign each case to one of the recurring patterns;
- name the control from this part that would have broken each chain;
- trace how a fork pull request led to a publish without any stored credential being stolen;
- quote dates and figures only as the cited sources give them.

## CONCEPT

**[ON SCREEN]** Lower third: GitHub Actions.

**[ANIMATION]** walk: columns=the_part,as_the_table_gives_it rows=What_happened:version_tags_were_repointed_to_a_malicious_commit_that_printed_secrets_from_runner_memory_into_workflow_logs;_more_than_23,000_repositories_used_the_action|Root_cause:a_stolen_bot_token;_the_chain_began_with_a_pull__request__target_flaw_in_an_upstream_project,_according_to_Unit_42|Lesson:tags_are_mutable;_only_commit-pinned_workflows_were_unaffected;_public_logs_are_world-readable mono=off title=tj-actions/changed-files,_March_2025 id=tj say_header=Sources:_the_CISA_alert_and_the_GitHub_advisory

**[ANIMATION]** step: tj.header

**tj-actions/changed-files, March 2025.** Sources: the CISA alert and the GitHub advisory.

**[ANIMATION]** step: tj.1

What happened: version tags were repointed to a malicious commit that printed secrets from runner memory into workflow logs. More than 23,000 repositories used the action.

**[ANIMATION]** step: tj.2

Root cause: a stolen bot token. The chain began with a `pull_request_target` flaw in an upstream project, according to the Unit 42 write-up.

**[ANIMATION]** step: tj.3

Lesson: tags are mutable. Only commit-pinned workflows were unaffected. And public logs are world-readable.

**[ANIMATION]** cards: question=Which_sentence_do_the_sources_support? cards=A:more_than_23,000_repositories_leaked_secrets|B:more_than_23,000_repositories_used_the_action marks=1:bad,2:ok id=quiz

**[ANIMATION]** step: quiz.2

Quick quiz. You retell this case in a design review. Which sentence do the sources support? A, more than 23,000 repositories leaked secrets. B, more than 23,000 repositories used the action. Your answer?

**[PAUSE]**

**[ANIMATION]** step: quiz.marks

B, and the flags explain it.

**[ANIMATION]** walk: columns=source,the_time_it_gives rows=CISA:12_March_00:00_UTC_to_15_March_12:00_UTC,_2025|the_advisory:14_to_15_March|Unit_42:the_mass_tag_override_on_14_March_at_16:57_UTC marks=1.2:ok mono=off title=A_conflict_about_the_time_window id=window say_3=Use_CISA's_window_for_audits

Flags: there is a conflict about the time window. CISA gives it as the twelfth of March at midnight UTC to the fifteenth of March at noon UTC, 2025. The advisory says the fourteenth to the fifteenth of March. Unit 42 places the mass tag override on the fourteenth of March at sixteen fifty-seven UTC. The textbook's instruction: use CISA's window for audits.

**[ANIMATION]** say: "218_repositories"_is_secondary_and_unverified._Say:_used_the_action

And how many repositories leaked secrets is not stated by either source. A figure of "218 repositories" is secondary and unverified. So when you tell this case, say "more than 23,000 repositories used the action". Don't say that number leaked.

**[ANIMATION]** walk: columns=the_part,as_the_table_gives_it rows=What_happened:malicious_versions_of_eight_packages_were_live_for_about_four_hours_and_harvested_developer_credentials|Root_cause:a_pull__request__target_workflow_that_echoed_an_unsanitised_pull_request_title;_a_legacy_read-write_default_token;_a_publish_workflow_that_could_be_dispatched|Lesson:one_injectable_line_plus_a_write_token_reaches_a_publish_credential|Flags:none mono=off title=Nx,_"s1ngularity",_August_2025 id=nx say_header=Source:_the_project's_post-mortem

**[ANIMATION]** step: nx.header

**Nx, "s1ngularity", August 2025.** Source: the project's post-mortem.

**[ANIMATION]** step: nx.1

What happened: malicious versions of eight packages were live for about four hours and harvested developer credentials.

**[ANIMATION]** step: nx.2

Root cause, in three parts. A `pull_request_target` workflow that echoed an unsanitised pull request title. A legacy read-write default token. And a publish workflow that could be dispatched.

**[ANIMATION]** step: nx.3

Lesson: one injectable line plus a write token reaches a publish credential.

**[ANIMATION]** step: nx.4

Flags: none.

Map the three causes to three videos. The echoed title is video 158. The legacy default token is video 156: a repository created before the default changed. And the dispatch is the documented exception from video 156: events from the job token start no runs, except `workflow_dispatch` and `repository_dispatch`.

**[ANIMATION]** walk: columns=the_part,as_the_table_gives_it rows=What_happened:compromised_maintainer_accounts_pushed_a_workflow_that_sent_secrets_to_an_attacker's_server:_3,325_secrets_from_817_repositories|Root_cause:write_access_equals_secret_access|Lesson:protect_workflow_files_with_code-owner_review;_prefer_environment-scoped_secrets_and_OIDC|Flag:a_vendor_report mono=off title=GhostAction,_September_2025 id=ghost say_header=Source:_GitGuardian

**[ANIMATION]** step: ghost.header

**GhostAction, September 2025.** Source: GitGuardian.

**[ANIMATION]** step: ghost.1

What happened: compromised maintainer accounts pushed a workflow that sent secrets to an attacker's server: 3,325 secrets from 817 repositories.

**[ANIMATION]** step: ghost.2

Root cause: write access equals secret access.

**[ANIMATION]** step: ghost.3

Lesson: protect workflow files with code-owner review, and prefer environment-scoped secrets and OIDC.

**[ANIMATION]** step: ghost.4

Flag: this is a vendor report.

**[ANIMATION]** walk: columns=the_part,as_the_table_gives_it rows=What_happened:a_self-replicating_npm_worm_stole_tokens,_pushed_secret-dumping_workflows,_and_in_its_second_wave_registered_infected_machines_as_self-hosted_runners|Root_cause:stolen_developer_and_CI_tokens|Lesson:a_token_with_workflow_write_access_is_equivalent_to_every_secret_it_can_reach;_monitor_for_new_workflows,_runners_and_repositories|Flag:the_size_of_the_second_wave_is_approximate:_about_700_malicious_versions_and_about_800_packages,_from_the_same_Wiz_post mono=off title=Shai-Hulud_and_its_sequel,_September_and_November_2025 id=shai say_header=Sources:_the_GitHub_Blog_and_Wiz

**[ANIMATION]** step: shai.header

**Shai-Hulud and its sequel, September and November 2025.** Sources: the GitHub Blog and Wiz.

**[ANIMATION]** step: shai.1

What happened: a self-replicating npm worm stole tokens, pushed secret-dumping workflows, and in its second wave registered infected machines as self-hosted runners.

**[ANIMATION]** step: shai.2

Root cause: stolen developer and CI tokens.

**[ANIMATION]** step: shai.3

Lesson: a token with workflow write access is equivalent to every secret it can reach. Monitor for new workflows, runners and repositories.

**[ANIMATION]** step: shai.4

Flag: the size of the second wave is approximate. The notes cite the same Wiz post for about 700 malicious versions and about 800 packages.

**[ANIMATION]** walk: columns=the_part,as_the_table_gives_it rows=What_happened:persistent_self-hosted_runners_on_a_public_ML_repository_could_be_reached_by_a_pull_request;_a_poisoned_Actions_cache_led_to_malicious_PyPI_releases_published_through_the_legitimate_workflow|Root_cause:self-hosted_runners_with_weak_approval_settings;_an_insecure_trigger_plus_cache_trust|Lesson:ML_projects_are_prime_targets;_use_ephemeral_runners_and_treat_caches_as_untrusted|Flag:PyTorch_is_a_researcher_disclosure,_not_an_observed_attack mono=off title=PyTorch_runners,_disclosed_January_2024,_and_Ultralytics,_December_2024 id=ml say_header=Sources:_a_researcher_write-up_and_the_PyPI_blog

**[ANIMATION]** step: ml.header

**PyTorch runners, disclosed January 2024, and Ultralytics, December 2024.** Sources: a researcher write-up and the PyPI blog.

**[ANIMATION]** step: ml.1

What happened: persistent self-hosted runners, machines the project operated itself, on a public ML repository could be reached by a pull request. And, in the second case, a poisoned Actions cache led to malicious PyPI releases published through the legitimate workflow.

**[ANIMATION]** step: ml.2

Root cause: self-hosted runners with weak approval settings, and an insecure trigger plus cache trust.

**[ANIMATION]** step: ml.3

Lesson: ML projects are prime targets. Use ephemeral runners and treat caches as untrusted.

**[ANIMATION]** step: ml.4

Flag: PyTorch is a researcher disclosure, not an observed attack. Say "could be reached", not "was attacked".

**[ANIMATION]** walk: columns=the_part,as_the_table_gives_it rows=What_happened:a_pull__request__target_flaw_leaked_a_token;_weeks_later_a_malicious_release,_and_almost_all_action_tags_force-pushed;_downstream,_a_publishing_credential_stolen|Root_cause:incomplete,_non-atomic_credential_rotation_after_the_first_incident;_tag-pinned_security_tooling|Lesson:rotate_everything_at_once;_security_tools_in_CI_are_high-value_targets;_pin_by_commit|Flags:tag_count:_75_of_76_according_to_Wiz,_76_of_77_according_to_Datadog;_the_account_behind_the_first_exploit_is_named_differently mono=off title=Trivy_and_LiteLLM,_February_to_March_2026 id=trivy say_header=Sources:_the_advisory,_the_vendor's_notice,_and_Datadog

**[ANIMATION]** step: trivy.header

**Trivy and LiteLLM, February to March 2026.** Sources: the advisory, the vendor's notice, and Datadog.

**[ANIMATION]** step: trivy.1

What happened: a `pull_request_target` flaw leaked a token. Weeks later a malicious scanner release was published and almost all action tags were force-pushed to malicious commits. A downstream LLM gateway library that ran the scanner unpinned had its publishing credential stolen, and two malicious versions were on PyPI for about three hours.

**[ANIMATION]** step: trivy.2

Root cause: incomplete, non-atomic credential rotation after the first incident, meaning the credentials weren't all replaced at once. And tag-pinned security tooling.

**[ANIMATION]** step: trivy.3

Lesson: rotate everything at once. Security tools in CI are high-value targets. Pin by commit.

**[ANIMATION]** step: trivy.4

Flags: a conflict in the count of tags: 75 of 76 according to Wiz, 76 of 77 according to Datadog. And write-ups name the account behind the first exploit differently. Use the advisory and the vendor notice for exact figures. That's why I said "almost all".

**[ANIMATION]** walk: columns=the_part,as_the_table_gives_it rows=What_happened:84_malicious_versions_of_42_packages_were_published_through_the_project's_own_trusted-publisher_identity;_no_npm_token_was_stolen|Root_cause:a_pull__request__target_workflow_built_fork_code;_the_fork_poisoned_the_shared_cache;_the_release_job_restored_it;_malware_read_the_job's_OIDC_token_from_runner_memory|Lesson:read-only_permissions_did_not_block_cache_writes;_OIDC_is_not_safe_if_untrusted_code_runs_in_the_job;_pull__request__target_bypassed_the_first-time-contributor_gate|Flags:the_claim_of_valid_provenance_attestations,_and_the_name_"Mini_Shai-Hulud",_come_from_secondary_reports;_no_GitHub-authored_post-mortem_was_found mono=off title=TanStack,_11_May_2026 id=tan say_header=Source:_the_project's_post-mortem

**[ANIMATION]** step: tan.header

**TanStack, the eleventh of May 2026.** Source: the project's post-mortem.

**[ANIMATION]** step: tan.1

What happened: 84 malicious versions of 42 packages were published through the project's own trusted-publisher identity. No npm token was stolen.

**[ANIMATION]** step: tan.2

Root cause, as a chain. A `pull_request_target` workflow built fork code. The fork poisoned the shared cache. The release job restored it. Malware read the job's OIDC token from runner memory.

**[ANIMATION]** step: tan.3

Lesson: read-only `permissions` didn't block cache writes. OIDC isn't safe if untrusted code runs in the job. And `pull_request_target` bypassed the first-time-contributor gate.

**[ANIMATION]** step: tan.4

Flags: whether the versions carried valid provenance attestations, and the name "Mini Shai-Hulud", come from secondary reports. The post-mortem does not say so. And no GitHub-authored post-mortem was found.

**[ANIMATION]** walk: columns=the_part,as_the_table_gives_it rows=What_happened:a_modified_uploader_script_exported_CI_environment_variables_for_two_months|Root_cause:a_mutable_script_fetched_and_executed_in_CI|Lesson:remote_scripts_are_the_same_risk_class_as_mutable_tags|Flag:history_only mono=off title=Codecov,_2021 id=codecov say_header=Source:_Codecov's_security_update

**[ANIMATION]** step: codecov.header

**Codecov, 2021.** Source: Codecov's security update.

**[ANIMATION]** step: codecov.1

What happened: a modified uploader script exported CI environment variables for two months.

**[ANIMATION]** step: codecov.2

Root cause: a mutable script fetched and executed in CI.

**[ANIMATION]** step: codecov.3

Lesson: remote scripts are the same risk class as mutable tags.

**[ANIMATION]** step: codecov.4

Flag: history only.

**[ANIMATION]** end

And one sentence of completeness from the textbook. A further tag hijack, of the actions-cool actions in May 2026, is known to the course only through secondary reporting. It is mentioned for completeness and nothing is built on it.

**Three recurring patterns.**

**[ANIMATION]** stores: boxes=pattern_one|pattern_two|pattern_three rows=1:A:mutable_references_repointed_after_a_maintainer_credential_was_stolen@hl|1:A:tj-actions|1:A:Trivy|2:B:a_privileged_trigger_ran_or_interpolated_outsider_input@hl|2:B:the_upstream_of_tj-actions|2:B:Nx|2:B:Trivy|2:B:TanStack|3:C:stolen_tokens_were_used_to_push_workflows@hl|3:C:GhostAction|3:C:Shai-Hulud title=Three_recurring_patterns id=patterns

**[ANIMATION]** step: patterns.1

One: mutable references were repointed after a maintainer credential was stolen. tj-actions and Trivy.

**[ANIMATION]** step: patterns.2

Two: a privileged trigger ran or interpolated outsider input. The upstream of tj-actions, Nx, Trivy, and TanStack.

**[ANIMATION]** step: patterns.3

Three: stolen tokens were used to push workflows. GhostAction and Shai-Hulud.

**[ANIMATION]** say: One_technique_across_them:_reading_the_runner_process's_memory

And one technique recurs across them: reading the runner process's memory to collect secrets and OIDC tokens.

**[ANIMATION]** say: Masked_logs_are_irrelevant_once_attacker_code_runs_in_a_job

The report's conclusion is the sentence to carry into a design review. Masked logs are irrelevant once attacker code runs in a job. Then the quotation: "the robust controls are preventing untrusted code from running in privileged jobs and limiting which secrets a job holds."

## MENTAL MODEL

A picture helps. Think of each incident as a chain, and of each control as a pair of cutters.

**[ANIMATION]** gates: packet=a_fork_pull_request gates=A_privileged_workflow_builds_fork_code:done:link_one:pull__request__target|The_fork_writes_into_the_shared_cache:done:link_two:the_cache_is_poisoned|The_release_job_restores_that_cache:done:link_three:restored|Code_in_the_release_job_reads_the_job's_OIDC_token:done:link_four:from_runner_memory title=TanStack,_11_May_2026_(the_project's_post-mortem) id=chain at_1=22 at_2=34 at_3=44 at_4=54

A chain needs every link. The TanStack chain, as the post-mortem gives it, has four. A privileged workflow builds fork code. The fork writes into the shared cache. The release job restores that cache. Code in the release job reads the job's OIDC token. There's the answer to "No password was stolen. How?" Four links, and none of them is a stolen password.

**[ANIMATION]** end

Try it now, thirty seconds, on paper. Write the four links as a chain, top to bottom. Then take the controls from this part and write each beside the link it cuts. Say them out loud.

**[PAUSE]**

**[ANIMATION]** walk: columns=the_link,the_control_that_cuts_it rows=1._A_privileged_workflow_builds_fork_code:not_using_pull__request__target_for_a_build,_or_not_running_the_fork's_code_under_it|2._The_fork_writes_into_the_shared_cache:a_read-only_default-branch_cache_for_low-trust_triggers|3._The_release_job_restores_that_cache:cache-mode:_none_on_the_job_that_holds_an_identity|4._Code_in_the_release_job_reads_the_job's_OIDC_token:cut_by_cutting_the_earlier_ones marks=1.2:ok,2.2:ok,3.2:ok,4.2:wait mono=off title=Each_control_cuts_one_link id=cuts

**[ANIMATION]** step: cuts.1

Not using `pull_request_target` for a build, or not running the fork's code under it: cuts link one. That's video 157, and the checkout action's refusal since version 7 leans on the same link.

**[ANIMATION]** step: cuts.2

A read-only default-branch cache for low-trust triggers: cuts link two. That's the platform change of the twenty-sixth of June 2026.

**[ANIMATION]** step: cuts.3

`cache-mode: none` on the job that holds an identity: cuts link three. That's video 160 and workflow 12.

**[ANIMATION]** step: cuts.4

Binding the identity to an environment with protection rules, and letting no untrusted code or cache into that job: addresses link four. Note the word. Once attacker code is running inside a job that may request the token, nothing in the job stops the request. Link four is cut by cutting the earlier ones.

**[ANIMATION]** say: You_do_not_know_in_advance_which_chain_will_be_tried:_layer_the_controls

Where this model breaks: it suggests one cut is enough. For one chain, it is. But you don't know in advance which chain will be tried, and several of these projects were hit through a combination nobody had drawn. That's why the controls are layered, and why section 21A.21 says to review workflows as a set.

## DIAGRAM

**[DIAGRAM]** Three columns, one per recurring pattern. Write the pattern as the column heading, then place each case under the pattern or patterns it shows. Under each column write the control from this part that answers it.

```text
  PATTERN 1                        PATTERN 2                          PATTERN 3
  mutable references repointed     a privileged trigger ran or        stolen tokens used to
  after a maintainer credential    interpolated outsider input        push workflows
  was stolen
  -----------------------------    -------------------------------    ---------------------------
  tj-actions (March 2025)          upstream of tj-actions             GhostAction (Sept 2025)
  Trivy (Feb to March 2026)        Nx (August 2025)                   Shai-Hulud (Sept, Nov 2025)
                                   Trivy (Feb to March 2026)
  same risk class:                 TanStack (11 May 2026)
  Codecov (2021), a mutable        related: Ultralytics (Dec 2024),
  script fetched in CI             an insecure trigger plus cache
                                   trust
  -----------------------------    -------------------------------    ---------------------------
  control: pin by commit ID;       control: no fork code in a         control: code-owner review
  no remote script piped into      privileged job; untrusted text     on workflow files;
  a shell; rotate everything       only through env; read-only        environment-scoped secrets
  at once after an incident        token; cache-mode none             and OIDC; monitor for new
                                                                      workflows and runners

  one technique across all three: reading the runner process's memory for secrets and OIDC tokens
  => masked logs are irrelevant once attacker code runs in a job
```

Three columns, one per recurring pattern: each case under the pattern or patterns it shows, and under each column the control from this part that answers it.

**[DIAGRAM]** Trivy appears in two columns, and that is the lesson of that case: the first incident was pattern two, and because the rotation afterwards was incomplete, the second was pattern one. The placement of Codecov and Ultralytics beside the patterns follows the lessons the table gives for them; the textbook's own sentence lists the six cases in the three patterns.

Read the columns. Trivy appears in two of them, and that's the lesson of that case: the first incident was pattern two, and because the rotation afterwards was incomplete, the second was pattern one.

## LIVE TERMINAL DEMO

**[TERMINAL]** One replay, once more: `labs/run ch21a/mutable-tag`. It is the local model of the first pattern. A bare repository plays the action's repository. This is Git in the sandbox; it shows the mechanism that the tj-actions and Trivy rows describe as "tags were repointed" and "force-pushed", and nothing else about those incidents.

**Step 1: the move.**

```bash
git tag -f -a v1 -m "report-size v1"
git push --force origin v1
```

`git tag -f` is 🟡 CAUTION: it moves a local tag. `git push --force` of a tag is 🔴 DANGEROUS. The five answers, as section 21A.7 gives them. What it changes: the remote tag ref. What it can destroy: it can silently change what every consumer of the tag runs. How to preview: `git ls-remote --tags origin v1`. How to recover: push the old tag object back, if you still have it. When it is appropriate: only for a deliberate "moving major tag" policy that consumers know about.

In the first pattern, who is at this keyboard? Read the root-cause column of the tj-actions row again before you answer. Say it out loud.

**[PAUSE]**

<!-- snippet: ch21a/mutable-tag/02-move -->
```text
# Anyone who can push to the action repository can point v1 somewhere else.
$ git tag -f -a v1 -m "report-size v1"
Updated tag 'v1' (was 71c87ce)
$ git push --force origin v1
To $LAB/ch21a/mutable-tag/hosting/report-size.git
 + 71c87ce...0ca190d v1 -> v1 (forced update)
```
<!-- /snippet -->

A forced update of `v1`, from `71c87ce` to `0ca190d`. The person at the keyboard holds a credential that can push to the action's repository. In the incident rows it was a stolen bot token in one case, and credentials that had not been fully rotated in the other. From Git's side, a legitimate maintainer and a thief with the maintainer's token are the same.

**Step 2: what consumers get afterwards.**

```bash
git ls-remote --tags hosting/report-size.git
```

<!-- snippet: ch21a/mutable-tag/03-after -->
```text
# Same name, different commit. No consumer workflow changed.
$ git ls-remote --tags hosting/report-size.git
0ca190da3c6db48b75af6a358aef5b189725e9a4	refs/tags/v1
5de1e2d145bc0b3fbb28e6d457f7220359d63f84	refs/tags/v1^{}

# The commit that was reviewed still exists, and its ID still names exactly that content.
$ git -C hosting/report-size.git cat-file -p 80827f43993c0dc6fc8324685d01e720707e5429:action.yml
name: report-size
description: Prints the size of the build output
runs:
  using: composite
  steps:
    - run: du -sh dist
      shell: bash
```
<!-- /snippet -->

The same name, a different commit: `5de1e2d`. No consumer workflow changed. And the commit that was reviewed still exists under its own ID, with exactly its old content.

**[ANIMATION]** graph: 80827f4 tag:v1; HEAD=none => + 80827f4-5de1e2d tag:v1 dx=420 title=Same_name,_different_commit

**[ANIMATION]** step: state-1

Now read the lesson column of the tj-actions row with this on screen: "only commit-pinned workflows were unaffected". You saw why a moment ago.

**[ANIMATION]** step: state-2

A workflow that named the tag ran the new commit on its next run. A workflow that named the old commit's ID ran the old commit.

**[ANIMATION]** end

And you can audit your own exposure with the same reading command, which is 🟢 SAFE: `git ls-remote --tags` against an action's repository shows what each tag points at today. Whether it pointed there last month is something only your pins, or your logs, can tell you.

## COMMON MISTAKES

Five mistakes to watch for.

1. **Quoting a figure that the sources do not support.** Root cause: several rows carry conflicts or secondary figures; for tj-actions the number of repositories that leaked secrets is not stated by the primary sources.
2. **Telling a researcher disclosure as an attack.** Root cause: the PyTorch case is a disclosure, not an observed attack; the flag says so.
3. **Concluding that OIDC or read-only permissions "failed".** Root cause: each did what it is defined to do; the chain went through a cache and through untrusted code inside the job, which neither control addresses.
4. **Rotating one credential after an incident.** Root cause: in the Trivy case, incomplete, non-atomic rotation after the first incident enabled the second.
5. **Arguing for one control per incident.** Root cause: the chains differ, and the edge case behind most of them is two workflows that share something.

## PRODUCTION EXAMPLE

Now, out of the lab. A staff engineer proposes three changes to an ML platform's repositories: require commit pins by policy, forbid `pull_request_target` except for metadata-only jobs, and move publishing credentials behind environments. A director asks why this is worth a week of work, given that "we have never had an incident".

**[ANIMATION]** walk: columns=the_proposed_change,the_row,its_flag rows=require_commit_pins_by_policy:tj-actions,_"only_commit-pinned_workflows_were_unaffected":how_many_leaked_secrets_is_not_given_by_the_primary_sources|forbid_pull__request__target_except_for_metadata-only_jobs:Nx,_with_its_three_causes:none|publishing_credentials_behind_environments:GhostAction,_with_its_one-line_root_cause:a_vendor_report mono=off title=Three_rows,_one_per_pattern id=rows

**[ANIMATION]** step: rows.3

The engineer answers with three rows, one per pattern, and for each row the three parts and the flag. For pins: the tj-actions row, with the sentence "only commit-pinned workflows were unaffected", the figure of more than 23,000 repositories that used the action, and the statement that the number of repositories that leaked secrets is not given by the primary sources. For the trigger: the Nx row, whose flags column says "none", with its three causes. For credentials: the GhostAction row, marked as a vendor report, with its one-line root cause.

**[ANIMATION]** say: The_numbers_match._That_is_what_the_flags_are_for

The director checks one of the links during the meeting. The numbers match. The proposal is approved. That's what the flags are for.

## PRACTICE EXERCISE

Your turn. Do Exercise 29.2, "The comment workflow", in [`exercises/m26-m31-actions-security.md`](../../exercises/m26-m31-actions-security.md).

Before you start, predict which of the three recurring patterns the exercise's workflow belongs to, and which case of the table it most resembles. Afterwards, write the chain for it link by link, and the control that cuts each link.

The challenge is Exercise 29.8, "A workflow nobody wrote", in the same file.

## INTERVIEW QUESTION

**[ON SCREEN]** Q332: "In the TanStack incident no credential was stolen from storage. Walk through how a fork pull request led to a publish, and name the control that would have broken each link."

Read the question on screen. Say your answer out loud.

**[PAUSE]**

A strong answer gives the chain as numbered links, in the post-mortem's order, and for each link one control with the video's worth of reasoning behind it in a sentence. It is careful about what is sourced: it uses the post-mortem's facts and marks what comes from secondary reports. The follow-up quotes the team: "We had read-only permissions and we publish through OIDC, so we followed best practice." Name the two assumptions in that sentence that the incident disproved. Both are in the lesson column of the row.

## RECAP

Let's land this.

You should now be able to say:

- Each case has three parts, what happened, root cause and lesson, and a flag that says how far its figures can be trusted.
- Three patterns recur: mutable references repointed after a credential theft; a privileged trigger that ran or interpolated outsider input; stolen tokens used to push workflows.
- One technique recurs across them: reading runner memory, which makes masked logs irrelevant once attacker code runs in a job.
- In the TanStack chain no stored credential was stolen: fork code under a privileged trigger, a poisoned shared cache, a release job that restored it, and an OIDC token read from memory.
- The robust controls are preventing untrusted code from running in privileged jobs and limiting which secrets a job holds.

## HOMEWORK

Read section 21A.18 of [Chapter 21A](../../textbook/ch21a-actions-security.md) and follow two of the source links to the published post-mortems. Read [`guides/security-guide.md`](../../guides/security-guide.md).

Today you walked through eight incidents with their flags, and cut one chain link by link. Retell one case aloud, with its flag, before the next video. Next time: the Git client, what a clone runs, the three guards, and recursive clones. Until then, look at the state first and type second. See you in the next one.
