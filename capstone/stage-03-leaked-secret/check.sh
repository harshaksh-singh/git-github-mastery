#!/usr/bin/env bash
# Read-only verification of capstone stage 3. Exit status 0 means the Git state is as required.
# It verifies the Git side only. Whether the credential was revoked cannot be checked from here.
. "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../lib/check-lib.bash"
check_begin 3 "${1:-}"
NEEDLE='capstone-dummy-token-not-a-real-secret'
blob=$(printf 'EMBED_API_URL=https://embeddings.staging.tessaly.example/v1\nEMBED_API_TOKEN=%s\nEMBED_TIMEOUT_SECONDS=2\n' "$NEEDLE" | git hash-object --stdin)
A=feature/embedding-client
T=feature/embedding-latency-log

# in_history <repository>: does any commit reachable from any ref contain the dummy secret?
in_history() {
  local c
  for c in $(git -C "$1" rev-list --all 2>/dev/null); do
    git -C "$1" grep -q -F "$NEEDLE" "$c" 2>/dev/null && return 0
  done
  return 1
}

expect "the server still has $A" git -C $S rev-parse --verify -q refs/heads/$A
expect "the server still has $T" git -C $S rev-parse --verify -q refs/heads/$T
for s in 'Add the embedding service client' 'Cache embeddings by message hash' 'Retry the embedding call once on timeout'; do
  once "\"$s\" is on $A" $S main..$A "$s"
done
once "\"Log the latency of embedding calls\" is on $T" $S main..$T 'Log the latency of embedding calls'
expect "$T still builds on the embedding client" git -C $S cat-file -e $T:router/embed_cache.py
expect "the client retries on timeout on $A" sh -c "git -C $S show $A:router/embed_client.py | grep -q 'for attempt in'"
expect 'main was not rewritten' git -C $S merge-base --is-ancestor 'v1.3.1^{commit}' main
expect_not 'no commit reachable from any ref on the server (branches, tags, pull request refs) contains the secret' in_history $S
expect_not 'the server no longer stores the blob at all' git -C $S cat-file -e "$blob"
expect "an ignore rule on $A covers deploy/staging.env" \
  sh -c "git -C $S show $A:.gitignore | grep -Eq '^/?(deploy/)?(\\*|staging)?\\.env\$|^/?deploy/\\*\\.env\$|^\\*\\.env\$'"
for c in you nandini kabir tanvi; do
  expect_not "no commit reachable from a ref in $c/ contains the secret" in_history $c
  expect_not "$c/ no longer stores the blob (reflogs expired and pruned, or re-cloned)" git -C $c cat-file -e "$blob"
  expect_not "no rebase is left in progress in $c/" in_progress $c
done
printf '  note  Git state only. If the credential was not revoked first, the incident is still open.\n'
check_end
