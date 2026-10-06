# Contributing

Thank you for helping. This file tells you how changes reach the default branch.

## Before you start

- Open an issue first for anything larger than a typo, so that the change can be discussed.
- One pull request does one thing. Small pull requests are reviewed faster.

## Workflow

1. Create a branch from an up-to-date `main`: `git switch -c fix/short-description`.
2. Make small commits. Write the subject line in the imperative: "Add version lookup".
3. Run the tests: `python3 -m unittest discover -s tests`.
4. Push the branch and open a pull request against `main`. Fill in the template.
5. Respond to review comments with new commits. Do not force-push a branch that is under
   review unless the reviewer asks for it.

## What a reviewer checks

- The tests pass and new behavior has a test.
- The pull request description says what changed and why.
- No credentials, tokens, datasets or model files are in the diff.
