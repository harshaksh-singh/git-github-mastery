#!/usr/bin/env bash
# Gate 8 (Security), prediction part. Everything is local and defensive; the "secrets" are
# obvious dummies. The pN-setup snippets are printed in the gate file, the pN-answer snippets
# only in the answer key.
. "$(dirname "$0")/../lib/lab-env.sh"
lab_begin gates g8-predict

# ---- P1: a secret that was "removed"
snip p1-setup
run 'git init -q notifier'
run 'cd notifier'
run "printf 'def notify(msg):\n    print(msg)\n' > notify.py && git add . && git commit -q -m 'Add notifier'"
run "mkdir config && printf 'SMTP_PASSWORD=dummy-not-a-real-password\n' > config/prod.env"
run "git add . && git commit -q -m 'Add production settings'"
run "printf 'def notify(msg):\n    print(\"[notify]\", msg)\n' > notify.py && git commit -q -am 'Prefix notifications'"
run "git rm -q config/prod.env && git commit -q -m 'Remove secrets from the repository'"
snip p1-answer
run_rc "git grep -c 'dummy-not-a-real' HEAD"
run "git log --format=%s -S'dummy-not-a-real'"
run "git log --format=%s -- config/prod.env"
run 'for c in $(git rev-list HEAD); do git cat-file -e "$c:config/prod.env" 2>/dev/null && git log -1 --format=%s "$c"; done'
run 'git show HEAD~1:config/prod.env'
cd "$LAB_DIR"

# ---- P2: what a clone copies of the things that execute
snip p2-setup
run 'git init -q toolbox'
run 'cd toolbox'
run "mkdir .githooks && printf '#!/bin/sh\necho tracked hook\n' > .githooks/pre-commit && chmod +x .githooks/pre-commit"
run "printf '*.ipynb filter=strip\n' > .gitattributes"
run 'git add . && git commit -q -m "Add hooks directory and attributes"'
run "printf '#!/bin/sh\necho local hook\n' > .git/hooks/post-checkout && chmod +x .git/hooks/post-checkout"
run 'git config set core.hooksPath .githooks'
run "git config set filter.strip.clean 'sed s/x/y/'"
run 'cd ..'
run 'git clone -q toolbox copy'
run 'cd copy'
snip p2-answer
run 'git ls-files'
run 'ls .git/hooks | grep -c -v "\.sample$" || true'
run_rc 'git config get core.hooksPath'
run_rc 'git config get filter.strip.clean'
run 'git check-attr filter notebook.ipynb'
cd "$LAB_DIR"

# ---- P3: a history rewrite and a clone that did not hear about it
mkdir p3 && cd p3 || exit 1
quiet 'git init --bare server.git'
quiet 'git clone server.git you && git -C you remote set-url origin ../server.git'
cd you || exit 1
quiet "printf 'a\n' > app.txt && git add . && git commit -m 'Add app'"
quiet "printf 'API_KEY=dummy-not-a-real-key\n' > keys.env && git add . && git commit -m 'Add key file'"
quiet "printf 'a\nb\n' > app.txt && git commit -am 'Extend app'"
quiet 'git push -u origin main'
cd ..
quiet 'git clone server.git asha && git -C asha remote set-url origin ../server.git'
cd you || exit 1
snip p3-setup
note 'server.git has three commits on main: "Add app", "Add key file", "Extend app".'
note 'you/ and asha/ are clones of it, both up to date. In you/:'
run "git rebase -q --onto HEAD~2 HEAD~1 main"
run 'git log --format=%s main'
run 'git push -q --force-with-lease origin main'
note 'In asha/, who was not told. She commits and pulls, then pushes:'
as asha
run "printf 'notes\n' > ../asha/NOTES.md && git -C ../asha add NOTES.md && git -C ../asha commit -q -m 'Add notes'"
run 'git -C ../asha pull -q --no-rebase'
run 'git -C ../asha push -q origin main'
as you
snip p3-answer
run 'git -C ../server.git log --graph --format=%s main'
run "git -C ../server.git log --format=%s -S'dummy-not-a-real' main"
run_rc 'git -C ../server.git cat-file -e main:keys.env'
cd "$LAB_DIR"

# ---- P4: a server-side guard that looks at the tip only
mkdir p4 && cd p4 || exit 1
quiet 'git init --bare server.git'
cat > server.git/hooks/pre-receive <<'HOOK'
#!/bin/sh
# Reject a push when the new tip of a ref contains the pattern.
while read old new ref; do
  if git grep -q 'dummy-not-a-real' "$new" --; then
    echo "rejected: $ref contains a secret pattern" >&2
    exit 1
  fi
done
HOOK
chmod +x server.git/hooks/pre-receive
quiet 'git clone server.git you && git -C you remote set-url origin ../server.git'
cd you || exit 1
quiet "printf 'a\n' > app.txt && git add . && git commit -m 'Add app'"
quiet 'git push -u origin main'
snip p4-setup
run 'cat ../server.git/hooks/pre-receive'
run "printf 'TOKEN=dummy-not-a-real-token\n' > .env && git add .env && git commit -q -m 'Add environment file'"
snip p4-answer-a
run_rc 'git push origin main'
snip p4-setup-b
run "git rm -q .env && git commit -q -m 'Remove environment file'"
snip p4-answer-b
run_rc 'git push -q origin main'
run "git -C ../server.git log --format=%s -S'dummy-not-a-real' main"
lab_end
