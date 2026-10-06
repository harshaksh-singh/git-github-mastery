#!/usr/bin/env bash
# Stage 7: a shared branch was rebased and force-pushed, and its pull request is broken.
# Applies the incident on top of the state that the solution of stage 6 leaves.
# Read BRIEFING.md, not this file, before you start: the script is part of the answer.
. "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../lib/capstone-lib.bash"
cap_inject_begin 7 "$@"
B=feature/vip-escalation

# Tuesday 22 September. You start the branch and open the pull request.
cap_go you
quiet 'git switch main' || cap_fail 'cannot switch to main in you/ (uncommitted changes?)'
quiet 'git pull --ff-only'
quiet "git switch -c $B"
cat > router/vip.py <<'F'
"""Customers whose messages are never left in the general queue."""

VIP_CUSTOMERS = {"northwind-air", "globex-bank", "acme-retail"}


def is_vip(customer):
    return customer in VIP_CUSTOMERS
F
_cp 'Add the VIP customer list' router/vip.py
quiet "git push -u origin $B"
cap_pr "open $B --title 'Escalate VIP customers'"

# Kabir joins the branch.
cap_go kabir
quiet 'git switch main'
quiet 'git pull --ff-only'
quiet "git switch $B"
cat >> router/vip.py <<'F'


def escalate(intent, customer, fallback="human_agent"):
    """A VIP message that would fall back goes to the priority desk instead."""
    if intent == fallback and is_vip(customer):
        return "priority_desk"
    return intent
F
_cp 'Escalate VIP messages that would fall back' router/vip.py
quiet 'git push'

# You pull and add the tests.
cap_go you
quiet 'git pull --ff-only'
cat > tests/test_vip.py <<'F'
import unittest

from router.vip import escalate, is_vip


class VipTest(unittest.TestCase):
    def test_vip_list(self):
        self.assertTrue(is_vip("globex-bank"))
        self.assertFalse(is_vip("someone-else"))

    def test_only_fallbacks_of_vips_are_escalated(self):
        self.assertEqual(escalate("human_agent", "globex-bank"), "priority_desk")
        self.assertEqual(escalate("human_agent", "someone-else"), "human_agent")
        self.assertEqual(escalate("order_status", "globex-bank"), "order_status")
F
_cp 'Test the VIP escalation' tests/test_vip.py
quiet 'git push'

# The tech lead checks the branch out to review it.
cap_go nandini
quiet 'git switch main'
quiet 'git pull --ff-only'
quiet "git switch $B"

# main moves: a small pull request by Tanvi is merged.
cap_go tanvi
quiet 'git switch main'
quiet 'git pull --ff-only'
quiet 'git switch -c chore/ci-timeout'
quiet "sed -i.bak -e 's/timeout-minutes: 10/timeout-minutes: 15/' .github/workflows/ci.yml && rm .github/workflows/ci.yml.bak"
_cp 'Give the CI job 15 minutes' .github/workflows/ci.yml
quiet 'git push -u origin chore/ci-timeout'
cap_pr 'open chore/ci-timeout'
cap_as nandini
cap_pr 'merge chore/ci-timeout --squash'
cap_go tanvi
quiet 'git switch main'
quiet 'git pull --ff-only'
quiet 'git branch -D chore/ci-timeout'

# Kabir brings the branch up to date with main. He fetches first, he does not look at what the
# fetch brought, he rebases the branch as he has it, and he pushes with a lease.
cap_go kabir
quiet 'git fetch'
quiet 'git rebase origin/main'
quiet 'git push --force-with-lease'

# The tech lead commits a review fix on what she had checked out, pulls, and pushes.
cap_go nandini
printf '\n## VIP customers\n\nA message of a customer in `router.vip.VIP_CUSTOMERS` that would fall back goes to the priority desk.\n' >> README.md
_cp 'Document the VIP escalation' README.md
quiet 'git config set pull.rebase false'
quiet 'git pull'
quiet 'git push'

# You have one more commit that is not pushed yet. You have not fetched since your last push.
cap_go you
quiet "sed -i.bak -e 's/^    if intent == fallback and is_vip(customer):/    if intent in (None, fallback) and is_vip(customer):/' router/vip.py && rm router/vip.py.bak"
cat >> tests/test_vip.py <<'F'

    def test_a_vip_message_without_any_intent_is_escalated(self):
        self.assertEqual(escalate(None, "globex-bank"), "priority_desk")
F
_cp 'Escalate VIP messages without any intent as well' router/vip.py tests/test_vip.py

cap_inject_end 7
