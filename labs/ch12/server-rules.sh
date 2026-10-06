#!/usr/bin/env bash
# "rejected" is decided by your Git, "remote rejected" by the server. Three server-side
# rules in plain Git: receive.denyNonFastForwards, receive.denyDeletes and a pre-receive
# hook. Chapter 12, section 12.7.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$(dirname "$0")/fixture.bash"
lab_begin ch12 server-rules

# Hidden setup: you rewrote your last published commit, so your main has diverged from the server.
make_server
new_clone you
enter you
commit_file app/settings.py 'TIMEOUT_SECONDS = 30\n' 'Set request timeout'
hidden 'git push'
hidden 'git commit --amend -m "Set request timeout to 30 seconds"'

# The server administrator's pre-receive hook, installed quietly and printed in the transcript.
cat > "$LAB_DIR/pre-receive" <<'HOOK'
#!/bin/sh
# Refuse every direct update of main. Standard input has one line per ref:
#   <old-id> <new-id> <ref-name>
while read old new ref; do
  if [ "$ref" = "refs/heads/main" ]; then
    echo "policy: main only changes through a reviewed merge" >&2
    exit 1
  fi
done
exit 0
HOOK

snip 01-deny-non-fast-forwards
run 'git status -sb'
run 'git -C ../../server/support-bot.git config set receive.denyNonFastForwards true'
run_rc 'git push --force'

snip 02-deny-deletes
run 'git push origin HEAD:refs/heads/tmp/scratch'
run 'git -C ../../server/support-bot.git config set receive.denyDeletes true'
run_rc 'git push origin --delete tmp/scratch'

snip 03-pre-receive
run 'git -C ../../server/support-bot.git config unset receive.denyNonFastForwards'
run 'cp ../../pre-receive ../../server/support-bot.git/hooks/pre-receive'
run 'chmod +x ../../server/support-bot.git/hooks/pre-receive'
run 'cat ../../server/support-bot.git/hooks/pre-receive'
run_rc 'git push --force'

lab_end
