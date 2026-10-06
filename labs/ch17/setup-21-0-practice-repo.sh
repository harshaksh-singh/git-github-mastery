#!/usr/bin/env bash
# Builds the starter repository for the GitHub-side labs of Modules 21 to 23: the ticket-router
# project with the same four commits (and the same commit IDs) as the transcripts in the book.
# You push it to your practice organization from your NORMAL shell, because the lab shell
# cannot authenticate to GitHub.
#
# Safety: once the repository has a remote called "origin" (that is, once you have published
# it), this script leaves it alone, so that re-running it, or running labs/verify-all.sh,
# cannot destroy local work. Delete the directory yourself if you want a fresh one.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$(dirname "$0")/fixture.bash"

target="$LAB_ROOT/hands-on/m21-github/ticket-router-lab"
if [ -f "$target/.git/config" ] && grep -q '^\[remote "origin"\]' "$target/.git/config"; then
  printf 'The starter repository already exists and has a remote "origin":\n  %s\n' "$target"
  printf 'Not rebuilding it. Remove the directory by hand if you want to start over.\n'
  exit 0
fi

sandbox_begin hands-on m21-github
make_server
hidden "git clone '$LAB_DIR/server/ticket-router.git' '$LAB_DIR/ticket-router-lab'"
git -C "$LAB_DIR/ticket-router-lab" remote remove origin || exit 1
rm -rf "$LAB_DIR/server"
require_ref "$LAB_DIR/ticket-router-lab" refs/heads/main

printf 'The starter repository is ready: %s/ticket-router-lab\n' "$LAB_DIR"
printf 'Use it from your normal shell (not labs/shell):\n'
printf '  cd "%s/ticket-router-lab"\n' "$LAB_DIR"
printf '  git log --oneline        # four commits; the newest is 9a383e5 "Add classifier test"\n'
