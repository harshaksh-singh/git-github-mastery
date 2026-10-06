#!/usr/bin/env bash
# CODEOWNERS patterns "follow most of the same rules used in gitignore files". Git cannot
# evaluate a CODEOWNERS file, but it can show how the gitignore rules behave, which makes the
# documented differences concrete. Every command here asks Git's ignore matcher, NOT GitHub.
# Chapter 19, section 19.5.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$(dirname "$0")/fixture.bash"
lab_begin ch18 codeowners-vs-gitignore
hidden 'git init patterns'
cd patterns || exit 1
git config set core.ignoreCase false

snip 01-last-match-wins
note 'Three patterns in one gitignore-format file. check-ignore -v names the pattern that decides:'
run "printf '*.py\n/router/*.py\n/router/priority.py\n' > .gitignore"
run 'git check-ignore -v --no-index tests/test_classify.py router/classify.py router/priority.py'

snip 02-anchoring
run "printf 'apps/\n/docs/\n**/logs\n' > .gitignore"
run 'git check-ignore -v --no-index apps/a.py services/billing/apps/a.py docs/a.md guide/docs/a.md build/logs/x.log logs/x.log'
note 'guide/docs/a.md is not listed: /docs/ is anchored to the top level.'

snip 03-directory-capture
note 'Where the two part ways: a catch-all first line, then a more specific pattern.'
run "printf '*\n*.py\n' > .gitignore"
run 'git check-ignore -v --no-index setup.py tests/test_classify.py'
note 'Git stops at the directory tests/, which the first line already matches.'
note 'CODEOWNERS documentation: after "*", a later "*.js" line owns every JS file.'

snip 04-docs-star
note 'The same mechanism behind a documented example: docs/* and nested files.'
run "printf 'docs/*\n' > .gitignore"
run 'git check-ignore -v --no-index docs/getting-started.md docs/build-app/troubleshooting.md'
note 'Git ignores the nested file too, because docs/* matches the directory docs/build-app.'
note 'CODEOWNERS documentation: docs/* does not match docs/build-app/troubleshooting.md.'

snip 05-negation
note 'Documented as unsupported in CODEOWNERS: ! negation. In gitignore it works:'
run "printf '*.yaml\n!config/routing.yaml\n' > .gitignore"
run 'git check-ignore -v --no-index config/routing.yaml deploy/values.yaml'

snip 06-range
note 'Documented as unsupported in CODEOWNERS: [ ] character ranges. In gitignore they work:'
run "printf 'shard-[0-3].yaml\n' > .gitignore"
run 'git check-ignore -v --no-index shard-2.yaml shard-7.yaml'

snip 07-hash
note 'Documented as unsupported in CODEOWNERS: a leading # escaped with a backslash.'
run "printf '\\\\#generated.md\n' > .gitignore"
run 'cat .gitignore'
run 'git check-ignore -v --no-index "#generated.md"'

snip 08-case
note 'CODEOWNERS paths are always case sensitive. Git depends on core.ignoreCase, which git init'
note 'switches on when the file system ignores case, as the default macOS file system does:'
run "printf '/docs/\n' > .gitignore"
run_rc 'git -c core.ignoreCase=false check-ignore -v --no-index Docs/a.md'
run_rc 'git -c core.ignoreCase=true check-ignore -v --no-index Docs/a.md'

lab_end
