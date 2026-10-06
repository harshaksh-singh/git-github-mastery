#!/usr/bin/env bash
# Two branches of the superproject move the gitlink. When one library commit is an ancestor of the
# other, Git picks the descendant; when the two have diverged, the merge stops with a submodule
# conflict that only a commit of the library can resolve. Chapter 23, section 23.10.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$LAB_SCRIPT_DIR/fixtures/fixtures.sh"
lab_begin ch23 submodule-conflict
fx_docqa_submodule
fx_textsplit_tokens_branch
fx_textsplit_release
cd doc-qa
quiet 'git -C vendor/textsplit fetch'
quiet 'git switch -c use-release'
quiet 'git -C vendor/textsplit checkout v0.2.0'
commit_all 'Use textsplit 0.2.0'
quiet 'git switch main'
quiet 'git submodule update'
quiet 'git switch -c use-tokens'
quiet 'git -C vendor/textsplit checkout origin/feature/tokens'
commit_all 'Use the token splitter of textsplit'

snip 01-two-pointers
run 'git log --graph --oneline --decorate --all'
run 'git ls-tree use-release vendor/'
run 'git ls-tree use-tokens vendor/'
run 'git -C vendor/textsplit log --graph --oneline --decorate v0.2.0 origin/feature/tokens'

snip 02-conflict
run_rc 'git merge use-release'

snip 03-stages
run 'git status --short'
run 'git ls-files --unmerged'
run 'git submodule status'
run 'git diff'

snip 04-library-merges
note 'The two library commits have to be combined in the library. Asha does that upstream:'
snip_end
fx_textsplit_merge_tokens
cd doc-qa
snip 04-library-merges
run 'git -C vendor/textsplit fetch origin'
run 'git -C vendor/textsplit log --graph --oneline --decorate -4 origin/main'

snip 05-resolve
run 'git -C vendor/textsplit checkout --quiet origin/main'
run 'git add vendor/textsplit'
run 'git status --short'
run 'git commit --no-edit'
run 'git ls-tree HEAD vendor/'
run 'git submodule status'

snip 06-ancestor-case
note 'A new branch from main that records the library merge commit. use-release records v0.2.0,'
note 'an ancestor of that merge. Both branches moved the pointer away from the one main has.'
quiet 'git switch -c use-merged main'
commit_all 'Use textsplit with the token splitter merged'
run 'git ls-tree main vendor/'
run 'git ls-tree use-merged vendor/'
run 'git ls-tree use-release vendor/'
run_rc 'git merge use-release'
run 'git ls-tree HEAD vendor/'
lab_end
