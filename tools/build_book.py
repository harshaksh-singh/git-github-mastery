#!/usr/bin/env python3
"""Assemble the textbook into four volumes (Markdown, HTML and, with Chrome, PDF) under dist/.

    python3 tools/build_book.py            Markdown + HTML
    python3 tools/build_book.py --pdf      also PDF through headless Chrome
"""
import html, pathlib, re, subprocess, sys
from markdown_it import MarkdownIt

ROOT = pathlib.Path(__file__).resolve().parent.parent
DIST = ROOT / "dist"
T = "Git & GitHub Mastery"
SUB = "From Zero → Internals → Production → Senior Engineer"
VOLUMES = [
    ("1", "Foundations and the Git data model", [
        "textbook/ch01-fundamentals.md", "textbook/ch02-mental-model.md", "textbook/ch03-git-internals.md",
        "textbook/ch04-working-tree.md", "textbook/ch05-index.md", "textbook/ch06-commits.md", "textbook/ch07-branches.md"]),
    ("2", "Integration, undo, remotes, recovery and advanced Git", [
        "textbook/ch08-merge.md", "textbook/ch09-rebase.md", "textbook/ch10-cherry-pick.md",
        "textbook/ch11-reset-revert-restore.md", "textbook/ch12-remote-operations.md", "textbook/ch13-recovery.md",
        "textbook/ch14a-history-investigation.md", "textbook/ch14b-config-tags-signing.md",
        "textbook/ch14c-stash-rerere-attributes-hooks.md", "textbook/ch14d-frontier.md"]),
    ("3", "GitHub, GitHub Actions and security", [
        "textbook/ch15-github.md", "textbook/ch16-authentication.md", "textbook/ch17-pull-requests.md",
        "textbook/ch18-branch-protection.md", "textbook/ch19-codeowners.md", "textbook/ch20a-actions-fundamentals.md",
        "textbook/ch20b-actions-delivery-debugging.md", "textbook/ch21a-actions-security.md",
        "textbook/ch21b-repository-security-incident-response.md"]),
    ("4", "Scale, professional practice, production, and reference", [
        "textbook/ch22-git-lfs.md", "textbook/ch23-submodules.md", "textbook/ch24-monorepos.md",
        "textbook/ch25-worktrees.md", "textbook/ch26-performance.md", "textbook/ch27-open-source-team-workflows.md",
        "textbook/ch28-ai-ml-workflows.md", "textbook/ch29-production-troubleshooting.md",
        "textbook/ch30-incident-response.md",
        ("Chapter 31: Interview Preparation", "interview/senior-engineer-interview-guide.md"),
        ("Chapter 32: Capstone", "capstone/README.md"),
        ("Chapter 33: Cheat Sheets", "cheatsheets/git-cheat-sheet.md"),
        ("Chapter 33 (continued): Emergency recovery, one page", "cheatsheets/emergency-recovery-one-page.md"),
        ("Chapter 33 (continued): Command safety", "reference/command-safety.md"),
        ("Chapter 34: Glossary", "reference/glossary.md"),
        ("Chapter 35: References", "reference/references.md")]),
]
CSS = """
@page { size: A4; margin: 18mm 16mm; }
body { font: 10.5pt/1.5 -apple-system, "Helvetica Neue", Arial, sans-serif; color: #1a1a1a; max-width: 900px; margin: auto; padding: 0 16px; }
h1 { font-size: 22pt; border-bottom: 2px solid #333; padding-bottom: 6px; page-break-before: always; }
h1.cover { page-break-before: avoid; border: 0; font-size: 34pt; margin-top: 30%; }
h2 { font-size: 15pt; margin-top: 1.6em; } h3 { font-size: 12pt; }
pre { background: #f6f8fa; border: 1px solid #d0d7de; border-radius: 4px; padding: 8px 10px; font: 8.5pt/1.35 Menlo, Consolas, monospace; white-space: pre-wrap; word-break: break-word; page-break-inside: auto; }
code { font: 9pt Menlo, Consolas, monospace; background: #f0f2f4; padding: 0 3px; border-radius: 3px; } pre code { background: none; padding: 0; font-size: inherit; }
table { border-collapse: collapse; width: 100%; font-size: 9pt; margin: 1em 0; } th, td { border: 1px solid #c8ccd1; padding: 4px 6px; vertical-align: top; } th { background: #eef1f4; }
blockquote { border-left: 4px solid #8a8f98; margin: 1em 0; padding: 2px 12px; background: #fafafa; }
a { color: #0b57d0; text-decoration: none; } .toc li { margin: 2px 0; } .sub { font-size: 14pt; color: #444; }
"""
SNIP = re.compile(r"<!-- /?snippet[^>]*-->\n?")

def load(entry):
    title, path = (None, entry) if isinstance(entry, str) else entry
    text = SNIP.sub("", (ROOT / path).read_text(encoding="utf-8"))
    if title:   # demote the file's own H1 and put the book's chapter title above it
        text = re.sub(r"^# (.+)$", r"## \1", text, count=1, flags=re.M)
        text = f"# {title}\n\n*Source file: `{path}`*\n\n" + text
    # links between course files do not work inside a single volume: keep the text, show the path
    text = re.sub(r"(?<!!)\[([^\]\n]+)\]\((?!https?://|#|mailto:)([^)\s]+)\)", lambda m: m.group(1), text)
    return text

def main():
    DIST.mkdir(exist_ok=True)
    md = MarkdownIt("commonmark").enable("table").enable("strikethrough")
    for num, name, entries in VOLUMES:
        parts = [load(e) for e in entries]
        titles = [re.search(r"^# (.+)$", p, re.M).group(1) for p in parts]
        front = (f"# {T}\n\n### {SUB}\n\n**Volume {num} of {len(VOLUMES)}: {name}**\n\n"
                 "Baseline: Git 2.55.0 on macOS; GitHub facts as of 1 October 2026. Every Git transcript in this book is "
                 "real output from the lab scripts under `labs/`, reproducible with `labs/verify-all.sh`. "
                 "GitHub-side behavior is described from GitHub's documentation and is marked as such.\n\n"
                 "## Contents of this volume\n\n" + "\n".join(f"- {t}" for t in titles) + "\n\n")
        body = front + "\n\n".join(parts)
        stem = f"Git-and-GitHub-Mastery-Volume-{num}"
        (DIST / f"{stem}.md").write_text(body, encoding="utf-8")
        page = md.render(body).replace("<h1>", '<h1 class="cover">', 1)
        (DIST / f"{stem}.html").write_text(
            f"<!doctype html><html><head><meta charset='utf-8'><title>{html.escape(T)} — Volume {num}</title>"
            f"<style>{CSS}</style></head><body>{page}</body></html>", encoding="utf-8")
        print(f"volume {num}: {len(body.split()):,} words, {len(titles)} chapters")
        if "--pdf" in sys.argv:
            chrome = "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
            r = subprocess.run([chrome, "--headless=new", "--disable-gpu", "--no-pdf-header-footer",
                                f"--print-to-pdf={DIST / (stem + '.pdf')}", (DIST / f"{stem}.html").as_uri()],
                               capture_output=True, text=True, timeout=900)
            print("   pdf:", "ok" if (DIST / f"{stem}.pdf").exists() else f"failed: {r.stderr[-200:]}")

if __name__ == "__main__":
    main()
