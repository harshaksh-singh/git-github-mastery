#!/usr/bin/env bash
# Chapter 26, sections 26.7 and 26.8: the multi-pack-index in a repository with several packs,
# and reachability bitmaps on the serving side, shown through the counters that pack-objects
# reports (no timings).
. "$(dirname "$0")/../lib/lab-env.sh"
lab_begin ch26 midx-bitmaps
. "$LAB_SCRIPT_DIR/../ch24/fixture-orbit.bash"
orbit_build || exit 1
orbit_server || exit 1
quiet 'git -C orbit config set maintenance.auto false'

snip 01-several-packs
note 'A clone that has fetched three times since it was made holds four packs, each with its own index:'
quiet 'git clone "file://$PWD/server/orbit.git" dev && git -C dev config set maintenance.auto false && git -C dev config set fetch.unpackLimit 1'
_i=1
while [ "$_i" -le 3 ]; do
  quiet "printf 'note %d\n' $_i >> orbit/docs/architecture.md && git -C orbit commit -am 'docs: add note $_i' && git -C orbit push ../server/orbit.git main"
  quiet 'git -C dev fetch'
  _i=$((_i + 1))
done
run 'cd dev'
run 'ls .git/objects/pack | cut -d. -f2 | sort | uniq -c'
run 'for p in .git/objects/pack/pack-*.idx; do git show-index < "$p" | wc -l; done | sort -rn'

snip 02-midx
note 'One index over all packs:'
run 'git multi-pack-index write'
run 'ls .git/objects/pack | cut -d. -f2 | sort | uniq -c'
run_rc 'git multi-pack-index verify'
note 'Signature MIDX, version, hash version, number of chunks, number of base files, number of packs:'
run 'xxd -l 12 .git/objects/pack/multi-pack-index'
note 'Objects are found exactly as before:'
run 'git cat-file -t HEAD'
run 'git rev-list --count --objects --all'

snip 03-bitmap-on-server
run 'cd ..'
note 'The bare repository that plays the server was packed by "git gc". Beside the pack:'
run 'ls server/orbit.git/objects/pack | cut -d. -f2 | sort | uniq -c'
note 'The non-bare repository after the same command:'
quiet 'git -C orbit gc'
run 'ls orbit/.git/objects/pack | cut -d. -f2 | sort | uniq -c'
note 'Why the difference: the default of repack.writeBitmaps depends on the kind of repository.'
run_rc 'git -C server/orbit.git config get repack.writeBitmaps'
run 'git -C server/orbit.git rev-parse --is-bare-repository'

snip 04-what-a-bitmap-saves
note 'Serve one full clone and ask the serving side how it filled the pack:'
quiet 'git -C server/orbit.git -c pack.threads=1 gc'
run "GIT_TRACE2_PERF=1 git clone -q --bare \"file://\$PWD/server/orbit.git\" with-bitmap.git 2>&1 | awk -F'|' '\$4 ~ /data/ {gsub(/[ .]/, \"\", \$NF); gsub(/ /, \"\", \$(NF-1)); print \$(NF-1), \$NF}' | grep -e ' written:' -e ' reused:' -e 'pack-reused:'"
note 'Remove the bitmap and serve the same clone again:'
run 'rm server/orbit.git/objects/pack/*.bitmap'
run "GIT_TRACE2_PERF=1 git clone -q --bare \"file://\$PWD/server/orbit.git\" without-bitmap.git 2>&1 | awk -F'|' '\$4 ~ /data/ {gsub(/[ .]/, \"\", \$NF); gsub(/ /, \"\", \$(NF-1)); print \$(NF-1), \$NF}' | grep -e ' written:' -e ' reused:' -e 'pack-reused:'"
note 'Both clones are complete:'
run 'git -C with-bitmap.git rev-list --count --objects --all'
run 'git -C without-bitmap.git rev-list --count --objects --all'

lab_end
