# Animation library gaps reported by script editors (for the finishing director of each batch)

**Status lines.** Each gap below carries a line "Library extension, 2026-10-06": DONE with the scene and parameter that covers it now, BY RECIPE when an existing scene draws it without a scene of its own, PARTLY or NOT DONE with the reason. The reference is `video/production/ANIMATION_STYLE.md` (section 0 is a table from topic to scene); `python3 tools/video_animtest.py --look '<tag>'` renders a tag before it goes into a script. The per-video picture lists in `authoring/scene-wishes/` were not worked through one by one: their recurring pictures (cards that arrive and are marked, layer bands, lines of a file against a path, two boxes and an arrow) are covered by `cards`, `layers`, `match` and `stores`.


## From V056 to V066
- rebase scene: fixed at two commits D, E on one main commit C; needs commit list, count and real IDs (V057, V059, V060 have three commits or their own letters); V056 is a stack. Editors used multi-state graphs instead, without the lift-and-copy motion.
  - **Library extension, 2026-10-06:** DONE. `rebase`: `common=`, `main_only=`, `feature_only=` (or `commits=`) as counts or lists of letters or real IDs; `new_ids=`; a stack: more commits in `feature_only=`. The lift-and-copy motion works for any count.
- reflog scene: rows, commits and rescue step are hard-coded; V059's story (bad rebase, ORIG_HEAD overwritten, feat/rerank@{2}, rescue branch first) uses a four-state graph.
  - **Library extension, 2026-10-06:** DONE. `reflog`: `commits=`, `back=`, `rows=id:selector:text|...`, `hl=`, `lost=reflog`, `rescue=branch|reset|none`, `rescue_name=`. NOT DONE as one scene: V059's whole story (a bad rebase, `ORIG_HEAD` overwritten, `feat/rerank@{2}`): the scene tells one reset and one rescue. Keep the four-state graph and add `reflog:` commits and `special:` / `HEAD@{n}` chips, which it could not show before.
- remotes scene: fixed step order, pull always a fast-forward, no forced update, no third repository; cannot show `git pull --rebase` (V058) or three-repository duplication (V059, V060).
  - **Library extension, 2026-10-06:** DONE. Any story is written as panels in the graph notation under the scene name `remotes` (`[your clone] ... || [origin] ... || [fork] ...`): free order of states, a rejected push (`rejected:`), a forced update (`ghost:`), `git pull --rebase`, a third repository. The six-step form also got `start=`, `incoming=`, `names=`.
- graph scene: no per-state caption or command line; no role annotations on commits (base, ours, theirs, P, C) so V061 and V063 diagrams stay still; no tree IDs under commits (V060, V063); no shading of a selected range such as A..B (V064); REBASE_HEAD not among special refs (V057, V062, V065); `step:` cannot name which scene it means (V064 workaround with a duplicate state).
  - **Library extension, 2026-10-06:** DONE. `say:` / `cmd:` / `title:` in a state (or `say_<step>=`, `cmd_<step>=`); `role:id:base`; `tree:id:4b825dc`; `range:ids:A..B` and `range2:`; `REBASE_HEAD` and every `..._HEAD` are special refs; `step: <scene or id>.<step>` with `id=name`.
- hash scene: `alt=` changes only the last line; content lines cannot contain a comma.
  - **Library extension, 2026-10-06:** DONE. `change=N` picks the line; lines that contain commas are separated by `|`.
- trees scene: with `steps=setup` only the first ID of `commits=` appears under HEAD.
  - **Library extension, 2026-10-06:** CONFIRMED, by design: the second ID belongs to the commit that the `commit` step makes. One ID is now enough (`commits=f7c044e`); `history=off` removes the strip.
- No scene for: range-diff pairing, a rebase todo list being rearranged, sequencer or state-directory files, stash and autostash.
  - **Library extension, 2026-10-06:** DONE: `todo` (the list being edited, with `result=`), `stash` (autostash: write the graph, `special:refs/stash`). BY RECIPE: range-diff pairing = `walk` (columns old, mark, new) or two `range:` sets in a graph; sequencer and state-directory files = `stores` (a box per directory, a row per file). No dedicated scene for these two.
- Convention to confirm: a paragraph read over a scene does not draw its first sentence, so risk labels are kept on key-point slides by ending or moving scenes.
  - **Library extension, 2026-10-06:** CONFIRMED and documented (ANIMATION_STYLE.md section 7): a paragraph read over a scene is not drawn; a risk label belongs on a key point before the scene or after `end`.

## From V045 to V055
- rebase scene: same limits as above (not used in V052 to V055; needs counts per side, real IDs, a stop after one copy, --onto ranges).
  - **Library extension, 2026-10-06:** DONE. Counts per side, real IDs, `stop=N` (steps `conflict`, `continue`, with `rebase_head=on`), `upstream=` and `upstream_only=` for `--onto`, `orig_head=on`.
- reflog scene: command (HEAD~2), count of dropped commits and reflog lines are fixed (V047 uses HEAD~1 and its own subjects).
  - **Library extension, 2026-10-06:** DONE. `back=1`, `rows=...`, `cmd_reset=` for other wording.
- trees scene: reset step only from a clean tree, no --soft/--mixed variants (V047's three modes); `chips=` only with `steps=setup`; no step for a second edit (V046); `commits=` needs two IDs even when one is drawn; no steps for `restore --staged` or `--source`.
  - **Library extension, 2026-10-06:** DONE. `state=2,2,1` starts from any state; `reset=soft|mixed|hard` and the steps `reset-soft`, `reset-mixed`, `reset-hard`; `edit2`; `unstage` (`restore --staged`); `restore-source`; one ID in `commits=`; `chips=` works with any steps.
- graph scene: no free-text notes on a commit (base/ours/theirs in V048, captions in V049, HEAD@{1} and main@{1} in V047); no anonymous commits (V054's generic drawing stays still).
  - **Library extension, 2026-10-06:** DONE. `note:id:text`, `role:id:text`, special chips for `HEAD@{1}` and `main@{1}`; `*`, `*1` are commits nobody names.
- remotes scene: always draws a parent commit; no parameter to draw only the script's two commits (V045).
  - **Library extension, 2026-10-06:** DONE. `start=1` (or the panel form with exactly the script's commits).
- merge scene: cannot show a one-parent three-way result, so "revert is a three-way merge" (V048) has no scene.
  - **Library extension, 2026-10-06:** DONE. `merge: three-way ... as=revert target=id` and `as=cherry-pick`: base, ours and theirs as role pills, a result with one parent.
- No scene for: a rebase todo list (V055), a decision tree (V051).
  - **Library extension, 2026-10-06:** DONE. `todo`, `decide`.
- Lengths: V045, V046 (about +20%) and V047 (+17%) exceed the 15% narration allowance.
  - **Library extension, 2026-10-06:** NOT DONE: not a library matter (narration length is the editors').

## From V034 to V044
- remotes scene: setup always two commits and one fixed six-step story; cannot start with a local commit ahead, show a rejected push, a second branch, a tag, renamed boxes, or commit/push without teammate steps (not used in V038, V041 to V044).
  - **Library extension, 2026-10-06:** DONE. Panel form (`remotes: [your clone] ... || [origin] ...`): a local commit ahead, a rejected push, a second branch, a tag (`tag:name` in both panels), renamed boxes, no teammate. Six-step form: `start=`, `incoming=0`, `names=`.
- graph scene: no state without HEAD (unborn branch after fetch in V038, before-state in V037, prune demos in V043); no per-commit mark such as pass/FAIL (V037 diagram kept still); no two refs with the same short name (V044 impostor local origin/main); no side-by-side panels; no placeholder for a commit whose ID is never printed (V041 labels it `yours`: confirm or fix).
  - **Library extension, 2026-10-06:** DONE. `HEAD=none`; marks `pass:id`, `fail:id`; the same short name twice (`remote:origin/main branch:origin/main#local`); panels with `||`; `?yours` is a commit whose ID is never printed (V041: replace the commit named `yours` by `?yours`).
- merge scene: `merge_id` needs an ID. trees scene: commit step cannot show a merge commit. hash scene: text only, no binary case (V035).
  - **Library extension, 2026-10-06:** DONE. `merge_id=none`; `trees ... merge=on`; `hash ... badge=binary`.
- No scene for: refspec name mapping, the wire conversation, the seven-step push with two gatekeepers (V041), the lease timeline in three columns (V042), pruning (V043).
  - **Library extension, 2026-10-06:** DONE. `push` (refspec, the two gatekeepers, `lease=expected,actual` in three columns); the wire conversation = `flow`; the seven steps = `gates`; pruning = `prune:` in the panel form (`drop:origin/old`).
- V037 line 232 starts with "2048." which Markdown may read as a list item: check how it renders in the storyboard.
  - **Library extension, 2026-10-06:** NOT DONE: outside the animation library (how the storyboard reads Markdown); not examined in this pass.
- A full check_course run reports one problem under video/production/.cache/selftest/: exclude that cache from the checker or clean it.
  - **Library extension, 2026-10-06:** DONE. `tools/check_course.py` skips `.cache` directories.

## From V078 to V088 (scene share only 5 to 13 percent)
- graph: annotated vs lightweight tags look the same, no tag-object node (V080, V082); no mark for a damaged/missing object, no trees under commits (V078); cannot remove a commit or distinguish "a reflog still names it" from "nothing names it" (V079 ladder stays ASCII); fewer than two commits refused, so no depth-1 clone (V082); one repository per picture and no same tag name on two commits (V081); no role letters alongside IDs (V085).
  - **Library extension, 2026-10-06:** DONE. `atag:name#tagid` draws the tag object between the tag and the commit (scene `tags` for the pair); `damaged:id`, `missing:id`; `tree:id:...`; `gone:id` removes a commit; `reflog:id` (only a reflog names it) against `ghost:id`; one commit is a graph; panels for several repositories; the same tag in two panels, or `v1.0` and `tag:v1.0#2` in one; `role:`.
- remotes: always two commits; no tags, tag push/fetch, CI clone or bundle box. objects: no TAG card or missing-object mark. reflog: hard-coded. hash: at most five content lines (V086 needs seven).
  - **Library extension, 2026-10-06:** DONE. Panel form with tags and a third box (CI clone, bundle); `objects ... cards=tag:...` with `missing=` / `damaged=`; `reflog` parameters; `hash` takes eight lines.
- trees: history strip cannot be hidden (V087, V088 pass `commits=before,after`, undocumented: confirm or add a parameter); content cannot change form on the way out (smudge filter, eol=crlf); restore always drawn destructive (V087 shows a harmless restore in red: fix); no `commit -a`; no two worktrees on one repository (V083, V084).
  - **Library extension, 2026-10-06:** DONE. `history=off` (V087, V088: replace `commits=before,after`); `forms=CRLF,LF,LF`; `safe=restore`; step `commit-a`; two worktrees = `stores`.
- No scene for: the recovery ladder and object deletion, several worktrees around one repository, a bundle, attribute precedence, rr-cache preimage/postimage, anatomy of a describe string, a shallow clone, file-level base/ours/theirs/result for merge drivers.
  - **Library extension, 2026-10-06:** DONE: `ladder`; worktrees, a bundle = `stores`; attribute precedence = `match` or `layers`; a shallow clone = `shallow:` with `absent:`; base/ours/theirs/result at file level = `walk`. BY RECIPE: rr-cache preimage and postimage = `stores`. NOT DONE: the anatomy of a describe string (no scene that takes one string apart; a `walk` with one row is the nearest).
- V079 draws a commit as a ghost while a reflog still names it (glossary calls it reachable): make the picture say "reachable only from the reflog".
  - **Library extension, 2026-10-06:** DONE. `reflog:id` in a graph, `lost=reflog` in `reflog`: dashed, not faded.

## From V089 to V099 (scene share 1 to 13 percent)
- rebase/reflog: fixed, unusable (V089, V092, V098). remotes: always four commits, skipping steps leaves a gap (V090, V093, V096). pr: review row, "#42" and letters cannot be hidden (V090). ci: fixed `ci.yml`, `job: test`, `ubuntu-latest` (V090, V093, V096).
  - **Library extension, 2026-10-06:** DONE. See above for `rebase` and `reflog`; `remotes ... incoming=0` (no gap), any number of `ids=`; `pr ... review=off number=off letters=off` (or real IDs with `base_ids=`, `commits=`); `ci ... file=off job=off runner=off`.
- trees: needs two IDs; no "no commit yet" form (V099). sandbox: `real=` and `inside=` exist in code but are undocumented. graph: no label kind for "the commit the superproject records"; no "no HEAD in this picture" (V098 uses HEAD=main with main not drawn: verify rendering). objects: no gitlink (mode 160000) or sub-tree entries (V091).
  - **Library extension, 2026-10-06:** DONE. `commits=id`, `commits=none`; `sandbox` parameters documented; `HEAD=none` (V098: write it instead of `HEAD=main`); `link:id>id:label` across panels and `role:` for the commit the superproject records; `objects ... cards=` with gitlink and sub-tree rows.
- No scene for: a hook timeline / gate (V089, V090), a separate LFS store with pointer and transfer (V095, V096), a submodule (superproject pointer into a second repository), a subtree.
  - **Library extension, 2026-10-06:** DONE. `hooks:` (= `gates`), `stores` for LFS, `submodule:` (two panels and `link:`), `subtree:` (graph).
- V090 and V094 infer parent links not printed in transcripts (f1edb7c child of 18e1b38; c2dc1b7 parent c77d389): verify in the lab sandboxes.
  - **Library extension, 2026-10-06:** NOT DONE: needs the lab sandboxes; outside the library.
- Contraction pass in V090 to V099 was only pattern-checked: spot-check.
  - **Library extension, 2026-10-06:** NOT DONE: outside the library.

## From V067 to V077 (scene share 0 to 20 percent)
- graph: no marks on a commit (good/BAD/skip for bisect, `<` `>` `=` for range comparisons, dangling, HEAD@{1}, a shaded range), so V067, V068, V071, V072, V074 drawings stay still; no elision or off-picture commit, max 12 commits (V071 shows 6 of 20 candidates); no chip kind for refs/bisect/*; HEAD cannot be hidden; title persists when a scene returns (V067); ghost style means "unreachable" but is used for "not visited by --first-parent" (V067, V072): add a distinct dim style.
  - **Library extension, 2026-10-06:** DONE. `good:` `bad:` `skip:` `left:` `right:` `same:` `dangling:` and `mark:word:id`; `range:`; `...14` elision and up to 48 commits, `view:ids` scrolls; `refs/bisect/*` is a special chip; `HEAD=none`; `title:` per state and `title_<step>=`; `dim:id` for "not visited".
- trees: no second edit after add, no "index entry gone, blob stays" (V077). remotes: no forced update / rejected push (V077). merge: HEAD chip and merge-base note cannot be hidden, no commit after the merge (V072).
  - **Library extension, 2026-10-06:** DONE. Steps `edit2` and `forget` (`git rm --cached`); panel form of `remotes` for a forced update or a rejected push; `merge ... head=off base=off after=1`.
- No scene for: blame (per-line attribution), pickaxe, rename chain, bisect exit-code protocol, the retention timeline, stash as ref plus reflog, the recovery decision tree.
  - **Library extension, 2026-10-06:** DONE: `blame` (with `after=` for a rename or an ignored reformatting commit), `stash`, `decide`, `bisect`. BY RECIPE: the bisect exit-code protocol = `walk`; the retention timeline = `ladder` with your own `rungs=`; a rename chain = a graph with `note:` per commit. NOT DONE: pickaxe (no scene shows a string's count per commit; a graph with `mark:` is the nearest).
- Verify in a sandbox: V075 and V076 move ORIG_HEAD to the pre-reset tip after a second reset (transcripts do not print it). V076's opening assumes the incident copy has main at cad5d75.
  - **Library extension, 2026-10-06:** NOT DONE: outside the library.
- `tools/video_animplan.py` changed at 14:34 without a matching update of ANIMATION_STYLE.md: reconcile.
  - **Library extension, 2026-10-06:** DONE. ANIMATION_STYLE.md was rewritten as the complete reference and is checked by the self-test (every example must parse).

## Batch 4, V111 to V121 (reported 2026-10-06 by the director-editor)

Scripts with no fitting scene: V114 (gate briefing: plumbing map, pack listing), V116 (forks: one object store, two sets of refs, one set deleted), V119 (tokens: token table, token-in-URL flow), V121 (two identities: directory → include → alias → key routing). V115, V117, V118 have only one short scene each.

- **trees:** cannot draw a file as absent from one box (sparse checkout: path in the index, not on disk); `commits=` needs two IDs even when one is drawn; no H/S (skip-worktree) flag on an index card; no sparse-index form.
  - **Library extension, 2026-10-06:** DONE: `in=index,head` with `absent=not_on_disk`; one ID; `badges=-,skip-worktree,-`. NOT DONE: a sparse-index form (a directory entry in the index).
- **pr:** "#42", "approved by a teammate", "tests"/"lint" and commit letters A to M cannot be hidden or replaced with real IDs (ruled it out for V115 and V117).
  - **Library extension, 2026-10-06:** DONE. `number=off`, `review_text=`, `review=off`, `check_names=`, `base_ids=`, `commits=`, `letters=off`.
- **ci:** workflow file, job and runner are always drawn (V113 names none).
  - **Library extension, 2026-10-06:** DONE. `file=off job=off runner=off`.
- **objects:** needs real tree and blob IDs; no "blob not present" mark (blobless clone, V113).
  - **Library extension, 2026-10-06:** DONE. `cards=` with `missing=id`.
- **graph:** no state without HEAD; no "absent from this clone" style (ghost means unreachable, wrong for a shallow clone); no per-state caption; cannot show two refs with the same short name.
  - **Library extension, 2026-10-06:** DONE. `HEAD=none`, `absent:id` (hatched), `say:`, `name#x`.
- **merge:** no mode that stops at the merge base by design; HEAD chip on `main` cannot be hidden.
  - **Library extension, 2026-10-06:** DONE. `steps=setup,merge-base` is the way to stop by design (the framing follows the steps that play); `head=off`.
- **hash:** IDs must be short, so SSH fingerprints are cut to 8 characters; `alt=` changes only the last line.
  - **Library extension, 2026-10-06:** DONE. IDs longer than 16 characters are set on two lines; `change=N`.
- **sandbox:** steps without cue words spread evenly, so the third box arrives late in a one-paragraph scene.
  - **Library extension, 2026-10-06:** DONE. `pace=quick`, or `at_<step>=percent`.
- **step:** cannot rewind a returned scene to its first step (V120 had to repeat the full `hash` tag).
  - **Library extension, 2026-10-06:** DONE. `**[ANIMATION]** replay: hash`.
- **No scene at all for:** a fork network; Git data inside a GitHub database (Git layer versus platform objects); "highest grant wins" (permission levels); the credential-helper sequence (get, store, erase against 401/403); a token's reach and lifetime; SSH's two proofs (host key, user key); `~/.ssh/config` resolution; directory-keyed identity routing (`includeIf`); a sparse index; a partial clone.
  - **Library extension, 2026-10-06:** DONE: fork network = `stores` or `forks:` panels; Git layer and platform objects, permission levels = `layers` (`winner=`); the credential helper, SSH's two proofs = `flow`; `~/.ssh/config` = `match wins=first`; `includeIf` = `match`; a partial clone = `objects ... missing=` and `absent:`. PARTLY: a token's reach = `stores`, but no scene draws its lifetime on a time axis. NOT DONE: a sparse index.

## Batch 4, V100 to V110 (reported 2026-10-06 by the director-editor)

Scripts with almost no scene: V108 (commit-graph file, Bloom filters, multi-pack-index, bitmaps: none), V104 (maintenance tasks, geometric repacking, cruft packs: 2%), V107 (SHA-1 versus SHA-256 layouts: 4%), V102 (packs and delta chains: 5%).

- **objects:** cannot show tree entries that are trees or gitlinks, modes, more than four entries, a commit card with parents, a tag object, or entries without IDs (V100, V102, V108).
  - **Library extension, 2026-10-06:** DONE. `cards=kind:id:row+row,...`: any rows (modes, trees, gitlinks, parents, rows without IDs), a `tag` card, up to nine cards.
- **graph:** no caption or command line (`say_`/`cmd_` are dropped for graphs); no free-text note on a commit (`HEAD^2`, `HEAD@{1}`, "in packed-refs", a generation number) (V101, V103, V105, V108); no documented way to hide HEAD (with labels and no `HEAD=`, HEAD attaches to the first label, which forced label-free graphs in V100, V102, V104); cannot place a pseudoref on two commits (`MERGE_HEAD`, V105) or remove a commit (pruned objects, V103, V104); needs distinct styles for "behind a shallow boundary" and "reachable only through the reflog" (ghost was used for both in V109 and V103).
  - **Library extension, 2026-10-06:** DONE. `say_`/`cmd_` work in graphs, and `say:` / `cmd:` per state; `note:`, `sub:id:gen_3`; `HEAD=none` documented; `MERGE_HEAD` and `special:MERGE_HEAD#2`; `gone:id`; `absent:` against `reflog:` against `ghost:`.
- **hash:** one `fn` for both cards, so two hash functions cannot be compared; a 64-digit ID does not fit; `ids=` needs two values even when only `one, same` play.
  - **Library extension, 2026-10-06:** DONE. `fn2=`; 64 digits on two lines; one value in `ids=`.
- **reflog:** commands, reflog lines and letters are fixed (matched neither V103 nor V105).
  - **Library extension, 2026-10-06:** DONE. See `reflog` above.
- **remotes:** exactly one new server commit, letters unless four IDs are given, a "teammate pushes" caption (V109's fetch brings two commits).
  - **Library extension, 2026-10-06:** DONE. `incoming=2`, any `ids=`, `say_teammate_push=`; or the panel form.
- **trees:** always starts with the file in all three boxes, so a new file cannot be shown (V106); no step for a deleted or rebuilt index.
  - **Library extension, 2026-10-06:** DONE: `in=wt` (a new, untracked file), `commits=none`. PARTLY: a deleted or rebuilt index is shown per file with the steps `forget` and `unstage`; there is no picture of the index file as a whole.
- **A scene tag with no `step:` tag** plays all its states over the following paragraphs (had to be pinned in V105, V109): document this.
  - **Library extension, 2026-10-06:** DONE. Documented in section 7.
- **Missing scenes:** packs and delta chains; pack sizes over several maintenance runs; a task trace; a per-commit filter list (Bloom filter / changed-path); the commit-graph file with generation numbers; two `.git` directory layouts side by side; a bundle file with header and prerequisite.
  - **Library extension, 2026-10-06:** DONE: packs and deltas, two `.git` layouts, a bundle = `stores`; pack sizes = `bars`; a task trace, a changed-path filter list = `walk`; generation numbers = `sub:id:gen_3` in a graph. No dedicated scene for the commit-graph file as a file (use `stores`).

## Batch 4, V122 to V133 (reported 2026-10-06 by the director-editor)

Low scene share: V122 (authentication failures, 2%), V129 (auto-merge and merge queue, 8%), V131 and V132 (rules, status-check traps, 6–8%). V128 keeps an ASCII side-by-side of the three merge methods.

- **pr:** no parameter for commit IDs or commit count (always A–D, two feature commits); always two check rows; default number #42 and fixed "approved by a teammate"; no step for "push after approval", "approval dismissed", "2 of 3 approvals"; the merge step always draws a merge commit (no squash, no rebase). Not usable in V123–V129, V131–V132.
  - **Library extension, 2026-10-06:** DONE. `commits=`, `base_ids=`, up to four `check_names=`, `number=`, `review_text=`, `approvals=2/3`, steps `push-again`, `dismissed`, `re-approve`, `method=squash|rebase`.
- **ci:** no `merge_group` event; no "workflow skipped by a path filter, check stays pending" state; a single job only (V132 needs a final job that depends on the others); always shows `ci.yml`, `ubuntu-latest` and a step list.
  - **Library extension, 2026-10-06:** DONE. `merge_group`; `result=skipped skip_text=`; several jobs with needs = `run`; `file=off job=off runner=off`, and `steps=event,workflow,result` leaves the step list out.
- **remotes:** no fork topology (upstream, fork, clone) for V127; no "push refused by a server rule" step for V131; `steps=` cannot skip the teammate push without leaving a gap.
  - **Library extension, 2026-10-06:** DONE. Three panels; `rejected:id` or a `gates` scene for the server rule; `incoming=0`.
- **rebase:** fixed letters and exactly two commits.
  - **Library extension, 2026-10-06:** DONE.
- **graph:** no annotation, bracket or range marker (two-dot versus three-dot in V123, "base..head = four commits" in V125); no tag object drawn between a ref and its commit (V130); no "approved here" marker (V124); no spacing control for long labels (three `gh-readonly-queue/main/pr-N` labels on adjacent commits overlap, V129); three graphs side by side (V128).
  - **Library extension, 2026-10-06:** DONE. `range:` and `range2:` (two dots, three dots), `atag:`, `mark:approved_here:id`, `dx=` for long labels on neighbouring commits (not automatic), three panels (`methods:` stacks them).
- **Missing scenes:** rule evaluation as a gate (old ID, new ID, ref); ruleset layering and aggregation; bypass modes; the pull-request lifecycle state diagram; the authentication relay (client, server front door, repository rules); the merge queue with its temporary branches.
  - **Library extension, 2026-10-06:** DONE. `gates` with `packet=old_new_ref` and `bypass`; `layers` (`ruleset:`); `lifecycle:` (give it `grid=`); `flow` for the authentication relay; the merge queue = `queue:` graph in rows with `dx=`.

## Batch 5, V134 to V144 (reported 2026-10-06; detailed picture lists per video are in `authoring/scene-wishes/VNNN.md`)

Eight of eleven scripts have no scene (rules, CODEOWNERS, signatures, gh and the API, gate briefing, events and contexts, shells). Wanted:
- a commit graph without HEAD, with unlabelled commits, a per-commit mark (signature result letter, pass or fail) and a bracket or shaded range;
  - **Library extension, 2026-10-06:** DONE. `HEAD=none`, `*1`, `mark:G:id` / `pass:` / `fail:`, `range:`.
- a commit or tag "object card" whose lines can be marked signed or not signed (what a signature covers);
  - **Library extension, 2026-10-06:** DONE. `objects ... cards=... signed=id:1-4 signed_text=`.
- a "numbered file lines against one path" scan for CODEOWNERS (last match wins);
  - **Library extension, 2026-10-06:** DONE. `match` (`codeowners:`) with `numbers=`.
- a two-lane "Git says / GitHub says" sheet;
  - **Library extension, 2026-10-06:** BY RECIPE. `walk` with two columns, or `layers` with two layers; no dedicated two-lane scene.
- a CI picture with a "no run created" state, two jobs, and the workflow file underneath the steps;
  - **Library extension, 2026-10-06:** PARTLY. `ci ... result=skipped`; two jobs = `run`. NOT DONE: the workflow file drawn underneath the steps.
- a pull-request card that can be approved, green and still blocked.
  - **Library extension, 2026-10-06:** DONE. `pr ... block=Rule:_...`.

## Round 3 (from the scene pass of V111 to V121, 2026-10-06): open
- `stores`, `walk`, `cards`, `flow`, `layers`, `gates` draw no caption line; `say_<step>=` is accepted without effect.
- `stores` cannot remove or restyle a row in a later step.
- `match` `header=` does not turn `_` into a space.
- `flow`: a label containing a colon is rejected ("not understood").
- Arrow labels between neighbouring `stores` boxes overlap rows when longer than about ten characters.
- `decide` edge labels wrap after about six characters.
- `python3 tools/video_animtest.py --help` runs the self-test instead of printing help.
