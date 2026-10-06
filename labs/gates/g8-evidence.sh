#!/usr/bin/env bash
# Gate 8 (Security), hands-on: the Git evidence for cases 2 and 3 of both variants. A bare
# repository plays the server. The "secrets" are obvious dummies. Nothing is run on GitHub.
. "$(dirname "$0")/../lib/lab-env.sh"
lab_begin gates g8-evidence

# ---- Variant A: a storage key in a settings file, "removed" two commits later
quiet 'git init --bare server.git'
quiet 'git clone server.git you && git -C you remote set-url origin ../server.git'
cd you || exit 1
mkdir -p uploader deploy
printf 'def upload(bucket, path):\n    bucket.put(path)\n' > uploader/upload.py
quiet 'git add . && git commit -m "Add uploader"'
quiet 'git tag -a v0.4.0 -m "uploader 0.4.0"'
as ravi
printf 'STORAGE_ACCOUNT=acme-uploads\nSTORAGE_KEY=dummy-storage-key-not-real-0000\n' > deploy/settings.env
quiet 'git add . && git commit -m "Add deployment settings"'
as you
printf 'def upload(bucket, path, retries=3):\n    bucket.put(path)\n' > uploader/upload.py
quiet 'git commit -am "Retry uploads"'
quiet 'git tag -a v0.5.0 -m "uploader 0.5.0"'
as ravi
quiet 'git rm deploy/settings.env && git commit -m "Remove settings file, use the vault"'
as you
quiet 'git push -u origin main && git push origin v0.4.0 v0.5.0'
quiet 'git switch -c feature/resume main~1'
printf 'RESUME = True\n' > uploader/resume.py
quiet 'git add . && git commit -m "Resume interrupted uploads"'
quiet 'git push -u origin feature/resume'
quiet 'git switch main'

snip a2-evidence
run "git grep -c 'STORAGE_KEY' HEAD || echo 'no match in the tip of main'"
run "git log --all --format='%h %an: %s' -S'dummy-storage-key'"
run "git for-each-ref --format='%(refname)' --contains \"\$(git log --all --format=%H -S'dummy-storage-key' | tail -1)\""
run 'git ls-remote origin'
run "for r in main v0.4.0 v0.5.0 feature/resume; do git cat-file -e \"\$r:deploy/settings.env\" 2>/dev/null && echo \"\$r: the tree has deploy/settings.env\" || echo \"\$r: not in the tree\"; done"

# The clean-up: every commit from the first affected one on is replaced. A second clone that
# was not told merges the old history back in.
cd "$LAB_DIR" || exit 1
quiet 'git clone server.git asha && git -C asha remote set-url origin ../server.git'
cd you || exit 1
first=$(git log --all --format=%H -S'dummy-storage-key' | tail -1)
quiet "git rebase --onto $first~1 $first main"
quiet 'git push --force-with-lease origin main'
cd "$LAB_DIR/asha" || exit 1
as asha
printf '# uploader\n' > README.md
quiet 'git add . && git commit -m "Add README"'
quiet 'git pull --no-rebase'
quiet 'git push origin main'
cd "$LAB_DIR/you" || exit 1
as you
quiet 'git fetch origin'

snip a3-evidence
note 'The day after the clean-up, in your clone, after a fetch:'
run "git log --graph --format='%h %an: %s' origin/main"
run "git log --format='%h %s' -S'dummy-storage-key' origin/main"
run "git log -1 --format='%h parents: %p' origin/main"
run 'git reflog show origin/main --format="%h %gs"'
cd "$LAB_DIR"

# ---- Variant B, case 2: a key in a notebook, on a branch that was squash-merged and deleted
mkdir b2 && cd b2 || exit 1
quiet 'git init --bare server.git'
quiet 'git clone server.git you && git -C you remote set-url origin ../server.git'
cd you || exit 1
printf 'def score(rows):\n    return len(rows)\n' > score.py
quiet 'git add . && git commit -m "Add scorer"'
quiet 'git push -u origin main'
as asha
quiet 'git switch -c feature/eval-notebook'
printf '{"cells": [{"outputs": ["Authorization: Bearer dummy-eval-api-key-not-real-0000"]}]}\n' > eval.ipynb
quiet 'git add . && git commit -m "Add evaluation notebook"'
printf '{"cells": [{"outputs": []}]}\n' > eval.ipynb
quiet 'git commit -am "Clear notebook outputs"'
quiet 'git push -u origin feature/eval-notebook'
# The hosting service: a ref for the pull request, a squash merge, and the branch deleted.
quiet 'git push origin feature/eval-notebook:refs/pull/12/head'
quiet 'git switch main'
quiet 'git merge --squash feature/eval-notebook && git commit -m "Add evaluation notebook (#12)"'
quiet 'git push origin main'
quiet 'git push origin --delete feature/eval-notebook'
quiet 'git branch -D feature/eval-notebook'
quiet 'git fetch --prune'
quiet 'git reflog expire --expire=now --all'
quiet 'git gc --prune=now'
as you

snip b2-evidence
note 'A fresh look from a clone that never had the branch:'
run "git log --all --format='%h %s' -S'dummy-eval-api-key'"
run 'git ls-remote origin'
run "git fetch -q origin 'refs/pull/*/head:refs/remotes/origin/pr/*'"
run "git log --all --format='%h %an: %s' -S'dummy-eval-api-key'"
run "git for-each-ref --format='%(refname)' --contains \"\$(git log --all --format=%H -S'dummy-eval-api-key' | tail -1)\""
cd "$LAB_DIR"

# ---- Variant B, case 3: a token in a remote URL
quiet 'git init ci-clone'
cd ci-clone || exit 1
quiet 'git remote add origin https://ci-bot:dummy-token-not-real-0000@git.example.com/acme/reports.git'
snip b3-evidence
run 'git remote -v'
run 'grep -n url .git/config'
run 'git config get --show-origin transfer.credentialsInUrl || echo "transfer.credentialsInUrl is not set"'
snip b3-fix
run 'git config set transfer.credentialsInUrl die'
run_rc 'git remote set-url origin https://git.example.com/acme/reports.git'
run 'git config set remote.origin.url https://git.example.com/acme/reports.git'
run 'git remote -v'
lab_end
