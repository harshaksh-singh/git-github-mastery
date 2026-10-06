#!/usr/bin/env bash
# Model answers for exercises 17.1 to 17.8 (Module 17: the index, refs and the .git directory)
# as real transcripts on the practice repositories built by
# exercises/gen/m17-ingestd-practice/generate.sh.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$LAB_SCRIPT_DIR/replay-lib.bash"
lab_begin ex2 answers-m17
ex_load m17-ingestd-practice

cd ex-17-1 || exit 1
snip 17-1-index
run 'git ls-files --stage'
run "echo 'workers: 8' >> config.yaml"
run 'git ls-files --stage config.yaml'
run 'git status -s'
snip 17-1-add
run 'git add config.yaml'
run 'git ls-files --stage config.yaml'
run 'git rev-parse HEAD:config.yaml'
run 'git rev-parse :config.yaml'
run "git ls-files --debug config.yaml | grep -e size -e flags"
cd "$LAB_DIR" || exit 1

cd ex-17-2 || exit 1
snip 17-2-loose
run 'git for-each-ref'
run 'find .git/refs -type f | sort'
snip 17-2-packed
run 'git pack-refs --all'
run 'find .git/refs -type f | sort'
run 'cat .git/packed-refs'
snip 17-2-both
run "echo 'See docs/format.md.' >> README.md && git commit -q -am 'Point to the format description'"
run 'find .git/refs -type f | sort'
run 'cat .git/refs/heads/main'
run 'grep refs/heads/main .git/packed-refs'
run 'git rev-parse main'
cd "$LAB_DIR" || exit 1

cd ex-17-3 || exit 1
snip 17-3-head
run 'cat .git/HEAD'
run 'git symbolic-ref HEAD'
run 'git symbolic-ref --short HEAD'
snip 17-3-update-ref
run 'git update-ref refs/heads/experiment HEAD~1'
run 'git branch -v'
run_rc 'git update-ref refs/heads/experiment HEAD HEAD'
run 'git update-ref refs/heads/experiment HEAD HEAD~1'
run 'git reflog show experiment'
run 'git update-ref -d refs/heads/experiment'
run 'git branch'
cd "$LAB_DIR" || exit 1

cd ex-17-4 || exit 1
snip 17-4-merge
run_rc 'git merge feature/streaming'
snip 17-4-stages
run 'git status -s'
run 'git ls-files -u'
snip 17-4-read
run 'git show :1:config.yaml | head -1'
run 'git show :2:config.yaml | head -1'
run 'git show :3:config.yaml | head -1'
run 'git merge --abort'
run 'git ls-files -u | wc -l'
cd "$LAB_DIR" || exit 1

cd ex-17-5 || exit 1
snip 17-5-names
run 'git rev-parse --abbrev-ref HEAD'
run 'git rev-parse --symbolic-full-name HEAD'
run 'git switch -q --detach'
run 'git rev-parse --abbrev-ref HEAD'
run 'git rev-parse --symbolic-full-name HEAD'
run 'git switch -q main'
snip 17-5-index
run "echo 'Run it with python3 -m src.ingest.' >> README.md && git add README.md"
run 'git rev-parse HEAD:README.md'
run 'git rev-parse :README.md'
snip 17-5-where
run 'cd src'
run 'git rev-parse --show-prefix'
run 'git rev-parse --show-cdup'
run 'git rev-parse --show-toplevel'
run 'git rev-parse --git-dir'
run 'cd ..'
snip 17-5-errors
run 'git rev-parse -q --verify refs/heads/nope; echo "exit status: $?"'
run_rc 'git rev-parse HEAD^2'
cd "$LAB_DIR" || exit 1

cd ex-17-6 || exit 1
snip 17-6-commands
run 'git ls-tree HEAD'
run "git commit-tree HEAD:docs -m 'Snapshot of the documentation'"
id=$(git commit-tree HEAD:docs -m 'Snapshot of the documentation')
run "git update-ref refs/heads/docs-snapshot ${id:0:7}"
snip 17-6-graph
run 'git log --graph --oneline --all'
snip 17-6-inspect
run 'git ls-tree docs-snapshot'
run 'git cat-file -p docs-snapshot'
run 'git status -sb'
run_rc 'git merge docs-snapshot'
cd "$LAB_DIR" || exit 1

cd ex-17-7 || exit 1
snip 17-7-symptom
run 'git branch'
run_rc 'git log --oneline -1 release/1.0'
snip 17-7-evidence
run 'cat .git/refs/heads/release/1.0'
run 'grep release .git/packed-refs'
run "awk '{print \$1, \$2}' .git/logs/refs/heads/release/1.0"
snip 17-7-trap
run 'mv .git/refs/heads/release/1.0 ../release-1.0.broken'
run 'git log --oneline -2 release/1.0'
snip 17-7-fix
new=$(tail -1 .git/logs/refs/heads/release/1.0 | cut -d' ' -f2)
run "git cat-file -t ${new:0:7}"
run "git update-ref -m 'repair: newest value from the reflog' refs/heads/release/1.0 ${new:0:7}"
run 'git log --oneline -3 release/1.0'
run 'git fsck'
cd "$LAB_DIR" || exit 1

cd ex-17-8/work || exit 1
snip 17-8-symptom
run 'cat config.yaml'
run 'git status -sb'
run 'git diff'
run_rc 'git pull'
snip 17-8-diagnose
run 'git ls-files -v'
snip 17-8-fix
run 'git update-index --no-skip-worktree config.yaml'
run 'git status -sb'
run 'git stash'
run 'git pull -q'
run 'git stash pop'
run 'cat config.yaml'
lab_end
