# Speech normaliser: what changed in the text handed to the voice

Generated on 2026-10-07 from all 201 storyboards, by running the builder's own `spoken_chunks()` over every narration beat with the old and the new `speakable()` (no video was built, nothing was rendered).

Only the text given to the voice changed. Scripts, storyboards, slides and subtitles are untouched.

## Summary

- Narration beats in the course: 16077. Beats whose spoken text changed: 2058 (12.8 percent).
- Videos whose spoken text changed: 198 of 201. Unchanged: V194, V195, V196.
- Distinct spoken pieces (one voice file each): 16352 after the change, of which 14292 are word for word the same as before and keep their cache file name; 2060 are new and will be spoken again when the video is rebuilt.
- Voice cache today (Tara, 165 words per minute): 7080 of the 16352 pieces are already in `video/production/.cache/tts/`.
- The cache key is unchanged: `sha1(voice|rate|spoken text)`. A changed sentence gets a new file, an unchanged one is reused. The self-test checks this.

## The rules

The full table is in `video/NARRATION_STYLE.md`, section 5, "How symbols are spoken". In short:

| Kind | Before (what the voice was given) | After |
|---|---|---|
| Reflog and upstream suffixes | HEAD at 1 (digits above ten), `@{-1}` as "at dash 1" | HEAD at one, at upstream, at minus one |
| Parent and ancestor suffixes | `^1`, `~1`, `^` and `~` raw when no name stands before them | caret one, tilde one, caret, tilde |
| Peeling | `caret{tree}`, `^{}`, `^{tag}` raw | caret, tree in curly braces; caret, empty curly braces |
| Ranges | `A^..B`, bare `..` and `...` raw | two dots, three dots (the guide's words) everywhere |
| Options | dash X for both `-x` and `-X`; `--` raw; `-fdx`, `-text` raw | dash capital X; dash dash; dash f d x; dash text |
| Globs | `*`, `**`, `refs/heads/*` raw | star, star star, refs heads star |
| Operators | `=`, `==`, `\|`, `+`, `#`, `@@` raw | equals, equals equals, pipe, plus, hash, at at |
| Angle brackets | `<` and `>` deleted or raw | less-than sign, greater-than sign; `a > b` is "a greater than b"; a placeholder `<path>` is still spoken as "path" |
| Conflict markers | `<<<<<<<`, `=======` raw | seven less-than signs, seven equals signs, seven greater-than signs, seven pipes |
| Exclamation mark in code | `! [rejected]`, `!cancelled()`, `fixup!` raw | exclamation mark |
| Square brackets | `[rejected]`, `[remote "origin"]` raw | rejected in square brackets; empty square brackets |
| Variables | `$GIT DIR`, `$1`, `$?` raw | dollar GIT DIR, dollar 1, dollar question mark (`$LAB` and `$HOME` stay "lab" and "home") |
| Format codes | `%gd`, `%GS`, `%(refname:short)` raw | percent g d; percent capital G capital S; percent, refname colon short in parentheses |
| Paths | leading and trailing slash dropped (`/dev/null` as "dev slash null"), `data/`, `actions/checkout` raw | slash dev slash null, data slash, actions slash checkout; refs stay "origin main" |
| Colon in code | `HEAD:path`, `:1:path`, `remote:` raw | HEAD colon path, colon 1 colon path, remote colon; times such as 10:27 untouched |
| Addresses | `git@git hub dot com:acme`, `https://` raw | git at git hub dot com colon acme; H T T P S colon slash slash |
| Underscores | `BISECT_`, `MERGE_*`, `ghp_` raw | BISECT underscore, MERGE underscore star; inside a name an underscore is a space |
| Versions | `v0.2.0`, `2.55.0` left to the voice | v 0 point 2 point 0, 2 point 55 point 0, Git 2 point 55 |
| Course names | `14A.14`, `m06`, `ch14a` left to the voice | 14 A point 14, M 6, C H 14 A |
| The dot argument | `git add .` lost its dot or ran into the next sentence | git add dot |
| Calls | `.lower()`, `success()` with raw parentheses | dot lower, success |
| Risk labels | a label emoji that stands without its word was dropped ("Its risk is : it adds a commit") | the word is spoken: SAFE, CAUTION, DANGEROUS |
| Code spans | the builder gave `speakable()` the text without backticks | it now gives the teleprompter text, so punctuation inside a code span is known to be code |

Not changed: commas, full stops, question marks, clause colons and semicolons, apostrophes, quotation marks, parentheses around words, hyphens inside words, `61%`, `$5`, times, plain decimals, `and/or`, `3/4`.

## 40 examples

**1. HEAD@{n}** (V060, beat 62)

- Script: feat/ingest@{1}, "commit: Add chunker". git cherry-pick 🟡 puts it on the new tip as 82659ee, and an ordinary push publishes it.
- Before: feat ingest at one, "commit: Add chunker". git cherry-pick puts it on the new tip as commit 8 2 6 5, and an ordinary push publishes it.
- After: feat ingest at one, "commit: Add chunker". git cherry-pick CAUTION puts it on the new tip as commit 8 2 6 5, and an ordinary push publishes it.

**2. @{upstream}** (V043, beat 44)

- Script: With only remote.pushDefault set, the push goes to the fork under the branch's own name, but Git 2.55 cannot answer @{push} under push.default=simple.
- Before: With only remote dot push Default set, the push goes to the fork under the branch's own name, but Git 2.55 cannot answer at push under push dot default=simple.
- After: With only remote dot push Default set, the push goes to the fork under the branch's own name, but Git 2 point 55 cannot answer at push under push dot default equals simple.

**3. HEAD~n** (V012, beat 68)

- Script: Stop here. The fix changed the index and the new commit. It didn't change any earlier commit. git show HEAD~1:.env prints the key.
- Before: Stop here. The fix changed the index and the new commit. It didn't change any earlier commit. git show HEAD tilde one:dot env prints the key.
- After: Stop here. The fix changed the index and the new commit. It didn't change any earlier commit. git show HEAD tilde one colon dot env prints the key.

**4. ^n without a name** (V036, beat 62)

- Script: ^1 and ^2 name them, the range ^1..^2 lists the commits that came in, and ^- adds the merge itself.
- Before: ^1 and ^2 name them, the range ^1..^2 lists the commits that came in, and ^- adds the merge itself.
- After: caret one and caret two name them, the range caret one two dots caret two lists the commits that came in, and caret dash adds the merge itself.

**5. ^{tree}** (V101, beat 78)

- Script: In scripts, --verify --quiet with ^{commit} gives one ID or a failing exit status.
- Before: In scripts, dash dash verify dash dash quiet with ^{commit} gives one ID or a failing exit status.
- After: In scripts, dash dash verify dash dash quiet with caret, commit in curly braces gives one ID or a failing exit status.

**6. ^{}** (V080, beat 11)

- Script: peel a tag to its commit with ^{};
- Before: peel a tag to its commit with ^{};
- After: peel a tag to its commit with caret, empty curly braces;

**7. ^@ ^! ^-** (V064, beat 57)

- Script: For an ordinary commit, A^! gives git diff the pair that git show uses.
- Before: For an ordinary commit, A caret! gives git diff the pair that git show uses.
- After: For an ordinary commit, A caret exclamation mark gives git diff the pair that git show uses.

**8. A..B** (V064, beat 23)

- Script: An omitted side means HEAD: origin/main.. is origin/main..HEAD.
- Before: An omitted side means HEAD: origin main.. is origin main two dots HEAD.
- After: An omitted side means HEAD: origin main two dots is origin main two dots HEAD.

**9. bare .. and ...** (V020, beat 20)

- Script: git commit --author=... --date=...: author as given. Committer you, now.
- Before: git commit dash dash author equals ... dash dash date equals ...: author as given. Committer you, now.
- After: git commit dash dash author equals three dots dash dash date equals three dots: author as given. Committer you, now.

**10. --long-option=value** (V200, beat 78)

- Script: Print the update. 🟢 for this form: with --ref-action=print only new objects are written.
- Before: Print the update. for this form: with dash dash ref action equals print only new objects are written.
- After: Print the update. SAFE for this form: with dash dash ref action equals print only new objects are written.

**11. -X capital option** (V032, beat 59)

- Script: -X theirs 🟡 CAUTION is the mirror image.
- Before: dash X theirs CAUTION is the mirror image.
- After: dash capital X theirs CAUTION is the mirror image.

**12. -- alone** (V046, beat 52)

- Script: git reset -- <path> is the older spelling of the same operation.
- Before: git reset -- path is the older spelling of the same operation.
- After: git reset dash dash path is the older spelling of the same operation.

**13. - alone** (V023, beat 61)

- Script: The older spellings, once: checkout -b for switch -c, checkout -B for switch -C, checkout - for switch -.
- Before: The older spellings, once: checkout dash b for switch dash c, checkout dash B for switch dash C, checkout - for switch -.
- After: The older spellings, once: checkout dash b for switch dash c, checkout dash capital B for switch dash capital C, checkout dash for switch dash.

**14. -fdx** (V014, beat 93)

- Script: git clean -fdx copied from an answer deletes the only copies of ignored data. Root cause: -x disregards ignore rules, and the files were never added, so no object holds them; run -n first.
- Before: git clean -fdx copied from an answer deletes the only copies of ignored data. Root cause. dash x disregards ignore rules, and the files were never added, so no object holds them; run dash n first.
- After: git clean dash f d x copied from an answer deletes the only copies of ignored data. Root cause. dash x disregards ignore rules, and the files were never added, so no object holds them; run dash n first.

**15. -text attribute** (V088, beat 11)

- Script: choose merge=union, -merge or a custom merge driver for a file and state the risk of each;
- Before: choose merge=union, -merge or a custom merge driver for a file and state the risk of each;
- After: choose merge equals union, dash merge or a custom merge driver for a file and state the risk of each;

**16. * glob** (V131, beat 75)

- Script: qa/* matches one level. qa/**/* matches any number of slashes.
- Before: qa/* matches one level. qa slash ** slash * matches any number of slashes.
- After: qa slash star matches one level. qa slash star star slash star matches any number of slashes.

**17. **** (V177, beat 49)

- Script: Predict: the pointer file is under data/, and /data/** ignores everything below data/. Is the pointer ignored? Say it out loud.
- Before: Predict: the pointer file is under data/, and data slash ** ignores everything below data/. Is the pointer ignored? Say it out loud.
- After: Predict: the pointer file is under data slash, and slash data slash star star ignores everything below data slash. Is the pointer ignored? Say it out loud.

**18. refs/heads/*** (V123, beat 58)

- Script: It does not. A clone fetches refs/heads/* only. To take a pull request into your clone, you name the ref.
- Before: It does not. A clone fetches refs heads * only. To take a pull request into your clone, you name the ref.
- After: It does not. A clone fetches refs heads star only. To take a pull request into your clone, you name the ref.

**19. pipe** (V080, beat 73)

- Script: Finding the newest release with plain git tag \| tail -1. Root cause: the default order is byte order, in which v1.10.0 sorts before v1.2.0.
- Before: Finding the newest release with plain git tag \| tail dash 1. Root cause. the default order is byte order, in which v1.10.0 sorts before v1.2.0.
- After: Finding the newest release with plain git tag pipe tail dash 1. Root cause. the default order is byte order, in which v 1 point 10 point 0 sorts before v 1 point 2 point 0.

**20. < and > markers** (V058, beat 14)

- Script: Read the =, !, <, and > markers.
- Before: Read the =, !, <, and > markers.
- After: Read the equals sign, exclamation mark, less-than sign, and greater-than sign markers.

**21. conflict markers** (V033, beat 49)

- Script: The working-tree copy. Between <<<<<<< HEAD and ======= is our version of the region. Between ======= and >>>>>>> feature/creative-judge is theirs. The last line, seed: 1234, is her seed change, merged outside the markers.
- Before: The working-tree copy. Between <<<<<<< HEAD and ======= is our version of the region. Between ======= and >>>>>>> feature creative-judge is theirs. The last line, seed: 1234, is her seed change, merged outside the markers.
- After: The working-tree copy. Between seven less-than signs HEAD and seven equals signs is our version of the region. Between seven equals signs and seven greater-than signs feature creative-judge is theirs. The last line, seed: 1234, is her seed change, merged outside the markers.

**22. = alone / key=value** (V043, beat 72)

- Script: With fetch.prune=true every fetch prunes.
- Before: With fetch dot prune=true every fetch prunes.
- After: With fetch dot prune equals true every fetch prunes.

**23. * text=auto** (V087, beat 33)

- Script: Try it now, on paper. A file is already stored with CRLF, and you add * text=auto. Is the file rewritten? Pause me for thirty seconds and write your answer, with the reason.
- Before: Try it now, on paper. A file is already stored with CRLF, and you add * text=auto. Is the file rewritten? Pause me for thirty seconds and write your answer, with the reason.
- After: Try it now, on paper. A file is already stored with CRLF, and you add star text equals auto. Is the file rewritten? Pause me for thirty seconds and write your answer, with the reason.

**24. ! in code** (V041, beat 33)

- Script: A, step 2. Your own clerk said no, and nothing was sent. Step 5 is the office, and its line says ! [remote rejected].
- Before: A, step 2. Your own clerk said no, and nothing was sent. Step 5 is the office, and its line says ! [remote rejected].
- After: A, step 2. Your own clerk said no, and nothing was sent. Step 5 is the office, and its line says exclamation mark remote rejected in square brackets.

**25. !word** (V154, beat 85)

- Script: An aggregate job without !cancelled(). Root cause: a job that needs a failed job is skipped, and a skipped job counts as passing.
- Before: An aggregate job without !cancelled(). Root cause. a job that needs a failed job is skipped, and a skipped job counts as passing.
- After: An aggregate job without exclamation mark cancelled. Root cause. a job that needs a failed job is skipped, and a skipped job counts as passing.

**26. [section]** (V038, beat 43)

- Script: Predict which sections the configuration has besides [core]. Say it out loud. I'll wait.
- Before: Predict which sections the configuration has besides [core]. Say it out loud. I'll wait.
- After: Predict which sections the configuration has besides core in square brackets. Say it out loud. I'll wait.

**27. [ahead 1]** (V040, beat 58)

- Script: [ahead 1, behind 1]. A pull that ends in this error is not a no-op.
- Before: [ahead 1, behind 1]. A pull that ends in this error is not a no-op.
- After: ahead 1, behind 1 in square brackets. A pull that ends in this error is not a no-op.

**28. $GIT_DIR** (V083, beat 17)

- Script: So inside a linked worktree Git works with two directories. $GIT_DIR is the private one. $GIT_COMMON_DIR is the repository's .git. Every path under "the Git directory" belongs to one of the two.
- Before: So inside a linked work tree Git works with two directories. $GIT DIR is the private one. $GIT COMMON DIR is the repository's dot git. Every path under "the Git directory" belongs to one of the two.
- After: So inside a linked work tree Git works with two directories. dollar GIT DIR is the private one. dollar GIT COMMON DIR is the repository's dot git. Every path under "the Git directory" belongs to one of the two.

**29. $1 $? $@** (V028, beat 98)

- Script: Predict what git tracked HEAD does when the alias uses $1 in the middle of a pipeline.
- Before: Predict what git tracked HEAD does when the alias uses $1 in the middle of a pipeline.
- After: Predict what git tracked HEAD does when the alias uses dollar 1 in the middle of a pipeline.

**30. %(field)** (V025, beat 72)

- Script: Feeding %(is-base:...) to automation. Root cause: it is a first-parent heuristic whose answer changes with the refs that exist.
- Before: Feeding %(is-base:...) to automation. Root cause. it is a first-parent heuristic whose answer changes with the refs that exist.
- After: Feeding percent, is-base colon three dots in parentheses to automation. Root cause. it is a first-parent heuristic whose answer changes with the refs that exist.

**31. %G?** (V137, beat 67)

- Script: The placeholders for scripts: %G? for the result letter, %GS for the signer, %GT for the trust level, %GK for the key.
- Before: The placeholders for scripts: %G? for the result letter, %GS for the signer, %GT for the trust level, %GK for the key.
- After: The placeholders for scripts: percent capital G question mark for the result letter, percent capital G capital S for the signer, percent capital G capital T for the trust level, percent capital G capital K for the key.

**32. git log -- path** (V069, beat 95)

- Script: git log -- <path> follows a path; --follow follows one file through renames by a heuristic that can miss.
- Before: git log -- path follows a path; dash dash follow follows one file through renames by a heuristic that can miss.
- After: git log dash dash path follows a path; dash dash follow follows one file through renames by a heuristic that can miss.

**33. trailing slash** (V183, beat 25)

- Script: git fsck --lost-found writes files under .git/lost-found/.
- Before: git F S check dash dash lost found writes files under dot git slash lost-found.
- After: git F S check dash dash lost found writes files under dot git slash lost-found slash.

**34. leading slash** (V028, beat 70)

- Script: Two global values, and the second, from the included file, wins. In ~/oss/evalkit, the file is not read.
- Before: Two global values, and the second, from the included file, wins. In home slash oss/evalkit, the file is not read.
- After: Two global values, and the second, from the included file, wins. In home slash oss slash evalkit, the file is not read.

**35. git@host:path** (V122, beat 29)

- Script: "Repository not found" over SSH is the same deliberate answer as over HTTPS. ssh -T git@github.com names the account.
- Before: "Repository not found" over S S H is the same deliberate answer as over HTTPS. ssh dash T git@git hub dot com names the account.
- After: "Repository not found" over S S H is the same deliberate answer as over HTTPS. ssh dash capital T git at git hub dot com names the account.

**36. scheme://** (V109, beat 92)

- Script: Testing a filter with a local path. Root cause: the local transport copies files and ignores the filter; a file:// URL uses the real transport.
- Before: Testing a filter with a local path. Root cause. the local transport copies files and ignores the filter; a file:// URL uses the real transport.
- After: Testing a filter with a local path. Root cause. the local transport copies files and ignores the filter; a file colon slash slash URL uses the real transport.

**37. rev:path** (V010, beat 46)

- Script: git show HEAD:rules.txt prints the committed version. git show :rules.txt, with a colon and no commit, prints the version in the index. cat prints the file on disk. Three versions exist at once.
- Before: git show HEAD:rules dot T X T prints the committed version. git show :rules dot T X T, with a colon and no commit, prints the version in the index. cat prints the file on disk. Three versions exist at once.
- After: git show HEAD colon rules dot T X T prints the committed version. git show colon rules dot T X T, with a colon and no commit, prints the version in the index. cat prints the file on disk. Three versions exist at once.

**38. label: line** (V158, beat 13)

- Script: explain why an expression inside run: is code generation and not variable passing;
- Before: explain why an expression inside run: is code generation and not variable passing;
- After: explain why an expression inside run colon is code generation and not variable passing;

**39. NAME_ prefix** (V033, beat 66)

- Script: git merge --continue 🟡 CAUTION creates the merge commit, a94e9f6. The MERGE_* files are gone, and ORIG_HEAD remains.
- Before: git merge dash dash continue CAUTION creates the merge commit, commit a 9 4 e. The MERGE_* files are gone, and orig head remains.
- After: git merge dash dash continue CAUTION creates the merge commit, commit a 9 4 e. The MERGE underscore star files are gone, and orig head remains.

**40. version string** (V130, beat 59)

- Script: The tip of main carries the tag v0.3.0. What does plain git describe print?
- Before: The tip of main carries the tag v0.3.0. What does plain git describe print?
- After: The tip of main carries the tag v 0 point 3 point 0. What does plain git describe print?

## Check with the voice

`say -v Tara -r 165 -o file.wav` was run on 174 spoken pieces: the 33 self-test sentences (one for each rule) and 139 changed sentences from the course, chosen so that they cover as many new word sequences as possible. Nobody listened; the check is that the command succeeds and the length fits the number of words (between 0.45 and 2.2 times the length at 165 words per minute).

- Errors from `say`: 0.
- Plausible length: 174 of 174; 12 of them only on a second attempt.
- That second attempt matters. The same sentence, spoken again by the same command, came out with a different length (for one twelve-word sentence: 4.08, 4.08, 2.93, 2.32, 4.08 and 5.05 seconds in six runs). This is not caused by the new text: "The base is commit 6 a e 3.", which did not change, took 8.02 s once and 2.03 s the next time. The builder keeps whatever file `say` writes if it is not empty.
- A look at the existing cache for the old text (Tara, 165) found 247 pieces of six or more words in 122 videos whose file is far too short or far too long for its words (for example 0.02 s for seven words, and 18.76 s for "You should now be able to say:"). These are worth checking before the voice steps are rebuilt; a length check with a retry in `tts()` would catch them. Not changed here.

## Changed sentences per video

These videos need their voice step rebuilt. Nothing was rebuilt.

| Video | Changed beats | Narration beats |
|---|---|---|
| V001 | 10 | 72 |
| V002 | 6 | 73 |
| V003 | 13 | 75 |
| V004 | 2 | 67 |
| V005 | 4 | 81 |
| V006 | 10 | 69 |
| V007 | 5 | 70 |
| V008 | 6 | 77 |
| V009 | 7 | 77 |
| V010 | 6 | 68 |
| V011 | 10 | 71 |
| V012 | 12 | 77 |
| V013 | 8 | 74 |
| V014 | 23 | 84 |
| V015 | 6 | 63 |
| V016 | 15 | 72 |
| V017 | 15 | 82 |
| V018 | 4 | 81 |
| V019 | 6 | 81 |
| V020 | 13 | 71 |
| V021 | 10 | 70 |
| V022 | 6 | 61 |
| V023 | 18 | 66 |
| V024 | 8 | 61 |
| V025 | 10 | 65 |
| V026 | 17 | 76 |
| V027 | 13 | 78 |
| V028 | 31 | 93 |
| V029 | 1 | 65 |
| V030 | 2 | 66 |
| V031 | 6 | 74 |
| V032 | 23 | 81 |
| V033 | 19 | 79 |
| V034 | 13 | 89 |
| V035 | 20 | 84 |
| V036 | 6 | 84 |
| V037 | 10 | 90 |
| V038 | 20 | 90 |
| V039 | 10 | 76 |
| V040 | 26 | 79 |
| V041 | 21 | 84 |
| V042 | 7 | 80 |
| V043 | 23 | 86 |
| V044 | 19 | 84 |
| V045 | 1 | 50 |
| V046 | 5 | 73 |
| V047 | 13 | 97 |
| V048 | 8 | 74 |
| V049 | 6 | 70 |
| V050 | 9 | 88 |
| V051 | 12 | 65 |
| V052 | 6 | 74 |
| V053 | 7 | 74 |
| V054 | 12 | 83 |
| V055 | 11 | 85 |
| V056 | 21 | 94 |
| V057 | 10 | 86 |
| V058 | 9 | 73 |
| V059 | 4 | 77 |
| V060 | 12 | 86 |
| V061 | 16 | 85 |
| V062 | 16 | 85 |
| V063 | 8 | 87 |
| V064 | 19 | 83 |
| V065 | 3 | 54 |
| V066 | 16 | 91 |
| V067 | 10 | 88 |
| V068 | 10 | 65 |
| V069 | 35 | 80 |
| V070 | 17 | 84 |
| V071 | 10 | 68 |
| V072 | 8 | 67 |
| V073 | 6 | 68 |
| V074 | 6 | 81 |
| V075 | 6 | 76 |
| V076 | 2 | 74 |
| V077 | 2 | 72 |
| V078 | 2 | 62 |
| V079 | 5 | 75 |
| V080 | 18 | 75 |
| V081 | 21 | 64 |
| V082 | 15 | 71 |
| V083 | 12 | 64 |
| V084 | 9 | 75 |
| V085 | 6 | 61 |
| V086 | 13 | 66 |
| V087 | 27 | 69 |
| V088 | 19 | 71 |
| V089 | 9 | 75 |
| V090 | 10 | 74 |
| V091 | 9 | 73 |
| V092 | 10 | 71 |
| V093 | 12 | 87 |
| V094 | 7 | 68 |
| V095 | 7 | 70 |
| V096 | 6 | 70 |
| V097 | 2 | 89 |
| V098 | 2 | 51 |
| V099 | 10 | 77 |
| V100 | 8 | 79 |
| V101 | 15 | 59 |
| V102 | 6 | 75 |
| V103 | 15 | 77 |
| V104 | 15 | 80 |
| V105 | 27 | 82 |
| V106 | 5 | 67 |
| V107 | 26 | 71 |
| V108 | 13 | 70 |
| V109 | 17 | 81 |
| V110 | 5 | 58 |
| V111 | 7 | 69 |
| V112 | 11 | 74 |
| V113 | 15 | 74 |
| V114 | 1 | 57 |
| V115 | 8 | 76 |
| V116 | 3 | 73 |
| V117 | 14 | 86 |
| V118 | 11 | 79 |
| V119 | 15 | 66 |
| V120 | 21 | 86 |
| V121 | 15 | 80 |
| V122 | 18 | 84 |
| V123 | 6 | 91 |
| V124 | 4 | 84 |
| V125 | 6 | 90 |
| V126 | 2 | 78 |
| V127 | 6 | 80 |
| V128 | 9 | 79 |
| V129 | 12 | 93 |
| V130 | 14 | 72 |
| V131 | 16 | 88 |
| V132 | 5 | 91 |
| V133 | 15 | 86 |
| V134 | 12 | 91 |
| V135 | 16 | 79 |
| V136 | 16 | 87 |
| V137 | 18 | 85 |
| V138 | 15 | 92 |
| V139 | 6 | 73 |
| V140 | 16 | 100 |
| V141 | 1 | 56 |
| V142 | 11 | 97 |
| V143 | 14 | 99 |
| V144 | 8 | 80 |
| V145 | 9 | 102 |
| V146 | 10 | 103 |
| V147 | 18 | 99 |
| V148 | 22 | 94 |
| V149 | 13 | 109 |
| V150 | 14 | 100 |
| V151 | 13 | 79 |
| V152 | 10 | 107 |
| V153 | 13 | 100 |
| V154 | 11 | 90 |
| V155 | 1 | 56 |
| V156 | 4 | 92 |
| V157 | 6 | 87 |
| V158 | 7 | 79 |
| V159 | 14 | 83 |
| V160 | 4 | 100 |
| V161 | 11 | 113 |
| V162 | 5 | 108 |
| V163 | 15 | 91 |
| V164 | 13 | 100 |
| V165 | 8 | 109 |
| V166 | 6 | 110 |
| V167 | 14 | 96 |
| V168 | 7 | 84 |
| V169 | 3 | 51 |
| V170 | 3 | 95 |
| V171 | 9 | 85 |
| V172 | 20 | 87 |
| V173 | 3 | 76 |
| V174 | 10 | 93 |
| V175 | 8 | 94 |
| V176 | 7 | 102 |
| V177 | 10 | 91 |
| V178 | 5 | 92 |
| V179 | 2 | 65 |
| V180 | 2 | 97 |
| V181 | 12 | 85 |
| V182 | 4 | 85 |
| V183 | 6 | 85 |
| V184 | 3 | 81 |
| V185 | 2 | 68 |
| V186 | 5 | 86 |
| V187 | 5 | 92 |
| V188 | 5 | 90 |
| V189 | 4 | 96 |
| V190 | 4 | 74 |
| V191 | 6 | 76 |
| V192 | 4 | 88 |
| V193 | 1 | 74 |
| V194 | 0 | 57 |
| V195 | 0 | 79 |
| V196 | 0 | 63 |
| V197 | 3 | 73 |
| V198 | 3 | 88 |
| V199 | 22 | 91 |
| V200 | 19 | 101 |
| V201 | 14 | 91 |

## Videos whose spoken text changes

V001, V002, V003, V004, V005, V006, V007, V008, V009, V010, V011, V012, V013, V014, V015, V016, V017, V018, V019, V020, V021, V022, V023, V024, V025, V026, V027, V028, V029, V030, V031, V032, V033, V034, V035, V036, V037, V038, V039, V040, V041, V042, V043, V044, V045, V046, V047, V048, V049, V050, V051, V052, V053, V054, V055, V056, V057, V058, V059, V060, V061, V062, V063, V064, V065, V066, V067, V068, V069, V070, V071, V072, V073, V074, V075, V076, V077, V078, V079, V080, V081, V082, V083, V084, V085, V086, V087, V088, V089, V090, V091, V092, V093, V094, V095, V096, V097, V098, V099, V100, V101, V102, V103, V104, V105, V106, V107, V108, V109, V110, V111, V112, V113, V114, V115, V116, V117, V118, V119, V120, V121, V122, V123, V124, V125, V126, V127, V128, V129, V130, V131, V132, V133, V134, V135, V136, V137, V138, V139, V140, V141, V142, V143, V144, V145, V146, V147, V148, V149, V150, V151, V152, V153, V154, V155, V156, V157, V158, V159, V160, V161, V162, V163, V164, V165, V166, V167, V168, V169, V170, V171, V172, V173, V174, V175, V176, V177, V178, V179, V180, V181, V182, V183, V184, V185, V186, V187, V188, V189, V190, V191, V192, V193, V197, V198, V199, V200, V201
