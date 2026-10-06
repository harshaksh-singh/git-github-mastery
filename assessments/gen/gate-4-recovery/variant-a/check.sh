#!/usr/bin/env bash
# Read-only verification of gate 4, hands-on variant A. Exit status 0 means the end state is right.
. "$(dirname "${BASH_SOURCE[0]}")/../../lib/check-lib.bash"
check_begin g4-a gate-4-recovery/variant-a "${1:-}"
R=modelcard-gen
expect_eq 'the tag v0.9.0 is the original tag object' "$(git -C $R rev-parse -q --verify refs/tags/v0.9.0 2>/dev/null)" "$(noted tag)"
expect_eq 'v0.9.0 is an annotated tag' "$(git -C $R cat-file -t refs/tags/v0.9.0 2>/dev/null)" tag
expect_eq 'the branch release/0.9 is back on the tagged commit' "$(git -C $R rev-parse -q --verify refs/heads/release/0.9 2>/dev/null)" "$(noted release)"
expect 'HEAD is on feature/license-section' on_branch $R feature/license-section
expect_eq 'feature/license-section has no new commit' "$(git -C $R rev-parse -q --verify refs/heads/feature/license-section 2>/dev/null)" "$(noted feature)"
expect_eq 'main has not moved' "$(git -C $R rev-parse -q --verify refs/heads/main 2>/dev/null)" "$(noted main)"
expect_eq 'cards/template.md has the final license section, uncommitted' "$(git -C $R hash-object cards/template.md 2>/dev/null)" "$(noted template)"
expect_eq 'notes/eval-plan.md is back' "$(git -C $R hash-object notes/eval-plan.md 2>/dev/null)" "$(noted plan)"
expect_eq 'the working tree differs from HEAD in exactly these two paths' "$(git -C $R status --porcelain --untracked-files=all 2>/dev/null | cut -c4- | sort | tr '\n' ' ')" 'cards/template.md notes/eval-plan.md '
expect_not 'no operation is left in progress' in_progress $R
check_end
