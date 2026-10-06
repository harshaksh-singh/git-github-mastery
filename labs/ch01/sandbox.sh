#!/usr/bin/env bash
# Chapter 1, section "How to use this book": what the lab environment sets, why Git inside it
# cannot see your real configuration, and where the fixed clock shows up.
. "$(dirname "$0")/../lib/lab-env.sh"
lab_begin ch01 sandbox

# The first listing must show what the lab library sets, and nothing else. The shell that starts
# a replay may export other variables whose names begin with GIT_: the course's own
# GIT_MASTERY_LABS (which only relocates the lab root), prompt settings such as
# GIT_PS1_SHOWDIRTYSTATE, GIT_ASKPASS, and so on. Remove those here, so that the transcript is
# identical on every machine and for every lab root.
for v in $(env | sed -n 's/^\(GIT_[A-Za-z0-9_]*\)=.*/\1/p'); do
  case "$v" in
    GIT_AUTHOR_NAME|GIT_AUTHOR_EMAIL|GIT_AUTHOR_DATE) ;;
    GIT_COMMITTER_NAME|GIT_COMMITTER_EMAIL|GIT_COMMITTER_DATE) ;;
    GIT_CONFIG_GLOBAL|GIT_CONFIG_NOSYSTEM|GIT_CEILING_DIRECTORIES|GIT_TEST_DATE_NOW) ;;
    GIT_EDITOR|GIT_PAGER|GIT_MERGE_AUTOEDIT|GIT_TERMINAL_PROMPT) ;;
    *) unset "$v" ;;
  esac
done

snip 01-env
run "env | grep '^GIT_' | sort"

snip 02-config
run 'git config list --show-origin --show-scope'
run 'git config set --global alias.st "status --short --branch"'
run 'git config list --show-origin --show-scope'

snip 03-clock
run 'git init -q clock && cd clock'
run 'git commit -q --allow-empty -m "Check the lab clock"'
run 'git log --format=fuller'

lab_end
