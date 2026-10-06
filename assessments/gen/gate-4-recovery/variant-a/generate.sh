#!/usr/bin/env bash
# Gate 4 (Recovery), hands-on part, variant A: the project "modelcard-gen".
# Builds one repository in which a clean-up removed a release branch, its annotated tag, the
# stash and every reflog entry. Some of the lost work can be found again; some cannot.
# Read SYMPTOMS.md, not this file, before you start: the script is the answer to "what happened".
. "$(dirname "${BASH_SOURCE[0]}")/../../../../labs/lib/lab-env.sh"
. "$COURSE_ROOT/assessments/gen/lib/gate-lib.bash"
[ -n "${LAB_REPLAY:-}" ] || sandbox_begin gates g4-a
gate_begin g4-a

quiet 'git init modelcard-gen'
cd modelcard-gen || exit 1
quiet "git config set user.name 'Ravi Menon' && git config set user.email ravi@example.com"
as ravi
mkdir -p cards gen notes
printf '# {{ model_name }}\n\n## Summary\n\n{{ summary }}\n' > cards/template.md
_c 'Add card template'
printf 'def render(template, values):\n    out = template\n    for key, value in values.items():\n        out = out.replace("{{ " + key + " }}", str(value))\n    return out\n' > gen/render.py
_c 'Add renderer'
printf '# {{ model_name }}\n\n## Summary\n\n{{ summary }}\n\n## Intended use\n\n{{ intended_use }}\n' > cards/template.md
_c 'Add intended-use section'
printf '# {{ model_name }}\n\n## Summary\n\n{{ summary }}\n\n## Intended use\n\n{{ intended_use }}\n\n## Limitations\n\n{{ limitations }}\n' > cards/template.md
quiet 'git add -A && git commit --amend -m "Add intended-use and limitations sections"'
gate_note main "$(git rev-parse main)"

# The 0.9 release line: a branch, two commits, an annotated tag. Never pushed anywhere.
quiet 'git switch -c release/0.9'
printf 'TEMPLATE_VERSION = "0.9"\n' > gen/version.py
_c 'Pin the template version for 0.9'
printf 'def render(template, values):\n    out = template\n    for key, value in sorted(values.items()):\n        out = out.replace("{{ " + key + " }}", str(value))\n    return out.rstrip() + "\\n"\n' > gen/render.py
_c 'Freeze the renderer output format'
quiet 'git tag -a v0.9.0 -m "modelcard-gen 0.9.0, approved by QA"'
gate_note tag "$(git rev-parse refs/tags/v0.9.0)"
gate_note release "$(git rev-parse release/0.9)"

# Work in progress on a feature branch, parked in a stash together with an untracked file.
quiet 'git switch main'
quiet 'git switch -c feature/license-section'
printf 'LICENSES = ["apache-2.0", "mit", "cc-by-4.0"]\n' > gen/licenses.py
_c 'Add the list of known licenses'
gate_note feature "$(git rev-parse HEAD)"
printf '# {{ model_name }}\n\n## Summary\n\n{{ summary }}\n\n## Intended use\n\n{{ intended_use }}\n\n## Limitations\n\n{{ limitations }}\n\n## License\n\nSee LICENSE.\n' > cards/template.md
quiet 'git add cards/template.md'
printf '# {{ model_name }}\n\n## Summary\n\n{{ summary }}\n\n## Intended use\n\n{{ intended_use }}\n\n## Limitations\n\n{{ limitations }}\n\n## License\n\n{{ license }} ({{ license_url }})\n' > cards/template.md
quiet 'git restore --staged cards/template.md'
printf '# Evaluation plan\n\n1. Render every card in the registry.\n2. Diff against the 0.9 output.\n' > notes/eval-plan.md
gate_note template "$(git hash-object cards/template.md)"
gate_note plan "$(git hash-object notes/eval-plan.md)"
quiet 'git stash push -u -m "license section, half done"'
# An edit made after the stash, saved in the editor, never staged, and thrown away.
printf 'def render(template, values):\n    raise NotImplementedError("rewrite with a real template engine")\n' > gen/render.py
quiet 'git restore gen/render.py'

# The clean-up.
quiet 'git branch -D release/0.9'
quiet 'git tag -d v0.9.0'
quiet 'git stash clear'
quiet 'git reflog expire --expire=now --all'

gate_end
gate_ready
