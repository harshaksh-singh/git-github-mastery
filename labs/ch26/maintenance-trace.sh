#!/usr/bin/env bash
# Chapter 26, sections 26.3 and 26.4: what "git maintenance run" does on Git 2.55 (the geometric
# strategy), traced with GIT_TRACE, compared with the gc task, and the geometric progression of
# packs over several runs. Everything runs in the foreground; no scheduler is installed.
. "$(dirname "$0")/../lib/lab-env.sh"
lab_begin ch26 maintenance-trace
. "$LAB_SCRIPT_DIR/../ch24/fixture-orbit.bash"
orbit_build || exit 1

snip 01-trigger
note 'Commands that write objects end by asking for maintenance. In a new repository:'
run 'git init -q probe'
run "echo 'probe' > probe/file.txt && git -C probe add file.txt"
run "GIT_TRACE=1 git -C probe commit -q -m 'Add a file' 2>&1 | sed -n 's/.*trace: run_command: //p'"
note 'In the repository we are going to study, nothing may run behind our back. Switch the trigger off:'
run 'cd orbit'
run 'git config set maintenance.auto false'

snip 02-needed
run 'git count-objects -v | grep -e "^count" -e in-pack -e "^packs"'
note 'Would an automatic run do anything? Exit status 0 means yes.'
run_rc 'git maintenance is-needed --auto'
note 'Task by task:'
run_rc 'git maintenance is-needed --auto --task=geometric-repack'
run_rc 'git maintenance is-needed --auto --task=commit-graph'
run_rc 'git maintenance is-needed --auto --task=gc'

snip 03-trace
note 'Run maintenance in the foreground and write the trace into a file beside the repository:'
run 'GIT_TRACE="$PWD/../trace-1.log" git maintenance run'
note 'The commands that maintenance started, in order:'
run "sed -n 's/.*trace: run_command: git //p' ../trace-1.log | grep -v -e '^pack-objects' -e '^multi-pack-index'"
note 'The commands that the repack started in turn (process ID and temporary file name masked):'
run "sed -n 's/.*trace: run_command: git //p' ../trace-1.log | grep -e '^pack-objects' -e '^multi-pack-index' | sed -e 's/tmp-[0-9]*-pack/tmp-PID-pack/' -e 's/pack-[0-9a-f]*\\.pack/pack-ID.pack/' -e 's/--refs-snapshot=[^ ]*/--refs-snapshot=FILE/' | fold -s -w 100"

snip 04-after
run 'git count-objects -v | grep -e "^count" -e in-pack -e "^packs"'
note 'Every file under objects/ that is not a loose object (40-digit names masked):'
run "find .git/objects -type f | grep -v '/[0-9a-f][0-9a-f]/' | sed 's/[0-9a-f]\\{40\\}/ID/' | sort"
note 'The refs moved into packed-refs:'
run 'head -3 .git/packed-refs'
run 'find .git/refs -type f | wc -l'
run_rc 'git maintenance is-needed --auto'

snip 05-second-run
note 'Six more commits, then a second run:'
_i=1
while [ "$_i" -le 6 ]; do
  quiet "printf 'note %d\n' $_i >> docs/architecture.md && git commit -am 'docs: add note $_i'"
  _i=$((_i + 1))
done
run 'git count-objects -v | grep -e "^count" -e in-pack -e "^packs"'
run 'GIT_TRACE="$PWD/../trace-2.log" git maintenance run'
run "sed -n 's/.*trace: run_command: git //p' ../trace-2.log | grep -v -e '^pack-objects' -e '^multi-pack-index'"
run 'git count-objects -v | grep -e "^count" -e in-pack -e "^packs"'

snip 06-progression
note 'Objects per pack, largest first:'
run 'for p in .git/objects/pack/pack-*.idx; do git show-index < "$p" | wc -l; done | sort -rn'
_i=1
while [ "$_i" -le 6 ]; do
  quiet "printf 'remark %d\n' $_i >> docs/architecture.md && git commit -am 'docs: add remark $_i'"
  _i=$((_i + 1))
done
note 'Six more commits and a third run. The new pack is not rolled into the old small one yet:'
run 'git maintenance run'
run 'for p in .git/objects/pack/pack-*.idx; do git show-index < "$p" | wc -l; done | sort -rn'
_i=1
while [ "$_i" -le 14 ]; do
  quiet "printf 'detail %d\n' $_i >> docs/architecture.md && git commit -am 'docs: add detail $_i'"
  _i=$((_i + 1))
done
note 'Fourteen more commits and a fourth run. Now the two small packs and the new objects merge:'
run 'git maintenance run'
run 'for p in .git/objects/pack/pack-*.idx; do git show-index < "$p" | wc -l; done | sort -rn'
note 'The commit-graph grew as a chain of files, one line per file:'
run 'wc -l < .git/objects/info/commit-graphs/commit-graph-chain'

snip 07-gc-task
note 'The same repository, maintained the older way:'
run 'GIT_TRACE="$PWD/../trace-3.log" git maintenance run --task=gc'
run "sed -n 's/.*trace: run_command: git //p' ../trace-3.log | grep -v -e '^pack-objects'"
run 'for p in .git/objects/pack/pack-*.idx; do git show-index < "$p" | wc -l; done | sort -rn'
run "find .git/objects -type f | grep -v '/[0-9a-f][0-9a-f]/' | sed 's/[0-9a-f]\\{40\\}/ID/' | sort"

snip 08-incremental-tasks
note 'The tasks of the "incremental" strategy, which a scheduler would run hourly and daily,'
note 'run here once in the foreground (prefetch is left out: this repository has no remote):'
run 'GIT_TRACE="$PWD/../trace-4.log" git maintenance run --task=commit-graph --task=loose-objects --task=incremental-repack'
run "sed -n 's/.*trace: run_command: git //p' ../trace-4.log"

lab_end
