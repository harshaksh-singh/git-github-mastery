#!/usr/bin/env bash
# Exercise 33.2 (Module 33): predict what an ML project's ignore file does to eight paths,
# one of which is already tracked. git check-ignore -v names the rule that decides.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$LAB_SCRIPT_DIR/fixture.bash"
lab_begin ex3 x33-ignore-predict
hidden 'git init ragbench'
cd ragbench || exit 1
printf 'model: small-v1\n' | put configs/eval.yaml
printf 'question,answer\nq1,a1\n' | put data/samples/smoke.csv
commit_all 'Add evaluation config and a smoke sample'
put .gitignore <<'IGN'
# data is versioned by reference
/data/**
!/data/**/
!/data/**/*.ref

# weights and run output
*.safetensors
*.ckpt
runs/
outputs/

# local settings
.env
*.local.yaml
IGN
commit_all 'Add ignore rules'
printf '{"sha256": "placeholder", "size": 1}\n' | put data/raw/tickets.csv.ref
printf 'id,text\n1,hello\n' | put data/raw/tickets.csv
printf 'x' | put models/ranker.safetensors
printf 'x' | put src/runs/helper.py
printf 'KEY=%s\n' "$DUMMY_KEY" | put .env
printf 'KEY=\n' | put .env.example
printf 'model: big\n' | put configs/eval.local.yaml

snip 01-rules
run 'cat .gitignore'
run 'git ls-files'

snip 02-answers
for p in data/raw/tickets.csv data/raw/tickets.csv.ref data/samples/smoke.csv models/ranker.safetensors src/runs/helper.py .env .env.example configs/eval.local.yaml; do
  run_rc "git check-ignore -v $p"
done

snip 03-status
run 'git status --short'
run 'git status --short --ignored'

lab_end
