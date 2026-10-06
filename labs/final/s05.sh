#!/usr/bin/env bash
# Final test, section 5 (Rebase): prediction items P1 and P2, diagram items G1 and G2 and
# interpretation items I1 and I2.
. "$(dirname "$0")/../lib/lab-env.sh"
lab_begin final s05

# ---- P1: who is the author and who is the committer after a rebase
snip p1-setup
run 'git init -q citations'
run 'cd citations'
run 'git commit -q --allow-empty -m "Add the citation style"'
run 'git switch -q -c feature/doi'
note 'Asha makes the next commit, on her machine, with her identity.'
as asha
run 'git commit -q --allow-empty -m "Resolve DOIs"'
as you
note 'You continue, with your identity, some minutes later.'
run 'git switch -q main'
run 'git commit -q --allow-empty -m "Add the BibTeX export"'
run 'git switch -q feature/doi'
run 'git rebase -q main'
snip p1-answer
run "git log -1 --date=format:%H:%M --format='%s%nauthor    %an at %ad%ncommitter %cn at %cd' ORIG_HEAD"
run "git log -1 --date=format:%H:%M --format='%s%nauthor    %an at %ad%ncommitter %cn at %cd' HEAD"
run "git log --format=%h -1 ORIG_HEAD; git log --format=%h -1 HEAD"
cd "$LAB_DIR"

# ---- P2: where the branch is while a rebase is stopped
snip p2-setup
run 'git init -q summarizer'
run 'cd summarizer'
run "printf 'max_len: 200\n' > summary.yaml"
run 'git add . && git commit -q -m "Add summarizer settings"'
run 'git switch -q -c feature/long-docs'
run "printf 'max_len: 800\n' > summary.yaml"
run 'git commit -q -a -m "Allow long documents"'
run "printf 'stride: 400\n' > window.yaml"
run 'git add . && git commit -q -m "Add a sliding window"'
run 'git switch -q main'
run "printf 'max_len: 300\n' > summary.yaml"
run 'git commit -q -a -m "Raise the default length"'
run 'git switch -q feature/long-docs'
run 'git rebase main > /dev/null 2>&1'
snip p2-answer
run 'git branch --show-current'
run 'git rev-parse --abbrev-ref HEAD'
run 'cat .git/rebase-merge/head-name'
run 'git log --oneline -1 feature/long-docs'
run 'git log --oneline -1 HEAD'
run 'git status --short'
run 'git status | head -5'
cd "$LAB_DIR"

# ---- G1: a stack of three branches and --update-refs
snip g1-setup
run 'git init -q etlflow'
run 'cd etlflow'
run 'git commit -q --allow-empty -m "A: add the scheduler"'
run 'git switch -q -c stack/extract'
run 'git commit -q --allow-empty -m "B: extract from the API"'
run 'git switch -q -c stack/transform'
run 'git commit -q --allow-empty -m "C: normalize the records"'
run 'git switch -q -c stack/load'
run 'git commit -q --allow-empty -m "D: load into the warehouse"'
run 'git switch -q main'
run 'git commit -q --allow-empty -m "E: add retries to the scheduler"'
run 'git switch -q stack/load'
snip g1-before
run 'git log --graph --oneline --all --decorate'
snip g1-command
run 'git rebase -q --update-refs main'
snip g1-answer
run 'git log --graph --oneline --all --decorate'
cd "$LAB_DIR"

# ---- G2: an interactive rebase that drops one commit and folds another
quiet 'git init -q glossary'
cd glossary || exit 1
printf 'terms = {}\n' > loader.py
quiet 'git add . && git commit -q -m "Add the glossary loader"'
quiet 'git switch -q -c feature/lookup'
printf 'def lookup(term):\n    return terms.get(term)\n' > lookup.py
quiet 'git add . && git commit -q -m "Add term lookup"'
printf 'SYNONYMS = {"llm": "large langauge model"}\n' > synonyms.py
quiet 'git add . && git commit -q -m "Add synonyms"'
printf 'print("DEBUG", terms)\n' > debug.py
quiet 'git add . && git commit -q -m "wip: debug print"'
printf 'SYNONYMS = {"llm": "large language model"}\n' > synonyms.py
quiet 'git add . && git commit -q -m "Fix a typo in the synonyms"'
snip g2-before
run 'git log --oneline main..feature/lookup'
snip g2-rebase
run_todo '3s/^pick/drop/;4s/^pick/fixup/' 'git rebase -i main'
snip g2-answer
run 'git log --oneline main..feature/lookup'
run 'git ls-files'
run 'cat synonyms.py'
cd "$LAB_DIR"

# ---- I1 and I2: range-diff and the reflog after a rebase with a conflict
quiet 'git init -q scoring'
cd scoring || exit 1
printf 'THRESHOLD = 0.50\nMETRIC = "f1"\n\n\ndef passed(score):\n    return score >= THRESHOLD\n\n\ndef report(scores):\n    ok = [s for s in scores if passed(s)]\n    return len(ok), len(scores)\n' > evaluate.py
quiet 'git add . && git commit -q -m "Add evaluation settings"'
quiet 'git switch -q -c feature/strict-eval'
printf 'THRESHOLD = 0.80\nMETRIC = "f1"\n\n\ndef passed(score):\n    return score >= THRESHOLD\n\n\ndef report(scores):\n    ok = [s for s in scores if passed(s)]\n    return len(ok), len(scores)\n\n\ndef strict_report(scores):\n    ok, total = report(scores)\n    if ok < total:\n        raise SystemExit(f"{total - ok} of {total} below {THRESHOLD}")\n    return ok, total\n' > evaluate.py
quiet 'git commit -q -a -m "Raise the pass threshold and add a strict report"'
printf 'SEED = 7\n' > seed.py
quiet 'git add . && git commit -q -m "Fix the random seed"'
printf 'FOLDS = 10\n\n\ndef folds(rows):\n    size = len(rows) // FOLDS\n    return [rows[i * size:(i + 1) * size] for i in range(FOLDS)]\n' > folds.py
quiet 'git add . && git commit -q -m "Use ten folds"'
quiet 'git switch -q main'
printf 'THRESHOLD = 0.60\nMETRIC = "f1"\n\n\ndef passed(score):\n    return score >= THRESHOLD\n\n\ndef report(scores):\n    ok = [s for s in scores if passed(s)]\n    return len(ok), len(scores)\n' > evaluate.py
quiet 'git commit -q -a -m "Raise the threshold a little"'
printf 'SEED = 7\n' > seed.py
quiet 'git add . && git commit -q -m "Fix the random seed"'
quiet 'git switch -q feature/strict-eval'
snip i1-transcript
run 'git rebase main 2>&1 | grep -v "^hint:"'
run 'git diff --name-only --diff-filter=U'
note 'You open evaluate.py in the editor, set the threshold to 0.85, and save.'
quiet "sed -e '/^THRESHOLD = 0.60/d' -e 's/^THRESHOLD = 0.80/THRESHOLD = 0.85/' evaluate.py > evaluate.py.new && mv evaluate.py.new evaluate.py"
run 'git add evaluate.py'
run 'git rebase --continue 2>&1 | grep -v "^hint:"'
run 'git range-diff main ORIG_HEAD HEAD'
snip i2-transcript
run 'git reflog -7'
run 'git reflog show feature/strict-eval'
run 'git log --oneline -1 ORIG_HEAD'
lab_end
