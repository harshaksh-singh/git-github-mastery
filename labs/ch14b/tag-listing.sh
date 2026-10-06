#!/usr/bin/env bash
# Chapter 14B, section 14B.9: listing, filtering and sorting tags. Why the default order
# is wrong for versions, and what version:refname and versionsort.suffix do about it.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$(dirname "$0")/fixture.bash"
lab_begin ch14b tag-listing
make_gateway "$LAB_DIR/inference-gateway"
tag_here() { tick; git tag -a "$1" -m "inference-gateway ${1#v}" > /dev/null 2>&1 || exit 1; }
tag_here v1.2.0
commit_file gateway/health.py 'def healthy():\n    return True\n' 'Add health endpoint'
tag_here v1.9.0
commit_file gateway/auth.py 'def check(token):\n    return bool(token)\n' 'Add token check'
tag_here v1.10.0
commit_file gateway/stream.py 'def stream(chunks):\n    yield from chunks\n' 'Add streaming responses'
tag_here v2.0.0-rc.1
commit_file gateway/stream.py 'def stream(chunks):\n    for chunk in chunks:\n        yield chunk\n' 'Fix stream flush'
tag_here v2.0.0-rc.2
tag_here v2.0.0
hidden 'git tag nightly'
commit_file docs/streaming.md '# Streaming\n' 'Document streaming'

snip 01-default-order
run 'git log --oneline --decorate'
run 'git tag'

snip 02-version-sort
run 'git tag --sort=version:refname'
run 'git -c versionsort.suffix=-rc tag --sort=version:refname'

snip 03-configured
run 'git config set tag.sort version:refname'
run 'git config set versionsort.suffix -rc'
run "git tag --list 'v2.*'"
run "git tag --list 'v[0-9]*' --sort=-version:refname | head -1"

snip 04-filters
run 'git tag --contains HEAD~2'
run 'git tag --no-contains HEAD~2'
run 'git tag --points-at HEAD~1'
run 'git tag --merged v1.9.0'

snip 05-formats
run 'git tag -n1 --list "v1.*"'
run "git tag --sort=-creatordate --format='%(creatordate:format:%H:%M) %(refname:short) %(objecttype) %(taggername)' | head -4"

lab_end
