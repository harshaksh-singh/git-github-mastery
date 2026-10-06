#!/usr/bin/env bash
# Incident 3: a secret is committed and pushed.
# Builds server.git and the clones you/, asha/ and ravi/ of the project "notify-service".
# The "secret" is an obvious dummy string made for this exercise. It is not a credential for
# anything and it matches no secret-scanner pattern. Read SYMPTOMS.md before you start.
. "$(dirname "${BASH_SOURCE[0]}")/../../labs/lib/lab-env.sh"
. "$COURSE_ROOT/incidents/lib/incident-lib.bash"
[ -n "${LAB_REPLAY:-}" ] || sandbox_begin incidents 03-committed-secret
inc_begin

inc_server
inc_clone you
cd you || exit 1
mkdir -p notify
printf 'def notify(user, message):\n    return queue.put((user.id, message))\n' > notify/core.py
printf '__pycache__/\n' > .gitignore
_c 'Add notification queue'
printf '# notify-service\n\nSends notifications to users.\n' > README.md
_c 'Add README'
quiet 'git push -u origin main'
cd "$LAB_DIR" || exit 1
inc_clone asha
inc_clone ravi

cd "$LAB_DIR/ravi" || exit 1
as ravi
quiet 'git switch -c feature/email-digest'
printf 'def build_digest(events):\n    return "\\n".join(e.summary for e in events)\n' > notify/digest.py
_c 'Add digest builder'
printf 'import os, smtplib\n\ndef send(to, body):\n    s = smtplib.SMTP(os.environ["SMTP_HOST"])\n    s.login(os.environ["SMTP_USER"], os.environ["SMTP_PASSWORD"])\n    s.sendmail("digest@example.com", to, body)\n' > notify/smtp.py
printf 'SMTP_HOST=smtp.example.com\nSMTP_USER=digest@example.com\nSMTP_PASSWORD=lab-fixture-not-a-real-password\n' > .env
_c 'Add SMTP sender'
printf 'def build_digest(events):\n    events = sorted(events, key=lambda e: e.ts)\n    return "\\n".join(e.summary for e in events)\n' > notify/digest.py
_c 'Sort digest events by time'
quiet 'git push -u origin feature/email-digest'
quiet 'cp .env ../ravi.env.keep && git rm -q .env'
_c 'Remove env file'
quiet 'mv ../ravi.env.keep .env'
printf 'digest:\n  every: 1h\n' > schedule.yaml
quiet 'git add schedule.yaml && git commit -m "Schedule the digest hourly"'
quiet 'git push'

cd "$LAB_DIR/asha" || exit 1
as asha
quiet 'git fetch'
quiet 'git switch -c feature/digest-template origin/feature/email-digest'
printf '<h1>Your digest</h1>\n<ul>{%% for e in events %%}<li>{{ e.summary }}</li>{%% endfor %%}</ul>\n' > notify/digest.html
_c 'Add HTML digest template'
quiet 'git push -u origin feature/digest-template'

inc_end
[ -n "${LAB_REPLAY:-}" ] || printf 'Incident ready. Open a lab shell there:\n  labs/shell "%s"\n' "$LAB_DIR"
