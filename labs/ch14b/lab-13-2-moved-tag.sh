#!/usr/bin/env bash
# Lab 13.2 replay: a published tag is moved. Three clones disagree about v1.2.0; a forced
# tag fetch spreads the wrong tag; the original tag object is found again and restored.
# Lab manual: lab-manual/m13-tags-versions.md.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$(dirname "$0")/fixture.bash"
lab_begin ch14b lab-13-2-moved-tag
scenario_13_2
as config

snip 01-published
run 'cd you/inference-gateway'
run 'git log --oneline --decorate'
run 'git ls-remote --tags origin'
run 'git -C ../../asha/inference-gateway show-ref --tags --dereference'

snip 02-move
run "printf 'requests_per_minute: 60\nmax_tokens: 4096\n' > config/limits.yaml"
run 'git commit -q -am "Fix max_tokens limit"'
run 'git push -q'
run 'git tag -f -a v1.2.0 -m "inference-gateway 1.2.0"'
run_rc 'git push origin v1.2.0'
run 'git push --force origin v1.2.0'

snip 03-asha
run 'cd ../../asha/inference-gateway'
run 'git pull -q'
run 'git log --oneline --decorate -2'
run 'git show v1.2.0:config/limits.yaml'

snip 04-fresh-clone
run 'cd ../..'
run 'git clone -q server/inference-gateway.git ci/inference-gateway'
run 'git -C ci/inference-gateway log --oneline --decorate -2'
run 'git -C ci/inference-gateway show v1.2.0:config/limits.yaml'

snip 05-detect
run 'cd asha/inference-gateway'
run "git ls-remote origin 'refs/tags/v1.2.0^{}'"
run "git rev-parse 'v1.2.0^{commit}'"
run_rc 'git fetch --tags'

snip 06-failure
note 'The quick "fix" that gets passed around in chat: force the tags.'
run 'git fetch --tags --force'
run 'git log --oneline --decorate -2'
run_rc 'git reflog show refs/tags/v1.2.0'

snip 07-find-the-original
note 'No reflog for a tag. But the old tag object is still in this clone, unreferenced.'
run 'git fsck --no-reflogs'
run 'git fsck --no-reflogs | sed -n "s/^dangling tag //p" > ../../original-tag-id'
run 'git cat-file -p "$(cat ../../original-tag-id)"'

snip 08-recovery
run 'git push --force origin "$(cat ../../original-tag-id):refs/tags/v1.2.0"'
run 'git fetch --tags --force'
run 'cd ../../you/inference-gateway'
run 'git fetch --tags --force'
run 'git tag -a v1.2.1 -m "inference-gateway 1.2.1: fix max_tokens limit"'
run 'git push origin v1.2.1'
run 'git -C ../../ci/inference-gateway fetch -q --tags --force'
run 'git -C ../../asha/inference-gateway fetch -q'

snip 09-verify
run 'git ls-remote --tags origin'
run 'cd ../..'
run 'for c in you asha ci; do echo "$c:"; git -C $c/inference-gateway show-ref --tags --dereference --abbrev | grep "{}"; done'
run 'git -C you/inference-gateway log --oneline --decorate -2'

lab_end
