#!/usr/bin/env bash
# Practice repositories for the Module 18 exercises 18.1 to 18.8 (clone variants, sparse
# checkout, transfer). Each exercise has its own directory ex-18-N/ with a bare server.git of
# the monorepo "searchstack"; you make most of the clones yourself.
# Do the exercises before you read this file: the script is the answer to some of them.
. "$(dirname "${BASH_SOURCE[0]}")/../../../labs/lib/lab-env.sh"
. "$COURSE_ROOT/labs/ex2/gen-lib.bash"
. "$COURSE_ROOT/labs/ex2/m18-fixture.bash"
ex_begin m18-searchstack-practice

for n in 1 2 3 4 5 6; do
  mkdir "ex-18-$n" && cd "ex-18-$n" || exit 1
  m18_server
  cd "$LAB_DIR" || exit 1
done

# ---------------------------------------------------------------- 18.7 a merge base that is not there
mkdir ex-18-7 && cd ex-18-7 || exit 1
m18_server
quiet 'git clone server.git dev'
( cd dev || exit 1
  quiet 'git switch -c feature/synonyms'
  printf 'SYNONYMS = {"k8s": "kubernetes"}\n' > libs/tokenize/synonyms.py
  printf '\n\ndef expand(query, synonyms):\n    return " ".join(synonyms.get(word, word) for word in query.split())\n' >> services/retriever/retrieve.py
  _c 'Add synonym table and expand queries in the retriever'
  put scripts/changed-services.sh <<'F'
#!/bin/sh
# Prints the services that changed on this branch, so that the pipeline tests only those.
base=$(git merge-base origin/main HEAD)
git diff --name-only "$base" HEAD | sed -n 's,^services/\([^/]*\)/.*,\1,p' | sort -u
F
  chmod +x scripts/changed-services.sh
  _c 'Add script that lists the changed services'
  quiet 'git push origin feature/synonyms' )
_lab_clock=$((_lab_clock + 240)); tick
rm -rf dev
quiet "git clone --depth 1 --branch feature/synonyms \"file://\$PWD/server.git\" ci"
quiet 'git -C ci fetch --depth 1 origin main:refs/remotes/origin/main'
cd "$LAB_DIR" || exit 1

# ---------------------------------------------------------------- 18.8 a file that is not on disk
mkdir ex-18-8 && cd ex-18-8 || exit 1
m18_server
quiet "git clone \"file://\$PWD/server.git\" work"
quiet 'git -C work sparse-checkout set --cone services/reranker'
cd "$LAB_DIR" || exit 1

ex_end
