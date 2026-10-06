#!/usr/bin/env bash
# Read-only verification of the recovery of incident 3. Exit status 0 means recovered.
# It verifies the Git side only. Rotation of the credential cannot be checked from here.
. "$(dirname "${BASH_SOURCE[0]}")/../lib/check-lib.bash"
check_begin 03-committed-secret "${1:-}"
S=server.git
NEEDLE='lab-fixture-not-a-real-password'
blob=$(printf 'SMTP_HOST=smtp.example.com\nSMTP_USER=digest@example.com\nSMTP_PASSWORD=%s\n' "$NEEDLE" | git hash-object --stdin)

# in_history <repo>: does any commit reachable from any ref contain the dummy secret?
in_history() {
  local c
  for c in $(git -C "$1" rev-list --all 2>/dev/null); do
    git -C "$1" grep -q -F "$NEEDLE" "$c" 2>/dev/null && return 0
  done
  return 1
}

expect 'the server still has feature/email-digest' git -C $S rev-parse --verify -q refs/heads/feature/email-digest
expect 'the server still has feature/digest-template' git -C $S rev-parse --verify -q refs/heads/feature/digest-template
for s in 'Add digest builder' 'Add SMTP sender' 'Sort digest events by time' 'Schedule the digest hourly'; do
  expect "feature/email-digest on the server has \"$s\"" has_subject $S feature/email-digest "$s"
done
expect 'feature/digest-template on the server has "Add HTML digest template"' has_subject $S feature/digest-template 'Add HTML digest template'
expect 'notify/smtp.py is still on feature/email-digest' git -C $S cat-file -e feature/email-digest:notify/smtp.py
expect_not 'no commit reachable from a server ref contains the secret' in_history $S
expect_not 'the server no longer stores the blob at all' git -C $S cat-file -e "$blob"
expect '.gitignore on feature/email-digest lists .env' sh -c "git -C $S show feature/email-digest:.gitignore | grep -qx '.env'"
for c in you asha ravi; do
  expect_not "no commit reachable from a ref in $c/ contains the secret" in_history $c
  expect_not "$c/ no longer stores the blob (reflogs expired and pruned, or re-cloned)" git -C $c cat-file -e "$blob"
done
printf '  note  Git state only. If the credential was not revoked or rotated first, the incident is still open.\n'
check_end
