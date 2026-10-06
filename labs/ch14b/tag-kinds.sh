#!/usr/bin/env bash
# Chapter 14B, section 14B.8: lightweight and annotated tags at the object level.
# (The third kind, the signed tag, needs a key and is shown in ssh-signing.sh.)
. "$(dirname "$0")/../lib/lab-env.sh"
. "$(dirname "$0")/fixture.bash"
lab_begin ch14b tag-kinds
make_gateway "$LAB_DIR/inference-gateway"

snip 01-lightweight
run 'git log --oneline'
run 'git tag staging-2026-09-07'
run 'cat .git/refs/tags/staging-2026-09-07'
run 'git cat-file -t staging-2026-09-07'
run 'git count-objects | cut -d, -f1'

snip 02-annotated
run 'git tag -a v1.0.0 -m "inference-gateway 1.0.0" -m "First release with rate limits."'
run 'git count-objects | cut -d, -f1'
run 'cat .git/refs/tags/v1.0.0'
run 'git cat-file -t v1.0.0'
run 'git cat-file -p v1.0.0'

snip 03-peel
run "git rev-parse v1.0.0 'v1.0.0^{tag}' 'v1.0.0^{commit}' 'v1.0.0^{}' 'v1.0.0^{tree}'"
run 'git show-ref --tags --dereference'
run "git for-each-ref refs/tags --format='%(refname:short) | %(objecttype) %(objectname:short) | peeled: %(*objecttype) %(*objectname:short)'"

snip 04-show
run 'git show --no-patch v1.0.0'
run 'git log -1 --oneline --decorate'

snip 05-older-commit
run 'git tag -a v0.9.0 -m "Internal preview" HEAD~1'
run 'git tag -m "Rate limits verified on staging" v1.0.0-verified'
run 'git tag -n1'
run "git for-each-ref refs/tags --format='%(refname:short) %(objecttype) %(creatordate:iso)'"

snip 06-not-a-commit
note 'A tag can name any object. Here: one blob, the limits file as released, and then a tag of a tag.'
run 'git tag -a limits-schema-v1 -m "Limits file format, version 1" HEAD:config/limits.yaml'
run 'git cat-file -p limits-schema-v1 | head -3'
run 'git tag -a v1.0.0-audited -m "Audit ticket SEC-88 closed" v1.0.0'
run 'git cat-file -p v1.0.0-audited | head -3'
run "git rev-parse v1.0.0-audited 'v1.0.0-audited^{tag}' 'v1.0.0-audited^{}'"

snip 07-names
run_rc 'git tag "v1.0 final"'
run_rc 'git tag v1.0.0'
run_rc 'git check-ref-format refs/tags/v1.0.0+build.7'
run_rc 'git check-ref-format "refs/tags/v1.0.0~1"'

lab_end
