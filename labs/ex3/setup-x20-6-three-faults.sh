#!/usr/bin/env bash
# Hands-on setup for Exercise 20.6: a home directory with three planted faults in the Git and
# ssh configuration. Running it again throws the sandbox away and builds a fresh one.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$(dirname "$0")/fixture.bash"
sandbox_begin hands-on x20-6
scenario_x20_faults
[ -f "$LAB_DIR/home/.ssh/config" ] || { echo 'fixture: ssh config missing' >&2; exit 1; }
[ -d "$LAB_DIR/home/work/chunker/.git" ] || { echo 'fixture: repository missing' >&2; exit 1; }
setup_done 20.6 x20-6 'export HOME="$PWD/home" GIT_CONFIG_GLOBAL="$PWD/home/.gitconfig"'
