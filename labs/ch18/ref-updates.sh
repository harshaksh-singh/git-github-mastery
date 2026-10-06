#!/usr/bin/env bash
# What a rule is underneath: a check that the server runs on every proposed ref update
# (old value, new value, ref name) before the ref moves. A pre-receive hook imitates five
# documented ruleset rules; the executable bit plays the enforcement status.
# Builds on Chapter 12, section 12.7. Chapter 18, section 18.2.
. "$(dirname "$0")/../lib/lab-env.sh"
. "$(dirname "$0")/fixture.bash"
lab_begin ch18 ref-updates
scenario_rules

snip 01-the-rules
run 'cat rules/pre-receive'

snip 02-install
note 'Install the rules on the server. Not executable yet: the "ruleset" exists but is disabled.'
run 'cp rules/pre-receive server/ticket-router.git/hooks/pre-receive'
run 'cd you/ticket-router'
run 'git commit -q --allow-empty -m "Start the 1.1 cycle"'
run 'git push origin main'
note 'Now active:'
run 'chmod +x ../../server/ticket-router.git/hooks/pre-receive'

snip 03-fast-forward-allowed
run "printf '# Changelog\n\n## 1.1 (unreleased)\n' > CHANGELOG.md && git add CHANGELOG.md"
run 'git commit -q -m "Open the changelog for 1.1"'
run 'git push origin main'

snip 04-force-push
run 'git commit -q --amend -m "Open the changelog for 1.1.0"'
run_rc 'git push --force origin main'
run_rc 'git push --force-with-lease origin main'
run 'git reset -q --hard origin/main'

snip 05-delete
run_rc 'git push origin --delete main'

snip 06-merge-commit
note 'A merge commit, the result of the "Create a merge commit" method, pushed to main:'
run 'git merge -q --no-ff -m "Merge pull request #1 from feature/priority-routing" feature/priority-routing'
run_rc 'git push origin main'
run 'git reset -q --hard origin/main'
note 'The squash method produces one ordinary commit, which the rule accepts:'
run 'git merge -q --squash feature/priority-routing'
run 'git commit -q -m "Route high-priority tickets to an escalations queue (#1)"'
run 'git push origin main'

snip 07-other-branches
note 'The rules target main. Another branch may still be rewritten and deleted:'
run 'git push -q origin main:refs/heads/scratch'
run 'git push --force origin main~1:refs/heads/scratch'
run 'git push origin --delete scratch'

snip 08-tags
run 'git tag -a v1.0.0 -m "ticket-router 1.0.0" main~1'
run 'git push origin v1.0.0'
note 'Moving a published tag, the supply-chain mistake of Chapter 14B:'
run 'git tag -f -a v1.0.0 -m "ticket-router 1.0.0" main'
run_rc 'git push --force origin v1.0.0'
run_rc 'git push origin --delete v1.0.0'

snip 09-disabled-again
note 'Enforcement status "disabled": the same force push goes through.'
run 'chmod -x ../../server/ticket-router.git/hooks/pre-receive'
run 'git push --force origin v1.0.0'

lab_end
