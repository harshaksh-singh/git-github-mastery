#!/usr/bin/env bash
# Lab 30.2 replay (the local part): write .github/dependabot.yml and check that it parses and
# has the keys the options reference requires. What Dependabot does with it happens on GitHub.
. "$(dirname "$0")/../lib/lab-env.sh"
lab_begin ch21b lab-30-2-dependabot
quiet 'git init inventory-api'
cd inventory-api || exit 1
mkdir -p .github
cat > .github/dependabot.yml <<'YML'
version: 2
updates:
  - package-ecosystem: "uv"
    directory: "/"
    schedule:
      interval: "weekly"
    groups:
      python-minor-and-patch:
        patterns:
          - "*"
        update-types:
          - "minor"
          - "patch"

  - package-ecosystem: "docker"
    directory: "/"
    schedule:
      interval: "weekly"

  - package-ecosystem: "github-actions"
    directory: "/"
    schedule:
      interval: "weekly"
    cooldown:
      default-days: 7
YML
cat > check.py <<'PY'
import sys, yaml
doc = yaml.safe_load(open(sys.argv[1]))
assert doc["version"] == 2, "version must be 2"
for u in doc["updates"]:
    missing = [k for k in ("package-ecosystem", "schedule") if k not in u]
    if "directory" not in u and "directories" not in u:
        missing.append("directory or directories")
    print(f'{u["package-ecosystem"]:<15} {u.get("directory", u.get("directories"))!s:<4} {u.get("schedule", {}).get("interval", "-"):<7} missing={missing}')
PY

snip 01-file
run 'cat .github/dependabot.yml'

snip 02-parse
run 'cat check.py'
run_rc 'python3 check.py .github/dependabot.yml'

snip 03-failure
note 'A common slip: the file saved one level too high, and an ecosystem without a schedule.'
run "printf 'version: 2\nupdates:\n  - package-ecosystem: \"pip\"\n    directory: \"/\"\n' > dependabot.yml"
run 'python3 check.py dependabot.yml'
run 'git status -s'

snip 04-recovery
run 'rm dependabot.yml'
run "git add .github/dependabot.yml && git commit -q -m 'Configure Dependabot version updates'"
run 'git ls-files'
lab_end
