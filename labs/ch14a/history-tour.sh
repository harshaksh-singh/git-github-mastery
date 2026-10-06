#!/usr/bin/env bash
# Chapter 14A, section 14A.1: the prepared history that the whole chapter investigates, and the
# symptom that starts the investigation.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$LAB_SCRIPT_DIR/fixtures/scorekit.sh"
lab_begin ch14a history-tour
fx_scorekit || exit 1

snip 01-symptom
run_rc 'python3 -B -m scorekit.runner data/smoke.jsonl'
run 'git describe'

snip 02-graph
run 'git log --graph --oneline --decorate --all'

snip 03-who-when
run "git log --first-parent --format='%h %ad %<(10)%an %s' --date=format:'%a %d %H:%M' v0.1.0..v0.2.0"
lab_end
