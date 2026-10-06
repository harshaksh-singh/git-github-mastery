#!/usr/bin/env bash
# Chapter 7, section 7.12: the "feature" versus "feature/x" conflict. A ref name cannot be both
# a ref and a prefix of other refs. The rule is part of Git's ref namespace: it holds for loose
# refs, for packed refs, and in a reftable repository. Also: names that Git rejects outright.
. "$(dirname "$0")/../lib/lab-env.sh"
lab_begin ch07 ref-name-conflict

quiet 'git init evalkit'
cd evalkit || exit 1
printf '# evalkit\n\nSmall evaluation harness for LLM outputs.\n' > README.md
quiet 'git add . && git commit -m "Add README"'

snip 01-conflict
run 'git branch feature'
run_rc 'git branch feature/login'
run 'ls .git/refs/heads'

snip 02-not-only-files
run 'git pack-refs --all'
run 'ls .git/refs/heads'
run_rc 'git branch feature/login'
run 'git init -q --ref-format=reftable ../reftable-repo'
run 'git -C ../reftable-repo commit -q --allow-empty -m "Start"'
run 'git -C ../reftable-repo branch feature'
run_rc 'git -C ../reftable-repo branch feature/login'

snip 03-other-direction
run 'git branch -m feature feature/base'
run 'git branch feature/login'
run_rc 'git branch feature'
run 'git branch'

snip 04-invalid-names
run_rc "git branch 'fix bug'"
run_rc 'git check-ref-format --branch fix..bug'
run_rc 'git check-ref-format --branch fix/judge.lock'
run_rc 'git check-ref-format --branch fix/judge-timeout'

snip 05-full-name-trap
run 'git branch refs/heads/fix/judge-timeout'
run "git for-each-ref --format='%(refname)' refs/heads"
run 'git branch -D refs/heads/fix/judge-timeout'

lab_end
