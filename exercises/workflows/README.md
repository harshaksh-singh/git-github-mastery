# Workflow files for the exercises of Modules 22 to 29

These files belong to the exercises in `exercises/m19-m25-github.md` and `exercises/m26-m31-actions-security.md`. Each one is **teaching material with planted flaws** and says so in its first line. Do not copy any of them into a real repository.

All of them were assembled from documented syntax and parse-checked with PyYAML. None was executed on GitHub. Actions are pinned to the commit IDs of [`workflows/ACTION_PINS.md`](../../workflows/ACTION_PINS.md), except where an unpinned reference is the planted flaw.

| File | Exercise | Kind of flaw |
|---|---|---|
| `x22-queue-ci.yml` | 22.3 | behavior |
| `x26-matrix-and-outputs.yml` | 26.3 | reading YAML, shells, outputs |
| `x27-deploy.yml` | 27.2 | delivery |
| `x28-nightly-eval.yml` | 28.2 | triggers and conditions |
| `x28-aggregate.yml` | 28.3 | required checks |
| `x29-pr-report.yml` | 29.2 | security (defensive review) |
| `x29-release.yml` | 29.3 | security (defensive review) |
| `x29-gpu-eval.yml` | 29.4 | security (defensive review) |

The analyses are in `solutions/exercises-m19-m25.md` and `solutions/exercises-m26-m31.md`.
