#!/usr/bin/env bash
# Chapter 3, section 3.5: reading objects with plumbing (cat-file, ls-tree) and with git show.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$LAB_SCRIPT_DIR/common/inference-service.sh" || exit 1
lab_begin ch03 read-objects
build_inference_service

snip 01-cat-file
note 'Type, size and content of one object, named three different ways.'
run 'git cat-file -t HEAD'
run 'git cat-file -t "HEAD^{tree}"'
run 'git cat-file -t HEAD:config.toml'
run 'git cat-file -s HEAD:config.toml'
run 'git cat-file -p HEAD:config.toml'
note '-e answers "does this object exist?" with the exit status only.'
run_rc 'git cat-file -e HEAD:config.toml'
run_rc 'git cat-file -e 1234567890123456789012345678901234567890'

snip 02-batch-check
note 'Many objects in one process: names on standard input, one line of output each.'
run "printf 'HEAD\\nHEAD^{tree}\\nHEAD:run.sh\\nv1.0.0\\nno-such-branch\\n' | git cat-file --batch-check"
note 'A custom format. %(rest) echoes whatever followed the name on the input line.'
run "git ls-tree -r HEAD | awk '{print \$3, \$4}' | git cat-file --batch-check='%(objectsize) %(objecttype) %(rest)'"

snip 03-batch-all-objects
note 'Every object in the database, reachable or not, without walking any history:'
run "git cat-file --batch-all-objects --batch-check='%(objecttype)' | sort | uniq -c"
note 'The three largest blobs in the whole history, with the path that leads to them:'
run "git rev-list --objects --all | git cat-file --batch-check='%(objecttype) %(objectsize) %(rest)' | grep '^blob' | sort -k2 -n | tail -3"

snip 04-ls-tree
run 'git ls-tree HEAD src/'
note '-r recurses into subtrees and lists only the leaves; -t also shows the trees on the way.'
run 'git ls-tree -r HEAD'
run 'git ls-tree -r -t HEAD src'
note '-l adds the blob size; -d lists only trees.'
run 'git ls-tree -l HEAD'
run 'git ls-tree -d --name-only HEAD'

snip 05-show
note 'git show adapts to the object type. A blob: its content.'
run 'git show HEAD:config.toml'
note 'A tree: the names in it.'
run 'git show "HEAD^{tree}"'
note 'An annotated tag: the tag object, then the commit it points at.'
run 'git show --no-patch v1.0.0'
note 'A commit in raw form: the object headers, then the message.'
run 'git show --no-patch --format=raw HEAD^2'

lab_end
