#!/usr/bin/env bash
# Lab 6.3 hands-on setup: builds the starting repository in the lab sandbox hands-on/m06-3.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$(dirname "$0")/fixtures/evalkit.sh"
. "$(dirname "$0")/fixtures/m06.sh"
sandbox_begin hands-on m06-3
quiet 'm06_3_fixture' || { echo "setup failed" >&2; exit 1; }
m06_setup_done 3
