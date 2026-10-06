#!/usr/bin/env bash
# Chapter 15, section 15.11: the Git side of a release. An annotated tag that you create and
# push, against a tag that appears on the server because a release was created for a tag
# name that did not exist. A plain "git tag" on the bare repository plays that part of the
# platform. What "git describe" makes of the two.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$LAB_SCRIPT_DIR/fixture.bash"
lab_begin ch15 tag-vs-release
make_server prompt-registry
clone_for you prompt-registry
clone_for asha prompt-registry

snip 01-annotated
run 'cd you/prompt-registry'
run 'git tag -a v0.2.0 -m "prompt-registry 0.2.0: first tagged version"'
run 'git push origin v0.2.0'
run 'git ls-remote --tags origin'

cd "$LAB_DIR/asha/prompt-registry" || exit 1
as asha
printf '\nVersions are immutable once registered.\n' >> docs/architecture.md
commit_paths 'Document that versions are immutable' docs/architecture.md
hidden 'git push origin main'
as you
cd "$LAB_DIR/you/prompt-registry" || exit 1

snip 02-server-side-tag
note 'Asha has merged one more commit. Then a release "v0.3.0" is created on the platform for a tag'
note 'that does not exist. Stand-in for what the platform does: a tag at the tip of the default branch.'
run 'git -C ../../server/prompt-registry.git tag v0.3.0 main'
run 'git tag --list'
run 'git ls-remote --tags origin'

snip 03-fetch
run 'git fetch origin'
run 'git tag --list'

snip 04-two-kinds
run 'git for-each-ref --format="%(refname:short)  %(objecttype)  tagger=%(taggername)  %(subject)" refs/tags'

snip 05-describe
run 'git describe origin/main'
run 'git describe --tags origin/main'

lab_end
