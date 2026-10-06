#!/usr/bin/env bash
# Exercise 13.9 (Level 4): two builds of "1.4.0" differ, and today's build does not even call
# itself 1.4.0. Builds server.git and the clones you/ and ci/ of the project "modelcard".
# Read SYMPTOMS.md, not this file: the script is the answer to "what happened".
. "$(dirname "${BASH_SOURCE[0]}")/../../../labs/lib/lab-env.sh"
. "$COURSE_ROOT/labs/ex2/gen-lib.bash"
ex_begin m13-modelcard

ex_server
ex_clone you
cd you || exit 1
put modelcard/render.py <<'F'
"""Renders a model card as Markdown."""


def render(card):
    lines = ["# " + card["name"], "", card["summary"], "", "## Metrics"]
    for name, value in card["metrics"].items():
        lines.append("- %s: %.3f" % (name, value))
    return "\n".join(lines)
F
put scripts/version.sh <<'F'
#!/bin/sh
# The version stamped into every build artifact.
git describe
F
chmod +x scripts/version.sh
_c 'Add Markdown renderer'
quiet "git tag -a v1.3.0 -m 'modelcard 1.3.0'"
printf '# modelcard\n\nRenders model cards from evaluation results.\n' > README.md
_c 'Add README'
put modelcard/schema.py <<'F'
REQUIRED = ("name", "summary", "metrics")


def validate(card):
    return [key for key in REQUIRED if key not in card]
F
_c 'Validate required fields'
sed -e 's/"## Metrics"\]/"## Metrics", ""]/' modelcard/render.py > r.tmp && mv r.tmp modelcard/render.py
_c 'Put a blank line under the metrics heading'
quiet 'git push -u origin main'
# The release: Asha, the release manager, tags 1.4.0 from your machine during a pairing session.
as asha
quiet "git tag -a v1.4.0 -m 'modelcard 1.4.0' -m 'Release checklist signed off by Asha on Monday.'"
as you
quiet 'git push origin v1.3.0 v1.4.0'

# A fix lands after the release.
put modelcard/render.py <<'F'
"""Renders a model card as Markdown."""


def render(card):
    lines = ["# " + card["name"], "", card["summary"], "", "## Metrics", ""]
    for name, value in card["metrics"].items():
        lines.append("- %s: %.3f" % (name, value))
    if not card["metrics"]:
        lines.append("No metrics reported.")
    return "\n".join(lines)
F
_c 'Say so when a card has no metrics'
quiet 'git push'
cd "$LAB_DIR" || exit 1

# Ravi "corrects" the release from a throwaway clone so that 1.4.0 includes the fix.
quiet 'git clone server.git ravi-tmp'
cd ravi-tmp || exit 1
as ravi
quiet 'git push origin :refs/tags/v1.4.0'
quiet 'git tag -d v1.4.0'
quiet 'git tag v1.4.0'
quiet 'git push origin v1.4.0'
cd "$LAB_DIR" || exit 1
rm -rf ravi-tmp
as you

# Your clone follows the advice in the CI documentation and overwrites its tags.
quiet 'git -C you fetch --tags --force'
# The build machine clones afresh for today's build.
ex_clone ci

ex_end you
