#!/usr/bin/env bash
# Chapter 13, section 13.11: a damaged object in an otherwise healthy repository. What Git
# reports, why an ordinary fetch does not repair it, and two repairs from another copy:
# one object through pack-objects and unpack-objects, or everything with "fetch --refetch".
. "$(dirname "$0")/../lib/lab-env.sh"
. "$LAB_SCRIPT_DIR/fixtures.bash"
lab_begin ch13 corruption
quiet 'git init --bare server.git'
_fx_clone searchsvc
cd searchsvc || exit 1
printf 'top_k: 5\n' > retriever.yaml
_c 'Add retriever config'
printf 'def embed(texts):\n    return model.encode(texts)\n' > embed.py
_c 'Add embedding client'
printf 'top_k: 10\n' > retriever.yaml
_c 'Raise top_k to 10'
quiet 'git push -u origin main'
cd "$LAB_DIR" || exit 1
_fx_clone asha asha
cd searchsvc || exit 1
tree=$(git rev-parse 'HEAD~1^{tree}')
treefile=".git/objects/$(printf '%s' "$tree" | sed 's/../&\//')"

snip 01-damage
run "git rev-parse 'HEAD~1^{tree}'"
note 'Simulate a bad disk block: overwrite the file of that tree object with seven bytes.'
run "chmod u+w $treefile"
run "printf 'garbage' > $treefile"

snip 02-symptoms
run 'git status -sb'
run 'git log --oneline -3'
run_rc 'git log --oneline --stat -2'

snip 03-fsck
run_rc 'git fsck'

snip 04-fetch-does-not-help
run_rc 'git fetch origin'
run 'git fsck 2>&1 | tail -1'

snip 05-repair-one-object
note 'Ask a clone that has the object for a pack with that one object, and unpack it here:'
run "echo $tree | git -C ../asha pack-objects --stdout -q | git unpack-objects -q"
run 'git fsck 2>&1 | tail -1'
note 'Nothing changed: a file with that name exists, so the object was not written.'
note 'Move the damaged file out of the object database (keep it as evidence), then repeat.'
run "mv $treefile ../damaged-tree.saved"
run "echo $tree | git -C ../asha pack-objects --stdout -q | git unpack-objects -q"
run_rc 'git fsck'
run 'git log --oneline --stat -2'

snip 06-refetch
note 'The blunt repair: lose two objects, then download everything again from the server.'
run "rm -f $treefile .git/objects/\$(git rev-parse HEAD:embed.py | sed 's/../&\//')"
run_rc 'git fsck'
run 'git fetch --refetch origin'
run_rc 'git fsck'

lab_end
