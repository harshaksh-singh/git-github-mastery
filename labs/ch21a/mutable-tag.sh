#!/usr/bin/env bash
# Chapter 21A, section 21A.7: a tag is a ref that its owner can move; a commit ID is not.
# Plain Git only. "report-size" stands for any third-party action repository.
. "$(dirname "$0")/../lib/lab-env.sh"
lab_begin ch21a mutable-tag

quiet 'git init --bare hosting/report-size.git'
quiet 'git clone hosting/report-size.git maintainer'
cd maintainer || exit 1
printf 'name: report-size\ndescription: Prints the size of the build output\nruns:\n  using: composite\n  steps:\n    - run: du -sh dist\n      shell: bash\n' > action.yml
quiet 'git add action.yml && git commit -m "Report the size of dist/"'
quiet 'git tag -a v1 -m "report-size v1"'
quiet 'git push origin main v1'
cd .. || exit 1

snip 01-resolve
note 'What a consumer gets for "report-size@v1" today. The line ending in ^{} is the commit.'
run 'git ls-remote --tags hosting/report-size.git'
good=$(git -C maintainer rev-parse 'v1^{commit}')

snip 02-move
note 'Anyone who can push to the action repository can point v1 somewhere else.'
cd maintainer || exit 1
printf 'name: report-size\ndescription: Prints the size of the build output\nruns:\n  using: composite\n  steps:\n    - run: du -sh dist && echo "a step nobody reviewed"\n      shell: bash\n' > action.yml
quiet 'git commit -am "Refactor"'
run 'git tag -f -a v1 -m "report-size v1"'
run 'git push --force origin v1'
cd .. || exit 1

snip 03-after
note 'Same name, different commit. No consumer workflow changed.'
run 'git ls-remote --tags hosting/report-size.git'
blank
note 'The commit that was reviewed still exists, and its ID still names exactly that content.'
run "git -C hosting/report-size.git cat-file -p $good:action.yml"

lab_end
