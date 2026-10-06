#!/usr/bin/env bash
# Exercises of Module 3 (commits; Chapter 6): the model runs behind
# exercises/m01-m05-foundations.md and solutions/exercises-m01-m05.md.
# Snippet names start with the exercise number: e04-... belongs to Exercise 3.4.
. "$(dirname "$0")/../lib/lab-env.sh"
lab_begin ex1 ex-m03

# ---- Exercise 3.1 (Level 1): read a commit field by field
snip e01-read
run 'git init -q batch-scorer'
run 'cd batch-scorer'
run "printf 'def score(batch):\n    return [len(x) for x in batch]\n' > scorer.py"
run 'git add scorer.py'
run 'git commit -q -m "Add batch scorer"'
run "printf 'def score(batch):\n    return [len(x.strip()) for x in batch]\n' > scorer.py"
run 'git commit -q -am "Ignore surrounding whitespace when scoring"'
run 'git cat-file -p HEAD'
run 'git rev-parse HEAD "HEAD^{tree}" HEAD~1'
run 'git show -s --format=fuller HEAD'

# ---- Exercise 3.2 (Level 1): author and committer
snip e02-author
run "printf 'def mean(xs):\n    return sum(xs) / len(xs)\n' > stats.py"
run 'git add stats.py'
run "git commit -q --author='Asha Rao <asha@example.com>' --date='2026-09-01T09:00:00+05:30' -m 'Add mean helper'"
run 'git show -s --format=fuller HEAD'
run "git log --format='%h | author %an, %ad | committer %cn, %cd' --date=short"
run 'git log --oneline --author=Asha'
run 'git log --oneline --committer=Asha'

# ---- Exercise 3.3 (Level 1): zero, one and two parents
snip e03-parents
run 'git switch -q -c feature/median'
run "printf 'def median(xs):\n    return sorted(xs)[len(xs) // 2]\n' >> stats.py"
run 'git commit -q -am "Add median helper"'
run 'git switch -q main'
run 'git merge -q --no-ff -m "Merge feature/median" feature/median'
run 'git log --graph --oneline'
run 'git rev-list --parents -n 1 HEAD'
run 'git rev-list --parents -n 1 HEAD~1'
run 'git rev-list --parents -n 1 --max-parents=0 HEAD'
run 'git show -s --format=%s HEAD^1'
run 'git show -s --format=%s HEAD^2'
cd "$LAB_DIR"

# ---- Exercise 3.4 (Level 2, prediction): an empty commit
snip e04-setup
run 'git init -q rerun'
run 'cd rerun'
run "printf 'schedule: nightly\n' > pipeline.yaml"
run 'git add pipeline.yaml'
run 'git commit -q -m "Add pipeline"'
run 'git commit -q --allow-empty -m "Trigger a re-run of the nightly evaluation"'
snip e04-answer
run 'git rev-parse "HEAD^{tree}" "HEAD~1^{tree}"'
run 'git show --stat --format="%h %s" HEAD'
run_rc 'git diff --quiet HEAD~1 HEAD'
run 'git rev-list --count HEAD'
run "find .git/objects -type f | wc -l | tr -d ' '"
cd "$LAB_DIR"

# ---- Exercise 3.5 (Level 2, prediction): which date does git log show, which does --since use?
snip e05-setup
run 'git init -q dates'
run 'cd dates'
run "printf 'x\n' > a.txt"
run 'git add a.txt'
run "git commit -q --date='2026-08-01T12:00:00+00:00' -m 'Backdated work'"
snip e05-answer
run 'git log -1'
run "git log -1 --format='author date:    %ad%ncommitter date: %cd'"
run 'git log --oneline --since=2026-08-15'
run 'git log --oneline --until=2026-08-15'
cd "$LAB_DIR"

# ---- Exercise 3.6 (Level 2): two atomic commits and a trailer
quiet 'git init atomic'
cd atomic
quiet "printf 'def retry(call, attempts):\n    for i in range(attempts):\n        try:\n            return call()\n        except TimeoutError:\n            pass\n' > retry.py"
quiet "printf '# retry\n\nRetries a call on timeout.\n' > README.md"
quiet 'git add . && git commit -m "Add retry helper"'
quiet "printf 'def retry(call, attempts):\n    for i in range(attempts):\n        try:\n            return call()\n        except TimeoutError:\n            pass\n    raise TimeoutError(\"all attempts timed out\")\n' > retry.py"
quiet "printf '# retry\n\nRetries a call on timeout.\n\n## Development\n\nRun the tests with python3 -m unittest.\n' > README.md"
snip e06-before
run 'git status --short'
run 'git diff --stat'
snip e06-commits
run 'git add retry.py'
run "git commit -q -m 'Raise TimeoutError when every attempt timed out' -m 'retry() returned None after the last failed attempt, so callers treated a timeout as an empty result.' --trailer 'Co-authored-by: Asha Rao <asha@example.com>'"
run 'git add README.md'
run "git commit -q -m 'Document how to run the tests'"
snip e06-verify
run 'git log --stat --format="--- %h %s" -2'
run 'git log -1 --format=%B HEAD~1'
run 'git log -1 --format="%(trailers:key=Co-authored-by,valueonly)" HEAD~1'
cd "$LAB_DIR"

# ---- Exercise 3.7 (Level 3): "ahead 1, behind 1" with nobody else pushing
quiet 'git init --bare origin.git'
quiet 'git clone origin.git scoring-api'
cd scoring-api
quiet "printf 'PASS_MARK = 0.7\n' > settings.py && git add settings.py && git commit -m 'Add pass mark'"
quiet "printf 'PASS_MARK = 0.7\nMAX_BATCH = 64\n' > settings.py && git commit -am 'Add maximum batch sise'"
quiet 'git push -u origin main'
quiet "git commit --amend -m 'Add maximum batch size'"
snip e07-evidence
run 'git status -sb'
run_rc 'git push'
run 'git log --oneline --graph --all'
snip e07-diagnosis
run 'git reflog -3'
run "git rev-parse 'HEAD^{tree}' 'origin/main^{tree}'"
run 'git log --format="%h %an %ad | %cd | %s" --date=format:%H:%M HEAD -1'
run 'git log --format="%h %an %ad | %cd | %s" --date=format:%H:%M origin/main -1'
snip e07-fix-shared
note 'If anyone may already have the pushed commit: go back to it and keep the message as it is.'
run "git reset --soft '@{u}'"
run 'git status -sb'
run 'git log --oneline --graph --all'
cd "$LAB_DIR"

# ---- Exercise 3.8 (Level 3): the commit that --author does not find
quiet 'git init audit'
cd audit
quiet "printf 'limit = 100\n' > quota.py && git add quota.py && git commit -m 'Add quota'"
as asha
tick
quiet "printf 'limit = 100\nburst = 20\n' > quota.py && git commit -a --author='Ravi Menon <ravi@example.com>' --date='2026-09-04T18:20:00+05:30' -m 'Allow a burst above the quota'"
as you
quiet "printf '# quota\n' > README.md && git add README.md && git commit -m 'Add README'"
snip e08-evidence
run 'git log --oneline'
run 'git log --oneline --author=Asha'
run 'git log --oneline --author=Ravi'
snip e08-answer
run "git log --format='%h  author: %an  committer: %cn  %s'"
run 'git log --oneline --committer=Asha'
run 'git show -s --format=fuller HEAD~1'
cd "$LAB_DIR"

lab_end
