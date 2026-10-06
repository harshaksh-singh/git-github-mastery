#!/usr/bin/env bash
# Final test, practical lab "merge" (section 4): the project "answerbank".
# Builds server.git and the clones you/, asha/ and ravi/. Two pull-request branches were merged
# into main without a conflict, and main is broken. Read TASK.md, not this file, before you start.
. "$(dirname "${BASH_SOURCE[0]}")/../../../labs/lib/lab-env.sh"
. "$COURSE_ROOT/assessments/gen/final-lib/final-lib.bash"
[ -n "${LAB_REPLAY:-}" ] || sandbox_begin final merge
final_begin merge

final_server
final_clone you
cd you || exit 1
mkdir -p answerbank tests
printf 'ANSWERS = {}\n\n\ndef fetch_answer(qid):\n    return ANSWERS.get(qid)\n\n\ndef put_answer(qid, text):\n    ANSWERS[qid] = text\n' > answerbank/store.py
printf 'from answerbank import store\n\n\ndef get(qid):\n    answer = store.fetch_answer(qid)\n    return {"id": qid, "answer": answer}\n' > answerbank/api.py
cat > tests/smoke.sh <<'SMOKE'
#!/bin/sh
# Smoke test: every "store.<name>(" call in the package must have a "def <name>(" in
# answerbank/store.py. Run it from the top of the repository: sh tests/smoke.sh
fail=0
for name in $(grep -rhoE 'store\.[a-z_]+\(' answerbank | sed -e 's/store\.//' -e 's/($//' | sort -u); do
  grep -q "^def $name(" answerbank/store.py || { echo "undefined: store.$name"; fail=1; }
done
[ "$fail" -eq 0 ] && echo "smoke test passed"
exit $fail
SMOKE
_c 'Add the answer store and its API'
quiet 'git push -u origin main'
final_note smoke "$(git rev-parse HEAD:tests/smoke.sh)"
cd "$LAB_DIR" || exit 1

# Asha renames the store functions. Her branch is green.
final_clone asha
cd asha || exit 1
as asha
quiet 'git switch -c refactor/store-names'
printf 'ANSWERS = {}\n\n\ndef get_answer(qid):\n    return ANSWERS.get(qid)\n\n\ndef put_answer(qid, text):\n    ANSWERS[qid] = text\n' > answerbank/store.py
printf 'from answerbank import store\n\n\ndef get(qid):\n    answer = store.get_answer(qid)\n    return {"id": qid, "answer": answer}\n' > answerbank/api.py
_c 'Rename fetch_answer to get_answer'
quiet 'git push -u origin refactor/store-names'
cd "$LAB_DIR" || exit 1

# Ravi adds an export that calls the store. His branch is green as well.
final_clone ravi
cd ravi || exit 1
as ravi
quiet 'git switch -c feature/bulk-export'
printf 'from answerbank import store\n\n\ndef export(qids):\n    rows = []\n    for qid in qids:\n        rows.append((qid, store.fetch_answer(qid)))\n    return rows\n' > answerbank/export.py
_c 'Add the bulk export'
quiet 'git push -u origin feature/bulk-export'
cd "$LAB_DIR/you" || exit 1

# You merge both pull requests, one after the other, and push.
as you
quiet 'git fetch'
quiet 'git merge --no-ff -m "Merge refactor/store-names" origin/refactor/store-names'
quiet 'git merge --no-ff -m "Merge feature/bulk-export" origin/feature/bulk-export'
quiet 'git push'
final_note main "$(git rev-parse HEAD)"

final_end
final_ready
