#!/usr/bin/env bash
# Chapter 26, section 26.9: the fetch conversation at concept level. Chapter 12 prints a whole
# trace; this demo shows only the lines that a shallow clone, a partial clone and an ordinary
# fetch add or change.
. "$(dirname "$0")/../lib/lab-env.sh"
lab_begin ch26 fetch-conversation
. "$LAB_SCRIPT_DIR/../ch24/fixture-orbit.bash"
orbit_build || exit 1
orbit_server || exit 1
quiet 'git -C orbit config set maintenance.auto false'

snip 01-capabilities
note 'What the serving side says it can do for a fetch:'
run "GIT_TRACE_PACKET=1 git ls-remote \"file://\$PWD/server/orbit.git\" HEAD 2>&1 | sed -n 's/.*packet: *ls-remote< //p' | sed -n '1,/^0000/p'"

snip 02-full-clone
note 'A full clone, with the conversation written to a file beside it:'
run 'GIT_TRACE_PACKET="$PWD/full.trace" git clone -q "file://$PWD/server/orbit.git" full'
note 'The request names one tip per ref it wants, has nothing to offer, and says so:'
run "sed -n 's/.*packet: *clone> //p' full.trace | sed -n '/command=fetch/,\$p' | grep -c '^want'"
run "sed -n 's/.*packet: *clone> //p' full.trace | sed -n '/command=fetch/,\$p' | grep -c '^have'"
run "sed -n 's/.*packet: *clone> //p' full.trace | sed -n '/command=fetch/,\$p' | grep -v -e '^want' | tr '\\n' ' '"
blank
note 'The answer is one section, the pack:'
run "sed -n 's/.*packet: *clone< //p' full.trace | grep -e acknowledgments -e shallow-info -e packfile"

snip 03-shallow-and-partial
note 'A shallow clone adds one line to the request, and the answer starts with the boundary:'
run "GIT_TRACE_PACKET=1 git clone --depth 1 \"file://\$PWD/server/orbit.git\" shallow 2>&1 | sed -n 's/.*packet: *\\(clone[<>]\\)/\\1/p' | grep -e deepen -e shallow"
note 'A partial clone adds one line as well:'
run "GIT_TRACE_PACKET=1 git clone --filter=blob:none \"file://\$PWD/server/orbit.git\" blobless 2>&1 | sed -n 's/.*packet: *\\(clone[<>]\\)/\\1/p' | grep -e 'filter '"

snip 04-incremental
note 'Later, the server has two new commits. The client names what it wants and what it has:'
quiet "printf 'note 1\n' >> orbit/docs/architecture.md && git -C orbit commit -am 'docs: add note 1'"
quiet "printf 'note 2\n' >> orbit/docs/architecture.md && git -C orbit commit -am 'docs: add note 2' && git -C orbit push ../server/orbit.git main"
run 'cd full'
run "GIT_TRACE_PACKET=1 git fetch 2>&1 | sed -n 's/.*packet: *\\(fetch[<>]\\)/\\1/p' | sed -n '/command=fetch/,\$p' | grep -e want -e have -e done -e ACK -e ready -e packfile | cut -c1-60"
run 'git log --oneline -3 origin/main'

lab_end
