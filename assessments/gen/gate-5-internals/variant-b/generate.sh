#!/usr/bin/env bash
# Gate 5 (Internals), hands-on part, variant B (retake): the project "shardlog".
# Builds server.git and asha/. Asha's clone is a blobless partial clone whose remote has moved;
# a file-syncing tool has also emptied a ref file and truncated the index.
# Read SYMPTOMS.md, not this file, before you start: the script is the answer to "what happened".
. "$(dirname "${BASH_SOURCE[0]}")/../../../../labs/lib/lab-env.sh"
. "$COURSE_ROOT/assessments/gen/lib/gate-lib.bash"
[ -n "${LAB_REPLAY:-}" ] || sandbox_begin gates g5-b
gate_begin g5-b

gate_server server-old.git
quiet 'git -C server-old.git config set uploadpack.allowFilter true'
gate_clone seed server-old.git
cd seed || exit 1
mkdir -p shardlog
printf 'FIELDS = ["ts", "shard", "payload"]\n' > shardlog/schema.py
_c 'Add log schema'
quiet 'git tag -a v1.0.0 -m "shardlog 1.0.0"'
printf 'FIELDS = ["ts", "shard", "payload", "checksum"]\n' > shardlog/schema.py
_c 'Add checksum field'
printf 'def write(log, record):\n    log.append(record)\n' > shardlog/writer.py
_c 'Add writer'
printf 'FIELDS = ["ts", "shard", "tenant", "payload", "checksum"]\n' > shardlog/schema.py
_c 'Add tenant field'
printf '# shardlog\n\nAppend-only log, one file per shard.\n' > README.md
_c 'Add README'
quiet 'git push -u origin main'
quiet 'git push origin v1.0.0'
gate_note server_main "$(git rev-parse main)"
cd "$LAB_DIR" || exit 1
rm -rf seed

# Asha's clone: blobless, as the onboarding guide recommends for this repository.
quiet "git clone --filter=blob:none file://$LAB_DIR/server-old.git asha"
quiet 'git -C asha remote set-url origin ../server-old.git'
quiet "git -C asha config set user.name 'Asha Rao' && git -C asha config set user.email asha@example.com"
cd asha || exit 1
as asha
printf 'def write(log, record, shard_id):\n    log.append({"shard": shard_id, **record})\n' > shardlog/writer.py
_c 'Add shard id to the writer'
gate_note head "$(git rev-parse HEAD)"
printf '# shardlog\n\nAppend-only log, one file per shard.\n\nEvery record carries the shard id.\n' > README.md
gate_note readme "$(git hash-object README.md)"
cd "$LAB_DIR" || exit 1

# The weekend: the server repository is renamed, and a file-syncing tool damages two files.
mv server-old.git server.git
: > asha/.git/refs/heads/main
printf 'DIRC' > asha/.git/index

gate_end
gate_ready
