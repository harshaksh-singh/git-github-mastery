#!/usr/bin/env bash
# Practice repositories for the Module 12 exercises 12.1 to 12.8 (recovery). Each exercise has
# its own directory ex-12-N/ with a small piece of the project "labelhub" (label schema,
# annotator roster and agreement reports of an annotation team) in a prepared state.
# Do the exercises before you read this file: the script is the answer to several of them.
. "$(dirname "${BASH_SOURCE[0]}")/../../../labs/lib/lab-env.sh"
. "$COURSE_ROOT/labs/ex2/gen-lib.bash"
ex_begin m12-labelhub

schema_v1() { put schema/labels.yaml <<'F'
labels:
  - id: toxic
    description: Abusive or hateful content
  - id: spam
    description: Unsolicited promotion
  - id: safe
    description: None of the above
F
}

# ---------------------------------------------------------------- 12.1 reading a reflog
quiet 'git init ex-12-1'
cd ex-12-1 || exit 1
schema_v1
_c 'Add label schema'
printf 'asha\nravi\n' > annotators.txt
_c 'Add annotator roster'
put reports/agreement.md <<'F'
# Agreement, week 36

Cohen's kappa between asha and ravi: 0.71
F
_c 'Add agreement report'
put scripts/export.sh <<'F'
#!/bin/sh
cat schema/labels.yaml
F
_c 'Add export script'
put scripts/export.sh <<'F'
#!/bin/sh
# Export the label schema for the annotation tool.
cat schema/labels.yaml
F
quiet 'git commit -a --amend --no-edit'
quiet 'git reset --hard HEAD~2'
printf '# labelhub\n\nLabel schema and annotator data.\n' > README.md
_c 'Add README'
cd "$LAB_DIR" || exit 1

# ---------------------------------------------------------------- 12.2 backup ref and ORIG_HEAD
quiet 'git init ex-12-2'
cd ex-12-2 || exit 1
schema_v1
_c 'Add label schema'
quiet 'git switch -c feature/guidelines'
printf '# Guidelines\n\nLabel the whole message, not single words.\n' > GUIDELINES.md
_c 'Add labelling guidelines'
printf '\nWhen two labels apply, choose the more severe one.\n' >> GUIDELINES.md
_c 'Say how to break ties'
printf '\nQuoted abuse is still labelled toxic.\n' >> GUIDELINES.md
_c 'Cover quoted content'
cd "$LAB_DIR" || exit 1

# ---------------------------------------------------------------- 12.3 fsck as a search tool
quiet 'git init ex-12-3'
cd ex-12-3 || exit 1
schema_v1
_c 'Add label schema'
printf 'asha\nravi\n' > annotators.txt
_c 'Add annotator roster'
quiet 'git switch -c spike/severity'
printf 'toxic: 3\nspam: 1\nsafe: 0\n' > severity.yaml
_c 'Add severity scores'
printf 'toxic: 3\nspam: 2\nsafe: 0\n' > severity.yaml
_c 'Raise the severity of spam'
quiet 'git switch main'
quiet 'git branch -D spike/severity'
printf 'asha\nravi\nmeera\n' > annotators.txt
quiet "git stash push -m 'roster with meera'"
quiet 'git stash drop'
printf 'kappa: 0.71\n' > agreement.yaml
quiet 'git add agreement.yaml'
printf 'kappa: 0.74\n' > agreement.yaml
quiet 'git add agreement.yaml'
_c 'Add agreement figure'
cd "$LAB_DIR" || exit 1

# ---------------------------------------------------------------- 12.4 is typed by the learner
mkdir ex-12-4

# ---------------------------------------------------------------- 12.5 one file from a reflog-only commit
quiet 'git init ex-12-5'
cd ex-12-5 || exit 1
printf '# labelhub\n' > README.md
_c 'Add README'
put schema/labels.yaml <<'F'
labels:
  - id: toxic
    description: Abusive or hateful content
  - id: spam
    description: Unsolicited promotion
  - id: safe
    description: None of the above
deprecated:
  - id: offensive
    replaced_by: toxic
  - id: advert
    replaced_by: spam
F
_c 'Add label schema'
schema_v1
printf '# labelhub\n\nThe schema is in `schema/labels.yaml`.\n' > README.md
quiet 'git commit -a --amend --no-edit'
cd "$LAB_DIR" || exit 1

# ---------------------------------------------------------------- 12.6 draw the graph
quiet 'git init ex-12-6'
cd ex-12-6 || exit 1
for s in 'A schema' 'B roster' 'C report' 'D export'; do
  printf '%s\n' "$s" > "${s#* }.txt"
  _c "$s"
done
cd "$LAB_DIR" || exit 1

# ---------------------------------------------------------------- 12.7 an amend that swallowed a pushed commit
mkdir ex-12-7 && cd ex-12-7 || exit 1
ex_server
ex_clone work
cd work || exit 1
schema_v1
_c 'Add label schema'
put scripts/export.py <<'F'
import json, sys, yaml

json.dump(yaml.safe_load(open("schema/labels.yaml")), sys.stdout)
F
_c 'Add JSON export of the schema'
quiet 'git push -u origin main'
put scripts/validate.py <<'F'
import sys, yaml

ids = [label["id"] for label in yaml.safe_load(open("schema/labels.yaml"))["labels"]]
sys.exit(0 if len(ids) == len(set(ids)) else 1)
F
quiet 'git add scripts/validate.py'
quiet 'git commit --amend --no-edit'
cd "$LAB_DIR" || exit 1

# ---------------------------------------------------------------- 12.8 an incremental bundle as the only backup
mkdir ex-12-8 && cd ex-12-8 || exit 1
ex_server
ex_clone laptop
cd laptop || exit 1
schema_v1
_c 'Add label schema'
printf 'asha\nravi\n' > annotators.txt
_c 'Add annotator roster'
quiet 'git push -u origin main'
quiet 'git switch -c feature/consensus'
put consensus.py <<'F'
from collections import Counter


def majority(votes):
    return Counter(votes).most_common(1)[0][0]
F
_c 'Add majority vote'
put consensus.py <<'F'
from collections import Counter


def majority(votes):
    (label, count), = Counter(votes).most_common(1)
    return label if count * 2 > len(votes) else None
F
_c 'Return no label without a strict majority'
quiet 'git switch -c spike/weights main'
printf 'asha: 1.0\nravi: 0.8\n' > weights.yaml
_c 'Try annotator weights'
quiet 'git bundle create ../backup.bundle --branches --not origin/main'
cd .. || exit 1
rm -rf laptop
# After the backup was taken, a teammate pushed to main.
ex_clone asha
cd asha || exit 1
as asha
printf 'asha\nravi\nmeera\n' > annotators.txt
_c 'Add meera to the roster'
quiet 'git push'
cd .. || exit 1
rm -rf asha

ex_end
