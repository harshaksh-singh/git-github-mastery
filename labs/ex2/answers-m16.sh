#!/usr/bin/env bash
# Model answers for exercises 16.1 to 16.8 (Module 16: the object database and its maintenance)
# as real transcripts on the practice repositories built by
# exercises/gen/m16-shardmap-practice/generate.sh.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$LAB_SCRIPT_DIR/replay-lib.bash"
lab_begin ex2 answers-m16
ex_load m16-shardmap-practice
COUNTS="git count-objects -v | grep -e '^count' -e in-pack -e '^packs'"

cd ex-16-1 || exit 1
snip 16-1-hash
run "printf 'shards: 16\n' > shards.yaml"
run 'git hash-object shards.yaml'
run "printf 'blob 11\0shards: 16\n' | shasum"
run 'find .git/objects -type f | wc -l'
snip 16-1-write
run 'git hash-object -w shards.yaml'
run 'find .git/objects -type f'
f=$(find .git/objects -type f)
run "python3 -c 'import sys, zlib; print(zlib.decompress(open(sys.argv[1], \"rb\").read()))' $f"
run 'cp shards.yaml other.yaml && git hash-object other.yaml'
cd "$LAB_DIR" || exit 1

cd ex-16-2 || exit 1
snip 16-2-chain
run 'git cat-file -p HEAD'
run "git cat-file -p 'HEAD^{tree}'"
run 'git cat-file -p HEAD:config'
snip 16-2-blob
run 'git rev-parse HEAD:config/shards.yaml'
b=$(git rev-parse --short HEAD:config/shards.yaml)
run "git cat-file -t $b"
run "git cat-file -s $b"
run "git cat-file -p $b"
run 'git ls-tree -r HEAD'
cd "$LAB_DIR" || exit 1

cd ex-16-3 || exit 1
snip 16-3-before
run "$COUNTS"
run 'git gc -q'
run "$COUNTS"
run 'find .git/objects -type f | sed "s/[0-9a-f]\{40\}/ID/" | sort'
snip 16-3-pack
run "git cat-file --batch-check --batch-all-objects | awk '{print \$2}' | sort | uniq -c"
run "git verify-pack -v .git/objects/pack/pack-*.idx | awk '\$2 == \"blob\" && NF == 7'"
run "git verify-pack -v .git/objects/pack/pack-*.idx | tail -5"
snip 16-3-base
run 'for c in $(git rev-list --reverse HEAD -- config/assignments.yaml); do echo "$(git log -1 --format=%s ${c}): $(git rev-parse --short "${c}:config/assignments.yaml"), $(git cat-file -s "${c}:config/assignments.yaml") bytes"; done'
cd "$LAB_DIR" || exit 1

cd ex-16-4 || exit 1
snip 16-4-setup
run 'git init -q objects-lab && cd objects-lab'
run "echo 'shards: 16' > a.yaml && cp a.yaml b.yaml && git add a.yaml b.yaml"
snip 16-4-answers
run 'git count-objects -v | head -1'
run "git commit -q -m 'Add two files' && git count-objects -v | head -1"
run "git commit -q --amend -m 'Add two identical files' && git count-objects -v | head -1"
run "mkdir config && git mv a.yaml config/a.yaml && git commit -q -m 'Move a file' && git count-objects -v | head -1"
run "echo 'shards: 32' > b.yaml && git commit -q -am 'Use 32 shards' && git count-objects -v | head -1"
snip 16-4-types
run "git cat-file --batch-check --batch-all-objects | awk '{print \$2}' | sort | uniq -c"
cd "$LAB_DIR" || exit 1

cd ex-16-5 || exit 1
snip 16-5-start
run 'git branch -a'
run 'git reflog | grep consistent'
c=$(git reflog | awk '/Try consistent hashing/ {print $1; exit}')
run "$COUNTS"
snip 16-5-gc
run 'git gc -q'
run "$COUNTS"
run "git cat-file -t $c"
snip 16-5-cruft
run 'git reflog expire --expire=now --all'
run 'git gc -q'
run "$COUNTS"
run 'ls .git/objects/pack | sed "s/[0-9a-f]\{40\}/ID/" | sort'
run "git cat-file -t $c"
snip 16-5-prune
run 'git gc -q --prune=now'
run "$COUNTS"
run_rc "git cat-file -t $c"
cd "$LAB_DIR" || exit 1

cd ex-16-6 || exit 1
snip 16-6-largest
run 'git ls-files'
run "git rev-list --objects --all | git cat-file --batch-check='%(objecttype) %(objectsize) %(objectname) %(rest)' | awk '\$1 == \"blob\"' | sort -k2 -n -r | head -3"
snip 16-6-where
big=$(git rev-list --objects --all | git cat-file --batch-check='%(objecttype) %(objectsize) %(objectname) %(rest)' | awk '$1 == "blob"' | sort -k2 -n -r | head -1 | cut -d' ' -f3)
run "git log --oneline --diff-filter=A -- fixtures/index.bin"
run "git log --oneline --diff-filter=D -- fixtures/index.bin"
run "git cat-file -e ${big:0:7} && echo still in the object database"
cd "$LAB_DIR" || exit 1

cd ex-16-7 || exit 1
snip 16-7-fsck
run_rc 'git fsck'
run 'git status -sb'
run_rc 'git show HEAD:shardmap/assign.py'
snip 16-7-missing
m=$(git fsck 2>/dev/null | awk '$1=="missing"{print $3}')
run "git ls-tree -r HEAD | grep $m"
run 'git hash-object shardmap/assign.py'
run 'git hash-object -w shardmap/assign.py'
run_rc 'git fsck'
snip 16-7-dangling
dc=$(git fsck 2>/dev/null | awk '$1=="dangling" && $2=="commit"{print $3}')
db=$(git fsck 2>/dev/null | awk '$1=="dangling" && $2=="blob"{print $3}')
run "git show -s --format='%h %s' ${dc:0:7}"
run "git cat-file -p ${db:0:7}"
cd "$LAB_DIR" || exit 1

cd ex-16-8 || exit 1
snip 16-8-before
run 'tools/current-commit.sh'
run 'tools/count-objects.sh'
snip 16-8-after
run 'git gc -q'
run_rc 'tools/current-commit.sh'
run 'tools/count-objects.sh'
snip 16-8-why
run 'cat .git/packed-refs'
run 'ls .git/refs/heads | wc -l'
run "$COUNTS"
snip 16-8-fix
run 'git rev-parse --verify refs/heads/main'
run 'git cat-file --batch-check --batch-all-objects | wc -l'
lab_end
