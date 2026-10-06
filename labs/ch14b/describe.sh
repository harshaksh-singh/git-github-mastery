#!/usr/bin/env bash
# Chapter 14B, section 14B.12: git describe. A version string derived from the nearest
# annotated tag, its options, and the three ways it fails.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$(dirname "$0")/fixture.bash"
lab_begin ch14b describe
make_gateway "$LAB_DIR/inference-gateway"

snip 01-no-tags
run_rc 'git describe'
run 'git describe --always'
run 'git tag staging-ok'
run_rc 'git describe'
run 'git describe --tags'

snip 02-on-the-tag
run 'git tag -a v1.0.0 -m "inference-gateway 1.0.0"'
run 'git describe'
run 'git describe --long'

snip 03-after-the-tag
quiet 'mkdir -p gateway docs'
commit_file gateway/health.py 'def healthy():\n    return True\n' 'Add health endpoint'
commit_file gateway/auth.py 'def check(token):\n    return bool(token)\n' 'Add token check'
run 'git log --oneline --decorate'
run 'git describe'
run 'git rev-parse --short HEAD'
run 'git rev-list --count v1.0.0..HEAD'
run 'git log --oneline "$(git describe)" -1'

snip 04-options
run 'git describe --abbrev=0'
run 'git describe --abbrev=12'
run 'git describe HEAD~1'
run_rc 'git describe --exact-match'
run 'git describe --exact-match HEAD~2'

snip 05-dirty
run "printf 'def check(token):\n    return token == \"letmein\"\n' > gateway/auth.py"
run 'git describe --dirty'
run 'git describe --dirty=+local'
run 'git restore gateway/auth.py'
run 'git describe --dirty'

snip 06-which-tags
run 'git tag -a v1.1.0-rc.1 -m "Release candidate" HEAD~1'
run 'git tag deployed-staging'
run 'git describe'
run "git describe --exclude '*-rc.*'"
run 'git describe --tags'
run "git describe --tags --match 'v[0-9]*'"

snip 07-contains
note 'The other direction: which tag came after this commit and contains it?'
run 'git describe --contains HEAD~3'
run 'git describe --contains HEAD~1'
quiet 'git commit --allow-empty -m "Start 1.2 development"'
run_rc 'git describe --contains HEAD'

lab_end
