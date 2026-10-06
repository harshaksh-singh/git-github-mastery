# Incident 3: what was reported

**Project:** `notify-service`. **Sandbox:** `server.git` (the server), `you/`, `asha/`, `ravi/`.

> The string in this exercise is a dummy made for the course (`lab-fixture-not-a-real-password`). It unlocks nothing. Treat it as if it were the production SMTP password of the company.

Ravi, in a direct message to you, late in the afternoon:

> Small thing, probably nothing. Earlier today I did `git add .` and my `.env` went into a commit on my digest branch. I noticed after lunch and deleted the file in a new commit and pushed that, so the branch is clean now. It was only ever on my feature branch, not on `main`, and the repository is private anyway. Do I need to do anything else? I would rather not make noise about it.

You know that Asha has been building the HTML template for the digest this afternoon.

What you are asked for: decide what has to happen and in which order, do the part of it that is Git work, and write down the part that is not. State clearly what "the branch is clean now" does and does not mean.

When you think you are done, run `incidents/03-committed-secret/check.sh` from the course root. The check can see only Git state. It cannot see whether the credential was rotated, and that is the step that matters most.
