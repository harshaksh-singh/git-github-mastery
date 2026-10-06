#!/usr/bin/env bash
# Chapter 20B, section 20B.11: a shell script committed with CRLF line endings fails on a
# Linux runner. git ls-files --eol shows what is in the index and in the working tree.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$(dirname "$0")/fixture.bash"
lab_begin ch20b line-endings
make_warehouse
# A colleague's editor on Windows saved the script with CRLF, and nothing normalised it.
quiet "printf '#!/usr/bin/env bash\r\nset -eu\r\necho \"would deploy to \$1\"\r\n' > scripts/deploy.sh"
commit_all 'Simplify the deploy script'

snip 01-symptom
run_rc './scripts/deploy.sh staging'

snip 02-eol
note 'i/ is the index (what is committed), w/ the working tree, attr/ the attributes in force.'
run 'git ls-files --eol scripts/deploy.sh README.md'
run 'git config get core.autocrlf'

snip 03-fix
note 'Declare the rule in the repository, so that it does not depend on anybody'"'"'s configuration:'
run "printf '* text=auto\n*.sh text eol=lf\n' > .gitattributes"
run 'git add --renormalize .'
run 'git status --short'
run 'git commit -q -m "Normalise line endings; shell scripts are always LF"'
run 'git ls-files --eol scripts/deploy.sh'

snip 04-working-tree
note 'The index is fixed. The file on disk is rewritten the next time Git checks it out:'
run 'rm scripts/deploy.sh'
run 'git restore scripts/deploy.sh'
run 'git ls-files --eol scripts/deploy.sh'
run_rc './scripts/deploy.sh staging'
lab_end
