#!/usr/bin/env bash
# Chapter 14D, section 14D.10: reading the primary sources that ship with Git itself. The release
# notes and the BreakingChanges document are installed next to the HTML manual
# ("git --html-path"). This demo needs the documentation that the Homebrew package installs.
. "$(dirname "$0")/../lib/lab-env.sh"
lab_begin ch14d release-notes

snip 01-where
run 'ls "$(git --html-path)/RelNotes" | grep -c adoc'
run 'ls "$(git --html-path)/RelNotes" | grep "^2\.5[3-5]"'

snip 02-sections
run 'grep -n -B1 "^---" "$(git --html-path)/RelNotes/2.55.0.adoc" | grep -v -e "---" -e "^--$"'

snip 03-search
note 'What did 2.55 say about the commands of this chapter?'
run 'grep -n -A1 -e "git history" -e "Rust support" -e "Hook scripts" "$(git --html-path)/RelNotes/2.55.0.adoc"'

snip 04-breaking-changes
run 'grep -n "^==" "$(git --html-path)/BreakingChanges.adoc"'
run 'grep -n "planned release date" "$(git --html-path)/BreakingChanges.adoc"'
note 'One line per planned change of a default:'
run "sed -n '/^=== Changes/,/^=== Removals/p' \"\$(git --html-path)/BreakingChanges.adoc\" | grep '^\* ' | cut -c1-78"

lab_end
