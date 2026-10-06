# practice-repo

A practice repository for the Git and GitHub mastery course. The code is a very small
"prompt registry": it stores named prompt templates for an LLM application and keeps every
version of each template.

## Run the tests

```bash
python3 -m unittest discover -s tests
```

The tests need Python 3.11 or later and nothing else.

## Layout

| Path | Purpose |
|---|---|
| `src/prompt_registry/` | the package |
| `tests/` | unit tests |
| `docs/` | design notes |
| `.github/` | issue forms and the pull request template |

## Contributing and security

Read [CONTRIBUTING.md](CONTRIBUTING.md) before you open a pull request, and
[SECURITY.md](SECURITY.md) before you report a vulnerability.
