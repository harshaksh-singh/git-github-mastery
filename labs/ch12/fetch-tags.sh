#!/usr/bin/env bash
# Tags and fetch: tags are followed automatically, but a tag you already have is never
# updated unless you force it. Chapter 12, section 12.4.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$(dirname "$0")/fixture.bash"
lab_begin ch12 fetch-tags

# Hidden setup: a release tag exists and you have it. Then Asha moves the tag on the
# server to a newer commit (a forced tag push) and also publishes a tag on a commit
# that is on no branch.
make_server
new_clone asha
enter asha
hidden 'git tag -a v0.1.0 -m "First internal release"'
hidden 'git push origin v0.1.0'
new_clone you
enter asha
commit_file app/retriever.py 'def retrieve(query, top_k):\n    return search(query)[:top_k]\n' 'Implement retrieval'
hidden 'git push'
hidden 'git tag -f -a v0.1.0 -m "First internal release, retagged"'
hidden 'git push --force origin v0.1.0'
hidden 'git switch --detach'
commit_file notes/experiment.md '# Rejected experiment\n' 'Record rejected experiment'
hidden 'git tag experiment/rejected-1'
hidden 'git push origin experiment/rejected-1'
hidden 'git switch main'
enter you

snip 01-moved-tag
run 'git ls-remote --tags origin'
run 'git fetch'
run 'git show-ref --abbrev --tags'

snip 02-fetch-tags
run_rc 'git fetch --tags'
run 'git show-ref --abbrev --tags'

snip 03-force
run 'git fetch --tags --force'
run 'git show-ref --abbrev --tags'

lab_end
