#!/usr/bin/env bash
# Lab 38.1: the facts for a timeline and a CTO summary of incident 4, read from reflogs, the
# deployment tag and commit metadata. Dates come from the fixed lab clock.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$LAB_SCRIPT_DIR/replay-lib.bash"
lab_begin incidents lab-38-1-timeline
incident_load 04-production-history-rewritten

snip 01-deployment
run 'cd you'
run 'git fetch'
run "git for-each-ref --format='%(refname:short)  %(taggerdate:iso)  %(taggername)  %(subject)' refs/tags"
run "git log -1 --format='%h  %cd  %s' --date=iso 'deploy-2026-09-07^{commit}'"

snip 02-rewrite
note 'When was the branch rewritten, and when was the rewrite published?'
run 'git -C ../ravi reflog show --date=iso production'
run 'git -C ../ravi reflog show --date=iso origin/production'

snip 03-adoption
note 'When did a second clone adopt the rewrite, and when did new work land on it?'
run 'git -C ../asha reflog show --date=iso production'
run 'git -C ../asha reflog show --date=iso origin/production'

snip 04-detection
note 'When did this clone first see it? (In real life: the time of the alert.)'
run 'git reflog show --date=iso origin/production'
lab_end
