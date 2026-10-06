#!/usr/bin/env bash
# Lab 22.2 replay (the Git half): an annotated tag as the anchor of a release, what the server
# stores for it, and what goes wrong when the platform creates the tag for you (a lightweight
# tag on the tip of the default branch). Lab manual: lab-manual/m22-merge-methods-releases.md.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$(dirname "$0")/fixture.bash"
lab_begin ch17 lab-22-2-annotated-tag-release
scenario_release
cd "$LAB_DIR" || exit 1

snip 01-tag
run 'cd you/ticket-router'
run 'git log --oneline -2'
run 'git tag -a v0.1.0 -m "ticket-router 0.1.0: keyword classifier"'
run 'git cat-file -t v0.1.0'
run 'git cat-file -p v0.1.0'

snip 02-push-tag
run 'git push origin v0.1.0'
run 'git ls-remote --tags origin'
run 'git describe'

snip 03-release
note 'On GitHub the next step is: gh release create v0.1.0 --verify-tag --notes-from-tag'
note 'The release is a GitHub object. The Git data it points at is what you see here:'
run 'git for-each-ref --format="%(refname) %(objecttype) -> %(*objecttype) %(*objectname:short)" refs/tags'

snip 04-checkpoint
run 'git rev-parse v0.1.0 "v0.1.0^{commit}" main'

as asha
quiet "cd ../../asha/ticket-router && git pull --ff-only && printf 'model: router-small-v1\nconfidence_threshold: 0.7\nfallback_queue: general\n' > config/routing.yaml && git commit -am 'Raise the confidence threshold to 0.7' && git push origin main; cd ../../you/ticket-router"
as you

snip 05-failure
note 'main has moved on by one commit (Asha). Someone creates release v0.2.0 on the platform for a'
note 'tag that does not exist. Documented result: the tag is created from the default branch.'
note 'The same thing in plain Git, on the server:'
run 'git -C ../../server/ticket-router.git tag v0.2.0 main'
run 'git pull -q --ff-only'
run 'git fetch --tags origin'
run 'git for-each-ref --format="%(refname:short) %(objecttype)" refs/tags'
run 'git describe'
run 'git describe --tags'
run_rc 'git cat-file -p v0.2.0 | grep -c "^tagger"'

snip 06-recovery
note 'On GitHub: gh release delete v0.2.0 --cleanup-tag, then recreate from an annotated tag.'
run 'git push origin --delete v0.2.0'
run 'git tag -d v0.2.0'
run 'git tag -a v0.2.0 -m "ticket-router 0.2.0: stricter threshold"'
run 'git push origin v0.2.0'

snip 07-verification
run 'git for-each-ref --format="%(refname:short) %(objecttype) %(taggername) %(subject)" refs/tags'
run 'git describe'
run 'git ls-remote --tags origin'

lab_end
