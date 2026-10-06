#!/usr/bin/env bash
# Chapter 14B, section 14B.11: why a published tag must not move. A release tag is moved
# and force-pushed; three clones then disagree about what "v1.2.0" is. Then the repair.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$(dirname "$0")/fixture.bash"
lab_begin ch14b moved-tag
make_server_and_clones you asha
enter you
hidden 'git tag -a v1.2.0 -m "inference-gateway 1.2.0"'
hidden 'git push origin v1.2.0'
enter asha
hidden 'git fetch'
enter you
# The server administrator's update hook, installed in the last snippet.
cat > "$LAB_DIR/update-hook" <<'HOOK'
#!/bin/sh
# update hook: called once per ref with <ref> <old-id> <new-id>.
# A release tag may be created. It may not be moved or deleted.
ref=$1 old=$2
case "$ref" in
refs/tags/v*)
  if ! printf '%s' "$old" | grep -q '^0*$'; then
    echo "policy: $ref is published and immutable; release a new version" >&2
    exit 1
  fi ;;
esac
exit 0
HOOK

snip 01-released
run 'git log --oneline --decorate'
run 'git ls-remote --tags origin'

snip 02-move
note 'A bug is found an hour after the release. The fix lands on main, and the tag is "corrected".'
run "printf 'requests_per_minute: 60\nmax_tokens: 4096\n' > config/limits.yaml"
run 'git commit -q -am "Fix max_tokens limit"'
run 'git push -q'
run 'git tag -f -a v1.2.0 -m "inference-gateway 1.2.0"'
run_rc 'git push origin v1.2.0'
run 'git push --force origin v1.2.0'

snip 03-asha
as asha
run 'cd ../../asha/inference-gateway'
run 'git pull'
run 'git log --oneline --decorate'
run 'git show v1.2.0:config/limits.yaml'

snip 04-fresh-clone
as you
run 'cd ../..'
run 'git clone -q server/inference-gateway.git ci/inference-gateway'
run 'cd ci/inference-gateway'
run 'git log --oneline --decorate'
run 'git show v1.2.0:config/limits.yaml'

snip 05-detect
as asha
run 'cd ../../asha/inference-gateway'
note 'What the server says the tag is, and what this clone says it is:'
run "git ls-remote origin 'refs/tags/v1.2.0^{}'"
run "git rev-parse 'v1.2.0^{commit}'"
run_rc 'git fetch --tags'

snip 06-repair
note 'The sane repair: put v1.2.0 back where it was published, and release the fix as v1.2.1.'
note 'Asha still has the original tag object, so she can restore it.'
run 'git push --force origin v1.2.0'
as you
run 'cd ../../you/inference-gateway'
run 'git fetch --tags --force'
run 'git tag -a v1.2.1 -m "inference-gateway 1.2.1: fix max_tokens limit"'
run 'git push origin v1.2.1'
run 'git log --oneline --decorate'

snip 07-ci-still-wrong
run 'cd ../../ci/inference-gateway'
run 'git fetch'
run 'git log -2 --oneline --decorate'
run 'git fetch --tags --force'
run 'git log -2 --oneline --decorate'

snip 08-server-settings
note 'Two server settings that sound as if they protect tags. Set them and try.'
as you
run 'cd ../../you/inference-gateway'
run 'git -C ../../server/inference-gateway.git config set receive.denyNonFastForwards true'
run 'git -C ../../server/inference-gateway.git config set receive.denyDeletes true'
run 'git tag -a v1.3.0-rc.1 -m "Release candidate"'
run 'git push -q origin v1.3.0-rc.1'
run 'git tag -f -a v1.3.0-rc.1 -m "Release candidate, moved" HEAD~1'
run_rc 'git push --force origin v1.3.0-rc.1'
run_rc 'git push origin --delete v1.3.0-rc.1'

snip 09-update-hook
note 'A server-side update hook: an existing tag under refs/tags/v* can be neither moved nor deleted.'
run 'cat ../../update-hook'
run 'cp ../../update-hook ../../server/inference-gateway.git/hooks/update'
run 'chmod +x ../../server/inference-gateway.git/hooks/update'
run 'git push -q origin v1.3.0-rc.1'
run 'git tag -f -a v1.3.0-rc.1 -m "Release candidate, moved again" HEAD'
run_rc 'git push --force origin v1.3.0-rc.1'
run_rc 'git push origin --delete v1.3.0-rc.1'

lab_end
