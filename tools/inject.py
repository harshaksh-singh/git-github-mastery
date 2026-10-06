#!/usr/bin/env python3
"""Inject real transcript snippets into Markdown files.

A snippet is a file  labs/<dir>/out/<demo>/<name>.txt  produced by a demo script.
In Markdown, mark where it belongs like this (the fenced block between the two
comment lines is replaced by the snippet, so never edit it by hand):

    <!-- snippet: ch08/conflict-basic/03-status -->
    ```text
    ```
    <!-- /snippet -->

Usage:
    tools/inject.py FILE...           fill or refresh snippets in the given files
    tools/inject.py --check FILE...   verify only; exit 1 if anything is missing or stale
    tools/inject.py [--check] --all   every .md file in the course
"""
import pathlib
import re
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
PAT = re.compile(
    r"(?P<open><!-- snippet: (?P<id>[A-Za-z0-9._/-]+) -->\n)(?P<body>.*?)(?P<close><!-- /snippet -->)",
    re.S,
)
SKIP_DIRS = {"research_notes", "reports", "authoring", "dist", ".git"}


def snippet_file(sid: str) -> pathlib.Path:
    parts = sid.split("/")
    if len(parts) != 3:
        raise ValueError(f"snippet id must be <dir>/<demo>/<name>: {sid}")
    d, demo, name = parts
    return ROOT / "labs" / d / "out" / demo / f"{name}.txt"


def render(sid: str) -> str:
    text = snippet_file(sid).read_text(encoding="utf-8").rstrip("\n")
    fence = "```"
    while fence in text:
        fence += "`"
    return f"{fence}text\n{text}\n{fence}\n"


def process(path: pathlib.Path, check: bool) -> list:
    src = path.read_text(encoding="utf-8")
    problems = []

    def repl(m):
        sid = m.group("id")
        try:
            new_body = render(sid)
        except FileNotFoundError:
            problems.append(f"{path}: snippet not found: {sid}")
            return m.group(0)
        except ValueError as e:
            problems.append(f"{path}: {e}")
            return m.group(0)
        if check and m.group("body") != new_body:
            problems.append(f"{path}: stale or hand-edited snippet: {sid}")
        return m.group("open") + new_body + m.group("close")

    out = PAT.sub(repl, src)
    if not check and out != src:
        path.write_text(out, encoding="utf-8")
    return problems


def all_markdown():
    for p in sorted(ROOT.rglob("*.md")):
        rel = p.relative_to(ROOT)
        if rel.parts and rel.parts[0] in SKIP_DIRS:
            continue
        yield p


def main(argv):
    check = "--check" in argv
    use_all = "--all" in argv
    files = [pathlib.Path(a) for a in argv if not a.startswith("--")]
    if use_all:
        files = list(all_markdown())
    if not files:
        print(__doc__)
        return 2
    problems = []
    count = 0
    for f in files:
        if not f.is_absolute():
            f = (pathlib.Path.cwd() / f).resolve()
        if not f.exists():
            problems.append(f"{f}: file not found")
            continue
        count += len(PAT.findall(f.read_text(encoding="utf-8")))
        problems.extend(process(f, check))
    for p in problems:
        print("PROBLEM:", p)
    print(f"{'checked' if check else 'injected'} {count} snippet marker(s) in {len(files)} file(s); {len(problems)} problem(s)")
    return 1 if problems else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
