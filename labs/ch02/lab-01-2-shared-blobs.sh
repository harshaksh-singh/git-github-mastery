#!/usr/bin/env bash
# Lab 1.2: prove that snapshots share unchanged blobs and unchanged subtrees, then delete a
# shared object on purpose and rebuild it from the same content.
. "$(dirname "$0")/../lib/lab-env.sh"
lab_begin ch02 lab-01-2-shared-blobs

snip 01-first-commit
run 'git init promptlib'
run 'cd promptlib'
run 'mkdir prompts eval'
run "printf '# promptlib\n' > README.md"
run "printf 'Answer only from the provided context.\n' > prompts/system.txt"
run "printf 'Reply with PASS or FAIL.\n' > prompts/judge.txt"
run "printf 'def exact_match(pred, gold):\n    return pred == gold\n' > eval/metrics.py"
run 'git add .'
run 'git commit -q -m "Add prompts and metrics"'
run 'git ls-tree -r -t HEAD'

snip 02-count
run "git cat-file --batch-all-objects --batch-check | cut -d' ' -f2 | sort | uniq -c"

snip 03-second-commit
run "printf 'Reply with PASS or FAIL, then one sentence of reasoning.\n' > prompts/judge.txt"
run 'git commit -q -am "Ask the judge for its reasoning"'
run 'git ls-tree -r -t HEAD'
run "git cat-file --batch-all-objects --batch-check | cut -d' ' -f2 | sort | uniq -c"

snip 04-what-changed
run 'git diff-tree -t --abbrev HEAD~1 HEAD'
run "git rev-parse HEAD~1:eval HEAD:eval"

snip 05-third-commit
run "printf 'Reply with PASS or FAIL.\n' > prompts/judge.txt"
run 'git commit -q -am "Go back to the short judge prompt"'
run "git cat-file --batch-all-objects --batch-check | cut -d' ' -f2 | sort | uniq -c"
run "git rev-parse 'HEAD~2^{tree}' 'HEAD^{tree}'"
run 'git log --oneline'

snip 06-break
note 'Failure scenario: delete one loose object that all three snapshots share.'
run 'git rev-parse HEAD:prompts/system.txt'
shared=$(git rev-parse HEAD:prompts/system.txt)
objfile=".git/objects/$(printf '%s' "$shared" | cut -c1-2)/$(printf '%s' "$shared" | cut -c3-)"
run "rm -f $objfile"
run 'git status'
run_rc 'git show HEAD~2:prompts/system.txt'
run_rc 'git fsck'

snip 07-repair
note 'Recovery: which path had that ID, and does the file on disk still hash to it?'
short=$(printf '%s' "$shared" | cut -c1-7)
run "git ls-tree -r HEAD | grep $short"
run 'git hash-object prompts/system.txt'
note 'Same ID, so the same bytes. Write the object back.'
run 'git hash-object -w prompts/system.txt'

snip 08-verify
run 'git show HEAD~2:prompts/system.txt'
run_rc 'git fsck'
run "git cat-file --batch-all-objects --batch-check | cut -d' ' -f2 | sort | uniq -c"

lab_end
