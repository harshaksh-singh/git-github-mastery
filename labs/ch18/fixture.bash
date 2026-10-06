# labs/ch18/fixture.bash - shared fixture for the Chapter 18 and 19 demos and the Module 23 labs.
#
# Sourced by the scripts in this directory right after lab-env.sh. It reuses the ticket-router
# project and the helpers of labs/ch17/fixture.bash (make_server, new_clone, enter, hidden, put,
# commit_all, the scenario functions) and adds what the governance demos need.
#
# Nothing here talks to GitHub. A ruleset is a GitHub object and cannot run in plain Git. What
# plain Git can show is the mechanism a rule relies on: a server that inspects every proposed
# ref update (old value, new value, ref name) before it lets the ref move. The hook below is
# the author's imitation of five documented rules, written to make that mechanism visible.

. "$LAB_SCRIPT_DIR/../ch17/fixture.bash"

# write_rules_hook <file>
# Writes the imitation "ruleset" as a pre-receive hook. It is not made executable here:
# switching the executable bit on and off plays the part of the enforcement status.
write_rules_hook() {
  put "$1" <<'HOOK'
#!/bin/sh
# pre-receive: the server runs this before any ref moves.
# Standard input has one line per proposed ref update: <old id> <new id> <ref name>
zero=0000000000000000000000000000000000000000
status=0
while read old new ref; do
  case "$ref" in
    refs/heads/main)                      # target of the branch rules
      if [ "$new" = "$zero" ]; then
        echo "rule 'restrict deletions': $ref may not be deleted"; status=1; continue
      fi
      [ "$old" = "$zero" ] && continue    # creation: nothing to compare with
      if ! git merge-base --is-ancestor "$old" "$new"; then
        echo "rule 'block force pushes': the update would remove commits from $ref"; status=1
      fi
      if [ -n "$(git rev-list --merges "$old..$new")" ]; then
        echo "rule 'require linear history': the update adds a merge commit to $ref"; status=1
      fi ;;
    refs/tags/v*)                         # target of the tag rules
      if [ "$new" = "$zero" ]; then
        echo "rule 'restrict deletions': $ref may not be deleted"; status=1
      elif [ "$old" != "$zero" ]; then
        echo "rule 'restrict updates': $ref already exists and may not move"; status=1
      fi ;;
  esac
done
exit $status
HOOK
}

# scenario_rules
# The server, your clone and Asha's clone. Your branch feature/priority-routing is pushed and
# main has moved on by one commit (as in Chapter 17). The hook file lies ready in the sandbox
# as rules/pre-receive but is not installed. Ends in $LAB_DIR with your identity.
scenario_rules() {
  scenario_pr
  hidden 'git fetch'
  hidden 'git switch main'
  hidden 'git merge --ff-only origin/main'
  cd "$LAB_DIR" || exit 1
  write_rules_hook "$LAB_DIR/rules/pre-receive"
  as you
}

# write_codeowners <file>
# The CODEOWNERS file used by the Chapter 19 demos and by Lab 23.2. The owners are placeholders:
# teams of an organization called example-org.
write_codeowners() {
  put "$1" <<'OWN'
# Default owners for everything in the repository.
*                       @example-org/platform

# The routing code.
/router/                @example-org/routing
/router/priority.py     @example-org/routing @example-org/on-call

# Configuration, wherever it lives.
*.yaml                  @example-org/platform @example-org/sre

# Documentation: files directly in docs/.
docs/*                  @example-org/docs

# The files that decide who must review, and what automation runs.
/.github/               @example-org/repo-admins
OWN
}

# scenario_codeowners
# Server and your clone. main has a CODEOWNERS file in .github/ (the one above) and a second,
# older one in docs/. Your branch docs/escalation-runbook changes four files, one of them the
# CODEOWNERS file itself. Ends in your clone on that branch, fetched.
scenario_codeowners() {
  make_server
  new_clone asha
  enter asha
  write_codeowners .github/CODEOWNERS
  commit_all 'Add CODEOWNERS'
  printf '*    @example-org/docs\n' | put docs/CODEOWNERS
  printf '# Runbooks\n' | put docs/README.md
  printf '# Escalation\n\nPage the on-call engineer.\n' | put docs/runbooks/escalation.md
  commit_all 'Add docs with an older CODEOWNERS file'
  hidden 'git push origin main'
  new_clone you
  enter you
  hidden 'git switch -c docs/escalation-runbook'
  printf '# Escalation\n\nPage the on-call engineer, then open an incident.\n' | put docs/runbooks/escalation.md
  printf '# Runbooks\n\n- runbooks/escalation.md\n' | put docs/README.md
  printf 'model: router-small-v1\nconfidence_threshold: 0.6\nfallback_queue: general\nescalation_queue: escalations\n' | put config/routing.yaml
  commit_all 'Describe the escalation path'
  sed '/^docs\/\*/d' .github/CODEOWNERS > .github/CODEOWNERS.new && mv .github/CODEOWNERS.new .github/CODEOWNERS
  commit_all 'Drop the docs team from CODEOWNERS'
  hidden 'git push -u origin docs/escalation-runbook'
}

# write_preflight <file>
# A small script that asks, for one branch on the server, the three questions that plain Git
# can answer about a pull request into main.
write_preflight() {
  put "$1" <<'SH'
#!/bin/sh
# usage: sh preflight.sh <branch>     (run inside a clone, after git fetch)
b="origin/$1"
echo "== $1 -> main"
echo "commits in the pull request: $(git rev-list --count origin/main..$b)"
if git merge-base --is-ancestor origin/main "$b"; then echo "up to date with main: yes"; else echo "up to date with main: no"; fi
if git merge-tree --write-tree origin/main "$b" > /dev/null; then echo "test merge: clean"; else echo "test merge: conflict"; fi
echo "merge commits among them: $(git rev-list --count --merges origin/main..$b)"
SH
}

# scenario_three_blocks
# Three open branches on the server, each with a different obstacle on the way into main:
#   feature/priority-routing (yours)   behind main, merges cleanly
#   fix/threshold (Ravi)               conflicts with main
#   docs/queues (Ravi)                 up to date, but contains a merge commit
# Your local main is one commit behind the server. preflight.sh lies in the sandbox root.
# Ends in $LAB_DIR with your identity. Starting state of Lab 23.3 (local part).
scenario_three_blocks() {
  scenario_pr
  enter ravi
  hidden 'git switch -c fix/threshold'
  printf 'model: router-small-v1\nconfidence_threshold: 0.65\nfallback_queue: general\n' | put config/routing.yaml
  commit_all 'Lower the confidence threshold to 0.65'
  hidden 'git push -u origin fix/threshold'
  hidden 'git switch -c docs/queues main'
  printf '# ticket-router\n\nSends each support ticket to the queue that can answer it.\n\n## Queues\n\nbilling, technical, general\n' | put README.md
  commit_all 'List the queues in the README'
  hidden 'git fetch'
  hidden 'git merge -m "Merge main into docs/queues" origin/main'
  hidden 'git push -u origin docs/queues'
  cd "$LAB_DIR" || exit 1
  write_preflight "$LAB_DIR/preflight.sh"
  as you
}
