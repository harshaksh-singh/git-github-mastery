#!/usr/bin/env bash
# Final test, section 12 (Security): prediction item P1 and interpretation item I1. The
# credential is an obvious dummy; it never worked anywhere.
. "$(dirname "$0")/../lib/lab-env.sh"
lab_begin final s12

# ---- P1: a deleted file and the history that still has it
snip p1-setup
run 'git init -q mailer'
run 'cd mailer'
run "printf 'def send(to, body):\n    return smtp.send(to, body)\n' > send.py"
run 'git add . && git commit -q -m "Add the mail sender"'
run "printf 'SMTP_PASSWORD=dummy-not-a-real-password-0000\n' > .env"
run 'git add . && git commit -q -m "Add local settings"'
run "printf 'def retry(fn, n=3):\n    return fn()\n' > retry.py"
run 'git add . && git commit -q -m "Add a retry helper"'
run 'git rm -q .env'
run 'git commit -q -m "Remove local settings"'
snip p1-answer
run_rc 'git grep -l dummy-not-a-real-password'
run "git log --oneline -S'dummy-not-a-real-password'"
run 'git rev-list HEAD | xargs git grep -l dummy-not-a-real-password'
cd "$LAB_DIR"

# ---- I1: "I amended it and force-pushed, so it is gone"
quiet 'git init -q --bare server.git'
quiet 'git clone -q server.git ravi && git -C ravi remote set-url origin ../server.git'
cd ravi || exit 1
as ravi
printf 'def handler(event):\n    return route(event)\n' > hook.py
quiet 'git add . && git commit -q -m "Add the webhook handler" && git push -q -u origin main'
quiet 'git switch -q -c feature/signing'
printf 'WEBHOOK_SECRET = "dummy-not-a-real-secret-1111"\n\ndef verify(sig, body):\n    return hmac_ok(WEBHOOK_SECRET, sig, body)\n' > verify.py
quiet 'git add . && git commit -q -m "Verify webhook signatures" && git push -q -u origin feature/signing'
leak=$(git rev-parse --short HEAD)
cd "$LAB_DIR" || exit 1
quiet 'git clone -q server.git asha && git -C asha remote set-url origin ../server.git'
cd ravi || exit 1
printf 'import os\n\ndef verify(sig, body):\n    return hmac_ok(os.environ["WEBHOOK_SECRET"], sig, body)\n' > verify.py
quiet 'git commit -q -a --amend --no-edit && git push -q --force-with-lease'
cd "$LAB_DIR" || exit 1
as you
snip i1-transcript
note "Ravi: \"I amended the commit and force-pushed. $leak is gone.\""
run 'git -C server.git for-each-ref --format="%(objectname:short) %(refname)"'
run "git -C server.git cat-file -t $leak"
run "git -C server.git grep -c dummy-not-a-real-secret $leak"
run "git -C ravi reflog show feature/signing"
run "git -C asha branch -r --contains $leak"
lab_end
