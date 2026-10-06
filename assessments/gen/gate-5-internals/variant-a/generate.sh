#!/usr/bin/env bash
# Gate 5 (Internals), hands-on part, variant A: the project "corpus-sync".
# Builds server.git and ravi/. Ravi's clone is shallow by design; after a crash and a run of a
# disk-cleaning tool it also lacks a pack index, has a stale lock and an empty object file.
# Read SYMPTOMS.md, not this file, before you start: the script is the answer to "what happened".
. "$(dirname "${BASH_SOURCE[0]}")/../../../../labs/lib/lab-env.sh"
. "$COURSE_ROOT/assessments/gen/lib/gate-lib.bash"
[ -n "${LAB_REPLAY:-}" ] || sandbox_begin gates g5-a
gate_begin g5-a

gate_server
gate_clone seed
cd seed || exit 1
mkdir -p sync
printf 'def list_remote(bucket):\n    return sorted(bucket.keys())\n' > sync/listing.py
_c 'Add remote listing'
printf 'def diff(local, remote):\n    return [k for k in remote if k not in local]\n' > sync/diff.py
_c 'Add listing diff'
quiet 'git tag -a v1.2.0 -m "corpus-sync 1.2.0"'
printf 'def copy(src, dst, keys):\n    for k in keys:\n        dst[k] = src[k]\n' > sync/copy.py
_c 'Add copy step'
printf '# corpus-sync\n\nMirrors a document bucket.\n' > README.md
_c 'Add README'
quiet 'git push -u origin main'
quiet 'git push origin v1.2.0'
gate_note server_main "$(git rev-parse main)"
cd "$LAB_DIR" || exit 1
rm -rf seed

# Ravi's clone was made by the team's bootstrap script, which clones with --depth 1.
quiet "git clone --depth 1 file://$LAB_DIR/server.git ravi"
quiet 'git -C ravi remote set-url origin ../server.git'
quiet "git -C ravi config set user.name 'Ravi Menon' && git -C ravi config set user.email ravi@example.com"
cd ravi || exit 1
as ravi
printf 'def copy(src, dst, keys):\n    for k in keys:\n        if k not in dst:\n            dst[k] = src[k]\n' > sync/copy.py
_c 'Skip keys that already exist'
gate_note head "$(git rev-parse HEAD)"
# Staged, not committed, when the machine lost power.
printf 'MANIFEST_VERSION = 2\n\ndef manifest(keys):\n    return {"version": MANIFEST_VERSION, "keys": sorted(keys)}\n' > sync/manifest.py
quiet 'git add sync/manifest.py'
blob=$(git rev-parse :sync/manifest.py)
gate_note blob "$blob"

# The crash: the object file of the staged blob is empty and the index lock was left behind.
f=".git/objects/$(printf %s "$blob" | cut -c1-2)/$(printf %s "$blob" | cut -c3-)"
chmod u+w "$f"; : > "$f"
: > .git/index.lock
# The disk-cleaning tool: it removes "index caches".
rm -f .git/objects/pack/*.idx .git/objects/pack/*.rev

gate_end
gate_ready
