# Exercise 6.10: what was reported

**Project:** `sampler-service`. Work happens on `develop`; every Friday `develop` is brought into `main`, and `main` is what gets deployed. **Sandbox:** `server.git` (the server), `you/` (your clone), `asha/` (Asha's clone).

Asha, who has done the Friday sync so far and is on leave from today:

> You have the sync this week, sorry. It used to be one command: on `main`, `git merge --squash develop`, commit, push. Week 36 was clean. Week 37 it stopped with a conflict in `sampler/config.py`, in lines that nobody ever edited on `main`. I took the `develop` version of the file and moved on. I tried this week's sync before leaving and backed out: the same file again, and this time the conflict covers more lines, including ones I had already settled last week. It gets worse every week.
>
> My theory is Ravi's hotfix. It is the only commit that ever went to `main` directly, and the trouble started right after it. I would revert it, sync, and put it back. Or we switch on that rerere thing so that Git remembers my resolutions.

Ravi:

> My hotfix touched `sampler/sample.py` and nothing else, and the conflicts are in `config.py`. One more thing I noticed: `git log --oneline main..develop` lists every commit `develop` ever had, including the ones from weeks 36 and 37 that are long deployed. As if the syncs had never happened.

What you are asked for: do this week's sync, so that `main` on the server contains everything `develop` has plus the hotfix; explain why the conflicts come back and grow; and leave the two branches in a state in which next Friday's sync has to consider only next week's commits. `main` is deployed and shared: its existing commits must stay. Do not rewrite `develop` either.

When you think you are done, run `exercises/gen/m06-weekly-sync/check.sh` from the course root.
