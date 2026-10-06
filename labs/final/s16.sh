#!/usr/bin/env bash
# Final test, section 16 (Debugging): prediction items P1 and P2, diagram item G1 and
# interpretation items I1 and I2.
. "$(dirname "$0")/../lib/lab-env.sh"
lab_begin final s16

# ---- P1: blame through a commit that only changed indentation
snip p1-setup
run 'git init -q ratecard'
run 'cd ratecard'
as asha
note 'Asha:'
run "printf 'def price(tokens):\n  base = tokens * 0.002\n  return round(base, 4)\n' > price.py"
run 'git add . && git commit -q -m "Add the price function"'
as ravi
note 'Ravi runs the formatter (two spaces become four):'
run "printf 'def price(tokens):\n    base = tokens * 0.002\n    return round(base, 4)\n' > price.py"
run 'git commit -q -a -m "Format with four spaces"'
as you
snip p1-answer
run "git blame -s -L 2,3 price.py"
run "git blame -s -w -L 2,3 price.py"
run "git log --format='%h %an: %s'"
cd "$LAB_DIR"

# ---- P2: blame and a function that moved to another file
snip p2-setup
run 'git init -q textnorm'
run 'cd textnorm'
as asha
note 'Asha:'
run "printf 'def squash_spaces(s):\n    parts = s.split()\n    joined = \" \".join(parts)\n    return joined.strip()\n\ndef lower(s):\n    return s.lower()\n' > clean.py"
run 'git add . && git commit -q -m "Add text cleaning"'
as ravi
note 'Ravi moves one function into a new file, unchanged, in one commit:'
run "printf 'def squash_spaces(s):\n    parts = s.split()\n    joined = \" \".join(parts)\n    return joined.strip()\n' > spaces.py"
run "printf 'def lower(s):\n    return s.lower()\n' > clean.py"
run 'git add . && git commit -q -m "Move squash_spaces into its own module"'
as you
snip p2-answer
run 'git blame -s spaces.py'
run 'git blame -s -C spaces.py'
run "git log --format='%h %an: %s'"
cd "$LAB_DIR"

# ---- G1: the path of a bisection
quiet 'git init -q p95tracker'
cd p95tracker || exit 1
n=1
for s in 'add the tracker' 'add percentile math' 'add the window' 'add the exporter' 'switch to a ring buffer' 'add labels' 'add the reset endpoint' 'add the dashboard link'; do
  if [ "$n" -ge 5 ]; then printf 'window: ring\n' > tracker.yaml; else printf 'window: list\n' > tracker.yaml; fi
  printf '%s\n' "$n" > step.txt
  quiet "git add . && git commit -q -m 'C$n: $s'"
  [ "$n" -eq 1 ] && quiet 'git tag v1.0'
  n=$((n + 1))
done
snip g1-graph
run 'git log --oneline --decorate'
note 'The check "grep -q list tracker.yaml" passes at v1.0 and fails at HEAD.'
snip g1-answer
run 'git bisect start HEAD v1.0'
run 'git bisect run grep -q list tracker.yaml'
run 'git bisect log | grep "^git bisect"'
run 'git bisect reset'
cd "$LAB_DIR"

# ---- I1: a sequence of cherry-picks that stopped
quiet 'git init -q geofence'
cd geofence || exit 1
printf 'radius_m: 100\n' > fence.yaml
quiet 'git add . && git commit -q -m "Add the fence radius"'
quiet 'git branch release/1.0'
printf 'radius_m: 100\nunits: metric\n' > fence.yaml
quiet 'git commit -q -a -m "Add units"'
printf 'radius_m: 150\nunits: metric\n' > fence.yaml
quiet 'git commit -q -a -m "Widen the fence"'
printf 'polygon: true\n' > shapes.yaml
quiet 'git add . && git commit -q -m "Support polygons"'
quiet 'git switch -q release/1.0'
printf 'radius_m: 120\n' > fence.yaml
quiet 'git commit -q -a -m "Release tuning"'
snip i1-transcript
run 'git cherry-pick main~1 main 2>&1 | grep -v "^hint:"'
run 'git status'
run 'ls .git | grep -E "^(CHERRY_PICK_HEAD|REVERT_HEAD|MERGE_HEAD|ORIG_HEAD|sequencer|rebase-merge)$"'
run 'cat .git/sequencer/todo'
run 'git log --oneline -1 CHERRY_PICK_HEAD'
cd "$LAB_DIR"

# ---- I2: every commit twice
quiet 'git init -q --bare server.git'
quiet 'git clone -q server.git you && git -C you remote set-url origin ../server.git'
cd you || exit 1
quiet 'git commit -q --allow-empty -m "Add the tile server" && git push -q -u origin main'
quiet 'git switch -q -c feature/vector-tiles'
printf 'format: mvt\n' > tiles.yaml
quiet 'git add . && git commit -q -m "Serve vector tiles"'
printf 'format: mvt\nmax_zoom: 14\n' > tiles.yaml
quiet 'git commit -q -a -m "Limit the zoom level"'
quiet 'git push -q -u origin feature/vector-tiles'
cd "$LAB_DIR" || exit 1
quiet 'git clone -q server.git asha && git -C asha remote set-url origin ../server.git'
cd asha || exit 1
as asha
quiet 'git switch -q feature/vector-tiles'
printf 'gzip: true\n' > compress.yaml
quiet 'git add . && git commit -q -m "Compress the tiles"'
cd "$LAB_DIR/you" || exit 1
as you
quiet 'git switch -q main && git commit -q --allow-empty -m "Add a health endpoint" && git push -q'
quiet 'git switch -q feature/vector-tiles && git rebase -q main && git push -q --force'
cd "$LAB_DIR/asha" || exit 1
as asha
quiet 'git pull -q --no-rebase --no-edit'
snip i2-transcript
note 'In Asha'"'"'s clone, after "git pull" on feature/vector-tiles:'
run 'git log --graph --format="%h %s" feature/vector-tiles'
run 'git log --format="%m %h %s" --cherry-mark --left-right "HEAD^1...HEAD^2"'
run 'git reflog show origin/feature/vector-tiles'
lab_end
