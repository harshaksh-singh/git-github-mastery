#!/usr/bin/env bash
# Final test, section 15 (Production incidents): interpretation item I1, the evidence of a
# history that was cleaned and then got its old commits back. The credential is an obvious dummy.
. "$(dirname "$0")/../lib/lab-env.sh"
lab_begin final s15

quiet 'git init -q --bare server.git'
quiet 'git clone -q server.git you && git -C you remote set-url origin ../server.git'
cd you || exit 1
printf 'def embed(texts):\n    return client.embed(texts)\n' > embed.py
quiet 'git add . && git commit -q -m "Add the embedding client"'
base=$(git rev-parse HEAD)
printf 'EMBED_API_KEY=dummy-not-a-real-key-2222\n' > .env
quiet 'git add . && git commit -q -m "Add local environment"'
leak=$(git rev-parse HEAD)
printf 'def batch(texts, n=32):\n    return [texts[i:i + n] for i in range(0, len(texts), n)]\n' > batch.py
quiet 'git add . && git commit -q -m "Batch the requests"'
printf 'def norm(v):\n    return v / (v @ v) ** 0.5\n' > norm.py
quiet 'git add . && git commit -q -m "Normalize the vectors"'
quiet 'git push -q -u origin main'
cd "$LAB_DIR" || exit 1
quiet 'git clone -q server.git ravi && git -C ravi remote set-url origin ../server.git'
quiet "git -C ravi config set user.name 'Ravi Menon' && git -C ravi config set user.email ravi@example.com"
# The cleanup: the commit that added .env is cut out and the branch is force-pushed.
cd you || exit 1
quiet "git rebase -q --onto $base $leak main"
quiet 'git push -q --force-with-lease origin main'
# The next morning Ravi commits in his clone, which still has the old history, and pulls.
cd "$LAB_DIR/ravi" || exit 1
as ravi
printf 'def cache_key(text):\n    return hash(text)\n' > cache.py
quiet 'git add . && git commit -q -m "Add a cache key"'
quiet 'git pull -q --no-rebase --no-edit'
quiet 'git push -q'
cd "$LAB_DIR/you" || exit 1
as you
snip i1-transcript
note 'Yesterday you removed a leaked key from history and force-pushed main. This morning:'
run 'git fetch'
run 'git log --graph --format="%h %an: %s" origin/main'
run 'git log --oneline origin/main -- .env'
run 'git reflog show origin/main'
lab_end
