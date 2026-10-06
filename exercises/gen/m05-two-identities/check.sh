#!/usr/bin/env bash
# Read-only verification of Exercise 5.9. Exit status 0 means solved.
. "$(dirname "${BASH_SOURCE[0]}")/../x1-lib/check-lib.bash"
check_begin m05-two-identities "${1:-}"
export HOME="$EX_DIR/home" XDG_CONFIG_HOME="$EX_DIR/home/.config"
W=home/work; C=lab.user@corp.example; P=lab.user@personal.example
for r in billing-llm invoice-ocr; do
  expect_eq "$r: the effective address is the company address" "$(git -C $W/$r config get user.email)" $C
  expect_not "$r: no repository-local user.email papers over the cause" git -C $W/$r config get --local user.email
  expect_eq "$r: the last commit has the company address as author and committer" "$(git -C $W/$r log -1 --format='%ae %ce')" "$C $C"
  expect_eq "$r: the history still has two commits" "$(git -C $W/$r rev-list --count HEAD)" 2
done
expect_eq 'billing-llm: the older commit is untouched' "$(git -C $W/billing-llm rev-parse -q --verify HEAD~1)" "$(noted billing_parent)"
expect_eq 'invoice-ocr: the older commit is untouched' "$(git -C $W/invoice-ocr rev-parse -q --verify HEAD~1)" "$(noted ocr_parent)"
expect_eq 'the personal repository still resolves the personal address' "$(git -C home/oss/dotfiles config get user.email)" $P
expect_eq 'the personal repository is untouched' "$(git -C home/oss/dotfiles rev-parse -q --verify HEAD)" "$(noted dotfiles_tip)"
expect_eq 'the global default address is still the personal one' "$(git config get --global user.email)" $P
inc="$(git config get --global --type=path 'includeIf.gitdir:~/work/.path' 2>/dev/null)"
if [ -n "$inc" ] && [ -f "$inc" ]; then ok 'the include for ~/work/ names a file that exists'; else bad 'the conditional include for ~/work/ does not name an existing file'; fi
check_end
