# Incident 1: what was reported

**Project:** `triage-bot`. **Sandbox:** `server.git` (the server), `you/` (your clone), `ravi/` (Ravi's clone, which is where you are asked to help).

Ravi, in the team channel, Monday morning:

> Can someone help, I think `git pull` ate my work. I spent all of Friday on the escalation rules, three or four commits, and now `git log` shows none of them. I only wanted to get rid of a half-done edit, so I reset to what is on the server, which should have kept my commits because they were committed. I never pushed the branch, so GitHub does not have them either.
>
> I also had a new priorities file that I am fairly sure I had added, and I was in the middle of changing the routing config. I have made one more commit since then, before I noticed. Please tell me this is not gone.

What you are asked for: get Ravi's work back, tell him exactly what could and could not be recovered and why, and leave his branch in a state he can keep working on.

When you think you are done, run `incidents/01-hard-reset/check.sh` from the course root.
