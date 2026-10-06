#!/usr/bin/env bash
# The library repository moves. set-url changes .gitmodules for everyone; each existing clone still
# has the old URL in its own configuration until "git submodule sync". Chapter 23, section 23.11.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$LAB_SCRIPT_DIR/fixtures/fixtures.sh"
lab_begin ch23 submodule-url
fx_docqa_submodule
fx_ravi_clone
quiet 'mv remotes/textsplit.git remotes/chunking.git'
fx_release_at_new_home() {
  cd "$LAB_DIR/asha-textsplit" || return 1
  quiet 'git remote set-url origin ../remotes/chunking.git'
  cd "$LAB_DIR" || return 1
  fx_textsplit_release
}
fx_release_at_new_home
cd doc-qa

snip 01-set-url
run 'git submodule set-url vendor/textsplit ../chunking.git'
run 'git diff'
run 'git config get submodule.vendor/textsplit.url'
run 'git -c protocol.file.allow=always submodule update --remote'
run 'git commit -am "textsplit moved to chunking.git; update to 0.2.0"'
run 'git push --recurse-submodules=check origin main'

snip 02-teammate-stale-url
run 'cd ../ravi-doc-qa'
as ravi
run 'git pull --no-recurse-submodules'
run 'cat .gitmodules'
run 'git config get submodule.vendor/textsplit.url'
run_rc 'git -c protocol.file.allow=always submodule update'

snip 03-sync
run 'git submodule sync'
run 'git config get submodule.vendor/textsplit.url'
run 'git -C vendor/textsplit remote get-url origin'
run 'git -c protocol.file.allow=always submodule update'
as you
lab_end
