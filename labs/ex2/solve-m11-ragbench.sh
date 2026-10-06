#!/usr/bin/env bash
# Model solution of exercise 11.11 (Level 5): a value changed inside a merge resolution, hidden
# behind a formatting commit. Every claim in the incident channel is tested before it is believed.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$LAB_SCRIPT_DIR/replay-lib.bash"
lab_begin ex2 solve-m11-ragbench
ex_load m11-ragbench
cd you || exit 1

snip 01-observe
run 'git status -sb'
run 'git log --graph --oneline --decorate'
run 'git diff deploy-2026-09-04 deploy-2026-09-11 -- ragbench/retrieve.py | grep TOP_K'

snip 02-on-call-claims
fmt=$(sid 'Format the package with the new formatter')
run 'git blame -s -L 3,7 ragbench/retrieve.py'
run "git log --oneline -S'TOP_K=5'"

snip 03-asha
run "git diff --stat $fmt^ $fmt"
run "git diff -w --stat $fmt^ $fmt"
run "git show $fmt^:ragbench/retrieve.py | grep TOP_K"
tune=$(sid 'Tune retrieval constants')
run "git show --format='%h %an: %s' $tune | grep '^[-+][A-Z]'"

snip 04-ravi
mrg=$(git log --merges --format=%h -1)
run "git log --oneline $mrg^1..$mrg^2"
run "git diff $mrg^1...$mrg^2 -- ragbench/retrieve.py"

snip 05-blame-through
run "git blame -s -L 3,7 --ignore-rev $fmt ragbench/retrieve.py"
run "git log --oneline -m -S'TOP_K=5'"

snip 06-bisect
run 'git bisect start deploy-2026-09-11 deploy-2026-09-04'
run "git bisect run grep -q '^TOP_K *= *20' ragbench/retrieve.py"
run 'git bisect reset'

snip 07-remerge
run "git show --remerge-diff --format='%h %an: %s' $mrg -- ragbench/retrieve.py"

snip 08-fix
run "git tag answer/culprit $mrg"
sed -e 's/^TOP_K = 5$/TOP_K = 20/' ragbench/retrieve.py > r.tmp && mv r.tmp ragbench/retrieve.py
note "edit ragbench/retrieve.py: TOP_K = 20"
run 'git diff'
run "git commit -q -am 'Restore TOP_K to 20' -m 'The conflict resolution of the feat/rerank merge ($mrg) wrote TOP_K=5. Neither side of the merge had asked for that value: main had 20, the branch had 20 and added RERANK_TOP=5.'"

snip 09-prevent
git rev-parse "$fmt" | sed 's/$/   # Format the package with the new formatter/' > .git-blame-ignore-revs
note "create .git-blame-ignore-revs with the full ID of the formatter commit"
run 'cat .git-blame-ignore-revs'
run "git add .git-blame-ignore-revs && git commit -q -m 'List the formatter commit for git blame to skip'"
run 'git config set blame.ignoreRevsFile .git-blame-ignore-revs'
run 'git blame -s -L 3,7 ragbench/retrieve.py'

snip 10-publish
run 'git log --oneline -4'
run 'git push origin main'
run 'git status -sb'
run 'cd ..'
show_check
ex_done
