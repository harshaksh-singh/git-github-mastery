#!/usr/bin/env bash
# Lab 6.2 hands-on setup: builds the starting repository in the lab sandbox hands-on/m06-2.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$(dirname "$0")/fixtures/evalkit.sh"
. "$(dirname "$0")/fixtures/m06.sh"
sandbox_begin hands-on m06-2
quiet 'm06_2_fixture' || { echo "setup failed" >&2; exit 1; }
m06_setup_done 2
