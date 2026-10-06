# V000: The animation library, scene by scene

- **Part.** 2: Integration and collaboration mechanics
- **Module.** 0
- **Planned minutes.** 16

## COMMIT GRAPH

**[ANIMATION]** graph: A-B-C main; B-D-E feature/login; HEAD=main

A history is drawn commit by commit. Here `main` has three commits, and `feature/login` leaves it at commit B.

## MERGE

**[ANIMATION]** merge: fast-forward versus three-way, feature into main

On the left and on the right, the same command is about to run.

On the left, `main` is an ancestor of `feature`.

So the label slides forward. That is a fast-forward.

On the right the two branches diverged. Git walks back from both tips to the merge base.

Then it writes a new commit with two parents.

## REBASE

**[ANIMATION]** rebase: feature onto main

A rebase starts from the same diverged picture.

Git lifts the commits that exist only on `feature`.

It copies them, one at a time, onto the tip of `main`. Each copy is a new commit with a new ID.

The originals are still there, but they fade: nothing points at them.

Finally the branch label moves to the last copy.

## THREE TREES

**[ANIMATION]** trees: file=judge.txt

Git keeps three versions of your file: the working tree, the index, and HEAD.

You edit the file.

`git add` copies it into the index.

`git commit` records the index as a new snapshot.

**[PAUSE]**

`git restore` is 🔴 DANGEROUS for unsaved work: it copies the index back over your edit.

And `git reset --hard` is 🔴 DANGEROUS too: it moves HEAD back and overwrites the other two.

## OBJECT MODEL

**[ANIMATION]** objects: shared blobs

A commit is a small object.

It points at a tree.

The tree points at blobs, one per file.

A second commit after one edit adds one new blob.

Everything else is shared.

## CONTENT ADDRESSING

**[ANIMATION]** hash: differs=byte

An object's ID is computed from its content.

Identical content gets the identical ID, on any machine.

Change one byte, and the ID is a different one.

## LAB SANDBOX

**[ANIMATION]** sandbox:

The lab is a sealed room on your own Mac.

Inside the room is the lab's own configuration, its clock and its directories.

Outside is everything you care about.

Both lab commands walk into the room.

The room has two doors with different clocks.

And nothing a lab does reaches your real configuration: no arrow gets there.

## REMOTES

**[ANIMATION]** remotes: with Asha

Three repositories: yours, origin, and a teammate's.

Asha pushes a commit.

You fetch: only `origin/main` moves.

You pull: now your `main` moves too.

You commit.

You push, and origin catches up.

## REFLOG RESCUE

**[ANIMATION]** reflog: on main

Four commits on `main`.

A 🔴 DANGEROUS reset yanks the label back two commits.

The reflog still lists where HEAD has been.

One more reset, and the commits are back.

## PULL REQUEST

**[ANIMATION]** pr: feature/login into main

**[ANIMATION]** step: branch

A pull request starts with a branch.

**[ANIMATION]** step: push

You push it and open the pull request.

**[ANIMATION]** step: review

A teammate reviews it.

**[ANIMATION]** step: checks

The checks run.

**[ANIMATION]** step: merge

And it is merged.

## CI PIPELINE

**[ANIMATION]** ci: push (checkout, set up Python, install, run tests)

A push is the event. GitHub finds the workflow, starts a job on a fresh runner, runs the steps in order, and reports the result on the commit.

## PARAMETERS

**[ANIMATION]** graph: 6ae3c51-5397d5f main ORIG_HEAD; 6ae3c51-640bfe1-45a7a67 feature/judge MERGE_HEAD; 6ae3c51 v0.1.0; HEAD=main title=Tags_and_special_refs

A tag has its own shape, and the names Git writes for itself during a merge are small hollow chips.

**[ANIMATION]** graph: 6eab4a9-23b0907 main feature/retry; HEAD=feature/retry => 6eab4a9-23b0907-f5192c8 feature/retry; 23b0907 main; HEAD=feature/retry

**[ANIMATION]** step: state-1

One graph can have several states. Two names on one commit.

**[ANIMATION]** step: state-2

Then a commit: the current branch slides to it, and the frame follows the picture as it grows.

**[ANIMATION]** merge: three-way feature/rouge into main common=6eab4a9,03f74b9 main_only=9500b9e,e12f113 feature_only=22c856c,5351fa7,eaab34d title=A_merge_with_real_commits

A merge can be drawn with as many commits as the transcript has, under their real short IDs. Both histories meet at the merge base, and the merge commit stands to the right of both parents.

**[ANIMATION]** remotes: solo fetch note=a_bare_repository_on_disk

Without a teammate in the story, only your clone and origin are drawn. Somebody pushes, and then you fetch.

**[ANIMATION]** pr: feature/login into main blocked cmd=off layers=on steps=branch,push,merge,review,checks title=The_merge_is_blocked

A pull request can be blocked. Is it the branch, which is Git? The review, which is GitHub? Or the checks, which are GitHub Actions?

**[ANIMATION]** trees: file=config/settings.yaml order=reverse names=Working_tree,Index,Repository ref=main steps=setup,edit,add,commit

The three boxes can be renamed and drawn in the other order, a long path is fitted, and the branch can be shown under the history. You edit, you add, you commit.

## GENERALIZED SCENES

**[ANIMATION]** rebase: feat/rerank onto main common=8afc6bd main_only=589d18b feature_only=5ee19f0,af65a92,bd62876 new_ids=1c2d3e4,3dfab55,a94e9f6 stop=1 rebase_head=on orig_head=on

A rebase can now carry the transcript's own commits and their new IDs. It can stop after one copy with a conflict, wait, and continue, and at the end `ORIG_HEAD` marks where the branch was.

**[ANIMATION]** rebase: client onto main upstream=server common=A,B main_only=C,D upstream_only=E,F feature_only=G,H title=Rebase_with_--onto

The three-point form takes the commits that are on `client` but not on `server`, and replays them on `main`.

**[ANIMATION]** reflog: on feat/rerank commits=8afc6bd,589d18b,5ee19f0,af65a92 back=1 lost=reflog rescue=branch rescue_name=rescue/rerank rows=589d18b:HEAD@{0}:reset:_moving_to_HEAD~1|af65a92:HEAD@{1}:commit:_Add_rerank_cache|5ee19f0:HEAD@{2}:commit:_Tune_limits

The reflog scene takes its own commits, its own reflog lines and its own rescue. A commit that only the reflog names is dashed but not faded, and here a new branch brings it back.

**[ANIMATION]** remotes: [your clone] A-B-C main; B origin/main || [origin] A-B-D main; HEAD=none; cmd:git_push; say:Both_sides_have_a_commit_the_other_lacks => + rejected:C; say:The_push_is_rejected:_not_a_fast-forward || => [your clone] A-B-D-C′ main; D origin/main; ghost:C; cmd:git_pull_--rebase; say:pull_--rebase_fetches_D_and_replays_your_commit_on_it || => + C′ origin/main; cmd:git_push; say:Now_the_push_is_a_fast-forward || [origin] A-B-D-C′ main

Any story between repositories is written as panels in the graph notation. A push is rejected, `git pull --rebase` replays the local commit, and the second push goes through.

**[ANIMATION]** merge: three-way feature into main as=cherry-pick common=A,B main_only=C feature_only=D,E merge_id=E′ head=off

A cherry-pick is drawn as the three-way merge it is. The base is the parent of the picked commit, and the result has one parent.

**[ANIMATION]** merge: three-way as=revert common=20cd723,51d62b3,0d77920,8c6d240 target=0d77920 merge_id=none

A revert is the same merge with the roles turned around: the base is the commit being undone.

**[ANIMATION]** trees: file=notes/todo.md in=wt commits=none ref=main steps=setup,add,commit title=A_new_file

A new file starts in the working tree only. You add it, then you commit it, and the first commit appears.

**[ANIMATION]** trees: file=config.yaml state=2,2,1 commits=f7c044e,2da8d74 ref=main steps=setup,commit,reset-soft,reset-mixed,reset-hard title=Three_kinds_of_reset

After a commit, a soft reset moves only HEAD. A mixed reset also rewrites the index. A hard reset is 🔴 DANGEROUS: it overwrites your files too.

**[ANIMATION]** trees: file=src/app.py in=index,head badges=-,skip-worktree,- absent=not_on_disk commits=9d940ca safe=restore steps=setup,restore forms=-,LF,LF title=A_sparse_checkout

A box can lack the file, an index entry can carry a flag, and a restore that destroys nothing is not drawn in red.

**[ANIMATION]** pr: feature/priority into main number=off review_text=Review:_1_approval_required check_names=ci,lint,build commits=44c1e7b,12ae95d,16d4788 base_ids=9a383e5,9aa221a merge_id=da48bba method=squash steps=branch,push,review,push-again,dismissed,re-approve,checks,merge late_id=7e0f1a2 title=Squash_and_merge

The pull request scene takes real commits, any number of checks and its own words. A push after the approval dismisses it, and the squash puts one new commit on `main`.

**[ANIMATION]** ci: merge_group result=skipped file=off job=off runner=off skip_text=paths:_docs/**_did_not_match steps=event,workflow,result title=A_run_that_never_starts

A workflow can be skipped by a path filter. Then no run starts, and a required check keeps waiting.

**[ANIMATION]** objects: cards=tag:131e7a7:object_20cd723+type_commit+tag_v1.0,commit:20cd723:tree_e223878+parent_51d62b3,tree:e223878:100644_blob_98a743c_README.md+040000_tree_27bb9f5_src+160000_commit_7e4a6f0_vendor/lib,tree:27bb9f5:100644_blob_257376b_app.py,blob:98a743c:#_Ticket_router,blob:257376b refs=tag:v1.0>131e7a7,main>20cd723,tag:v0.9>20cd723 missing=257376b

Any objects can be drawn as cards: a tag object, a commit, a tree with a sub-tree and a gitlink entry, and a blob that is not in this repository.

**[ANIMATION]** hash: differs=byte lines=tree_29b0184|parent_d4c9fab|author_Lab_User_1788755640_+0530|committer_Lab_User_1788755640_+0530|Add_scorer,_first_version fn=SHA-1 fn2=SHA-256 ids=1442f02427f21cdc85e98b91d69535929f65e7ab,02698852622172279f75a9ccc7b8505d411bf4e26c48dba8010e6c447439e8de left=a_SHA-1_repository right=a_SHA-256_repository steps=one,different

The same content can go through two different functions, and long IDs are set on two lines.

## GRAPH POWER

**[ANIMATION]** graph: A-B-...14-C-D main; B-E-F feature; HEAD=none; note:B:merge_base; role:D:ours; role:F:theirs; tree:E:4b825dc; range:E,F:main..feature; say:Notes,_roles,_a_tree_ID_and_a_shaded_range => + range:E,F:main...feature; range2:...14,C,D; left:D; right:F; dim:A; say:Three_dots:_both_sides,_marked_left_and_right => + drop:D; drop:F; range:; range2:; absent:A; reflog:E; pass:C; fail:D; cmd:git_log_--oneline; say:Absent_from_this_clone,_only_in_the_reflog,_pass_and_fail id=power

A commit can carry a note, a role, a tree ID and a mark. A range is shaded, fourteen commits are folded into three dots, and every state has its own caption and command line.

**[ANIMATION]** say: A held scene can change its caption

A held scene can get a new caption without moving.

**[ANIMATION]** graph: *1-*2-?yours main special:refs/bisect/bad; *1 HEAD@{1}; *2 remote:origin/main branch:origin/main#local; HEAD=none title=Other_commits,_other_names => + *2-131e7a7 main; 131e7a7 atag:v2.0#b99c6ad; title:An_annotated_tag

Commits without a name, a commit whose ID is never printed, special refs, two names that look alike, and a tag object between a tag and its commit.

**[ANIMATION]** submodule: [superproject] A-B-C main; HEAD=main || [vendor/lib, a repository of its own] P-Q-R main; HEAD=none => + link:C>Q:records_Q_(mode_160000); say:The_superproject's_commit_holds_one_commit_ID_of_the_other_repository || + Q HEAD point_state_2=Q

Two repositories stand side by side, and an arrow can cross from a commit of one to a commit of the other.

**[ANIMATION]** twig: nod

Twig can nod when a prediction was right.

**[ANIMATION]** twig: careful

And Twig can ask for care without the alarm of a red label.

**[ANIMATION]** step: power.state-2

A step can name its scene, so the first graph of this section returns in its second state.

## NEW SCENES

**[ANIMATION]** bisect: commits=16 first_bad=11

Bisect halves what is left. Git checks out the middle, you say good or bad, and the shaded range shrinks until one commit remains: four tests instead of fifteen.

**[ANIMATION]** blame: file=router/classify.py lines=53e7f57:def_classify(ticket):|53e7f57:____words_=_ticket.lower().split()|9aa221a:____threshold_=_0.7|b4554be:____for_w_in_words:|b4554be:________if_w_in_URGENT:|9a383e5:____________return_"high" after=53e7f57,53e7f57,9aa221a,53e7f57,53e7f57,9a383e5

Blame tags every line with the commit that last changed it. When a reformatting commit is ignored, two lines point further back.

**[ANIMATION]** todo: todo=pick:1edd58e:Add_parser|pick:614c93b:Fix_typo_in_parser|pick:266d3b2:Add_tests|pick:e8b4036:Debug_print edit=pick:1edd58e:Add_parser|fixup:614c93b:Fix_typo_in_parser|reword:266d3b2:Add_tests result=Add_parser,Add_tests

The todo list of an interactive rebase is edited: one line becomes a fixup, one is reworded, one is dropped, and two commits come out.

**[ANIMATION]** stash: commits=6eab4a9,23b0907 index=c1d2e3f stash=f5192c8 on main

A stash entry is two commits, and `refs/stash` points at the second one. After a pop nothing names them.

**[ANIMATION]** tags: commits=d4c9fab,bb904cd,191bbd1 light=v0.9@bb904cd annotated=v1.0@191bbd1#131e7a7

A lightweight tag points at a commit. An annotated tag points at a tag object first.

**[ANIMATION]** stores: boxes=main_worktree:its_own_HEAD_and_index|linked_worktree:its_own_HEAD_and_index|*one_repository:objects_and_refs rows=1:A:HEAD_->_main|1:A:index|1:B:HEAD_->_hotfix|1:B:index|2:C:objects_(shared)@hl|2:C:refs/heads/main|2:C:refs/heads/hotfix arrows=2:A1>C2:|2:B1>C3: title=Two_worktrees,_one_repository

Two working trees have their own HEAD and their own index, and share one object store.

**[ANIMATION]** push: src=main dst=main refspec=refs/heads/main:refs/heads/main local=810dc2f remote=4e1f5fe client=pass server=stop notes=the_new_tip_contains_the_old_one,rule:_block_force_pushes lease=9aa221a,4e1f5fe result=!_[remote_rejected]_main_->_main

A push in parts: the refspec maps a local name to a remote name, your own Git checks the fast-forward rule, the server has the last word, and a lease compares what you expected with what is there.

**[ANIMATION]** prune: [your clone] A-B main origin/main; A origin/old-feature || [origin] A-B main; HEAD=none => + drop:origin/old-feature; cmd:git_fetch_--prune; say:The_branch_is_gone_on_the_server,_so_the_remote-tracking_name_is_removed ||

Fetch with prune removes a remote-tracking name whose branch no longer exists on the server.

**[ANIMATION]** shallow: ...older-C-D-E main; HEAD=main; absent:...older; say:A_clone_of_depth_3:_older_history_is_not_here title=A_shallow_clone

A shallow clone holds the newest commits. What lies behind the boundary is drawn as absent, not as unreachable.

**[ANIMATION]** stores: boxes=repo.bundle:one_file|*a_repository:after_git_fetch rows=1:A:header:_refs/heads/main_4e1f5fe|1:A:prerequisite:_-9aa221a@hl|1:A:pack:_3_commits|2:B:9aa221a_(must_be_there)@hl|3:B:3_new_commits@ok arrows=2:A2>B1:needs|3:A3>B2:unpacked title=A_bundle

A bundle is one file: a header with refs, a prerequisite that the receiver must already have, and a pack.

**[ANIMATION]** subtree: A-B-M main; X-Y-M; HEAD=main; note:Y:the_other_project's_history; note:M:merged_under_vendor/lib title=A_subtree_merge

A subtree is another project's history merged into a directory of this one.

**[ANIMATION]** stores: boxes=working_tree:what_you_edit|*Git_repository:.git/objects|LFS_store:.git/lfs/objects rows=1:A:model.bin_(2_GB)|2:B:pointer_file_(134_bytes)@hl|2:C:the_2_GB_of_content|3:A:model.bin_again@ok arrows=2:A1>B1:clean_filter|2:A1>C1:bytes|3:C1>A2:smudge_filter title=Git_LFS

With Git LFS a small pointer file goes into Git and the bytes go into a store of their own. The clean filter works on the way in, the smudge filter on the way out.

**[ANIMATION]** hooks: packet=git_push_origin_main gates=pre-commit:pass:client:can_stop_the_commit|pre-push:pass:client:can_stop_the_push|pre-receive:stop:server:can_refuse_every_ref|update:skip:server:one_ref_at_a_time|post-receive:skip:server:cannot_stop_anything zones=your_machine,the_server split=2 result=!_[remote_rejected] title=Where_hooks_can_stop_you

Hooks are gates on a line. Two stand on your machine, three on the server, and each one says what it can stop.

**[ANIMATION]** trees: file=notes.txt forms=CRLF,LF,LF history=off steps=setup,edit,add title=Content_changes_form_on_the_way_in

Filters and line-ending rules change the form of the content between the working tree and the index.

**[ANIMATION]** stores: boxes=loose_objects:.git/objects/ab/...|*one_packfile:.git/objects/pack rows=1:A:blob_v1_(40_KB)|1:A:blob_v2_(40_KB)|1:A:blob_v3_(40_KB)|2:B:base:_blob_v3_(40_KB)@hl|2:B:delta:_v2_against_v3_(1_KB)|2:B:delta:_v1_against_v2_(1_KB) arrows=2:A3>B1:git_gc title=Loose_objects_become_a_pack

Loose objects become a pack: one base, and deltas that say how to rebuild the others.

**[ANIMATION]** bars: bars=after_clone:412|after_100_commits:498|git_gc:96|git_repack_-ad:71 unit=MB title=Pack_sizes

A few numbers can be shown as bars, one at a time.

**[ANIMATION]** ladder: commit=af65a92

The recovery ladder: reachable, only in the reflog, unreachable, pruned. Each rung says what still brings the commit back.

**[ANIMATION]** decide: nodes=q1:Was_the_work_ever_committed?|q2:Does_a_branch_or_tag_still_reach_it?|q3:Is_it_in_a_reflog?|a:git_log_finds_it|b:git_reflog,_then_git_branch|c:git_fsck_--lost-found|d:not_in_Git:_check_the_editor's_history edges=q1>q2:yes|q1>d:no|q2>a:yes|q2>q3:no|q3>b:yes|q3>c:no path=q1,q2,q3,b title=Where_is_my_commit?

A decision tree takes its own questions and its own leaves, and can show the way that was taken.

**[ANIMATION]** walk: columns=file,base,ours,theirs,result rows=config.yaml:v1:v2:v1:ours_(v2)|router.py:v1:v1:v3:theirs_(v3)|README.md:v1:v2:v2:same_(v2)|rules.yaml:v1:v2:v3:CONFLICT marks=1.5:ok,2.5:ok,3.5:ok,4.5:bad pick=4 last=result title=A_merge,_file_by_file

A table is walked row by row: base, ours, theirs, and the result for each file.

**[ANIMATION]** cards: question=How_did_the_change_merge_without_the_platform_team_seeing_it? cards=No_rule_required_the_review|A_later_line_took_the_path_away_from_the_team|The_team_has_no_write_access,_so_its_line_was_skipped|The_pull_request_was_a_draft|The_person_who_merged_could_bypass_the_rule:the_next_video dim=4,5 ask=5 numbered=on marks=1:ok,2:ring,3:ok,5:lock

A few statements can stand as cards, arrive one by one, and then be ticked, ringed or locked.

## GITHUB AND ACTIONS

**[ANIMATION]** pr: feature into main number=off review_text=Review:_one_approval check_names=ci block=Rule:_conversations_must_be_resolved cmd=off title=Green_and_still_blocked

A pull request can be approved and green and still be blocked by a rule.

**[ANIMATION]** objects: cards=tag:131e7a7:object_20cd723+type_commit+tag_v1.0+tagger_Lab_User+gpgsig_-----BEGIN_SSH_SIGNATURE-----,commit:20cd723:tree_e223878+author_Lab_User signed=131e7a7:1-4 signed_text=what_the_signature_covers title=What_a_signature_covers

On an object card a bar can mark the lines that a signature covers.


**[ANIMATION]** ruleset: probe=merge_into_main layers=organization_ruleset:block_force_pushes+1_approval|repository_ruleset_A:signed_commits+3_approvals|repository_ruleset_B:required_check_ci|classic_rule_on_main:linear_history+2_approvals verdicts=pass,fail,pass,pass result=no_force_push+signed_commits+ci_green+linear_history+3_approvals rule=a_merge_must_satisfy title=Rules_add_up

Every label in the platform pictures comes from the script. Here layers of rules add up, and one of them fails.

**[ANIMATION]** gates: packet=old_9aa221a_new_810dc2f_refs/heads/main gates=restrict_deletions:pass:ruleset|block_force_pushes:bypass:ruleset:the_actor_is_on_the_bypass_list|require_linear_history:stop:ruleset:a_merge_commit result=remote_rejected title=A_push_meets_the_rules

One push meets the rules one after the other. A bypass lets it pass a rule; the next rule stops it.

**[ANIMATION]** codeowners: header=.github/CODEOWNERS rules=*:@example-org/platform|/router/:@example-org/routing|/router/priority.py:@example-org/on-call|*.yaml:@example-org/sre|docs/*:@example-org/docs numbers=2,5,6,9,12 paths=router/classify.py:1+2|router/rules/eu.yaml:1+2+4|docs/runbooks/escalation.md:1 wins=last title=Last_match_wins

For each changed path the matching lines light up, and the last one wins.

**[ANIMATION]** methods: [Create a merge commit] 9a383e5-9aa221a-4c53f2e main; 9a383e5-44c1e7b-16d4788; 16d4788-4c53f2e; HEAD=none || [Squash and merge] 9a383e5-9aa221a-da48bba main; HEAD=none || [Rebase and merge] 9a383e5-9aa221a-dbb1f36-ec49c9c main; HEAD=none title=What_lands_on_main

Three merge methods side by side, with what lands on the base branch.

**[ANIMATION]** stores: boxes=upstream:refs_of_example-org/router|your_fork:refs_of_you/router|*one_object_store:the_fork_network rows=1:A:refs/heads/main|1:B:refs/heads/main|1:B:refs/heads/my-fix|2:C:all_objects_of_both_(shared)@hl arrows=2:A1>C1:|2:B1>C1: title=A_fork_network

A fork network: two sets of refs over one object store.

**[ANIMATION]** auth: actors=Git,credential_helper,*the_server subs=git_push,osxkeychain,HTTPS msgs=1>2:get|2>1:username_+_token|1>3:request_with_the_token|3>1:401_Unauthorized:fail|1>2:erase boundary=2 zones=your_machine,the_network title=Where_HTTPS_authentication_fails

An authentication path is a sequence between actors, and the place where it fails is marked in red.

**[ANIMATION]** run: event=pull_request ref=refs/pull/7/merge sha=135aad1 jobs=lint|test|build:lint+test|deploy:build matrix=test:3.11+3.12+3.13 token=contents:read+id-token:write artifact=build>deploy:dist cache=test:uv_cache env=deploy:production:a_required_reviewer concurrency=deploy-main title=One_workflow_run

One workflow run in detail: the event and the commit it runs on, jobs that need other jobs, a matrix, the token's permissions, a cache and an artifact, an environment that waits for a reviewer, and an older run cancelled by its concurrency group.

**[ANIMATION]** flow: actors=the_fork's_code,the_workflow_run,*secrets_and_the_write_token msgs=1>2:pull_request_event|2>2:runs_the_fork's_code|2>3:asks_for_secrets:fail|2>2:read-only_token boundary=2 zones=untrusted,trusted title=What_crosses_the_line

A trusted and an untrusted side, and what may cross the line between them.

**[ANIMATION]** pin: A-B-C main; B tag:v4; HEAD=none; note:B:pinned_by_SHA_stays_here; say:A_workflow_uses_the_tag_v4 => + C tag:v4; say:The_tag_is_moved:_everyone_who_wrote_v4_now_runs_C title=A_tag_can_move,_a_commit_ID_cannot

A mutable tag is moved to another commit. A pin by commit ID stays where it was.

**[ANIMATION]** oidc: actors=the_job,the_platform's_token_service,*the_cloud msgs=1>2:asks_for_an_identity_token|2>1:a_signed,_short-lived_token:ok|1>3:presents_the_token|3>3:checks_issuer,_repository_and_branch|3>1:temporary_credentials:ok title=A_token_exchange_instead_of_a_stored_secret

A token exchange instead of a stored secret.

**[ANIMATION]** response: gates=contain:done:revoke_the_secret|assess:done:what_could_it_reach|eradicate:done:remove_it_everywhere|recover:done:issue_a_new_one|communicate:done:tell_who_must_know|prevent:done:scanning_and_reviews title=The_response_to_a_leaked_secret

The response to a leaked secret is a sequence in a fixed order.

**[ANIMATION]** stale: [server, after the rewrite] A-B′-C′ main; HEAD=none || [a stale clone] A-B-C main; HEAD=main; note:B:still_holds_the_secret => + A-B-C-D main; cmd:git_push_--force; say:A_stale_clone_pushes,_and_the_old_history_is_back || + A-B-C-D main

And a rewritten history can come back from a stale clone that pushes its old commits again.

## RECAP

1. **Scenes are triggered by tags.** One line in the script picks the scene.
2. **Steps follow the narration.** Each paragraph plays the next step.
3. **Everything else animates by itself.** Terminals type, tables and lists reveal.
