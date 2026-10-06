#!/usr/bin/env bash
# Chapter 14A, section 14A.2: "git diff A B", "A..B" and "A...B" compare different pairs of
# snapshots. main and feat/report have diverged, and one commit exists on both sides as a copy.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$LAB_SCRIPT_DIR/fixtures/scorekit.sh"
lab_begin ch14a diff-endpoints
fx_scorekit || exit 1

snip 01-graph
run 'git log --graph --oneline --decorate -6 main feat/report'
run 'git merge-base main feat/report'

snip 02-two-endpoints
run 'git diff --stat main feat/report'
run 'git diff --stat main..feat/report'

snip 03-three-dots
run 'git diff --stat main...feat/report'
run 'git diff --stat $(git merge-base main feat/report) feat/report'

snip 04-config
note 'Two endpoints: the line that main added after the fork shows up as a deletion.'
run 'git diff main feat/report -- scorekit/config.py'
note 'Three dots: the branch never touched the file.'
run 'git diff main...feat/report -- scorekit/config.py'

snip 05-readme
note 'The README paragraph was cherry-picked to main. Both tips have it, the merge base does not.'
run 'git diff --stat main feat/report -- README.md'
run 'git diff main...feat/report -- README.md'

snip 06-other-direction
run 'git diff --stat feat/report...main'

snip 07-trees-and-blobs
run 'git diff --stat v0.1.0:scorekit main:scorekit'
run 'git diff v0.1.0:scorekit/config.py main:scorekit/config.py'
lab_end
