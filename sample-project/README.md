# inventory-api

The sample project of the Git and GitHub mastery course. It is small on purpose: the subject is the automation around the code, not the code.

You push this directory to your practice organization as its own public repository in Lab 26.1, and then add the course workflows to it one at a time (Chapters 20A, 20B and 21A).

## What is here

| Path | What it is |
|---|---|
| `src/inventory_api/stock.py` | Pure functions over a stock table. Standard library only |
| `tests/test_stock.py` | `unittest` tests; pytest runs them too |
| `pyproject.toml` | Project metadata, a `dev` dependency group (pytest, ruff), build backend, tool settings |
| `scripts/deploy.sh` | A simulated deployment. It prints what it would deploy and where, and changes nothing |
| `Dockerfile` | An image that runs the stock report |
| `java-service/` | A minimal Maven module: one class, one JUnit 5 test |

## Commands

The standard library is enough to run the tests:

```bash
PYTHONPATH=src python3 -m unittest discover -s tests
```

With [uv](https://docs.astral.sh/uv/) installed, the commands the workflows run are:

```bash
uv lock                      # once: creates uv.lock, which you commit (Lab 26.2)
uv sync --locked             # create .venv from uv.lock; fails if uv.lock does not match pyproject.toml
uv run pytest
uv run ruff check .
uv run ruff format --check .
uv build                     # writes an sdist and a wheel to dist/
bash scripts/deploy.sh staging
```

In `java-service/`:

```bash
mvn -B verify
```

## What was and was not verified when the course was written

- The Python tests pass with `python3 -m unittest`, and `ruff check` and `ruff format --check` pass, on the author's machine.
- `uv.lock` is not included: creating it downloads package metadata, and nothing was downloaded while the course was written. You create it in Lab 26.2.
- `uv build`, the Maven module and the Dockerfile were written from the tools' documented conventions and were **not** built by the author (no network, no JDK, no image pulls). The labs have you build them on GitHub Actions and read the result.

## Rules for this repository

It is public practice material. Never push a secret, work code or customer data to it.
