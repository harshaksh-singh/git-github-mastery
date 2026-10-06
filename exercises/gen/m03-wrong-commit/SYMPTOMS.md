# Exercise 3.9: what was reported

**Project:** `scorer-service`. **Sandbox:** one repository, `scorer-service/`. It is Ravi's clone; the repository's own configuration carries his name and email. Nothing has been pushed yet.

Asha, reviewing before the push:

> Three problems with your last commit, Ravi, and I would like them gone before this goes anywhere:
>
> 1. It says it was written by "Meeting Room 4". You wrote it, on the laptop in the meeting room, during our pairing session.
> 2. `debug.log` is in the commit. It must not be in history. You said you still need the file itself this afternoon.
> 3. The title has two typos. It should read "Add retry budget to the scorer". The body and my `Reviewed-by` line are fine, keep them.
>
> Please do not turn this into two commits and do not lose the time the change was written: the commit is cited by its date in the evaluation notes.

What you are asked for: replace the last commit by one corrected commit on the same parent. Its author is `Ravi Menon <ravi@example.com>`, its author date is the original one, its title is the corrected one, its body and trailer are unchanged, `debug.log` is not part of it, and `debug.log` is still in the working tree. Then say where the old commit is now and for how long.

When you think you are done, run `exercises/gen/m03-wrong-commit/check.sh` from the course root.
