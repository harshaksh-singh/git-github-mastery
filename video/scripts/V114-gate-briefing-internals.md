# V114: Gate briefing: Internals

- **Part.** 4: Git internals
- **Module.** 18
- **Planned minutes.** 10
- **Prerequisites.** V107, V110, V113
- **Textbook sections.** The gate rules in [`assessments/README.md`](../../assessments/README.md); the "Interview questions" sections of [Chapter 3](../../textbook/ch03-git-internals.md), [Chapter 24](../../textbook/ch24-monorepos.md) and [Chapter 26](../../textbook/ch26-performance.md)
- **Demo scripts.** `labs/ch03/packfiles.sh` (warm-up)

## HOOK

**[ON SCREEN]** "Explain it as: which file, which reader, which failure."

Part 4 of this course asked one kind of question fifteen times: where is it stored, what reads it, and what happens when it is stale or missing? Gate 5, the mastery test for this part, asks the same question, and it asks it of you with no book open.

The typical way to fail the hands-on part isn't a lack of knowledge. It's a habit: opening `.git/refs` and reading a file by hand. You know from three videos of this part why that gives a wrong answer in some repositories. Hold on to that habit. Four commands will replace it.

## INTRODUCTION

Welcome back to Git and GitHub Deep Mastery. Pull up a chair. This is a briefing, not a lesson. It tells you what Gate 5 covers, how it's scored, and how to prepare. I won't open the gate file on screen, and you shouldn't open it either before you sit it. In the words of the gate rules, a gate that has been read is a gate that has been taken.

Everything shown in this video reads state, with one exception in the warm-up: `git gc`, 🟡 CAUTION, as in the packfiles video.

## LEARNING OBJECTIVES

After this video you can:

- State what Gate 5 covers and its threshold of 85.
- Prepare by explaining each storage structure as "what it stores, what reads it, what happens when it is stale or missing".
- Run the hands-on part with plumbing that works in every format.
- Explain maintenance and reachability under questioning.

## CONCEPT

**[ON SCREEN]** The gate table row: Gate 5, Internals, threshold 85, after Module 18.

Gate 5 comes after Module 18. Its threshold is 85. It covers the object database, packfiles, the index format, ref storage, and transfer and scale.

**[ANIMATION]** walk: id=parts columns=part,how,points,70_percent rows=1_Concepts:six_written_questions,_closed_book:30:21|2_Prediction:four_items,_no_terminal:20:14|3_Hands-on_diagnosis:a_broken_repository,_in_the_lab_shell:30:21|4_Oral_interview:six_questions,_each_with_a_follow-up:20:14 mono=off last=70_percent title=Gate_5:_100_points,_threshold_85 at_1=45

**[ANIMATION]** step: 1

Every gate has 100 points in four parts with fixed weights. Part 1, Concepts: 30 points, six written questions of 5 points each, closed book, no terminal. Each requires a mechanism: which objects, refs, files or rules are involved, and what reads or writes them.

**[ANIMATION]** step: 2

Part 2, Prediction: 20 points, four items. You get the commands that built a state, and you predict the output of further commands and the new state. No terminal, and object IDs aren't asked for.

**[ANIMATION]** step: 3

Part 3, Hands-on diagnosis: 30 points. For this gate it's a repository that a script builds in a broken state, with a report that is incomplete and partly wrong, and you work in the lab shell.

**[ANIMATION]** step: 4

Part 4, Oral interview: 20 points, six questions asked one at a time, each with a follow-up, spoken, with no terminal and no notes.

The pass rule has two conditions. The threshold overall, 85 here, and at least 70 percent in every part: 21 of 30 in Concepts, 14 of 20 in Prediction, 21 of 30 in Hands-on, 14 of 20 in Oral. A total above the threshold with one part below 70 percent is a miss.

**[ANIMATION]** gates: id=hands packet=Part_3 gates=generator:done:variant_A:prints_the_path_of_the_sandbox|SYMPTOMS.md:done:lab_shell:read_it|command_log:done:you:every_command|check.sh:done:at_the_end:when_you_think_you_are_done title=How_the_hands-on_part_runs at_1=8 at_2=35 at_3=2 at_4=18

**[ANIMATION]** step: 2

How the hands-on part runs. From the course root you run the generator of variant A, and it prints the path of the sandbox. You open the lab shell there and read `SYMPTOMS.md`. You don't read `generate.sh`, which is the answer to "what happened", or `check.sh`, which lists the end state line by line.

**[ANIMATION]** step: 4

You keep a log of every command. When you think you're done, you run `check.sh`. The generator uses the fixed lab clock, so the commit IDs in your sandbox equal the IDs in the answer key. Commits you make in the lab shell use the real clock and get other IDs.

**[ANIMATION]** end

The oral part needs a second person or the tutor. If you rehearse alone, record yourself and score the recording the next day.

Why are the questions shaped this way? Because the goal of the course is diagnosis from first principles. A command recited is worth little. A mechanism, stated with the file, the reader and the failure, is what lets you answer a question you haven't seen.

## MENTAL MODEL

Prepare with one sentence pattern, applied to every structure of this part:

"It stores this. This reads it. If it is stale, this happens. If it is missing, this happens."

**[ANIMATION]** walk: id=pattern columns=structure,stores,read_by,stale,missing rows=pack_index:object_IDs_with_offsets:every_object_lookup:cannot_be:Git_warns,_rebuild_it|commit-graph:parents,_generation_numbers,_filters:history_walks,_path-limited_logs:slower,_not_wrong:Git_reads_the_objects mono=off title=One_sentence_pattern at_1=12

**[ANIMATION]** step: 1

Try it on the pack index, the lookup file beside a pack. It stores object IDs with offsets into a pack. Every object lookup reads it. It can't be stale, since a pack never changes. If it's missing, Git warns, and you rebuild it from the pack, because it's derived data.

**[ANIMATION]** step: 2

Try it on the commit-graph. It stores parents, generation numbers and changed-path filters. History walks and path-limited logs read it. Stale: slower, not wrong. Missing: Git reads the objects.

If you can do that for objects, packs, refs, the index and each cache, you're ready for Parts 1 and 4. The pattern breaks only where data is primary: for an object or a reflog, "missing" has no rebuild, only another copy.

**[ANIMATION]** end

Try it now, thirty seconds, on paper. Write five words: objects, packs, refs, index, caches. Under each, write primary or derived. I'll wait.

**[PAUSE]**

## DIAGRAM

**[DIAGRAM]** One slide, five boxes. Under each, the plumbing that reads it.

```text
  +-------------+  +-------------+  +-------------+  +-------------+  +------------------+
  |   objects   |  |    packs    |  |    refs     |  |    index    |  |      caches      |
  +-------------+  +-------------+  +-------------+  +-------------+  +------------------+
   git cat-file     git count-       git for-each-    git ls-files     git commit-graph
     -t -s -p -e      objects -v       ref              --stage          verify
   git cat-file     git verify-      git show-ref     git ls-files     git multi-pack-
     --batch-all-     pack -v        git rev-parse      --debug          index verify
     objects        git show-index     --verify       git diff-files   git maintenance
   git fsck                          git symbolic-                       is-needed
                                       ref
   primary data     .pack primary,   primary data     derived, except  derived: delete
                    .idx derived     (and reflogs)    staged content   and rebuild
```

Five boxes: objects, packs, refs, index, caches. Under each, the commands that read it in every format. Nowhere on this slide is there a `cat` of a file under `.git`.

Now check your five answers against the bottom line. It's the distinction from the first page of Chapter 3: before you delete or repair anything under `.git`, decide whether it's primary or derived data. An index or a pack index can be rebuilt. An object or a reflog can't.

## LIVE TERMINAL DEMO

**[TERMINAL]** A warm-up, not gate material. Replay the packfiles demonstration and narrate it yourself, aloud, before I do.

```bash
labs/run ch03/packfiles
```

```bash
git count-objects -v
```

Six commits, one file of 200 lines changed five times, one small configuration file. Say the `count` before it appears, and say why. I'll wait.

**[PAUSE]**

<!-- snippet: ch03/packfiles/01-loose -->
```text
$ git log --oneline
14fbba9 Relax case 150 to two sentences
d076308 Relax case 120 to two sentences
5c0b0dc Relax case 90 to two sentences
709d5d8 Relax case 60 to two sentences
213918f Relax case 30 to two sentences
609e81f Add evaluation cases
$ wc -l eval/cases.jsonl
     200 eval/cases.jsonl
$ git count-objects -v
count: 25
size: 100
in-pack: 0
packs: 0
size-pack: 0
prune-packable: 0
garbage: 0
size-garbage: 0
```
<!-- /snippet -->

Twenty-five, all loose.

```bash
git gc
git count-objects -v
```

State what `git gc` changes in `.git`, in one sentence, with the file names. Say it out loud.

**[PAUSE]**

<!-- snippet: ch03/packfiles/02-gc -->
```text
$ git gc
$ git count-objects -v
count: 0
size: 0
in-pack: 25
packs: 1
size-pack: 4
prune-packable: 0
garbage: 0
size-garbage: 0
$ find .git/objects -type f | sort
.git/objects/info/commit-graph
.git/objects/info/packs
.git/objects/pack/pack-8027c3005e9ed6293511e1bef76969aa63a131bc.idx
.git/objects/pack/pack-8027c3005e9ed6293511e1bef76969aa63a131bc.pack
.git/objects/pack/pack-8027c3005e9ed6293511e1bef76969aa63a131bc.rev
```
<!-- /snippet -->

Nothing loose now, and one pack holds all 25.

```bash
git verify-pack -v .git/objects/pack/pack-*.idx
```

Quick quiz, two options. Which version of the file is stored whole, the newest or the oldest? And how will the listing show it? Say it out loud.

**[PAUSE]**

<!-- snippet: ch03/packfiles/03-verify-pack -->
```text
$ git verify-pack -v .git/objects/pack/pack-*.idx
14fbba9f81a145d88e699ad6379b7844b71e855a commit 232 163 12
d076308a75023ff48e849cd91e1acac4fce7f4c6 commit 232 166 175
5c0b0dc76a1661cca61de1475a80959793e9280c commit 231 164 341
709d5d8beab89236b8649acadca336e7406c6132 commit 231 163 505
213918f93a4e5886620977a101f7181e57459140 commit 231 165 668
609e81f2752953bc7efa6215b74b1d08bde2ceef commit 173 128 833
a4e58256c921e15fecaaaf744fbdb04b37907a40 blob   16789 1372 961
26489f627fb36b56d87f8b615855f57c7888fd60 blob   17 27 2333
794774c4549fba17c4a64943e946feeac7c0ed4d tree   31 40 2360
89f3a9862e1b2373ab6e9bcac1e76d158b8c478f tree   78 85 2400
8c9b4e17e9e4d4e2aa09bd48ba220549944e06d2 tree   31 40 2485
5a92fde4e91ed06f182b9a45d78fa51d92e87e7f tree   78 85 2525
739088cda5ca15c1fd59dc40238f8852f7f677de blob   22 35 2610 1 a4e58256c921e15fecaaaf744fbdb04b37907a40
59ded879fc1920533dd82f4e9f2a55ecc7480549 tree   31 41 2645
9513db28fdebd67318d477e402e045a33336949c tree   78 84 2686
d77675f2a7b00158d41dc879b35011a742015f48 blob   17 30 2770 2 739088cda5ca15c1fd59dc40238f8852f7f677de
b19c9a4c02f3742eab5f0ccfc40e1fc2b4f66b3c tree   31 40 2800
5b0701b0d0b031208d1e4972513376c5cd0ae392 tree   78 85 2840
d900a91b8bd7c1bafc34c1c8baef1c92f5af3832 blob   22 35 2925 3 d77675f2a7b00158d41dc879b35011a742015f48
be320f0afa9a2877aa5134ee84b85c6ada640031 tree   31 40 2960
b99c6ada4476e39a26ae54f9ab22db3aec8d1f1d tree   78 84 3000
782b8e9b7662fd152695234c4ba08fde34c18f73 blob   18 30 3084 4 d900a91b8bd7c1bafc34c1c8baef1c92f5af3832
b803d0495a5e56f35f19109a922d0ca78f64c184 tree   31 41 3114
a1356effbbb0a03fd3fa3115791bcf98670794b4 tree   78 84 3155
0928d48c558a6457e11c9fa47f347fb2a190259f blob   22 35 3239 5 782b8e9b7662fd152695234c4ba08fde34c18f73
non delta: 20 objects
chain length = 1: 1 object
chain length = 2: 1 object
chain length = 3: 1 object
chain length = 4: 1 object
chain length = 5: 1 object
.git/objects/pack/pack-8027c3005e9ed6293511e1bef76969aa63a131bc.pack: ok
```
<!-- /snippet -->

**[ANIMATION]** walk: id=chain columns=version_of_cases.jsonl,stored_as,bytes_in_the_pack rows=a4e58256_(newest):whole:1372|739088cd:delta,_chain_1:35|d77675f2:delta,_chain_2:30|d900a91b:delta,_chain_3:35|782b8e9b:delta,_chain_4:30|0928d48c_(oldest):delta,_chain_5:35 marks=1.2:ok title=One_pack,_six_versions pace=quick

**[ANIMATION]** step: 6

The newest, `a4e58256`. Each older version's line adds a chain depth and the ID of its base.

Last one. The oldest version costs 35 bytes in the pack. What does `git cat-file -p` return for it, and what does that tell you about "Git stores snapshots"? Make your prediction.

**[PAUSE]**

<!-- snippet: ch03/packfiles/04-snapshots-intact -->
```text
# Logical size, size on disk, and delta base of each version of the file, newest first:
$ git log --format='%H:eval/cases.jsonl' | git cat-file --batch-check='%(objectname) %(objectsize) %(objectsize:disk) %(deltabase)'
a4e58256c921e15fecaaaf744fbdb04b37907a40 16789 1372 0000000000000000000000000000000000000000
739088cda5ca15c1fd59dc40238f8852f7f677de 16788 35 a4e58256c921e15fecaaaf744fbdb04b37907a40
d77675f2a7b00158d41dc879b35011a742015f48 16787 30 739088cda5ca15c1fd59dc40238f8852f7f677de
d900a91b8bd7c1bafc34c1c8baef1c92f5af3832 16786 35 d77675f2a7b00158d41dc879b35011a742015f48
782b8e9b7662fd152695234c4ba08fde34c18f73 16785 30 d900a91b8bd7c1bafc34c1c8baef1c92f5af3832
0928d48c558a6457e11c9fa47f347fb2a190259f 16784 35 782b8e9b7662fd152695234c4ba08fde34c18f73
# The oldest version sits at the end of a five-step chain and still reads back whole:
$ git cat-file -p 0928d48c | wc -l
     200
$ git cat-file -p 0928d48c | sed -n 30p
{"id": 30, "prompt": "Summarise ticket 30 in one sentence", "expected_tokens": 30}
$ git cat-file -p HEAD:eval/cases.jsonl | sed -n 30p
{"id": 30, "prompt": "Summarise ticket 30 in two sentences", "expected_tokens": 30}
```
<!-- /snippet -->

**[ANIMATION]** step: chain.6

All 200 lines. The pack saves space, and the object you read back is still whole.

**[ANIMATION]** end

If you could narrate those four snippets without the book, with the columns named, you have the level of Part 2 of the gate. If you hesitated, redo Labs 16.1 and 16.2 before you sit it.

**[ANIMATION]** cards: id=tools question=Four_instruments_for_the_hands-on_part cards=git_cat-file_--batch-all-objects_--batch-check:every_object|git_for-each-ref:every_ref|git_count-objects_-v:storage|git_fsck:connectivity_and_integrity at_1=12 at_2=38 at_3=50 at_4=62

**[ANIMATION]** step: 4

For the hands-on part, four commands are your instruments: `git cat-file --batch-all-objects --batch-check` to see every object, `git for-each-ref` to see every ref, `git count-objects -v` for storage, and `git fsck` for connectivity and integrity. They work whether refs are loose, packed or in reftable. Those four replace the habit from the hook.

## COMMON MISTAKES

Five mistakes to watch for.

1. Reading `.git/refs` or `packed-refs` by hand in the hands-on part. Root cause: a ref can be in one of several storage locations; only plumbing gives the current value in every format.
2. Running a prune or `git gc --prune=now` to "clean up" a `dangling` line. Root cause: dangling describes fsck's starting points; the prune destroys what recovery needs.
3. Answering a concept question with a command. Root cause: the gate asks for a mechanism: which file, which reader, which failure.
4. Passing the total and missing a part. Root cause: the pass rule also requires 70% in each of the four parts.
5. Opening `generate.sh` or `check.sh` first. Root cause: they are the answer to "what happened" and the list of end conditions.

## PRODUCTION EXAMPLE

Now, out of the lab. Think of the gate as a rehearsal of a real hour. A build server's repository misbehaves. The report from the person who noticed is incomplete and partly wrong. Your CTO wants the root cause, the lowest-risk fix and proof that it worked. In that hour you wouldn't open files under `.git` with an editor. You'd count objects, list refs through Git, run `git fsck`, decide what is primary and what is derived, and repair only derived data without a second thought. Part 3 of the gate is that hour, in a sandbox.

## PRACTICE EXERCISE

Your turn. Redo the three Level 4 exercises of Modules 16 to 18 in [`exercises/m16-m18-internals.md`](../../exercises/m16-m18-internals.md): Exercise 16.9, "Removed from history, and still there". Exercise 17.9, "Not a git repository". And Exercise 18.9, "The clone that believes it is up to date". For each, write your diagnosis before you type the first command, and keep a log of every command, as the gate requires.

Then take Gate 5: [`assessments/gate-5-internals.md`](../../assessments/gate-5-internals.md), in one sitting, parts in order.

## INTERVIEW QUESTION

Question 65 of the CTO question bank:

> "How does Git store data?"

**[PAUSE]**

It is the broadest question of the part, and it has a follow-up about why four hundred versions of a large line-oriented file are not four hundred copies on disk, and when that argument fails. A strong answer is layered: objects and how they are named, then how they are stored loose and in packs, then names, then the index. It keeps the object level and the storage level apart, and it knows the limits of delta compression. Give it in two minutes, then give it in thirty seconds.

## RECAP

Let's land this.

You should now be able to say:

- Gate 5 covers the object database, packfiles, the index format, ref storage, transfer and scale; the threshold is 85, with at least 70% in each part.
- For every structure: what it stores, what reads it, what happens when it is stale or missing.
- In the hands-on part, read state through plumbing and keep a command log.
- Primary data cannot be rebuilt; derived data can.

## HOMEWORK

Before the gate: answer the "Interview questions" sections of Chapters 3, 24 and 26 aloud.

**[ANIMATION]** step: tools.4

You can now say, for every box of this part, what it stores and what reads it. Rehearse out loud before the gate. Next time, the platform: Git data and GitHub objects. Until then, look at the state first and type second. See you in the next one.
