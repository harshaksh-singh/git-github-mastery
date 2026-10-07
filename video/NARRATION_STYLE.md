# Narration style guide for the video scripts

One page for editors who rewrite the narration of `video/scripts/VNNN-*.md`. The pilot rewrites are V001, V007 and V030; their plain originals are in `video/scripts-original/`. Read one pair side by side before you start.

**The voice.** A friendly senior engineer at a whiteboard, talking to one colleague. Warm, a little playful, never in a hurry, and exact about every fact.

## 1. What you may touch

| Edit freely | Leave byte for byte |
|---|---|
| Plain narration paragraphs | The `#` title, the header block, the thirteen `##` headings and their order |
| You may add a short narration paragraph to open or close a section | Every `**[ON SCREEN]**`, `**[TERMINAL]**`, `**[DIAGRAM]**`, `**[PAUSE]**` paragraph; do not add new ones |
| You may split a long paragraph in two | Fenced blocks and snippet blocks |
| | Lists (objectives, common mistakes, homework) and the line `After this video you can:`: they are the bullet slides |
| | The `Qnn: "..."` interview question, risk labels (🟢 SAFE, 🟡 CAUTION, 🔴 DANGEROUS), bold lead-ins such as `**The ladder.**` (they are slide headlines), direct quotations from the manual |

Every fact, command, flag, number, version, caveat and "Unverified" note stays as accurate as the original. Add no technical claim. An analogy must come with the place where it breaks.

**Length.** Narration words may grow by about 10 percent at most. A greeting, a sign-off and the prediction prompts cost about 120 words, so tighten elsewhere.

## 2. Three facts about the pipeline that shape the writing

1. **The first sentence of every narration paragraph is drawn on the slide.** Make it the point of the paragraph. A chatty opener is fine only if it is shorter than 28 characters, because then the slide also takes the next sentence ("Your turn." "Now, out of the lab." "Two pictures now.").
2. **Code spans in demo narration choose which page of a long transcript is shown.** Keep the code spans of the things you point at.
3. **Do not put a new paragraph between a stage direction and the block or list it introduces.** Put it before the direction or after the block.

## 3. The rules, with examples from the pilot

**Spoken English.** Short sentences, contractions, "you", questions. If you would not say it, rewrite it.

> Before: "So the same commands run at two different moments produce different IDs. Replays pin the identity and the clock."
> After: "So the same commands, run at two different moments, produce different IDs. That's why replays pin the identity and the clock."

**A hook that earns thirty seconds.** A concrete scene or a question, then the promise. Never "in this video we will".

> Before (V030): "Your CTO asks, after an ordinary release week: ..." and, at the end of the hook, "Part 2 starts by getting the foundation right."
> After: "It's the end of an ordinary release week, and your CTO asks: ..." and, at the end, "Part 2 starts by getting the foundation right. Keep that Monday mystery in mind. It comes back."

**Connective tissue.** Each section opens with a line that links back: "So that's the destination. Now, why is the course built the way it is?" "Enough about the room. Let's walk in." "Now, out of the lab." "Let's land this."

**One curiosity loop per video,** opened in the hook or introduction and closed out loud later.

> Opened (V007): "Hold on to that word, snapshot. In a few minutes it explains why a second commit didn't store `README.md` again."
> Closed: "`README.md` wasn't stored again. That's your snapshot, paid off."

**Predict, then look.** Before a demo step, ask for a prediction. Use "Say it out loud. I'll wait." only where the script already has a `**[PAUSE]**` after it. Elsewhere use "Say it out loud." or "Make your prediction."

> Before: "Fast-forward, true merge, or nothing?"
> After: "Fast-forward, true merge, or nothing? Say it out loud. I'll wait."

**A quick check after a hard point.** "If that felt fast, here it is in one sentence: the name of a thing is computed from the thing." The one sentence must restate the original, not add to it.

**Humour.** At most one small moment per section, often none. Wry and kind, never at the learner's expense: "You can breathe out." "Nobody wants to discover that on a Friday evening."

**Motivation without hype.** Say why it matters at work, and that confusion here is normal: "If that part feels out of reach today, that's normal." The ending names real progress: "No Git commands yet, and you already have a safe room to break things in, and a way to prove it's safe."

## 4. Series fixtures

- **Greeting** (first line of INTRODUCTION): "Welcome to Git and GitHub Deep Mastery. Pull up a chair." From V002 on: "Welcome back to Git and GitHub Deep Mastery. Pull up a chair."
- **Sign-off** (last lines, after the homework list): one sentence of real progress, one teaser from the next video's title, then: "Until then, look at the state first and type second. See you in the next one."
- **Section openers that recur:** "Your turn." (PRACTICE EXERCISE), "Now, out of the lab." (PRODUCTION EXAMPLE), "Let's land this." (RECAP), "Five mistakes to watch for." (COMMON MISTAKES).
- **Recurring characters.** The on-call engineer on a Friday evening. The CTO who asks calm, precise questions. The teammate who force-pushes, always treated kindly. Asha and Ravi, where the textbook uses them. Give the characters no new technical behavior.

## 5. Writing for a text-to-speech voice

- No parentheses, no slashes, no semicolons, no percent sign, no "e.g." in your own sentences. Write "61 percent", "AI and ML".
- Dotfiles and paths are spoken: "the dot git folder", "your dot gitconfig file in your home directory", "eval dot yaml, in the config directory", "under the lab root".
- Notation is described: "two dots", "three dots", "a caret, and the word tree in curly braces", "the less-than sign".
- Dates and times as words: "Monday the seventh of September 2026, at ten in the morning, five and a half hours ahead of UTC".
- Videos are "video 7", not V007.
- Keep a command, flag, variable or object ID as inline code when it is on screen at that moment: in the snippet being shown, in the table on screen, or in the first sentence of the paragraph. Elsewhere prefer words, unless the exact spelling is the fact being taught.
- One idea per sentence. A list of more than three items becomes several sentences.

### How symbols are spoken

Code that stays in the narration is turned into words by `speakable()` in `tools/video_build.py` before it reaches the voice. Slides and subtitles keep the script's spelling: only the spoken text changes. The table is the whole rule set; `python3 tools/video_build.py --speech-selftest` holds one test sentence for each row (pure text, nothing is spoken or rendered). Write a symbol inside a code span: there every mark is code, so `git add .` ends in "dot" and `remote:` ends in "colon".

| In the script | The voice is given |
|---|---|
| `main..topic`, `main...topic`, `..`, `...` | main two dots topic, main three dots topic, two dots, three dots |
| `HEAD~2`, `main~`, `HEAD^`, `HEAD^2`, `HEAD^^` | HEAD tilde two, main tilde, HEAD caret, HEAD caret two, HEAD caret caret |
| `HEAD@{1}`, `@{upstream}`, `@{-1}` | HEAD at one, at upstream, at minus one |
| `HEAD^{tree}`, `^{}`, `^@`, `^!`, `^-` | HEAD caret, tree in curly braces; caret, empty curly braces; caret at; caret exclamation mark; caret dash |
| `--force-with-lease`, `--sort=x`, `--` | dash dash force with lease, dash dash sort equals x, dash dash |
| `-m`, `-X`, `-fdx`, `-M40%`, `-text`, `-` | dash m, dash capital X, dash f d x, dash capital M 40%, dash text, dash |
| `*`, `**`, `*.log`, `refs/heads/*`, `core.*` | star, star star, star dot log, refs heads star, core dot star |
| `\|`, `+`, `#`, `##`, `@@`, `~`, `^`, `\` | pipe, plus, hash, hash hash, at at, tilde, caret, backslash |
| `=`, `key=value`, `==` | equals sign (alone) or equals, key equals value, equals equals |
| `<`, `>` | less-than sign, greater-than sign. Never dropped |
| `a > b`, `2 <= 3` (a comparison, with spaces) | a greater than b, 2 less than or equal to 3 |
| `<path>` (a placeholder) | path: a placeholder is spoken as its name |
| `<<<<<<<`, `=======`, `>>>>>>>`, `\|\|\|\|\|\|\|` | seven less-than signs, seven equals signs, seven greater-than signs, seven pipes |
| `!` in code: `! [rejected]`, `!cancelled()`, `fixup!`, `!!` | exclamation mark; two exclamation marks |
| `[rejected]`, `[remote "origin"]`, `[0-9]`, `[]` | rejected in square brackets, remote "origin" in square brackets, 0 to 9 in square brackets, empty square brackets |
| `${{ github.sha }}` | dollar, git hub dot sha in double curly braces |
| `$GIT_DIR`, `$1`, `$?`, `$@`; `$LAB`, `$HOME` | dollar GIT DIR, dollar 1, dollar question mark, dollar at; lab, home |
| `%gd`, `%GS`, `%G?`, `%(refname:short)` | percent g d, percent capital G capital S, percent capital G question mark, percent, refname colon short in parentheses |
| `labs/shell`, `/dev/null`, `data/`, `./run`, `../x`, `~/work` | labs slash shell, slash dev slash null, data slash, dot slash run, dot dot slash x, home slash work |
| `origin/main`, `refs/heads/main` (a ref) | origin main, refs heads main |
| `README.md`, `.gitignore`, `user.name`, `git add .` | read me dot M D, dot git ignore, user dot name, git add dot |
| `HEAD:path`, `:1:path`, `blob:none`, `remote:` | HEAD colon path, colon 1 colon path, blob colon none, remote colon. A time such as 10:27 is left to the voice |
| `git@github.com:acme/x.git`, `https://`, `@v4` | git at git hub dot com colon acme slash x dot git, H T T P S colon slash slash, at v4 |
| `GIT_DIR`, `ghp_`, `MERGE_*`, `__git_ps1` | GIT DIR, ghp underscore, MERGE underscore star, underscore underscore git ps1 |
| `v0.2.0`, `2.55.0`, `Git 2.55`, `2.x`, `v1.1.0-2-g57c8425` | v 0 point 2 point 0, 2 point 55 point 0, Git 2 point 55, 2 point x, v 1 point 1 point 0 dash 2 dash g 5 7 c 8 |
| `14A.14` (a section), `m06`, `ch14a` (course folders) | 14 A point 14, M 6, C H 14 A |
| `6ae3c51` (an object ID) | commit 6 a e 3 |
| `.lower()`, `log2(n)`, `(1/3)`, `W&B`, `#12` | dot lower, log2 (n), (1 of 3), W and B, number 12 |
| 🟢, 🟡, 🔴 without the word after it | SAFE, CAUTION, DANGEROUS |

Left alone, because the voice reads them as prose: commas, full stops, question marks, colons and semicolons that end a clause, apostrophes, quotation marks, parentheses around words, hyphens inside words (`fast-forward`, `lab-26-7-artifact`), a percent sign or a currency sign next to a number (`61%`, `$5`), times and plain decimals (`10:27`, `Lab 6.1`), the slash of `and/or` and of `3/4`, and a dash that stands between two spaces outside a code span. Any other symbol that no row covers is given its plain name, so nothing reaches the voice raw.

## 6. Phrases to avoid

"In this video we will", "let's dive in", "without further ado", "ultimate", "insane", "game-changer", "mind-blowing", "simply", "just" as a minimizer, "obviously", "as everyone knows", "easy", "trust me", "smash that like button", "you will never ... again", "master Git in N minutes". No exclamation marks. No jokes about people who make the mistake being described.

## 7. Before you hand in

```bash
python3 tools/inject.py --check video/scripts/VNNN-*.md
python3 tools/check_course.py video/scripts/VNNN-*.md
```

Both must report no problems. Then diff against the original and confirm that only narration paragraphs changed, and count the narration words. A rewritten script needs its storyboard and slides rebuilt, and any existing recording of the changed paragraphs read again.

## Owner's brief (6 October 2026): who we are talking to, and how

These rules come from the course owner and take priority over anything above that conflicts with them.

1. **A newcomer can follow every video.** Assume a viewer with no technical background has clicked on this video first. The first time a term appears in a video, say what it is in one plain sentence before using it ("a commit: one saved snapshot of your whole project, with a note about who saved it and why"). Never say "as you know". Later videos may be brief about earlier terms but still give a five-second reminder.
2. **Complete in itself.** The viewer should not need another source to understand the topic. If a step is skipped, name it and say where it is taught. Go deep: why, what, how, what happens inside, when to use it, when not to, how it fails, how to recover.
3. **A kind professor.** The depth of a PhD, the manners of a good teacher: polite, warm, patient, never rude, never sarcastic about learners, never "obviously" or "simple". Mistakes are normal and are named as such ("almost everyone gets this wrong the first time, and here is why").
4. **Interactive, with small activities.** Every video has at least three moments where the viewer does something, each followed by a `[PAUSE]`: a prediction ("say it out loud before I run it"), a quick quiz with two or three options, and a thirty-second "try it now" in the lab shell or on paper (draw the graph, point at the commit). Give the answer after the pause and explain it kindly.
5. **Fun, lightly.** One small smile per section at most: a playful analogy, the recurring characters, the mascot Twig mentioned by name once in a while ("Twig looks worried, and with a red label on screen, fairly so"). No sarcasm, no hype.
6. **Confidence at the end.** The recap says what the viewer can now do, in their own words, and the sign-off encourages them to practise before the next video.
7. Accuracy rules are unchanged: no new technical claims, every fact, number, caveat and "Unverified" note stays exactly as in the script.
