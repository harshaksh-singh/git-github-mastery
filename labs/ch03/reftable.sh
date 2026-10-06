#!/usr/bin/env bash
# Chapter 3, section 3.13: the reftable backend, created with "git init --ref-format=reftable"
# and compared with the "files" backend.
# The names of reftable tables end in a random suffix, so listings pipe through sed to mask it.
. "$(dirname "$0")/../lib/lab-env.sh"
lab_begin ch03 reftable

snip 01-init
run 'git init --ref-format=reftable inference-service'
run 'cd inference-service'
run 'git rev-parse --show-ref-format'
run 'cat .git/config'

snip 02-stubs
run 'ls -A .git'
note 'Two stub files are kept for tools that look for them. Neither holds a ref:'
run 'cat .git/HEAD'
run 'cat .git/refs/heads'
note 'The real answer comes from Git:'
run 'git symbolic-ref HEAD'

snip 03-tables
run "printf 'retry_limit = 3\\n' > config.toml"
run 'git add config.toml'
run 'git commit --quiet -m "Add service configuration"'
run 'git branch feature/batching'
run 'git tag -a v1.0.0 -m "Release 1.0.0"'
note 'Refs and reflogs live in binary tables. tables.list names the tables in use, oldest first.'
note 'A table name is first update number, last update number and a random suffix (masked here).'
run "sed -E 's/-[0-9a-f]{8}\\./-<random>./' .git/reftable/tables.list"
note 'Compaction merges tables. Git does it on its own; git pack-refs asks for it explicitly:'
run 'git pack-refs --all'
run "sed -E 's/-[0-9a-f]{8}\\./-<random>./' .git/reftable/tables.list"
note 'The 24-byte header: REFT, version 1, block size, first and last update number.'
run 'head -c 24 .git/reftable/*.ref | xxd'

snip 04-same-answers
note 'No logs directory and no packed-refs file. Plumbing answers as in any other repository:'
run 'ls -A .git'
run 'git for-each-ref'
run 'git reflog show feature/batching'
run 'git rev-parse main'

snip 05-root-refs
note 'A conflicted merge, to see where the refs outside refs/ are kept in this format:'
run "git switch --quiet feature/batching && printf 'retry_limit = 4\\n' > config.toml && git commit --quiet -am 'Allow four retries'"
run "git switch --quiet main && printf 'retry_limit = 5\\n' > config.toml && git commit --quiet -am 'Allow five retries'"
run_rc 'git merge feature/batching'
note 'MERGE_HEAD is a file, as in every repository. ORIG_HEAD and AUTO_MERGE are not files here:'
run 'ls -A .git'
run 'git for-each-ref --include-root-refs | grep -v refs/'
run 'git merge --abort'

snip 06-names
note 'Names that differ only in case are two refs here, on a filesystem that ignores case:'
run 'git branch Hotfix'
run 'git branch hotfix'
run 'git branch --list "[Hh]otfix"'
note 'The same two commands in a files-format repository on the same disk:'
run 'git init --quiet ../files-repo'
run 'git -C ../files-repo commit --quiet --allow-empty -m "Start"'
run 'git -C ../files-repo branch Hotfix'
run_rc 'git -C ../files-repo branch hotfix'
note 'One rule of the files layout is kept: a ref cannot be both a name and a prefix of names.'
run_rc 'git branch feature'

snip 07-git-3-preview
note 'The two formats that Git 3.0 plans as defaults for new repositories can be chosen today:'
run 'git init --quiet --object-format=sha256 --ref-format=reftable ../future-repo'
run 'cat ../future-repo/.git/config'

lab_end
