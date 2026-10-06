#!/usr/bin/env bash
# Model answers for exercises 11.1 to 11.8 (Module 11, history investigation) as real transcripts
# on the practice repository built by exercises/gen/m11-docsplit/generate.sh.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$LAB_SCRIPT_DIR/replay-lib.bash"
lab_begin ex2 answers-m11
ex_load m11-docsplit
cd docsplit || exit 1

snip 11-0-graph
run 'git log --graph --oneline --all'

snip 11-1-filters
run 'git log --oneline --author=Asha'
run 'git log --oneline -- docsplit/config.py'
run 'git log --oneline --merges'
run "git log --format='%h %ad %an: %s' --date=format:'%a %H:%M' --since='2026-09-09 00:00' --until='2026-09-09 23:59'"

snip 11-1-dates
p=$(sid 'Fix off-by-one in paragraph splitter' main)
run "git log --format='%h author %ad | committer %cd | %an, %cn' --date=format:'%a %H:%M' -1 $p"
run "git log --oneline --author=Asha -- docsplit/config.py | wc -l"

snip 11-2-pickaxe
run "git log --oneline -S'OVERLAP'"
run "git log --oneline -G'OVERLAP'"
snip 11-2-why
o=$(sid 'Sort the configuration constants')
run "git show --format=%s $o -- docsplit/config.py"
run "git grep -c OVERLAP $o^ $o -- docsplit/config.py"

snip 11-3-blame
run 'git blame -L 3,5 docsplit/config.py'
c=$(git blame -s -L '/CHUNK_SIZE/,+1' docsplit/config.py | cut -d' ' -f1)
run "git show --stat --format='%h %an: %s' $c"
run "git blame -L '/CHUNK_SIZE/,+1' $c^ -- docsplit/config.py"

snip 11-4-ranges
run 'git log --oneline main..feat/markdown'
run 'git log --oneline feat/markdown..main | wc -l'
run 'git rev-list --left-right --count main...feat/markdown'
run 'git log --oneline --cherry-pick --right-only main...feat/markdown'
snip 11-4-diff
run 'git diff --stat main...feat/markdown'
run 'git diff --stat main..feat/markdown'

snip 11-5-deleted
run 'git log --diff-filter=D --oneline -- configs/legacy.yaml'
d=$(git log --diff-filter=D --format=%h -- configs/legacy.yaml)
run "git restore --source=$d^ --staged --worktree -- configs/legacy.yaml"
run 'git status -s'
run 'cat configs/legacy.yaml'
run 'git log -1 --oneline'
quiet 'git rm -q -f configs/legacy.yaml'

snip 11-6-notes
run "git log --no-merges --reverse --format='- %s (%an)' v0.2.0..v0.3.0"
run 'git shortlog -sn --no-merges v0.2.0..v0.3.0'
run 'git log --first-parent --oneline v0.2.0..v0.3.0'

snip 11-7-blame
run 'git blame -s docsplit/window.py'
run 'git blame -s -C docsplit/window.py'
snip 11-7-origin
r=$(git blame -s -C -L 8,8 docsplit/window.py | cut -d' ' -f1)
run "git show $r"
snip 11-7-linelog
m=$(git log --format=%h --diff-filter=A -- docsplit/window.py)
run "git log --oneline --no-patch -L :window:docsplit/window.py"
run "git log --oneline --no-patch -L :window:docsplit/split.py $m^"
k=$(sid 'Keep the tail in the last window')
run "git log -1 --format='%h %an%n%n%B' $k"

snip 11-8-simplified
run 'git log --oneline -- docsplit/clean.py'
run 'git log --oneline --author=Asha -- docsplit/clean.py'
run 'git log --oneline --full-history -- docsplit/clean.py'
t=$(git log --format=%h --author=Asha --full-history -- docsplit/clean.py)
run "git merge-base --is-ancestor $t main; echo \"exit status: \$?\""
snip 11-8-merge
g=$(git log --format=%h --merges --full-history -1 -- docsplit/clean.py)
run "git show --remerge-diff --format='%h %s' $g"
lab_end
