#!/usr/bin/env bash
# Chapter 3, section 3.8: where Git checks object IDs and where it does not.
# One loose object is replaced by a well-formed object with different content. Ordinary reads
# trust it; git fsck and the fetch machinery recompute the ID from the content and refuse it.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$LAB_SCRIPT_DIR/common/inference-service.sh" || exit 1
lab_begin ch03 object-integrity
build_inference_service

snip 01-tamper
run 'git rev-parse HEAD:src/server.py'
run 'git cat-file -p HEAD:src/server.py'
note 'Overwrite that loose object with a valid zlib stream: same header, same length, other content.'
run 'chmod u+w .git/objects/e2/238784c412f0a5151764c07c7a44e7b3a9c073'
run "python3 -c \"import sys, zlib; open(sys.argv[1], 'wb').write(zlib.compress(b'blob 40\\0def predict(text):\\n    return 999999999\\n'))\" .git/objects/e2/238784c412f0a5151764c07c7a44e7b3a9c073"
note 'Ordinary commands read the object by its name and do not recompute the hash:'
run_rc 'git cat-file -p HEAD:src/server.py'
run_rc 'git status --short'

snip 02-detect
note 'git fsck hashes what it finds and compares the result with the file name:'
run_rc 'git fsck'
note 'A fetch-style transfer rebuilds every ID on the receiving side, so the bad object cannot travel:'
run_rc 'git clone --quiet --no-local . ../clone-over-transport'
note 'A plain file copy has no such check:'
run_rc 'git clone --quiet . ../clone-by-file-copy'
run 'git -C ../clone-by-file-copy cat-file -p HEAD:src/server.py'

snip 03-repair
note 'The working tree still holds the true content, and content alone determines the ID.'
run 'git hash-object src/server.py'
note 'Git will not rewrite an object it believes it has, so remove the bad file first.'
run 'rm -f .git/objects/e2/238784c412f0a5151764c07c7a44e7b3a9c073'
run 'git hash-object -w src/server.py'
run_rc 'git fsck'
run 'git cat-file -p HEAD:src/server.py'

lab_end
