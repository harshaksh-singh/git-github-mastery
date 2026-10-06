#!/usr/bin/env python3
"""Course consistency checker.

    tools/check_course.py                 check everything
    tools/check_course.py textbook/ch08-merge.md lab-manual/m06-merge.md   check only these files

Checks
  1. every snippet marker resolves and its block equals the stored snippet (tools/inject.py --check)
  2. every relative Markdown link points at an existing file
  3. no placeholder text is left (TODO, TBD, FIXME, XXX, lorem ipsum, "to be written")
  4. every demo or generator script passes "bash -n"
  5. every workflow under workflows/ parses as YAML and has "on" and "jobs"
  6. every object ID quoted in prose exists in a real transcript (catches hand-typed and stale IDs);
     IDs that are legitimately external go into authoring/id-whitelist.txt, one per line
  7. word counts per top-level directory (information only)
"""
import pathlib
import re
import subprocess
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
SKIP_DIRS = {"research_notes", "reports", "authoring", "dist", ".git"}
LINK = re.compile(r"\]\(([^)\s]+)\)")
PLACEHOLDER = re.compile(r"\b(TODO|TBD|FIXME|XXX)\b|[Ll]orem ipsum|[Tt]o be written|\[placeholder\]")
SNIP_OPEN = re.compile(r"<!-- snippet: ([A-Za-z0-9._/-]+) -->")


HEXID = re.compile(r"(?<![0-9a-zA-Z/=_-])(?=[0-9a-f]*[0-9])(?=[0-9a-f]*[a-f])[0-9a-f]{7,64}(?![0-9a-zA-Z])")
SNIP_BLOCK = re.compile(r"<!-- snippet: [A-Za-z0-9._/-]+ -->\n.*?<!-- /snippet -->", re.S)
WELL_KNOWN = {
    "e69de29bb2d1d6434b8b29ae775ad8c2e48c5391",   # the empty blob
    "4b825dc642cb6eb9a060e54bf8d69288fbee4904",   # the empty tree
}


def known_ids():
    """All hex tokens that appear in real transcripts, in the action pin list, or in the whitelist."""
    import bisect  # noqa: F401
    toks = set(WELL_KNOWN)
    hexany = re.compile(r"[0-9a-f]{7,64}")
    for f in (ROOT / "labs").rglob("out/*/*.txt"):
        toks.update(hexany.findall(f.read_text(encoding="utf-8", errors="replace")))
    for extra in [ROOT / "workflows" / "ACTION_PINS.md", ROOT / "authoring" / "id-whitelist.txt"]:
        if extra.exists():
            toks.update(hexany.findall(extra.read_text(encoding="utf-8", errors="replace")))
    return sorted(toks)


def is_known(tok, sorted_toks):
    import bisect
    i = bisect.bisect_left(sorted_toks, tok)
    if i < len(sorted_toks) and sorted_toks[i].startswith(tok):
        return True
    # tok may be longer than a stored abbreviation of the same object
    j = i - 1
    while j >= 0 and len(sorted_toks[j]) >= 7 and tok.startswith(sorted_toks[j][:7]):
        if tok.startswith(sorted_toks[j]):
            return True
        j -= 1
    return False


def md_files(args):
    if args:
        return [(ROOT / a).resolve() if not pathlib.Path(a).is_absolute() else pathlib.Path(a) for a in args]
    out = []
    for p in sorted(ROOT.rglob("*.md")):
        rel = p.relative_to(ROOT)
        if rel.parts[0] in SKIP_DIRS or ".cache" in rel.parts:      # .cache: working files of the video tools (self-test scripts, pages), not course content
            continue
        out.append(p)
    return out


def main(argv):
    files = md_files([a for a in argv if not a.startswith("--")])
    problems = []

    # 1 snippets
    r = subprocess.run([sys.executable, str(ROOT / "tools" / "inject.py"), "--check"] + [str(f) for f in files],
                       capture_output=True, text=True)
    for line in r.stdout.splitlines():
        if line.startswith("PROBLEM:"):
            problems.append(line[len("PROBLEM: "):])
    snippet_summary = r.stdout.strip().splitlines()[-1] if r.stdout.strip() else "no snippet output"

    words = {}
    in_fence = False
    KNOWN = known_ids()
    for f in files:
        if not f.exists():
            problems.append(f"{f}: file not found")
            continue
        text = f.read_text(encoding="utf-8")
        rel = f.relative_to(ROOT)
        words[rel.parts[0]] = words.get(rel.parts[0], 0) + len(text.split())
        # 6 object IDs quoted in prose must exist in a transcript
        prose = SNIP_BLOCK.sub("", text)
        seen = set()
        for n, line in enumerate(prose.splitlines(), 1):
            if "http://" in line or "https://" in line:
                line = re.sub(r"https?://\S+", "", line)
            for tok in HEXID.findall(line):
                if tok in seen:
                    continue
                seen.add(tok)
                if not is_known(tok, KNOWN):
                    problems.append(f"{rel}: object ID in prose not found in any transcript: {tok}")
        in_fence = False
        for n, line in enumerate(text.splitlines(), 1):
            if line.lstrip().startswith("```"):
                in_fence = not in_fence
            # 2 links (outside code fences)
            if not in_fence:
                for target in LINK.findall(line):
                    if target.startswith(("http://", "https://", "#", "mailto:")):
                        continue
                    path = target.split("#")[0].replace("%20", " ")
                    if not path:
                        continue
                    if not (f.parent / path).exists():
                        problems.append(f"{rel}:{n}: broken relative link: {target}")
            # 3 placeholders (outside code fences)
            if not in_fence and PLACEHOLDER.search(line):
                problems.append(f"{rel}:{n}: placeholder text: {line.strip()[:80]}")

    full = not [a for a in argv if not a.startswith("--")]
    if full:
        # 4 shell syntax
        for s in sorted(ROOT.rglob("*.sh")):
            if s.relative_to(ROOT).parts[0] in SKIP_DIRS or ".cache" in s.relative_to(ROOT).parts:
                continue
            r = subprocess.run(["bash", "-n", str(s)], capture_output=True, text=True)
            if r.returncode != 0:
                problems.append(f"{s.relative_to(ROOT)}: bash -n failed: {r.stderr.strip()[:120]}")
        # 5 workflows
        try:
            import yaml
            for w in sorted((ROOT / "workflows").rglob("*.y*ml")):
                try:
                    doc = yaml.safe_load(w.read_text(encoding="utf-8"))
                except Exception as e:  # noqa: BLE001
                    problems.append(f"{w.relative_to(ROOT)}: YAML error: {str(e)[:120]}")
                    continue
                if not isinstance(doc, dict):
                    problems.append(f"{w.relative_to(ROOT)}: not a mapping")
                    continue
                keys = set(doc.keys())
                # PyYAML reads the bare key  on:  as boolean True (YAML 1.1); accept both spellings.
                if "broken" in w.parts or "vulnerable" in w.parts:
                    continue
                if not ({"on", True} & keys) or "jobs" not in keys:
                    if "runs" not in keys:  # composite or other action metadata is allowed
                        problems.append(f"{w.relative_to(ROOT)}: missing 'on' or 'jobs'")
        except ImportError:
            problems.append("PyYAML not available: workflows not checked")

    for p in problems:
        print("PROBLEM:", p)
    print("----")
    print("snippets:", snippet_summary)
    print("words   :", ", ".join(f"{k}={v}" for k, v in sorted(words.items())), f"| total={sum(words.values())}")
    print(f"files   : {len(files)} markdown file(s); {len(problems)} problem(s)")
    return 1 if problems else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
