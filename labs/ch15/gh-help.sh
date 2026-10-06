#!/usr/bin/env bash
# Chapter 15, sections 15.11 and 15.15: what the installed GitHub CLI documents about itself.
# Only "--help" is run: nothing contacts GitHub, and no credential is read. gh gets an empty
# configuration directory inside the sandbox.
# VOLATILE: the text depends on the installed gh version (2.88.1 when the book was written).
. "$(dirname "$0")/../lib/lab-env.sh"
. "$LAB_SCRIPT_DIR/fixture.bash"
lab_begin ch15 gh-help --volatile
export GH_CONFIG_DIR="$LAB_DIR/home/.config/gh" GH_NO_UPDATE_NOTIFIER=1 NO_COLOR=1
unset GH_TOKEN GITHUB_TOKEN GH_ENTERPRISE_TOKEN GITHUB_ENTERPRISE_TOKEN GH_HOST GH_REPO

snip 01-families
run "gh --help | sed -n '/^CORE COMMANDS/,/^HELP TOPICS/p' | sed '\$d'"

snip 02-release-create
run "gh release create --help | sed -n '/^If a matching git tag/,/^If the tag is not annotated/p'"
run "gh release create --help | grep -E -- '--(verify-tag|target|notes-from-tag|generate-notes|draft|prerelease) '"
run "gh release delete --help | grep -- '--cleanup-tag'"

snip 03-api-flags
run "gh api --help | sed -n '/^FLAGS/,/^INHERITED FLAGS/p' | sed '\$d'"

snip 04-ruleset
run "gh ruleset --help | sed -n '/^AVAILABLE COMMANDS/,/^FLAGS/p' | sed '\$d'"

lab_end
