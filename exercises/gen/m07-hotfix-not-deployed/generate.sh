#!/usr/bin/env bash
# Exercise 7.10 (Level 5): the hotfix that was pushed and is not on the server.
# Builds server.git (the company's Git server since the migration), old-server.git (the host that
# was used before), and the clones you/, asha/ and ravi/ of the project "embed-gateway".
# Read SYMPTOMS.md, not this file, before you start.
. "$(dirname "${BASH_SOURCE[0]}")/../../../labs/lib/lab-env.sh"
. "$COURSE_ROOT/exercises/gen/x1-lib/gen-lib.bash"
[ -n "${LAB_REPLAY:-}" ] || sandbox_begin exercises m07-hotfix-not-deployed
ex_begin m07-hotfix-not-deployed

ex_server
ex_clone asha
cd asha || exit 1
as asha
mkdir -p gateway
printf 'def embed(texts):\n    return client.embed(texts)\n' > gateway/embed.py
printf '# Changelog\n\n## 2.4.0\n\n- First release of the embedding gateway.\n' > CHANGELOG.md
_c 'Add embedding gateway'
quiet 'git push -u origin main'
quiet 'git switch -c release/2.4'
printf '2.4.0\n' > VERSION
_c 'Release 2.4.0'
quiet 'git push -u origin release/2.4'
cd "$LAB_DIR" || exit 1

# The old host, as it was on migration day.
quiet 'git clone --bare server.git old-server.git'
quiet 'git -C old-server.git remote remove origin'

ex_clone you
ex_clone ravi
# The migration script rewrote remote.origin.url. Ravi's clone also had a pushurl, set long ago
# when pushes went through a different address, and the script did not know about it.
quiet 'git -C ravi remote set-url --push origin ../old-server.git'

# Ravi's hotfix.
cd ravi || exit 1
as ravi
quiet 'git switch release/2.4'
printf 'BATCH = 96\n\ndef embed(texts):\n    out = []\n    for i in range(0, len(texts), BATCH):\n        out.extend(client.embed(texts[i:i + BATCH]))\n    return out\n' > gateway/embed.py
_c 'Split embedding requests into batches of 96'
ex_note hotfix "$(git rev-parse HEAD)"
quiet 'git push'

# Asha prepares the release on the real server.
cd "$LAB_DIR/asha" || exit 1
as asha
quiet 'git pull'
printf '# Changelog\n\n## 2.4.1\n\n- Embedding requests are split into batches of 96.\n\n## 2.4.0\n\n- First release of the embedding gateway.\n' > CHANGELOG.md
printf '2.4.1\n' > VERSION
_c 'Prepare changelog for 2.4.1'
quiet 'git push'
ex_note changelog "$(git rev-parse HEAD)"

# Ravi looks again.
cd "$LAB_DIR/ravi" || exit 1
as ravi
quiet 'git fetch'

ex_end
[ -n "${LAB_REPLAY:-}" ] || printf 'Exercise ready. Open a lab shell there:\n  labs/shell "%s"\n' "$LAB_DIR"
