#!/usr/bin/env bash
# Gate 5 (Internals), prediction part. The pN-setup snippets are printed in the gate file, the
# pN-answer snippets only in the answer key.
. "$(dirname "$0")/../lib/lab-env.sh"
lab_begin gates g5-predict

# ---- P1: one loose object
snip p1-setup
run 'git init -q objdb'
run 'cd objdb'
run "printf 'top_k: 5\n' > a.yaml"
run 'cp a.yaml b.yaml'
run 'git hash-object -w a.yaml'
run 'git hash-object -w b.yaml'
snip p1-answer
run 'find .git/objects -type f | sort'
run 'git cat-file -t 1380a9d'
run 'git cat-file -s 1380a9d'
note 'The file, decompressed: header, NUL byte, content.'
run "python3 -c \"import zlib,sys; print(repr(zlib.decompress(open(sys.argv[1],'rb').read())))\" .git/objects/13/80a9de8d8f7c7cb7da1739d9dfc9c7539b9fe6"
run 'git status --short'
run 'git fsck'
cd "$LAB_DIR"

# ---- P2: loose and packed, objects and refs
snip p2-setup
run 'git init -q packing'
run 'cd packing'
run "printf 'epochs: 1\n' > train.yaml && git add . && git commit -q -m 'One epoch'"
run "printf 'epochs: 2\n' > train.yaml && git commit -q -am 'Two epochs'"
run "printf 'epochs: 3\n' > train.yaml && git commit -q -am 'Three epochs'"
run 'git tag v1'
snip p2-answer-a
run "git count-objects -v | grep -E '^(count|in-pack|packs):'"
run 'find .git/refs -type f | sort'
snip p2-setup-b
run 'git gc -q'
snip p2-answer-b
run "git count-objects -v | grep -E '^(count|in-pack|packs):'"
run 'find .git/refs -type f | sort'
run "grep -c . .git/packed-refs"
run 'git rev-parse --short main'
snip p2-setup-c
run "printf 'epochs: 4\n' > train.yaml && git commit -q -am 'Four epochs'"
snip p2-answer-c
run "git count-objects -v | grep -E '^(count|in-pack|packs):'"
run 'find .git/refs -type f | sort'
run "grep -c \"\$(git rev-parse main)\" .git/packed-refs"
cd "$LAB_DIR"

# ---- P3: what the index records
snip p3-setup
run 'git init -q idx'
run 'cd idx'
run 'mkdir -p tools conf'
run "printf '#!/bin/sh\necho ok\n' > tools/run.sh && chmod +x tools/run.sh"
run "printf 'a: 1\n' > conf/base.yaml"
run 'ln -s conf/base.yaml current.yaml'
run "printf 'draft\n' > NOTES.md"
run 'git add tools conf current.yaml'
run 'git add -N NOTES.md'
snip p3-answer
run "git ls-files -s | cut -c1-7,48-"
run "git ls-files -s NOTES.md"
run 'git status --short'
run 'git cat-file -p $(git write-tree) | cut -c1-12,53-'
cd "$LAB_DIR"

# ---- P4: a blobless clone
quiet 'git init --bare server.git'
quiet 'git -C server.git config set uploadpack.allowFilter true'
quiet 'git clone server.git seed'
cd seed || exit 1
quiet "printf 'lr: 0.1\n' > model.yaml && printf 'notes\n' > README.md && git add . && git commit -m 'Add model'"
quiet "printf 'lr: 0.01\n' > model.yaml && git commit -am 'Lower learning rate'"
quiet "printf 'lr: 0.001\n' > model.yaml && git commit -am 'Lower learning rate again'"
quiet 'git push origin main'
cd "$LAB_DIR"
snip p4-setup
note 'server.git has three commits on main. Each commit changed model.yaml; README.md was'
note 'added in the first commit and never changed.'
run 'git -C seed log --oneline --stat --format="%s" | grep -v "^$" | grep -v changed'
run "git clone -q --filter=blob:none file://\$PWD/server.git partial"
run 'cd partial'
snip p4-answer
run 'git rev-list --count HEAD'
run "git rev-list --objects --missing=print HEAD | grep -c '^?'"
run "git cat-file --batch-all-objects --batch-check='%(objecttype)' | sort | uniq -c | sed 's/^ *//'"
run 'git show HEAD~1:model.yaml'
run "git rev-list --objects --missing=print HEAD | grep -c '^?'"
run 'git log --oneline -- model.yaml | wc -l | tr -d " "'
run "git rev-list --objects --missing=print HEAD | grep -c '^?'"
run 'git log -p --format=%s -- model.yaml | grep -c "^[-+]lr"'
run "git rev-list --objects --missing=print HEAD | grep -c '^?'"
lab_end
