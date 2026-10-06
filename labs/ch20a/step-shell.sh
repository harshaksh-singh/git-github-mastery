#!/usr/bin/env bash
# Three things about `run` steps, reproduced with local bash and files:
#   1. the default template `bash -e {0}` lets a failing pipeline pass; `shell: bash` adds pipefail;
#   2. every step is a new process, so shell state does not carry over;
#   3. GITHUB_OUTPUT and GITHUB_ENV are files that steps append to.
# The runner is imitated: the two shell command lines are the documented templates, and the files
# stand in for the ones the runner provides. Chapter 20A, sections 20A.6 and 20A.7.
. "$(dirname "$0")/../lib/lab-env.sh"
lab_begin ch20a step-shell

quiet "printf 'set -u\nfalse | tee /dev/null\necho \"the step reached its last line\"\n' > step.sh"
snip 01-pipefail
run 'cat step.sh'
note 'No shell key on Linux or macOS: bash -e {0}'
run_rc 'bash -e step.sh'
note 'shell: bash: bash --noprofile --norc -eo pipefail {0}'
run_rc 'bash --noprofile --norc -eo pipefail step.sh'

snip 02-new-process-per-step
quiet 'mkdir -p build'
quiet "printf 'export BUILD_ID=build-42\ncd build\npwd\n' > step1.sh"
quiet "printf 'echo \"BUILD_ID is [\${BUILD_ID:-}]\"\npwd\n' > step2.sh"
run 'cat step1.sh'
run 'bash -e step1.sh'
run 'cat step2.sh'
run 'bash -e step2.sh'

snip 03-github-output
note 'The runner gives each step a file path in GITHUB_OUTPUT. A file stands in for it here.'
run 'export GITHUB_OUTPUT="$PWD/step-describe.output"'
run 'echo "describe=v0.1.0-1-g$(printf abc1234)" >> "$GITHUB_OUTPUT"'
run 'echo "files=inventory_api-0.1.0.tar.gz inventory_api-0.1.0-py3-none-any.whl" >> "$GITHUB_OUTPUT"'
run 'cat "$GITHUB_OUTPUT"'
note 'A multi-line value needs the delimiter form:'
run 'printf "notes<<EOF_NOTES\nline one\nline two\nEOF_NOTES\n" >> "$GITHUB_OUTPUT"'
run 'cat "$GITHUB_OUTPUT"'

snip 04-deprecated-set-output
note 'The deprecated form wrote a command to standard output, where any program can print it:'
run 'echo "::set-output name=describe::v0.1.0"'
lab_end
