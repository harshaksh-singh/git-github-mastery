#!/usr/bin/env python3
"""Build the finished video of a recording: MP4 (1920x1080, 30 fps, H.264 + AAC), subtitles and YouTube chapters.

    python3 tools/video_build.py V008            from video/production/recordings/V008.*  -> out/V008.mp4, .srt, .chapters.txt
    python3 tools/video_build.py all             every video that has a recording and is not up to date
    python3 tools/video_build.py --draft V008    no recording needed: the narration is spoken by the macOS voice
                                                 -> out/V008.draft.mp4 (+ .draft.srt, .draft.chapters.txt), marked "DRAFT VOICE"
    python3 tools/video_build.py --draft all     a draft of every script that has no up-to-date draft yet

Options:  --force            rebuild even if the output is newer than its inputs
          --allow-missing    final build although some beats are not recorded (they become silence)
          --voice NAME       draft voice (default: Samantha if installed)      --rate N   words per minute for the draft voice
          --keep-temp        keep the working directory under video/production/.cache/build/
          --no-anim          ignore the animation layer of a video and use the still slides
          --no-encode        stop before ffmpeg: write the cut narration, subtitles and chapters only (works without ffmpeg)
          --speech-selftest  check the text handed to the voice, the rules for accepting a voice clip and the subtitle cues
                             (nothing is spoken or rendered)
          --audio-selftest   check the true-peak limit of the sound track on a synthetic signal (needs ffmpeg, a few seconds)

What happens: the retakes and pauses logged by the booth are cut out of the recording, every beat's slide is shown for
exactly as long as the narrator spent on that beat, the thumbnail (or title card) is shown for one second first,
and the sound is normalised to about -16 LUFS, with its true peak held at -1.5 dBTP or below in the finished file.
"""
import os
import array, json, math, os, re, shutil, subprocess, sys, time, wave
from concurrent.futures import ThreadPoolExecutor

sys.path.insert(0, str(__import__("pathlib").Path(__file__).resolve().parent))
from video_common import *   # noqa: F401,F403
import math
import video_takes
try:
    import video_animate
except Exception:              # the animation layer is optional: without it the builder makes still-slide videos
    video_animate = None

SR = 48000
LEAD = 1.0                 # seconds of thumbnail / title card before the first beat
DRAFT_GAP = 0.30           # silence after each spoken beat in a draft
LIST_GAP, MARK_GAP = 0.32, 0.22   # silence between the items of a list read in one beat / at a pause mark
FADE = int(SR * 0.008)     # 8 ms fade at every cut, so cuts never click
BUILD_VERSION = 4


def run(cmd, **kw):
    r = subprocess.run(cmd, capture_output=True, text=True, **kw)
    if r.returncode != 0:
        raise RuntimeError(f"command failed: {' '.join(str(c) for c in cmd[:6])} ...\n{r.stderr[-1500:]}")
    return r


def need_ffmpeg():
    ff, fp = find_tool("ffmpeg"), find_tool("ffprobe")
    if not ff or not fp:
        raise SystemExit("ffmpeg is not installed (or not finished installing). Install it with:  brew install ffmpeg")
    return ff, fp


# ---- audio -------------------------------------------------------------------------------------------
def read_wav(path):
    with wave.open(str(path), "rb") as w:
        if w.getframerate() != SR or w.getnchannels() != 1 or w.getsampwidth() != 2:
            raise RuntimeError(f"{path}: expected 48 kHz mono 16-bit WAV")
        a = array.array("h"); a.frombytes(w.readframes(w.getnframes()))
    if sys.byteorder == "big": a.byteswap()
    return a


def write_wav(path, samples):
    if sys.byteorder == "big":
        samples = array.array("h", samples); samples.byteswap()
    with wave.open(str(path), "wb") as w:
        w.setnchannels(1); w.setsampwidth(2); w.setframerate(SR)
        w.writeframes(samples.tobytes())


def fade_edges(seg):
    n = min(FADE, len(seg) // 2)
    for k in range(n):
        g = k / n
        seg[k] = int(seg[k] * g)
        seg[-1 - k] = int(seg[-1 - k] * g)
    return seg


def silence(seconds):
    return array.array("h", bytes(2 * int(round(seconds * SR))))


PAUSE = "‖"            # marks a short silence inside spoken text (the voice is given the pieces one by one)
SAY_EXT = {"md": "M D", "py": "pie", "txt": "T X T", "yaml": "yammel", "yml": "yammel", "json": "jason", "sh": "S H", "js": "J S", "ts": "T S",
           "html": "H T M L", "css": "C S S", "cfg": "config", "toml": "toml", "lock": "lock", "log": "log", "git": "git", "ini": "I N I",
           "csv": "C S V", "pdf": "P D F", "png": "P N G", "webm": "web M", "mp4": "M P 4", "pub": "pub", "bak": "back", "orig": "orig", "patch": "patch"}
SAY_WORD = {"YAML": "yammel", "SHA": "shah", "README": "read me", "ORIG_HEAD": "orig head", "FETCH_HEAD": "fetch head", "MERGE_HEAD": "merge head",
            "CHERRY_PICK_HEAD": "cherry pick head", "REBASE_HEAD": "rebase head", "GPG": "G P G", "SSH": "S S H", "CI": "C I", "PR": "P R", "gh": "G H",
            "CODEOWNERS": "code owners", "stdout": "standard out", "stderr": "standard error", "sudo": "soo doo", "wip": "W I P", "WIP": "W I P",
            "ff": "F F", "noff": "no F F", "LFS": "L F S", "OIDC": "O I D C", "CLI": "C L I", "fsck": "F S check", "gc": "G C", "mv": "M V", "rm": "R M",
            "config": "config", "reflog": "ref log", "refspec": "ref spec", "refspecs": "ref specs", "reflogs": "ref logs", "packfile": "pack file",
            "packfiles": "pack files", "gitignore": "git ignore", "gitattributes": "git attributes", "gitconfig": "git config", "gitmodules": "git modules",
            "github": "git hub", "gitkeep": "git keep", "mailmap": "mail map", "worktree": "work tree", "worktrees": "work trees", "untracked": "un-tracked",
            "LAB": "lab", "eval": "eval", "evals": "evals",
            "sha1": "shah 1", "sha256": "shah 256", "SHA1": "shah 1", "SHA256": "shah 256", "diff3": "diff 3", "zdiff3": "z diff 3"}
REF_HEADS = ("origin", "upstream", "refs", "heads", "tags", "remotes", "feature", "feat", "fix", "hotfix", "release", "bugfix", "pull", "HEAD")
NOT_PATHS = {"and/or", "either/or", "i/o", "ci/cd", "n/a", "read/write", "yes/no", "true/false", "client/server", "he/she", "km/h", "24/7", "tcp/ip"}
NUM_WORD = {"0": "zero", "1": "one", "2": "two", "3": "three", "4": "four", "5": "five", "6": "six", "7": "seven", "8": "eight", "9": "nine", "10": "ten"}
# A symbol typed twice is named twice ("star star"); three or more are counted ("seven less-than signs").
SYM_TWICE = {"=": "equals equals", "*": "star star", "#": "hash hash", "@": "at at", "|": "pipe pipe", "+": "plus plus",
             "<": "two less-than signs", ">": "two greater-than signs", "!": "two exclamation marks"}
SYM_MANY = {"=": "equals signs", "*": "stars", "#": "hashes", "@": "at signs", "|": "pipes", "+": "plus signs",
            "<": "less-than signs", ">": "greater-than signs", "!": "exclamation marks"}
# What is left of a symbol once every rule in speakable() has had its turn: its plain name.
SYM_NAME = {"*": "star", "|": "pipe", "<": "less-than sign", ">": "greater-than sign", "+": "plus", "#": "hash", "@": "at", "~": "tilde", "^": "caret",
            "$": "dollar", "\\": "backslash", "=": "equals", "/": "slash", "_": "underscore", "%": "percent", "&": "ampersand",
            "[": "open square bracket", "]": "close square bracket", "{": "open curly brace", "}": "close curly brace"}
SPAN_NAME = {"...": "three dots", "..": "two dots", ".": "dot", "?": "question mark", "!": "exclamation mark", ":": "colon", ";": "semicolon",
             "<": "less-than sign", ">": "greater-than sign", "=": "equals sign", "-": "dash", "??": "two question marks", "!!": "two exclamation marks", ",": "comma", "'": "single quote", '"': "double quote", "(": "open parenthesis", ")": "close parenthesis", "()": "empty parentheses"}
RISK_WORD = {"\U0001F7E2": "SAFE", "\U0001F7E1": "CAUTION", "\U0001F534": "DANGEROUS"}
SAY_SCHEME = {"https": "H T T P S", "http": "H T T P", "ssh": "S S H"}


def _say_token(w):
    """One word-like piece (letters, digits, _ and -) as it should be said."""
    if w in SAY_WORD: return SAY_WORD[w]
    if "_" in w: return " ".join(_say_token(x) for x in w.split("_") if x)
    if re.fullmatch(r"[a-z]+[A-Z][A-Za-z]*", w): return re.sub(r"(?<=[a-z])(?=[A-Z])", " ", w)          # camelCase config keys
    return w


def _say_letters(s):
    """The letters of an option or a format code one by one, a capital announced: X -> capital X     gd -> g d"""
    return " ".join(("capital " + c) if c.isupper() else c for c in s)


def _say_path(m):
    """labs/shell -> labs slash shell     origin/main, refs/heads/main -> origin main, refs heads main"""
    tok = m.group(0)
    end = ""
    while tok and tok[-1] in ".-": tok, end = tok[:-1], tok[-1] + end     # a full stop after a path is the sentence's
    return _say_path_tok(tok) + end


def _say_path_tok(tok):
    if tok.lower() in NOT_PATHS or re.fullmatch(r"\d+/\d+", tok):
        return tok.replace("/", "\x02")                                                                # prose (and/or, 3/4): the slash is kept for the voice
    parts = [p for p in tok.split("/")]
    lead = tok.startswith("/")
    refish = parts[0] in REF_HEADS and not lead and "." not in tok
    said = [_say_dotted(p) for p in parts if p]
    if not said: return tok
    if refish: return " ".join(said)
    # every other slash is spoken, also the one a path starts or ends with: /dev/null -> slash dev slash null     logs/refs/ -> logs slash refs slash
    return ("slash " if lead else "") + " slash ".join(said) + (" slash" if tok.endswith("/") else "")


def _say_dotted(w):
    """README.md -> read me dot M D     .gitignore -> dot git ignore     user.name -> user dot name"""
    if re.fullmatch(r"v?\d+(\.\d+)*", w): return w                                                    # version numbers
    bits = w.split(".")
    out = []
    for k, bit in enumerate(bits):
        if k: out.append("dot")
        if not bit: continue
        if k and k == len(bits) - 1 and bit.lower() in SAY_EXT: out.append(SAY_EXT[bit.lower()])
        else: out.append(" ".join(_say_token(x) for x in bit.split("-") if x) if k or "." in w else _say_token(bit))
    return " ".join(out)


def _say_version(m):
    """v0.2.0 -> v 0 point 2 point 0     2.55.0 -> 2 point 55 point 0     1.2.x -> 1 point 2 point x"""
    v, nums, x = m.group(1), m.group(2), m.group(3) or ""
    if not ((v and "." in nums) or x or nums.count(".") >= 2): return m.group(0)
    return ("v " if v else "") + nums.replace(".", " point ") + (" point x" if x else "")


def _say_run(m):
    ch, n = m.group(1), len(m.group(0))
    return " " + (SYM_TWICE[ch] if n == 2 else f"{NUM_WORD.get(str(n), n)} {SYM_MANY[ch]}") + " "


def _say_square(m):
    """[rejected] -> rejected in square brackets     [0-9] -> 0 to 9 in square brackets     [] -> empty square brackets"""
    inner = re.sub(r"\b(\w)-(\w)\b", r"\1 to \2", m.group(1).strip())
    return " " + (inner + " in square brackets" if inner else "empty square brackets") + " "


def _say_span(m):
    """A code span of the script (the teleprompter text keeps the backticks).  Inside it punctuation is code and is named:
    git add . -> git add dot     fixup! -> fixup exclamation mark     remote: -> remote colon     $1 -> dollar 1"""
    s = m.group(1).strip()
    if s in SPAN_NAME: return SPAN_NAME[s]
    s = s.replace("...", " three dots ").replace("$?", " dollar question mark")
    s = re.sub(r"(?<!\.)\.\.(?![./])", " two dots ", s)
    s = re.sub(r"(?:(?<=\s)|^)\.(?=\s|$)", "dot", s)
    s = re.sub(r"(?:(?<=\s)|^)-(?=\s|$)", "dash", s)                                                  # git switch -
    s = re.sub(r"(%[A-Za-z]{1,3})\?", r"\1 question mark ", s)
    s = re.sub(r"(?:(?<=\s)|^)\?(?=\s|$)", "question mark", s)
    s = re.sub(r"\$(?=\d)", " dollar ", s)
    s = re.sub(r"(?<=[\w)\]])([:!?])$", lambda k: " " + SPAN_NAME[k.group(1)], s)
    return s


def speakable(text):
    """Text for the computer voice.  It changes only what is SPOKEN (subtitles and slides keep the script's spelling):
    symbols and Git spellings the synthesiser reads badly are written out, and PAUSE marks short silences.
    The forms are listed in video/NARRATION_STYLE.md ("How symbols are spoken"); speech_selftest() below holds one case of each."""
    t = re.sub(r"`([^`]+)`", _say_span, text)                                                          # code spans first: there punctuation is code
    t = re.sub(r"(?<=[\w-] )\.(?=[\s,;:?!]|$)", "dot", t)                                              # git add .  -> git add dot (text without code spans)
    # a risk label that stands without its word is spoken as the word: "is 🔴." -> "is DANGEROUS."
    t = re.sub("([\U0001F7E2\U0001F7E1\U0001F534])\ufe0f?(?!\\s*(?:SAFE|CAUTION|DANGEROUS))", lambda m: f" {RISK_WORD[m.group(1)]} ", t)
    t = re.sub("[\U0001F7E0-\U0001F7EB\U0001F534\U0001F535✅❌⚠️]", " ", t)
    # a placeholder is spoken as its name: <path> -> path; any other < or > is named further down, never dropped
    t = re.sub(r"<([A-Za-z0-9_-]+(?: [A-Za-z0-9_-]+)*)>(\.\.\.)?", lambda m: m.group(1) + (" three dots" if m.group(2) else ""), t)
    t = re.sub(r"(?<=[\w)]) ([<>])(=?) (?=[\w(])", lambda m: (" less than " if m.group(1) == "<" else " greater than ") + ("or equal to " if m.group(2) else ""), t)   # 3 > 2
    t = t.replace("&&", " and ").replace("->", " points to ").replace("=>", " gives ")
    t = re.sub(r"([<>=|*#@!+])\1+", _say_run, t)                                                       # <<<<<<<  =======  **  @@
    t = re.sub(r"(?<![\w-])-{3,}(?![\w-])", lambda m: f"{NUM_WORD.get(str(len(m.group(0))), len(m.group(0)))} dashes", t)
    t = t.replace("…", ". ").replace("→", " to ").replace("·", ", ").replace("`", "").replace("↪", " ")
    t = re.sub(r"\be\.g\.,?", "for example,", t); t = re.sub(r"\bi\.e\.,?", "that is,", t)
    # list prefixes: "Root cause: ..." gets a breath before and after
    t = re.sub(r"(?<=[.!?\"”)])\s+(Root cause|Fix|Prevention|Mechanism|Symptom|Diagnosis|Correct fix)\s*:\s*", lambda m: f" {PAUSE} {m.group(1)}. {PAUSE} ", t)
    t = re.sub(r"^(Root cause|Fix|Prevention|Mechanism|Symptom|Diagnosis|Correct fix)\s*:\s*", lambda m: f"{m.group(1)}. {PAUSE} ", t)
    # the suffix of git describe: v1.1.0-2-g57c8425 -> ... dash 2 dash g 5 7 c 8
    t = re.sub(r"(?<=\w)-(\d+)-g([0-9a-f]{7,40})\b", lambda m: f" dash {m.group(1)} dash g " + " ".join(m.group(2)[:4]), t)
    # object IDs: the first four characters, spelled out (the narration itself says what kind of object it is)
    def oid(m):
        h = m.group(2)
        if not (re.search(r"[a-f]", h) and re.search(r"\d", h)): return m.group(0)
        four = " ".join(h[:4])
        return (m.group(1) or "") + four + (" three dots" if m.group(3) else "")   # never add a type word: a bare ID may be a blob, a tree or a tag
    # an ID that Git itself shortens with dots ("could not apply 0805fd8... Add settings") keeps them, named: after the ID is
    # spelled out the dots would stand after a letter, where no rule below sees them (a range, A...B, is not touched here)
    t = re.sub(r"(\b[Cc]ommits?\s+|\b[Tt]ree\s+|\b[Bb]lob\s+|\b[Tt]ag\s+|\bID\s+|\band\s+(?=[0-9a-f]{7}\b))?\b([0-9a-f]{7,40})\b(\.\.\.(?![\w/@{(^~.]))?", oid, t)
    # version numbers and numbered labs: the dots between the numbers are "point"
    t = re.sub(r"\b(\d+)([A-Da-d])\.(\d+)\b", lambda m: f"{m.group(1)} {m.group(2).upper()} point {m.group(3)}", t)                 # Lab 14A.14
    t = re.sub(r"(?<!\w)(?<!\w\.)(v?)(\d+(?:\.\d+)*)(\.x\b)?(?![\w])(?!\.\d)", _say_version, t)
    t = re.sub(r"\b(Git|version|Python) (\d+)\.(\d+)(?![\w]|\.\d)", r"\1 \2 point \3", t)                                           # Git 2.55
    # ranges and revision suffixes
    t = t.replace("../", " dot dot slash ")
    t = re.sub(r"(?<![\w.])\./", "dot slash ", t); t = re.sub(r"(?<![\w.])\.(?=\[)", "dot ", t)       # ./run   .[]
    t = re.sub(r"(?<=[\w)}/^~'\"])\.\.\.(?=[\w/@{(^~])", " three dots ", t)                           # A...B
    t = re.sub(r"(?<![\w.)}'\"])\.\.\.(?=[\"”'])", " three dots", t)                                 # three dots that stand alone before a closing quote: "On main: ..."
    t = re.sub(r"(?<![\w.)}'\"])\.\.\.(?=[\w/@^~)]|\s*$|\s)", " three dots ", t)                       # ...B, and three dots that stand alone
    t = re.sub(r"(?<!\.)\.\.(?!\.)", " two dots ", t)                                                  # A..B  ..B  A..
    t = re.sub(r"@\{-(\d+)\}", lambda m: " at minus " + NUM_WORD.get(m.group(1), m.group(1)), t)
    t = re.sub(r"@\{(\d+)\}", lambda m: " at " + NUM_WORD.get(m.group(1), m.group(1)), t)
    t = re.sub(r"@\{([^}]+)\}", r" at \1", t)
    t = re.sub(r"(?<!\w)~/", "home slash ", t)
    t = re.sub(r"~(\d+)", lambda m: " tilde " + NUM_WORD.get(m.group(1), m.group(1)), t)
    t = re.sub(r"(?<=\w)~", " tilde", t); t = t.replace("~/", "home slash ")
    t = re.sub(r"\^\{([^}]*)\}", lambda m: " caret, " + (m.group(1).strip() + " in curly braces" if m.group(1).strip() else "empty curly braces") + " ", t)
    t = re.sub(r"\^(\d+)", lambda m: " caret " + NUM_WORD.get(m.group(1), m.group(1)), t)
    t = re.sub(r"\^-(\d*)(?!\w)", lambda m: " caret dash " + NUM_WORD.get(m.group(1), m.group(1)), t)
    t = t.replace("^@", " caret at ").replace("^!", " caret exclamation mark ")
    t = re.sub(r"(?<=\w)\^(?!\w)", " caret", t)
    # format codes and shell variables: %(refname:short)  %gd  ${{ github.sha }}  $GIT_DIR  $?
    t = re.sub(r"%\(([^()]*)\)", lambda m: " percent, " + m.group(1).replace(":", " colon ") + " in parentheses ", t)
    t = re.sub(r"(?<![\d\w])%([A-Za-z]{1,3})(?![A-Za-z])", lambda m: " percent " + _say_letters(m.group(1)) + " ", t)
    t = t.replace("$LAB", "lab").replace("$HOME", "home")
    t = re.sub(r"\$\{\{\s*(.*?)\s*\}\}", r" dollar, \1 in double curly braces ", t)
    t = t.replace("$?", " dollar question mark").replace("$@", " dollar at ")
    t = re.sub(r"\$(?=[A-Za-z_])", " dollar ", t)                                                       # $5 in a sentence is money and is left to the voice
    # options: --force-with-lease -> dash dash force with lease     -m -> dash m     -X -> dash capital X     -- -> dash dash
    t = re.sub(r"(?<![\w-])--([A-Za-z0-9][\w-]*)(=?)", lambda m: "dash dash " + " ".join(_say_token(x) for x in m.group(1).split("-") if x) + (" equals " if m.group(2) else ""), t)
    t = re.sub(r"(?<![\w-])--(?![\w-])", "dash dash", t)
    t = re.sub(r"(?<=[A-Za-z])--(?=[A-Za-z])", " dash dash ", t)                                       # git fsmonitor--daemon
    t = re.sub(r"(?<![\w-])-([A-Za-z]{1,3})(\d+%?)?(?![\w-])", lambda m: "dash " + _say_letters(m.group(1)) + (" " + m.group(2) if m.group(2) else ""), t)
    t = re.sub(r"(?<![\w-])-(\d{1,2})(?![\w-])", r"dash \1", t)
    t = re.sub(r"(?<![\w-])-(?=[A-Za-z]{4})", "dash ", t)                                              # -text  -committerdate
    t = re.sub(r"(?<=\w)-(?![\w-])", " dash", t)                                                       # sha-  pr-
    t = re.sub(r"\*\.(\w+)", lambda m: "star dot " + SAY_EXT.get(m.group(1).lower(), m.group(1)), t)
    t = re.sub(r"(?<=\w)\.\*", " dot star", t)                                                         # core.*
    t = re.sub(r"(?<!\w)#(\d+|N\b)", r"number \1", t)
    # addresses: https://  git@github.com:OWNER/REPO.git  HEAD:path  (a colon inside code is spoken; the time 10:27 is left alone)
    t = re.sub(r"\b([A-Za-z]+)://", lambda m: SAY_SCHEME.get(m.group(1).lower(), m.group(1)) + " colon slash slash ", t)
    t = re.sub(r"(?<=\w)@(?=\w)", " at ", t)
    t = re.sub(r"(?<!\S):(?=[\w/])", "colon ", t)                                                     # :1:path
    t = re.sub(r"(?<=[\w)\]}\"'*>]):(?=[\w/.*+~^$@%<{-])(?<!\d:(?=\d))", " colon ", t)
    t = re.sub(r"\[([^\[\]]*)\]", _say_square, t)
    t = re.sub(r"\{([^{}]*)\}", lambda m: " " + (m.group(1).strip() + " in curly braces" if m.group(1).strip() else "empty curly braces") + " ", t)
    t = re.sub(r"(?<=\w)\(\)", "", t)                                                                  # lower() -> lower
    t = re.sub(r"(?<=\w)\((?=\S)", " (", t)                                                            # log2(n) -> log2 (n)
    # paths and refs, then dotted names, then single words
    t = re.sub(r"(?<![\w.])/?[\w.$~-]+(?:/[\w.$~*-]+)+/?", _say_path, t)
    t = re.sub(r"(?<=\()(\d+)\x02(\d+)(?=\))|(?<=PATCH )(\d+)\x02(\d+)", lambda m: f"{m.group(1) or m.group(3)} of {m.group(2) or m.group(4)}", t)   # Rebasing (1/3)
    t = re.sub(r"(?<![\w/])\.[A-Za-z][\w-]*(?:\.[A-Za-z]\w*)*", lambda m: _say_dotted(m.group(0)), t)                      # .git  .gitignore
    t = re.sub(r"\b[A-Za-z][\w-]*(?:\.[A-Za-z][\w-]*)+\b", lambda m: _say_dotted(m.group(0)), t)                           # README.md  user.name
    t = re.sub(r"(?<=\d)\.(?=[A-Za-z])|(?<=[A-Za-z])\.(?=\d)", " dot ", t)                             # 1.week  rc.1
    t = re.sub(r"\bSHA-?(\d+)", r"shah \1", t)
    t = re.sub(r"\b(m|ch)0?(\d{1,2})([a-d]?)\b", lambda m: " ".join(m.group(1).upper()) + " " + m.group(2) + (" " + m.group(3).upper() if m.group(3) else ""), t)   # m06  ch14a
    t = re.sub(r"\b[A-Za-z][A-Za-z0-9]*(?:_[A-Za-z0-9]+)*\b", lambda m: _say_token(m.group(0)), t)
    # whatever symbol is still there is named: nothing is handed to the voice raw, and nothing is dropped
    t = re.sub(r"(?<=[A-Za-z]),(?=[A-Za-z])", ", ", t)
    t = re.sub(r"(?<=[A-Za-z0-9])_(?=[A-Za-z0-9])", " ", t)
    t = re.sub(r"(?<=\s)=(?=[,.;:?!]|\s*$)", "equals sign", t)
    t = re.sub(r"(?<=\w)\s*&\s*(?=\w)", " and ", t)
    t = re.sub(r"(?<![\w\"”')\]])!|!(?=[\w.\[/*])", " exclamation mark ", t)
    t = re.sub(r"(?<=\d)%", "\x00", t); t = re.sub(r"\$(?=\d)", "\x01", t)                             # 61% and $5 stay: the voice reads them
    t = re.sub(r"[*|<>+#@~^$\\=/_%&\[\]{}]", lambda m: f" {SYM_NAME[m.group(0)]} ", t).replace("\x00", "%").replace("\x01", "$").replace("\x02", "/")
    t = re.sub(r"\s+", " ", t).strip()
    t = re.sub(r" (?=[,;:?!.](?:\s|$|[\"”')]))", "", t)
    t = re.sub(r",(\s*,)+", ",", t); t = re.sub(r"\(\s+", "(", t); t = re.sub(r"\s+\)", ")", t)
    t = t.replace("in square brackets in brackets", "in square brackets")
    t = re.sub(rf"\s*{PAUSE}(\s*{PAUSE})*\s*", f" {PAUSE} ", t).strip()
    return t


def spoken_chunks(sb, b):
    """What the voice is given for one beat: [text or seconds of silence, ...].  A list that is read in one beat gets a
    breath between its items; PAUSE marks from speakable() become short silences.  speakable() is given the teleprompter
    text, which is the narration with its code spans still in backticks, so that it can tell code from prose."""
    pieces = [b.get("tele") or b["text"]]
    slide = next((s for s in sb["slides"] if s["n"] == b["slide"]), None)
    if slide and slide.get("kind") == "bullets" and len(slide.get("items", [])) >= 2:
        item = lambda it, tick: re.sub(r"\s+", " ", html_unescape(re.sub(r"<[^>]+>", "", re.sub(r"</?code>", tick, it)))).strip().rstrip(".;") + "."
        items = [item(it, "") for it in slide["items"]]
        if re.sub(r"\s+", " ", " ".join(items)) == re.sub(r"\s+", " ", b["text"]).strip():
            pieces = [item(it, "`") for it in slide["items"]]
    out = []
    for k, piece in enumerate(pieces):
        if k: out.append(LIST_GAP)
        for j, part in enumerate(x.strip() for x in speakable(piece).split(PAUSE)):
            if not part or not re.search(r"\w", part): continue
            if out and isinstance(out[-1], str): out.append(MARK_GAP)
            out.append(part)
    return out or [speakable(b["text"])]


def html_unescape(s):
    import html as _h
    return _h.unescape(s)


def pick_voice(want=None):
    out = subprocess.run(["say", "-v", "?"], capture_output=True, text=True).stdout
    names = []
    for l in out.splitlines():
        m = re.match(r"^(.*?)\s+en[_-](US|GB|AU|IN|IE|ZA)\b", l)      # "Tara (English (India)) en_IN  # ..." -> "Tara (English (India))"
        if m and m.group(1).strip() not in names: names.append(m.group(1).strip())
    short = [re.sub(r"\s*\(.*$", "", n) for n in names]
    if want:
        if want in names or want in short: return want
        raise SystemExit(f"voice {want!r} is not installed. Installed English voices: {', '.join(sorted(set(short))[:30])}")
    for v in ("Samantha", "Ava", "Allison", "Daniel", "Karen", "Alex", "Tom", "Fred"):
        if v in short: return v
    if not names:
        raise SystemExit("no English voice is installed for the 'say' command")
    return short[0]


def tts_path(spoken, voice, rate):
    """Where the voice cache keeps one spoken piece.  The name is made from the voice, the rate and the spoken text itself:
    a sentence whose spoken text changes is spoken again, every other sentence is reused."""
    return CACHE / "tts" / f"{sha1(f'{voice}|{rate}|{spoken}')}.wav"


class _say_lock:
    """A lock file shared by every build on this machine, so that only one `say` runs at a time."""
    def __enter__(self):
        import fcntl
        (CACHE / "tts").mkdir(parents=True, exist_ok=True)
        self.f = open(CACHE / "tts" / ".say.lock", "w")
        fcntl.flock(self.f, fcntl.LOCK_EX)
        return self
    def __exit__(self, *a):
        import fcntl
        fcntl.flock(self.f, fcntl.LOCK_UN); self.f.close()


def _wav_seconds(path):
    try:
        return max(0.0, (path.stat().st_size - 44) / (SR * 2))
    except OSError:
        return 0.0


# The pace a spoken piece must have.  tools/video_qc.py judges every beat by these same numbers (its item C1, where the reasons
# for each value are written down), so a clip the builder accepts is a clip the check accepts.
PACE_FACTOR = (0.55, 1.65)   # words per second, as factors of the configured rate (165 wpm: 1.51 to 4.54), pieces of PACE_MIN_WORDS words or more
PACE_LETTERS = (8.0, 19.0)   # letters per second of such a piece (a digit counts as four letters: "7" is said "seven")
PACE_MIN_WORDS = 8           # shorter pieces are judged by the wide bounds below: one long or short word moves their pace a lot
PACE_FLOOR_WPS = 10.0        # no piece of any length may be faster than this
PACE_SHORT_FACTOR = 2.0      # a short piece may be this much slower or faster, in letters per second, than PACE_LETTERS (4 to 38)
VOICE_TRIES = 8              # attempts for one piece before it is split
SENTENCE_GAP, CLAUSE_GAP = 0.33, 0.18   # silence between the parts of a piece that had to be spoken in parts (measured on whole
                                        # takes of this voice: 0.33 s between two sentences, 0.12 to 0.22 s at a comma)


def pace_units(said):
    """-> (words, letters) as the pace bounds count them."""
    return len(said.split()), len(re.findall(r"[^\W\d_]", said)) + 4 * len(re.findall(r"\d", said))


def pace_fault(said, seconds, rate):
    """Is `seconds` a believable length for the spoken text `said` at `rate` words per minute?
    -> (None or "fast" or "slow", words per second, letters per second).  "fast" is what a clip that was cut short looks like,
    "slow" one with silence or noise added.  The one rule for the builder (every clip) and for the quality check (every beat)."""
    words, letters = pace_units(said)
    if seconds <= 0.05: return "fast", 99.0, 999.0
    wps, lps = words / seconds, letters / seconds
    lo, hi = PACE_FACTOR[0] * rate / 60.0, PACE_FACTOR[1] * rate / 60.0
    if words >= PACE_MIN_WORDS:
        if wps > hi or lps > PACE_LETTERS[1]: return "fast", wps, lps
        if wps < lo or lps < PACE_LETTERS[0]: return "slow", wps, lps
    else:
        if wps > PACE_FLOOR_WPS or lps > PACE_LETTERS[1] * PACE_SHORT_FACTOR: return "fast", wps, lps
        if lps < PACE_LETTERS[0] / PACE_SHORT_FACTOR: return "slow", wps, lps
    return None, wps, lps


def pace_range(said, rate):
    """The lengths in seconds that pace_fault() accepts for this text -> (shortest, longest)."""
    words, letters = pace_units(said)
    if words >= PACE_MIN_WORDS:
        return (max(words / (PACE_FACTOR[1] * rate / 60.0), letters / PACE_LETTERS[1]), min(words / (PACE_FACTOR[0] * rate / 60.0), letters / PACE_LETTERS[0]))
    return max(words / PACE_FLOOR_WPS, letters / (PACE_LETTERS[1] * PACE_SHORT_FACTOR)), letters / (PACE_LETTERS[0] / PACE_SHORT_FACTOR)


def clip_seconds(path):
    """Length of a voice clip as it is used in a video: without the synthesiser's silence before and after it."""
    return len(trim_voice(read_wav(path))) / SR


# Measured on 2,247 verified Tara clips (7 October 2026): the level of the spoken parts lies between -20.5 and -17.7 dBFS and
# the longest gap inside a clip is 0.55 s.  A faulty take is about 10 dB louder and clipped (38 of them, -10 to -7 dBFS, tens
# of thousands of samples at full scale), or has seconds of silence in the middle (one with 11.5 s).  Lengths agree in both
# cases, so the length checks do not see them.
VOICE_RMS_DB = (-24.0, -15.0)      # allowed level of the spoken parts of a clip
VOICE_MAX_CLIPPED = 20             # samples at full scale
VOICE_MAX_GAP = 1.5                # seconds of silence inside a clip


def sound_fault(samples):
    """A voice clip that is too loud, clipped, too quiet or has a hole in it -> "loud" / "quiet" / "gap", else None."""
    try:
        import numpy as np
    except Exception:
        np = None
    n = len(samples) // 2400                                 # 50 ms frames
    if n < 2:
        return None
    floor = (32768.0 * 10 ** (-45 / 20)) ** 2                # a frame below -45 dBFS is silence
    if np is not None:
        x = np.frombuffer(samples.tobytes(), dtype=np.int16).astype(np.float64)
        clipped = int((np.abs(x) >= 32700).sum())
        energies = (x[:n * 2400].reshape(n, 2400) ** 2).mean(1).tolist()
    else:
        clipped = sum(1 for v in samples if v >= 32700 or v <= -32700)
        energies = [sum(v * v for v in samples[i * 2400:(i + 1) * 2400]) / 2400.0 for i in range(n)]
    if clipped > VOICE_MAX_CLIPPED:
        return "loud"
    voiced = [e for e in energies if e > floor]
    if not voiced:
        return "quiet"
    db = 10 * math.log10(sum(voiced) / len(voiced) / (32768.0 ** 2))
    if db > VOICE_RMS_DB[1]: return "loud"
    if db < VOICE_RMS_DB[0]: return "quiet"
    first = next(i for i, e in enumerate(energies) if e > floor)
    last = max(i for i, e in enumerate(energies) if e > floor)
    run = longest = 0
    for e in energies[first:last + 1]:
        run = run + 1 if e <= floor else 0
        longest = max(longest, run)
    return "gap" if longest * 0.05 > VOICE_MAX_GAP else None


def clip_pace_fault(said, path, rate):
    """pace_fault() of a clip in the voice cache, and sound_fault(); a file that cannot be read is a fault too."""
    try:
        wav = read_wav(path)
        fault, wps, lps = pace_fault(said, len(trim_voice(wav)) / SR, rate)
        return (fault or sound_fault(wav)), wps, lps
    except Exception:
        return "unreadable", 0.0, 0.0


def split_spoken(said):
    """Smaller pieces of a spoken text for the voice -> (parts, gap in seconds), or ([], 0) if it cannot be split.
    Sentences first; a single sentence at its clause marks (comma, semicolon, colon, dash).  A part has at least two words,
    so that an abbreviation or a single spelled letter never stands alone."""
    def join_short(parts):
        out = []
        for x in parts:
            if out and (len(out[-1].split()) < 2 or not re.search(r"\w", out[-1])): out[-1] += " " + x
            else: out.append(x)
        if len(out) > 1 and len(out[-1].split()) < 2: out[-2] += " " + out.pop()
        return out
    said = said.strip()
    for pat, gap in ((r"(?<=[.!?])(?<!\b[A-Za-z]\.)[\"”')]*\s+(?=[\"“(]?[A-Z0-9])", SENTENCE_GAP), (r"(?<=[,;:])[\"”')]?\s+|\s+-\s+", CLAUSE_GAP)):
        cuts, parts, a = [m for m in re.finditer(pat, said)], [], 0
        for m in cuts:
            k = m.start() + len(m.group(0)) - len(m.group(0).lstrip("\"”')"))      # a closing quote stays with its sentence
            parts.append(said[a:k].strip()); a = m.end()
        parts.append(said[a:].strip())
        parts = join_short([x for x in parts if x])
        if len(parts) > 1: return parts, gap
    return [], 0.0


class VoiceError(RuntimeError):
    """The voice could not speak a sentence correctly: the video is not built (bad sound is never kept)."""


def _say(spoken, voice, rate, out):
    """One run of the synthesiser -> None, or what went wrong.  speech_selftest() puts a stand-in here: it never speaks."""
    try:
        with _say_lock():           # one synthesis at a time on the whole machine: two at once disturb each other
            r = subprocess.run(["say", "-v", voice, "-r", str(rate), "-o", str(out), f"--data-format=LEI16@{SR}", "--", spoken],
                               capture_output=True, text=True, timeout=120)
    except subprocess.TimeoutExpired:      # the synthesiser now and then hangs on one paragraph and never returns
        return "say did not finish within 120 s"
    if r.returncode != 0:
        return r.stderr.strip()[:300] or f"say ended with exit code {r.returncode}"
    return None


def _speak_whole(spoken, voice, rate, p):
    """Speak one piece in one go until two attempts agree in length (within 2 %) and that length is inside the pace bounds.
    -> (True, seconds) with the clip written to p, or (False, why)."""
    lo, hi = pace_range(spoken, rate)
    takes, notes = [], []                   # (seconds, path) of the attempts inside the bounds; what the others were
    try:
        for attempt in range(VOICE_TRIES):
            tmp = p.with_suffix(f".{os.getpid()}.{id(spoken) % 100000}.{attempt}.tmp.wav")
            err = _say(spoken, voice, rate, tmp)
            secs = 0.0 if err else _wav_seconds(tmp)
            if not err and secs <= 0: err = "no sound file was written"
            if not err:
                fault, wps, lps = clip_pace_fault(spoken, tmp, rate)
                if fault:                   # cut short, or with silence added: such an attempt never counts, however often it comes
                    err = f"{clip_seconds(tmp) if fault != 'unreadable' else 0:.2f} s ({ {'fast': 'cut short', 'slow': 'too long', 'loud': 'too loud or clipped', 'quiet': 'too quiet', 'gap': 'silence inside'}.get(fault, fault) })"
            if err:
                notes.append(err)
                try: tmp.unlink()
                except OSError: pass
                continue
            for other, _ in takes:
                if abs(other - secs) <= max(0.05, 0.02 * secs):
                    os.replace(tmp, p)
                    return True, secs
            takes.append((secs, tmp))
        said = ", ".join(notes[:8] + [f"{t:.2f} s (alone)" for t, _ in takes])
        return False, f"{VOICE_TRIES} attempts, none twice with the same believable length ({lo:.1f} to {hi:.1f} s for these {len(spoken.split())} words): {said}"
    finally:
        for _, t in takes:
            try: t.unlink()
            except OSError: pass


def tts(spoken, voice, rate, _depth=0):
    """Speak one piece of already prepared text (see speakable) with the macOS voice -> cached 48 kHz mono WAV path.

    The macOS synthesiser is not repeatable on a busy machine: the same sentence now and then comes out with words missing, or
    drawn out, or with silence added, and it can come out wrong the same way twice.  So a piece is accepted only if
      1. two attempts agree in length (within 2 %), and
      2. that length is inside the pace bounds (pace_fault: words and letters per second for the configured rate).
    Only such a file is kept and marked with a ".ok" file beside it.  A cached file without the mark, or with a mark but outside
    the bounds (marks from before the bounds existed), is spoken again.
    A piece that does not pass after VOICE_TRIES attempts is split at its sentences (a single sentence at its clauses), the
    parts are spoken and checked one by one in the same way and joined with a short gap.  If a part still cannot pass, VoiceError
    is raised with the sentence in it and the video is not built."""
    p = tts_path(spoken, voice, rate)
    ok = p.with_suffix(".ok")
    p.parent.mkdir(parents=True, exist_ok=True)
    if p.exists() and p.stat().st_size > 44 and ok.exists():
        if not clip_pace_fault(spoken, p, rate)[0]:
            return p
        try: ok.unlink()                    # marked, but too short or too long for its words: not a verified clip
        except OSError: pass
    done, why = _speak_whole(spoken, voice, rate, p)
    if done:
        ok.write_text(f"{why:.3f}\n")
        return p
    parts, gap = split_spoken(spoken) if _depth < 2 else ([], 0.0)
    if not parts:
        raise VoiceError(f"the voice cannot speak this sentence correctly: {spoken!r}\n      {why}")
    try:
        wavs = [tts(x, voice, rate, _depth + 1) for x in parts]
    except VoiceError as e:
        raise VoiceError(f"{e}\n      (a part of: {spoken[:160]!r})" if _depth == 0 else str(e)) from None
    whole = array.array("h")
    for k, w in enumerate(wavs):
        if k: whole.extend(silence(gap))
        whole.extend(trim_voice(read_wav(w), 2400 if k == len(wavs) - 1 else 480))
    secs = len(whole) / SR
    fault = pace_fault(spoken, len(trim_voice(array.array("h", whole))) / SR, rate)[0]
    if fault:
        raise VoiceError(f"the voice cannot speak this sentence correctly, not even in {len(parts)} parts ({secs:.2f} s, {'cut short' if fault == 'fast' else 'too long'}): {spoken!r}")
    tmp = p.with_suffix(f".{os.getpid()}.{id(spoken) % 100000}.join.tmp.wav")
    write_wav(tmp, whole)
    os.replace(tmp, p)
    ok.write_text(f"{secs:.3f} joined from {len(parts)} parts\n")
    return p


SPEECH_CASES = (   # (narration with its code spans, what the voice is given): one line for each form in NARRATION_STYLE.md, "How symbols are spoken"
    ('Look at `HEAD@{1}`, `HEAD@{upstream}` and `@{-1}`.',
     'Look at HEAD at one, HEAD at upstream and at minus one.'),
    ('Go to `HEAD~2`, then `main~`, then `HEAD^`, `HEAD^2` and `HEAD^^`.',
     'Go to HEAD tilde two, then main tilde, then HEAD caret, HEAD caret two and HEAD caret caret.'),
    ('Peel with `v1.0.0^{}`, `HEAD^{tree}` and `^{tag}`.',
     'Peel with v 1 point 0 point 0 caret, empty curly braces, HEAD caret, tree in curly braces and caret, tag in curly braces.'),
    ('The forms `^@`, `^!` and `^-` are shorthands, and `^1..^2` is a range.',
     'The forms caret at, caret exclamation mark and caret dash are shorthands, and caret one two dots caret two is a range.'),
    ('Compare `main..topic`, `main...topic`, `..topic` and `@{u}..`.',
     'Compare main two dots topic, main three dots topic, two dots topic and at u two dots dot'),
    ('Know `..` from `...`.',
     'Know two dots from three dots.'),
    ('Use `--force-with-lease`, `--force-with-lease=main`, `-X ours`, `-x`, `-fdx`, `-M40%` and `--3way`.',
     'Use dash dash force with lease, dash dash force with lease equals main, dash capital X ours, dash x, dash f d x, dash capital M 40% and dash dash 3way.'),
    ('Run `git log --all -- <path>` and `git checkout -`.',
     'Run git log dash dash all dash dash path and git checkout dash.'),
    ('The patterns `*`, `**`, `*.log`, `refs/heads/*`, `v[0-9]*` and `core.*`.',
     'The patterns star, star star, star dot log, refs heads star, v 0 to 9 in square brackets star and core dot star.'),
    ('Run `git tag | tail -1`.',
     'Run git tag pipe tail dash 1.'),
    ('Read the `=`, `!`, `<`, and `>` markers.',
     'Read the equals sign, exclamation mark, less-than sign, and greater-than sign markers.'),
    ('Between `<<<<<<<` and `=======`, then `>>>>>>>`, and `|||||||` in diff3 style.',
     'Between seven less-than signs and seven equals signs, then seven greater-than signs, and seven pipes in diff 3 style.'),
    ('It compared `pred == gold`, and `MAX_TIMEOUT_S = 60`.',
     'It compared pred equals equals gold, and MAX TIMEOUT S equals 60.'),
    ('Set `* text=auto`, `-text` and `eol=lf`.',
     'Set star text equals auto, dash text and eol equals lf.'),
    ('In `$GIT_DIR/hooks`, `$HOME`, `$1`, `$?` and `${{ github.sha }}`.',
     'In dollar GIT DIR slash hooks, home, dollar 1, dollar question mark and dollar, git hub dot sha in double curly braces.'),
    ('Print `%gd %gs`, `%GS`, `%G?` and `%(refname:short)`.',
     'Print percent g d percent g s, percent capital G capital S, percent capital G question mark and percent, refname colon short in parentheses.'),
    ('Open `/dev/null`, `data/`, `/build/`, `./run`, `../ravi` and `~/work/`.',
     'Open slash dev slash null, data slash, slash build slash, dot slash run, dot dot slash ravi and home slash work slash.'),
    ('Open `labs/shell`, `origin/main`, `README.md`, `.gitignore` and `exercises/m06-m10-integration.md`.',
     'Open labs slash shell, origin main, read me dot M D, dot git ignore and exercises slash M 6 M 10 integration dot M D.'),
    ('Git 2.55 and Git 2.55.0, the tags `v0.2.0` and `v2.0.0-rc.1`, `2.x`, and `v1.1.0-2-g57c8425`.',
     'Git 2 point 55 and Git 2 point 55 point 0, the tags v 0 point 2 point 0 and v 2 point 0 point 0-rc dot 1, 2 point x, and v 1 point 1 point 0 dash 2 dash g 5 7 c 8.'),
    ('Section 14A.14 and Lab 6.1.',
     'Section 14 A point 14 and Lab 6.1.'),
    ('It says `! [rejected]`, `[remote "origin"]`, `[ahead 1, behind 2]` and `[]`.',
     'It says exclamation mark rejected in square brackets, remote "origin" in square brackets, ahead 1, behind 2 in square brackets and empty square brackets.'),
    ('Clone `git@github.com:acme/support-bot.git` or `https://github.com/acme/support-bot.git`.',
     'Clone git at git hub dot com colon acme slash support bot dot git or H T T P S colon slash slash git hub dot com slash acme slash support bot dot git.'),
    ('Show `HEAD:path`, `:1:path`, `blob:none`, and a `remote:` line at 10:27.',
     'Show HEAD colon path, colon 1 colon path, blob colon none, and a remote colon line at 10:27.'),
    ('Run `git add .`, then `git restore --staged .` twice.',
     'Run git add dot, then git restore dash dash staged dot twice.'),
    ('The prefixes `ghp_`, `GIT_COMMITTER_`, `MERGE_*`, `fixup!` and `__git_ps1`.',
     'The prefixes ghp underscore, GIT COMMITTER underscore, MERGE underscore star, fixup exclamation mark and underscore underscore git ps1.'),
    ('Call `.lower()`, `success()` and `!cancelled()`.',
     'Call dot lower, success and exclamation mark cancelled.'),
    ('A `+` line, a `-` line, `+refs/heads/*:refs/remotes/origin/*`, `#`, `##` and `@@`.',
     'A plus line, a dash line, plus refs heads star colon refs remotes origin star, hash, hash hash and at at.'),
    ('Use `actions/checkout@v4`, W&B, and issue #12.',
     'Use actions slash checkout at v4, W and B, and issue number 12.'),
    ('`git fsmonitor--daemon` and `Rebasing (1/3)`.',
     'git fsmonitor dash dash daemon and Rebasing (1 of 3).'),
    ('It is 🔴. This one is 🟡 CAUTION: careful.',
     'It is DANGEROUS. This one is CAUTION: careful.'),
    ('The base is 6ae3c51.',
     'The base is 6 a e 3.'),
    ('It failed. Root cause: the tip moved.',
     'It failed. ‖ Root cause. ‖ the tip moved.'),
    ('Is `a > b`, or is 2 <= 3?',
     'Is a greater than b, or is 2 less than or equal to 3?'),
    ('Entries are named "On <branch>: ..." and do not contain "WIP".',
     'Entries are named "On branch: three dots" and do not contain "W I P".'),
    ('It\'s refused: "is at `4f2cc0c`... but expected `b602c1f`...". Then: "could not apply 0805fd8... Add staging settings".',
     'It\'s refused: "is at 4 f 2 c three dots but expected b 6 0 2 three dots". Then: "could not apply 0 8 0 5 three dots Add staging settings".'),
    ('The line "(cherry picked from commit f98ffd3..." and the range `4f2cc0c...b602c1f`.',
     'The line "(cherry picked from commit f 9 8 f three dots" and the range 4 f 2 c three dots b 6 0 2.'),
)
SPEECH_PROSE = (   # ordinary punctuation is never touched
    "It's a 50/50 call, and/or a coin toss - on 3/4 of the days.",
    'Don\'t worry: it\'s a well-known, two-step fix, "as the manual says", isn\'t it? About 61% of teams, for $5.',
    "So that's the destination. Now, why is the course built the way it is (and for whom)?",
    "It's the end of an ordinary release week; at 10:27 your CTO asks, calmly: what changed?",
)
RAW_SYMBOL = r"[*|<>+#@~^\\\\=/_&\[\]{}`]|(?<!\d)%|\$(?!\d)|\.\.|(?<![\w\"')])!|\s[-.]+(?=\s|$)"


def speech_selftest():
    """Pure text checks of speakable(): no voice, no rendering.  -> list of problems (empty when all is well).
    Run it with:  python3 tools/video_build.py --speech-selftest"""
    bad = []
    for src, want in SPEECH_CASES:
        got = speakable(src)
        if got != want: bad.append(f"{src!r}\n      expected {want!r}\n      got      {got!r}")
    for src, want in SPEECH_CASES:
        left = re.findall(RAW_SYMBOL, speakable(src).replace(PAUSE, " "))
        if left: bad.append(f"{src!r}: raw symbols reach the voice: {left}")
    for src in SPEECH_PROSE:
        if speakable(src) != src: bad.append(f"prose was changed: {src!r} -> {speakable(src)!r}")
    # the voice cache: one file per (voice, rate, spoken text), so a changed sentence is spoken again and an unchanged one is reused
    a, b = speakable("Go to `HEAD~2`."), speakable("Go to `HEAD~3`.")
    if tts_path(a, "Tara", 165) != tts_path(speakable("Go to `HEAD~2`."), "Tara", 165): bad.append("the voice cache key is not stable for the same spoken text")
    if len({tts_path(a, "Tara", 165), tts_path(b, "Tara", 165), tts_path(a, "Tara", 175), tts_path(a, "Samantha", 165)}) != 4:
        bad.append("the voice cache key does not depend on the spoken text, the voice and the rate")
    if tts_path(a, "Tara", 165).name != sha1(f"Tara|165|{a}") + ".wav": bad.append("the voice cache key changed its form: every cached sentence would be spoken again")
    sb = {"slides": [{"n": 1, "kind": "bullets", "items": ["Run <code>git add .</code> first", "Use <code>-X</code> ours."]}]}
    beat = {"i": 0, "slide": 1, "text": "Run git add . first. Use -X ours.", "tele": "Run `git add .` first. Use `-X` ours."}
    got = spoken_chunks(sb, beat)
    if got != ["Run git add dot first.", LIST_GAP, "Use dash capital X ours."]: bad.append(f"a list beat: {got!r}")
    got = spoken_chunks({"slides": []}, {"i": 0, "slide": 9, "text": "Run git add .. Done.", "tele": "Run `git add .`. Done."})
    if got != ["Run git add dot. Done."]: bad.append(f"a beat with a code span: {got!r}")
    return bad + voice_selftest() + srt_selftest()


def voice_selftest():
    """The rules of tts() with a stand-in for the synthesiser: nothing is spoken, the voice cache is not touched."""
    import tempfile
    bad = []
    full = "Here are the candidates on the first-parent line again. HEAD now points at commit 0 7 4 d, and at no branch."
    s1, s2 = "Here are the candidates on the first-parent line again.", "HEAD now points at commit 0 7 4 d, and at no branch."
    # the bounds, on the lengths measured for these texts (V071 beat 39: 3.94 s was marked verified)
    for said, secs, want in ((full, 7.30, None), (full, 6.70, None), (full, 3.94, "fast"), (full, 16.0, "slow"), (s1, 2.72, None), (s1, 2.07, "fast"),
                             ("Root cause.", 0.80, None), ("Root cause.", 0.15, "fast"), ("You should now be able to say:", 19.0, "slow")):
        got = pace_fault(said, secs, 165)[0]
        if got != want: bad.append(f"pace bounds: {said[:40]!r} in {secs} s is {got!r}, expected {want!r}")
    lo, hi = pace_range(full, 165)
    if pace_fault(full, lo + 0.01, 165)[0] or pace_fault(full, hi - 0.01, 165)[0] or not pace_fault(full, lo - 0.01, 165)[0] or not pace_fault(full, hi + 0.01, 165)[0]:
        bad.append(f"pace_range() and pace_fault() disagree for {lo:.2f} to {hi:.2f} s")
    for said, want in ((full, ([s1, s2], SENTENCE_GAP)), (s2, (["HEAD now points at commit 0 7 4 d,", "and at no branch."], CLAUSE_GAP)),
                       ('He said "stop." Then he left. Git 2.55 was out.', (['He said "stop."', "Then he left.", "Git 2.55 was out."], SENTENCE_GAP)),
                       ("Yes, it is, as planned.", (["Yes, it is,", "as planned."], CLAUSE_GAP)), ("and at no branch.", ([], 0.0))):
        if split_spoken(said) != want: bad.append(f"split_spoken({said!r}): {split_spoken(said)!r}, expected {want!r}")
    global tts_path, _say
    real = tts_path, _say
    with tempfile.TemporaryDirectory() as d:
        d = pathlib.Path(d)
        calls = []
        def tone(path, seconds):
            n = int(seconds * SR) - 480 - 2400          # the length tts() measures: trim_voice() keeps 480 samples before and 2400 after
            write_wav(path, silence(0.3) + array.array("h", [3500 if (k // 40) % 2 else -3500 for k in range(n)]) + silence(0.3))
        def stand_in(plan):
            def say(spoken, voice, rate, out):
                calls.append(spoken)
                todo = plan.get(spoken, [])
                secs = todo.pop(0) if len(todo) > 1 else (todo[0] if todo else None)
                if secs is None: return "say did not finish within 120 s"
                tone(out, secs); return None
            return say
        def run_case(name, plan, said, want_secs=None, want_error=None, want_calls=None, mark=None):
            global _say
            calls.clear(); _say = stand_in({k: list(v) for k, v in plan.items()})
            try:
                p = tts(said, "Tara", 165)
                secs, note = clip_seconds(p), p.with_suffix(".ok").read_text()
                if want_error: bad.append(f"voice, {name}: accepted a clip of {secs:.2f} s, expected the build to fail")
                elif abs(secs - want_secs) > 0.02: bad.append(f"voice, {name}: clip of {secs:.2f} s, expected {want_secs:.2f}")
                elif mark and mark not in note: bad.append(f"voice, {name}: the mark says {note!r}")
            except VoiceError as e:
                if not want_error: bad.append(f"voice, {name}: {e}")
                elif want_error not in str(e): bad.append(f"voice, {name}: the message does not name the sentence {want_error!r}: {e}")
                elif tts_path(said, "Tara", 165).with_suffix(".ok").exists(): bad.append(f"voice, {name}: a failed sentence was marked verified")
            if want_calls is not None and len(calls) != want_calls: bad.append(f"voice, {name}: {len(calls)} runs of the synthesiser, expected {want_calls}")
            if list(d.glob("*/*.tmp.wav")): bad.append(f"voice, {name}: temporary files were left behind")
        case = [0]
        def fresh():
            global tts_path
            case[0] += 1; sub = d / str(case[0]); sub.mkdir()
            tts_path = lambda spoken, voice, rate: sub / f"{sha1(f'{voice}|{rate}|{spoken}')}.wav"
        try:
            fresh(); run_case("two equal attempts", {full: [7.30]}, full, want_secs=7.30, want_calls=2)
            fresh(); run_case("cut short twice the same way, then right", {full: [3.94, 3.94, 7.30, 9.57 * 2, 7.30]}, full, want_secs=7.30, want_calls=5)
            fresh(); run_case("two believable lengths that differ", {full: [6.70, 7.30, 6.71]}, full, want_secs=6.71, want_calls=3)
            fresh(); run_case("always cut short: spoken in sentences", {full: [3.94], s1: [2.72], s2: [4.26]}, full, want_secs=2.72 - 0.04 + SENTENCE_GAP + 4.26, want_calls=VOICE_TRIES + 4, mark="joined from 2 parts")
            fresh(); run_case("a sentence that fails too: spoken in clauses", {full: [3.94], s1: [2.72], s2: [1.0], "HEAD now points at commit 0 7 4 d,": [2.9], "and at no branch.": [1.2]}, full,
                              want_secs=2.72 - 0.04 + SENTENCE_GAP + (2.9 - 0.04 + CLAUSE_GAP + 1.2), want_calls=2 * VOICE_TRIES + 6)
            fresh(); run_case("a part that never passes: the build fails", {full: [3.94], s1: [2.72], s2: [1.0], "HEAD now points at commit 0 7 4 d,": [2.9], "and at no branch.": [0.1]}, full, want_error="and at no branch.")
            fresh(); run_case("the synthesiser hangs: the build fails", {}, "Root cause.", want_error="Root cause.", want_calls=VOICE_TRIES)
            # a clip that was marked before the bounds existed is not trusted, and its mark goes
            fresh(); p = tts_path(full, "Tara", 165); tone(p, 3.94); p.with_suffix(".ok").write_text("3.986\n")
            run_case("a marked clip outside the bounds is spoken again", {full: [7.30]}, full, want_secs=7.30, want_calls=2)
            fresh(); p = tts_path(full, "Tara", 165); tone(p, 7.30); p.with_suffix(".ok").write_text("7.300\n")
            run_case("a marked clip inside the bounds is reused", {}, full, want_secs=7.30, want_calls=0)
        finally:
            tts_path, _say = real
    return bad


def audio_selftest():
    """seal_audio() on a synthetic track: loud syllables with sharp high tones (peaks between the samples), reveal sounds mixed in.
    The finished AAC track must be at or below PEAK_CEILING and still at the loudness target.  -> (problems, what was measured)"""
    import tempfile
    ff, _ = need_ffmpeg()
    bad = []
    with tempfile.TemporaryDirectory() as d:
        work = pathlib.Path(d)
        raw, norm, seconds = work / "narration.raw.wav", work / "narration.wav", 24.0
        a = array.array("h", bytes(2 * int(seconds * SR)))
        for k in range(len(a)):
            t = k / SR
            env = abs(math.sin(2 * math.pi * 1.6 * t)) ** 3 * (0.35 + 0.65 * abs(math.sin(2 * math.pi * 0.11 * t)))
            a[k] = int(30000 * env * (0.5 * math.sin(2 * math.pi * 170 * t) + 0.22 * math.sin(2 * math.pi * 510 * t + 1) + 0.2 * math.sin(2 * math.pi * 2300 * t) + 0.08 * math.sin(2 * math.pi * 11900 * t + 2)))
        write_wav(raw, a)
        loudnorm(ff, raw, norm, seconds)
        mix_sfx(ff, norm, [(0.5 + 0.63 * k, ("pop", "tick", "whoosh")[k % 3], 1.5) for k in range(36)])
        before = work / "before.m4a"
        run([ff, "-y", "-v", "error", "-i", str(norm)] + AAC + [str(before)])
        i0, tp0 = measure_audio(ff, before)
        res = seal_audio(ff, norm, seconds, work)
        final = work / "final.m4a"
        run([ff, "-y", "-v", "error", "-i", str(norm), "-af", f"apad,atrim=0:{seconds:.6f}"] + AAC + ["-t", f"{seconds:.6f}", str(final)])
        i1, tp1 = measure_audio(ff, final)
        target = float(__import__("inspect").getsource(loudnorm).split('target = "I=')[1].split(":")[0])
        if tp1 is None or tp1 > PEAK_CEILING: bad.append(f"true peak of the finished track is {tp1} dBTP, above {PEAK_CEILING:g}")
        if i1 is None or abs(i1 - target) > 0.5: bad.append(f"integrated loudness of the finished track is {i1} LUFS, target {target:g}")
        if i0 is not None and i1 is not None and abs(i1 - i0) > 0.3: bad.append(f"the limiter moved the loudness from {i0} to {i1} LUFS")
        if read_wav(norm).buffer_info()[1] != int(round(seconds * SR)): bad.append("the limiter changed the length of the track")
        note = f"without the limiter {tp0} dBTP at {i0} LUFS; finished track {tp1} dBTP at {i1} LUFS (limiter at {res['limiter_dbtp']} dBTP, {res['rounds']} round(s))"
    return bad, note


def srt_selftest():
    """Subtitle cues never overlap, whatever the beat lengths are (V096 and V103 had a cue that started 55 ms before the last one ended)."""
    bad = []
    beats = [{"type": "narration", "text": "A long first sentence that needs a little while to be read by anybody. And a second one that follows it."},
             {"type": "narration", "text": "Yes."}, {"type": "hold"}, {"type": "narration", "text": "Short."}, {"type": "narration", "text": "Gone."},
             {"type": "narration", "text": "The next beat starts right after it."}, {"type": "narration", "text": "End."}]
    for name, durs, tail in (("ordinary beats", [6.0, 0.9, 2.0, 0.8, 0.7, 2.5, 0.8], 0.3), ("a beat of 0.305 s", [6.0, 0.305, 0.0, 0.305, 0.31, 2.5, 0.1], 0.3),
                             ("beats of a few frames", [6.0, 0.1, 0.0, 0.07, 0.0, 2.5, 0.0], 0.3), ("a recording, no tail", [5.0, 0.2, 1.0, 0.05, 0.3, 2.0, 0.3], 0.0)):
        starts, t = [], 1.0
        for x in durs: starts.append(t); t += x
        cues = srt_cues({"beats": beats}, starts, durs, tail)
        for a, b in zip(cues, cues[1:]):
            if b[0] < a[1] or b[0] < a[0]: bad.append(f"subtitles, {name}: the cue at {srt_time(b[0] / 1000)} starts before the one before it ends at {srt_time(a[1] / 1000)}")
        if any(c[1] <= c[0] for c in cues): bad.append(f"subtitles, {name}: a cue ends before it starts")
        said = " ".join(c[2].replace("\n", " ") for c in cues)
        if said != " ".join(b["text"] for b in beats if b["type"] == "narration"): bad.append(f"subtitles, {name}: text was lost or reordered: {said!r}")
        if name == "ordinary beats" and [c[:2] for c in cues[-2:]] != [[11400, 13560], [13900, 14360]]: bad.append(f"subtitles, {name}: the times changed: {[c[:2] for c in cues]}")
    return bad


def trim_voice(seg, tail=2400):
    """Cut the synthesiser's leading / trailing digital silence."""
    lo, hi, th = 0, len(seg), 90
    while lo < hi and abs(seg[lo]) < th: lo += 1
    while hi > lo and abs(seg[hi - 1]) < th: hi -= 1
    return fade_edges(seg[max(0, lo - 480):min(len(seg), hi + tail)])


def decode_take(ff, path, work):
    """Recorded take (webm / m4a / ogg / wav) -> 48 kHz mono WAV on the container's own clock."""
    out = work / (path.stem.replace(".", "_") + ".wav")
    if path.suffix == ".wav":
        try:
            read_wav(path); return path           # already in the working format
        except Exception:
            pass
    if not ff:
        raise SystemExit("ffmpeg is needed to read the recording. Install it with:  brew install ffmpeg")
    run([ff, "-y", "-v", "error", "-i", str(path), "-vn", "-af", "aresample=async=1:first_pts=0", "-ac", "1", "-ar", str(SR), "-c:a", "pcm_s16le", str(out)])
    return out


def assemble_audio(sb, mode, work, ff, opts):
    """-> (raw wav path, per-beat durations in seconds, info dict)"""
    beats = sb["beats"]
    parts, durs = [silence(LEAD)], []
    info = {"mode": mode}
    if mode == "draft":
        voice, rate = pick_voice(opts.get("voice")), int(opts.get("rate") or 175)
        info.update({"voice": voice, "rate": rate})
        todo = [b for b in beats if b["type"] == "narration"]
        chunks = {b["i"]: spoken_chunks(sb, b) for b in todo}
        texts = sorted({c for cs in chunks.values() for c in cs if isinstance(c, str)})
        with ThreadPoolExecutor(6) as ex:
            wavs = dict(zip(texts, ex.map(lambda x: tts(x, voice, rate), texts)))
        # what was actually sent to the voice, beat by beat (subtitles and slides keep the script's own spelling)
        log = work / "spoken.txt"
        log.write_text("\n".join(f"{b['i']:4d}  " + " ".join(c if isinstance(c, str) else f"[{c:.2f} s]" for c in chunks[b["i"]]) for b in todo) + "\n", encoding="utf-8")
        (CACHE / "tts").mkdir(parents=True, exist_ok=True)
        shutil.copyfile(log, CACHE / "tts" / f"{sb['id']}.spoken.txt")
        for b in beats:
            if b["type"] == "narration":
                seg = array.array("h")
                cs = chunks[b["i"]]
                for k, c in enumerate(cs):
                    if isinstance(c, str): seg.extend(trim_voice(read_wav(wavs[c]), 2400 if k == len(cs) - 1 else 960))
                    else: seg.extend(silence(c))
                seg = seg + silence(DRAFT_GAP)
            else:
                seg = silence(b["hold"])
            parts.append(seg); durs.append(len(seg) / SR)
    else:
        timing = video_takes.load_timing(sb["id"])
        if not timing or not timing.get("takes"):
            raise SystemExit(f"{sb['id']}: no recording in video/production/recordings/. Record it with: video/production/make.sh record {sb['id']}"
                             f"   (or make a preview with: video/production/make.sh draft {sb['id']})")
        use, stale, missing = video_takes.resolve(sb, timing)
        if stale:
            print(f"  {sb['id']}: the script changed after beats {stale[:12]}{' ...' if len(stale) > 12 else ''} were recorded; they must be read again")
        if missing and not opts.get("allow_missing"):
            secs = sorted({beats[i]["section"] for i in missing})
            raise SystemExit(f"{sb['id']}: {len(missing)} beat(s) are not recorded yet (sections: {', '.join(secs)}). "
                             f"Record them with: video/production/make.sh record {sb['id']}   (or build anyway with --allow-missing)")
        cache = {}
        cut = 0.0
        for b in beats:
            i = b["i"]
            if i in use:
                f, s, e = use[i]
                if f not in cache:
                    src = RECORDINGS / f
                    if not src.exists():
                        raise SystemExit(f"{sb['id']}: the take file {rel(src)} named in the timing file is missing")
                    cache[f] = read_wav(decode_take(ff, src, work))
                a = cache[f]
                seg = fade_edges(a[int(round(s * SR)):min(len(a), int(round(e * SR)))])
                if len(seg) == 0:
                    seg = silence(b["hold"] if b["type"] == "hold" else b["est"])
            else:
                seg = silence(b["hold"] if b["type"] == "hold" else b["est"])
            parts.append(seg); durs.append(len(seg) / SR)
        total_takes = sum(len(a) for a in cache.values()) / SR
        info.update({"takes": [t["file"] for t in timing["takes"]], "takes_seconds": round(total_takes, 2),
                     "kept_seconds": round(sum(durs), 2), "missing_beats": missing, "stale_beats": stale})
    raw = work / "narration.raw.wav"
    whole = array.array("h")
    for p in parts: whole.extend(p)
    write_wav(raw, whole)
    return raw, durs, info


def loudnorm(ff, raw, out, total):
    """Two-pass EBU R128 normalisation of the narration to -16 LUFS (true peak -1.5 dB).  The finished track, with the reveal
    sounds mixed in and encoded as AAC, is held at that peak by seal_audio()."""
    target = "I=-16:TP=-1.5:LRA=11"
    r = subprocess.run([ff, "-hide_banner", "-nostats", "-i", str(raw), "-af", f"loudnorm={target}:print_format=json", "-f", "null", "-"],
                       capture_output=True, text=True)
    m = re.search(r"\{[^{}]*\"input_i\"[^{}]*\}", r.stderr, re.S)
    af = f"loudnorm={target}"
    meas = None
    if m:
        try:
            meas = json.loads(m.group(0))
            if all(math.isfinite(float(meas[k])) for k in ("input_i", "input_tp", "input_lra", "input_thresh", "target_offset")):
                af = (f"loudnorm={target}:measured_I={meas['input_i']}:measured_TP={meas['input_tp']}:measured_LRA={meas['input_lra']}"
                      f":measured_thresh={meas['input_thresh']}:offset={meas['target_offset']}:linear=true")
            else:
                af = None                    # digital silence: nothing to normalise
        except Exception:
            meas = None
    if af is None:
        shutil.copyfile(raw, out)
    else:
        run([ff, "-y", "-v", "error", "-i", str(raw), "-af", af + f",apad,atrim=0:{total:.6f}", "-ar", str(SR), "-ac", "1", "-c:a", "pcm_s16le", str(out)])
    return meas


PEAK_CEILING = -1.5        # dBTP: the sound track of the finished MP4 (after the reveal sounds and the AAC encoder) is at or below this
PEAK_MARGIN = 0.1          # dB kept below the ceiling when the limiter is set
AAC = ["-c:a", "aac", "-b:a", "160k", "-ar", str(SR), "-ac", "1"]     # the sound track of every MP4; seal_audio() measures with the same


def measure_audio(ff, path):
    """EBU R128 measurement of a sound file -> (integrated LUFS, true peak dBTP); None where ffmpeg gives no number (silence)."""
    r = subprocess.run([ff, "-hide_banner", "-nostats", "-i", str(path), "-vn", "-af", "ebur128=peak=true:framelog=quiet", "-f", "null", "-"], capture_output=True, text=True)
    tail = r.stderr[r.stderr.rfind("Summary:"):] if "Summary:" in r.stderr else ""
    num = lambda pat: (lambda m: float(m.group(1)) if m else None)(re.search(pat, tail))
    return num(r"\bI:\s+(-?[\d.]+) LUFS"), num(r"Peak:\s+(-?[\d.]+) dBFS")


def seal_audio(ff, wav, seconds, work):
    """Last step of the sound: hold the true peak of the finished track at or below PEAK_CEILING.  Rewrites `wav` in place.

    loudnorm() limits the narration alone to -1.5 dBTP, but the reveal sounds are mixed in after it and the AAC encoder moves
    peaks, so finished videos measured -1.0 to -1.3 dBTP.  Here the mixed track goes through a limiter (at four times the sample
    rate, so that peaks between the samples are seen), is encoded exactly as it will be in the MP4, and is measured; if the encoded
    track is above the ceiling the limiter is set lower by the excess and the step is repeated.  Only peaks are touched: the
    integrated loudness stays where loudnorm() put it.  -> {"true_peak_dbtp", "integrated_lufs", "limiter_dbtp", "rounds"}"""
    src, lim, trial = work / "narration.mix.wav", work / "narration.lim.wav", work / "narration.trial.m4a"
    shutil.copyfile(wav, src)
    want = PEAK_CEILING - PEAK_MARGIN
    limit, res = want - 0.6, None
    for rounds in range(1, 7):
        run([ff, "-y", "-v", "error", "-i", str(src), "-af",
             f"aresample={4 * SR},alimiter=limit={10 ** (limit / 20):.6f}:attack=5:release=50:level=false:latency=true,aresample={SR},apad,atrim=0:{seconds:.6f}",
             "-ar", str(SR), "-ac", "1", "-c:a", "pcm_s16le", str(lim)])
        run([ff, "-y", "-v", "error", "-i", str(lim), "-af", f"apad,atrim=0:{seconds:.6f}"] + AAC + ["-t", f"{seconds:.6f}", str(trial)])
        i_lufs, tp = measure_audio(ff, trial)
        res = {"true_peak_dbtp": tp, "integrated_lufs": i_lufs, "limiter_dbtp": round(limit, 2), "rounds": rounds}
        if tp is None or tp <= want + 0.05:           # no number: digital silence
            os.replace(lim, wav)
            for f in (src, trial):
                try: f.unlink()
                except OSError: pass
            (work / "audio_final.json").write_text(json.dumps(res), encoding="utf-8")
            return res
        limit -= (tp - want) + 0.1
    raise RuntimeError(f"the sound track could not be brought to {PEAK_CEILING:g} dBTP or below: it measures {res['true_peak_dbtp']} dBTP after {res['rounds']} rounds of limiting")


# ---- video -------------------------------------------------------------------------------------------
def watermark_slides(sb, work):
    """Draft builds: stamp every slide so a draft can never be mistaken for a final video."""
    from PIL import Image, ImageDraw, ImageFont
    out = work / "slides"
    out.mkdir(exist_ok=True)
    font = None
    for f in ("/System/Library/Fonts/Menlo.ttc", "/System/Library/Fonts/Helvetica.ttc", "/System/Library/Fonts/Supplemental/Arial Bold.ttf"):
        try:
            font = ImageFont.truetype(f, 24, index=1 if f.endswith("Menlo.ttc") else 0); break
        except Exception:
            continue
    font = font or ImageFont.load_default()
    label = "DRAFT VOICE"
    stamp = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    d = ImageDraw.Draw(stamp)
    tw = d.textlength(label, font=font)
    x1, y1 = W - 36, H - 26
    x0, y0 = x1 - tw - 36, y1 - 44
    if os.environ.get("VIDEO_NARRATOR") != "ai":      # narrated-by-voice final videos carry no stamp
        d.rounded_rectangle((x0, y0, x1, y1), radius=10, fill=(11, 13, 18, 215), outline=(227, 179, 65, 255), width=2)
        d.text((x0 + 18, y0 + 8), label, font=font, fill=(227, 179, 65, 255))

    def one(n):
        src = SLIDES / sb["id"] / f"{n:03d}.png"
        im = Image.open(src).convert("RGBA")
        if im.size != (W, H): im = im.resize((W, H))
        Image.alpha_composite(im, stamp).convert("RGB").save(out / f"{n:03d}.png", compress_level=1)
    with ThreadPoolExecutor(6) as ex:
        list(ex.map(one, sorted({b["slide"] for b in sb["beats"]})))
    return out


def frame_plan(sb, durs):
    """-> (list of (slide number, frames), beat start times, total frames).  Cuts fall on frame boundaries."""
    t, starts = LEAD, []
    seq = [(sb["beats"][0]["slide"], 0.0, LEAD)]
    for b, d in zip(sb["beats"], durs):
        starts.append(t)
        seq.append((b["slide"], t, t + d)); t += d
    plan, done = [], 0
    for n, a, e in seq:
        f1 = int(round(e * FPS))
        if f1 <= done: continue
        if plan and plan[-1][0] == n: plan[-1][1] += f1 - done
        else: plan.append([n, f1 - done])
        done = f1
    return plan, starts, done


def encode(ff, sb, slide_dir, plan, audio, out, total_frames, work):
    lst = work / "frames.txt"
    lines = ["ffconcat version 1.0"]
    for n, frames in plan:
        p = str(slide_dir / f"{n:03d}.png").replace("'", "'\\''")
        lines += [f"file '{p}'", f"duration {frames / FPS:.6f}"]
    p = str(slide_dir / f"{plan[-1][0]:03d}.png").replace("'", "'\\''")
    lines.append(f"file '{p}'")          # the concat demuxer needs the last picture named twice
    lst.write_text("\n".join(lines) + "\n", encoding="utf-8")
    total = total_frames / FPS
    seal_audio(ff, audio, total, work)
    tmp = out.with_suffix(".part.mp4")
    run([ff, "-y", "-v", "error", "-f", "concat", "-safe", "0", "-i", str(lst), "-i", str(audio),
         # colour conversion first (once per slide), then the frame-rate filter repeats the converted picture
         "-vf", f"scale={W}:{H}:flags=lanczos:out_color_matrix=bt709:out_range=tv,format=yuv420p,fps={FPS}", "-frames:v", str(total_frames),
         "-c:v", "libx264", "-preset", "veryfast", "-tune", "stillimage", "-crf", "20", "-g", str(FPS * 5), "-pix_fmt", "yuv420p",
         "-colorspace", "bt709", "-color_primaries", "bt709", "-color_trc", "bt709", "-color_range", "tv",
         "-r", str(FPS), "-video_track_timescale", "15360",
         "-af", f"apad,atrim=0:{total:.6f}"] + AAC + [
         "-t", f"{total:.6f}", "-movflags", "+faststart", str(tmp)])
    os.replace(tmp, out)


# ---- animated video ---------------------------------------------------------------------------------------
ZOOM_AMOUNT, ZOOM_PERIOD = 0.014, 20.0     # holds drift in by up to 1.4 % and back out, one cycle every 20 s
CHUNK = 360                                # frames per encoding job: long holds are cut up so that all cores stay busy
DISSOLVE = 8                               # frames of crossfade when the picture changes
X264 = ["-c:v", "libx264", "-preset", "veryfast", "-crf", "23", "-g", str(FPS * 5), "-pix_fmt", "yuv420p", "-threads", "2",
        "-colorspace", "bt709", "-color_primaries", "bt709", "-color_trc", "bt709", "-color_range", "tv", "-r", str(FPS), "-video_track_timescale", "15360"]
SFX = {   # name: (ffmpeg lavfi source, level).  Synthesised here; nothing is downloaded.  Kept far below the voice.
    "pop": ("aevalsrc='sin(2*PI*(420+760*exp(-t*38))*t)*exp(-t*34)':d=0.14:s=48000", 0.040),
    "tick": ("anoisesrc=d=0.03:c=white:a=0.9:r=48000:seed=7,highpass=f=1800,lowpass=f=5200,afade=t=out:st=0.002:d=0.026", 0.014),
    "whoosh": ("anoisesrc=d=0.34:c=pink:a=0.9:r=48000:seed=3,bandpass=f=1400:w=1100,afade=t=in:d=0.14,afade=t=out:st=0.14:d=0.2", 0.030),
}
MASCOT_X, MASCOT_Y = W - 170 + 14, H - 200 - 12     # top-left corner of the mascot sprite: the bottom-right margin


def sfx_samples(ff):
    d = CACHE / "sfx"
    d.mkdir(parents=True, exist_ok=True)
    out = {}
    for name, (src, level) in SFX.items():
        p = d / f"{name}-{sha1(src)[:8]}.wav"
        if not p.exists():
            run([ff, "-y", "-v", "error", "-f", "lavfi", "-i", src, "-ac", "1", "-ar", str(SR), "-c:a", "pcm_s16le", str(p)])
        out[name] = (read_wav(p), level)
    return out


def mix_sfx(ff, wav, events):
    """Add the reveal sounds to the (already normalised) narration.  events: [(seconds, name, gain)]"""
    if not events:
        return 0
    bank = sfx_samples(ff)
    a = read_wav(wav)
    last, n = {}, 0
    for t, name, gain in sorted(events):
        if name not in bank or t - last.get(name, -9) < 0.07: continue      # never a machine-gun of clicks
        last[name] = t
        smp, level = bank[name]
        o = int(t * SR)
        g = level * max(0.0, min(1.5, gain))
        for k in range(min(len(smp), len(a) - o)):
            v = a[o + k] + int(smp[k] * g)
            a[o + k] = 32767 if v > 32767 else (-32768 if v < -32768 else v)
        n += 1
    write_wav(wav, a)
    return n


def anim_timeline(sb, man, durs):
    """Put every cue of every beat on the frame timeline.
    -> segments [{"f": first frame, "n": frames, "clip": id, "m": frames of the clip used, "under": clip id or None, "g0": frame the zoom of
    this picture started, "beat": i}], total frames, sound events"""
    clips = man["clips"]
    t, start, events = LEAD, 0, []
    gstart, group = 0, None
    for b, pb, d in zip(sb["beats"], man["beats"], durs):
        t += d
        end = int(round(t * FPS))
        n = end - start
        busy = start
        for c in pb["cues"]:
            f = max(start + int(round(c["at"] * n)), busy)
            if f >= end and c["at"] > 0: f = max(start, end - 1)
            if pb["group"] != group:
                group, gstart = pb["group"], f
            events.append({"f": f, "clip": c["clip"], "dissolve": c["dissolve"], "g0": gstart, "beat": b["i"], "pose": c.get("pose")})
            busy = f + clips[c["clip"]]["frames"]
        start = end
    total = start
    segs, sounds = [], []
    events.sort(key=lambda e: e["f"])
    for k, e in enumerate(events):
        nxt = events[k + 1]["f"] if k + 1 < len(events) else total
        n = nxt - e["f"]
        if n <= 0:
            continue                                        # two cues on the same frame: the later picture wins
        m = clips[e["clip"]]["frames"]
        used = min(m, n)
        seg = dict(e, n=n, m=m, used=used, under=(segs[-1]["clip"] if (e["dissolve"] and segs) else None),
                   under_g0=(segs[-1]["g0"] if segs else 0))
        segs.append(seg)
        speed = used / m if m > used else 1.0              # a clip longer than its slot is played faster
        for st, name, gain in clips[e["clip"]].get("sfx", []):
            sounds.append(((e["f"] + st * FPS * speed) / FPS, name, gain))
    if segs and segs[0]["f"] > 0:
        segs[0]["n"] += segs[0]["f"]; segs[0]["f"] = 0
    return segs, total, sounds


def zoom_expr(g0, var):
    """Zoom factor as an ffmpeg expression of the frame counter: eases in and out, never jumps."""
    return f"1+{ZOOM_AMOUNT / 2:.5f}*(1-cos(2*PI*({var}+{g0})/{ZOOM_PERIOD * FPS:.1f}))"


def zoom_at(frames):
    return 1 + ZOOM_AMOUNT / 2 * (1 - math.cos(2 * math.pi * frames / (ZOOM_PERIOD * FPS)))


POSE_LINGER = 75                           # frames a cue's own pose stays after its clip (the worry at a destructive step)


def mascot_track(sb, man, durs, total, sprites, segs=()):
    """Which mascot sprite is on screen at every frame: pose from the beat, a hop when the pose changes, blinks now and then.
    A cue can carry a pose of its own (a destructive scene step): it lasts for the clip and a little longer, not for the whole beat.
    -> list of file paths (None = hidden), one per frame"""
    L, HOP = video_animate.MASCOT_LOOP, video_animate.MASCOT_HOP
    pose_at, t, start = [None] * total, LEAD, 0
    for pb, d in zip(man["beats"], durs):
        t += d
        end = min(total, int(round(t * FPS)))
        p = pb.get("pose", "curious")
        for f in range(start, end): pose_at[f] = None if p == "hidden" else p
        start = end
    for sg in segs:
        if sg.get("pose") in video_animate.POSES:
            for f in range(sg["f"], min(total, sg["f"] + sg["used"] + POSE_LINGER)):
                if pose_at[f] is not None: pose_at[f] = sg["pose"]
    track, since, phase = [], 0, 0
    seed = int(sha1(sb["id"])[:8], 16)
    next_blink = 70 + seed % 60
    blink_left = 0
    prev = None
    for f in range(total):
        p = pose_at[f]
        if p is None:
            track.append(None); prev = None; continue
        if p != prev:
            since, phase = 0, 0
        prev = p
        if since < HOP:
            idx = 3 * L + since
        else:
            if blink_left == 0 and f >= next_blink and p != "celebrate":
                blink_left = 5
            if blink_left:
                row = (1, 2, 2, 2, 1)[5 - blink_left]
                blink_left -= 1
                if blink_left == 0:
                    seed = (seed * 1103515245 + 12345) & 0x7FFFFFFF
                    next_blink = f + 75 + seed % 130       # every 2.5 to 7 seconds
            else:
                row = 0
            idx = row * L + phase % L
            phase += 1
        since += 1
        track.append(str(sprites / p / f"{idx:05d}.png"))
    return track


def encode_animated(ff, sb, man, durs, audio, out, work, stamp=None):
    """Clips + holds -> the finished MP4.  Every cue becomes one segment (its clip, then its last frame held with a slow zoom);
    segments are encoded side by side and joined without re-encoding."""
    segs, total, sounds = anim_timeline(sb, man, durs)
    cdir = video_animate.ANIM / sb["id"] / "clips"
    sprites = video_animate.mascot_sprites(sb["palette"])
    track = mascot_track(sb, man, durs, total, sprites, segs)
    blank = work / "blank.png"
    from PIL import Image
    Image.new("RGBA", (video_animate.MASCOT_W, video_animate.MASCOT_H), (0, 0, 0, 0)).save(blank)
    sdir = work / "seg"
    sdir.mkdir(exist_ok=True)

    jobs = []
    for k, sg in enumerate(segs):
        a = 0
        while a < sg["n"]:
            e = sg["n"] if sg["n"] - a <= CHUNK * 1.4 else a + CHUNK
            jobs.append((k, a, e)); a = e

    def one(job):
        k, a, e = job
        s = segs[k]
        n, m, used = e - a, s["m"], s["used"]
        cmd = [ff, "-y", "-v", "error", "-i", str(cdir / f"{s['clip']}.mp4")]
        fc = []
        v = "[0:v]"
        if a >= used:                                        # a later piece of a long hold: only the clip's last frame is needed
            fc.append(f"{v}trim=start_frame={m - 1},setpts=PTS-STARTPTS[lf]"); v = "[lf]"
            pick = f"trim=end_frame={n}"
        else:
            if m > used:                                     # squeeze the clip into its slot
                fc.append(f"{v}setpts=PTS*{used / m:.6f},fps={FPS}[sq]"); v = "[sq]"
            pick = f"trim=start_frame={a}:end_frame={e}"
        fc.append(f"{v}tpad=stop_mode=clone:stop=-1,{pick},setpts=PTS-STARTPTS,"
                  f"scale={2 * W}:{2 * H}:flags=bilinear,zoompan=z='{zoom_expr(s['f'] + a - s['g0'], 'in')}':x=0:y='ih-ih/zoom':d=1:s={W}x{H}:fps={FPS}[z]")
        v = "[z]"
        ix = 1
        if s["under"] and a == 0 and n > 2:                  # the picture before fades out over the new one
            cmd += ["-i", str(cdir / f"{s['under']}.mp4")]
            um = man["clips"][s["under"]]["frames"]
            z = zoom_at(s["f"] - s["under_g0"])
            d = min(DISSOLVE, n - 1)
            fc.append(f"[{ix}:v]trim=start_frame={um - 1},setpts=PTS-STARTPTS,tpad=stop_mode=clone:stop={d},trim=end_frame={d},"
                      f"scale={int(round(W * z / 2)) * 2}:-2:flags=bilinear,crop={W}:{H}:0:ih-{H},format=yuva420p,fade=t=out:st=0:d={d / FPS:.4f}:alpha=1[u]")
            fc.append(f"{v}[u]overlay=0:0:eof_action=pass[d]"); v = "[d]"
            ix += 1
        frames = track[s["f"] + a:s["f"] + e]
        if any(frames):
            lst = sdir / f"{k:04d}_{a:06d}.mascot.txt"
            lines, j = ["ffconcat version 1.0"], 0
            while j < len(frames):
                q = j
                while q + 1 < len(frames) and frames[q + 1] == frames[j]: q += 1
                lines += [f"file '{frames[j] or str(blank)}'", f"duration {(q - j + 1) / FPS:.6f}"]
                j = q + 1
            lines.append(f"file '{frames[-1] or str(blank)}'")
            lst.write_text("\n".join(lines) + "\n", encoding="utf-8")
            cmd += ["-f", "concat", "-safe", "0", "-i", str(lst)]
            fc.append(f"[{ix}:v]fps={FPS},format=rgba[m]")
            fc.append(f"{v}[m]overlay={MASCOT_X}:{MASCOT_Y}:eof_action=repeat[mm]"); v = "[mm]"
            ix += 1
        if stamp:
            cmd += ["-i", str(stamp)]
            fc.append(f"{v}[{ix}:v]overlay=0:0[st]"); v = "[st]"
            ix += 1
        fc.append(f"{v}format=yuv420p[out]")
        outp = sdir / f"{k:04d}_{a:06d}.mp4"
        cmd += ["-filter_complex", ";".join(fc), "-map", "[out]", "-frames:v", str(n)] + X264 + ["-an", str(outp)]
        run(cmd)
        return outp

    with ThreadPoolExecutor(max(2, (os.cpu_count() or 4) - 2)) as ex:
        files = list(ex.map(one, jobs))
    lst = work / "segments.txt"
    lst.write_text("ffconcat version 1.0\n" + "".join(f"file '{p}'\n" for p in files), encoding="utf-8")
    nsfx = mix_sfx(ff, audio, sounds)
    seconds = total / FPS
    seal_audio(ff, audio, seconds, work)                    # after the reveal sounds: the limit holds for the finished track
    tmp = out.with_suffix(".part.mp4")
    run([ff, "-y", "-v", "error", "-f", "concat", "-safe", "0", "-i", str(lst), "-i", str(audio), "-map", "0:v", "-map", "1:a", "-c:v", "copy",
         "-af", f"apad,atrim=0:{seconds:.6f}"] + AAC + ["-t", f"{seconds:.6f}",
         "-video_track_timescale", "15360", "-movflags", "+faststart", str(tmp)])
    os.replace(tmp, out)
    return {"segments": len(segs), "clips": len(man["clips"]), "clip_frames": sum(s["used"] for s in segs), "sound_effects": nsfx, "frames": total}


def draft_stamp(work):
    """The "DRAFT VOICE" label of preview builds as a transparent overlay (bottom left: the bottom right belongs to the mascot)."""
    from PIL import Image, ImageDraw, ImageFont
    font = None
    for f in ("/System/Library/Fonts/Menlo.ttc", "/System/Library/Fonts/Helvetica.ttc"):
        try:
            font = ImageFont.truetype(f, 24, index=1 if f.endswith("Menlo.ttc") else 0); break
        except Exception:
            continue
    font = font or ImageFont.load_default()
    im = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    tw = d.textlength("DRAFT VOICE", font=font)
    x0, y1 = 40, H - 26
    d.rounded_rectangle((x0, y1 - 44, x0 + tw + 36, y1), radius=10, fill=(11, 13, 18, 215), outline=(227, 179, 65, 255), width=2)
    d.text((x0 + 18, y1 - 36), "DRAFT VOICE", font=font, fill=(227, 179, 65, 255))
    p = work / "stamp.png"
    im.save(p)
    return p


# ---- subtitles and chapters -----------------------------------------------------------------------------
def srt_time(t):
    ms = int(round(t * 1000))
    return f"{ms // 3600000:02d}:{ms % 3600000 // 60000:02d}:{ms % 60000 // 1000:02d},{ms % 1000:03d}"


def two_lines(c):
    """One cue text -> the same text broken near its middle if it is longer than a 42-character line."""
    if len(c) > 42:
        mid, best = len(c) / 2, None
        for m in re.finditer(" ", c):
            if best is None or abs(m.start() - mid) < abs(best - mid): best = m.start()
        if best is not None and max(best, len(c) - best - 1) <= 60: c = c[:best] + "\n" + c[best + 1:]
    return c


def cue_chunks(text, limit=84):
    """Split narration into subtitle cues of at most two 42-character lines."""
    words_, cues, cur = text.split(), [], ""
    for w in words_:
        if cur and len(cur) + 1 + len(w) > limit:
            cues.append(cur); cur = w
        else:
            cur = (cur + " " + w).strip()
            if re.search(r"[.?!][\"”)]?$", w) and len(cur) > limit * 0.6:
                cues.append(cur); cur = ""
    if cur: cues.append(cur)
    return [two_lines(c) for c in cues]


CUE_GAP = 0.04             # seconds between the end of a cue and the start of the next
CUE_MIN = 0.20             # a cue that would be shorter than this once it is cut back to make room for the next one is joined to that one


def srt_cues(sb, starts, durs, tail=0.0):
    """The subtitle cues of a video -> [[start ms, end ms, text], ...], in order and never overlapping.
    Cue times are spread over a beat in proportion to the text.  A beat gets at least 0.4 s; where that is more than the beat
    has (a narration beat of a few frames), the cue ends where the next one starts, or is joined to it."""
    raw = []
    for b, t0, d in zip(sb["beats"], starts, durs):
        if b["type"] != "narration": continue
        cues = cue_chunks(b["text"])
        span = max(0.4, d - tail)
        total = sum(len(c) for c in cues) or 1
        t = t0
        for c in cues:
            dt = span * len(c) / total
            raw.append([int(round(t * 1000)), int(round((t + dt - CUE_GAP) * 1000)), c])
            t += dt
    out, gap = [], int(round(CUE_GAP * 1000))
    for k, c in enumerate(raw):
        if out and c[0] < out[-1][0]: c[0] = out[-1][0]              # never before the cue before it
        if k + 1 < len(raw):
            nxt = raw[k + 1]
            if c[1] > nxt[0] - gap or nxt[0] <= c[0]:                # it would still be shown when the next one starts
                if nxt[0] - gap - c[0] < CUE_MIN * 1000:             # ... and has no room of its own: one cue for both texts
                    nxt[0], nxt[2] = c[0], two_lines(c[2].replace("\n", " ") + " " + nxt[2].replace("\n", " "))
                    continue
                c[1] = nxt[0] - gap
        if out and out[-1][1] > c[0]: out[-1][1] = c[0]
        if c[1] <= c[0]: c[1] = c[0] + 1
        out.append(c)
    return out


def write_srt(sb, starts, durs, path, tail=0.0):
    cues = srt_cues(sb, starts, durs, tail)
    lines = []
    for n, (a, e, c) in enumerate(cues, 1):
        lines += [str(n), f"{srt_time(a / 1000)} --> {srt_time(e / 1000)}", c, ""]
    path.write_text("\n".join(lines), encoding="utf-8")
    return len(cues)


def chapter_time(t):
    t = int(t)
    return f"{t // 3600}:{t % 3600 // 60:02d}:{t % 60:02d}" if t >= 3600 else f"{t // 60}:{t % 60:02d}"


SECTION_TITLES = {"HOOK": "Hook", "INTRODUCTION": "Introduction", "LEARNING OBJECTIVES": "Learning objectives", "CONCEPT": "Concept",
                  "MENTAL MODEL": "Mental model", "DIAGRAM": "Diagram", "LIVE TERMINAL DEMO": "Live terminal demo",
                  "COMMON MISTAKES": "Common mistakes", "PRODUCTION EXAMPLE": "Production example", "PRACTICE EXERCISE": "Practice exercise",
                  "INTERVIEW QUESTION": "Interview question", "RECAP": "Recap", "HOMEWORK": "Homework"}


def write_chapters(sb, starts, total, path):
    """YouTube chapters: first at 0:00, at least 10 seconds each, ascending."""
    ch = []
    for k, s in enumerate(sb["sections"]):
        t = 0.0 if k == 0 else starts[s["beat"]]
        name = SECTION_TITLES.get(s["name"], s["name"].capitalize())
        if ch and (int(t) - int(ch[-1][0]) < 10):
            ch[-1] = (ch[-1][0], ch[-1][1] + " · " + name)         # too short to stand alone: joined to the previous chapter
        else:
            ch.append((t, name))
    while len(ch) > 1 and total - ch[-1][0] < 10:
        last = ch.pop(); ch[-1] = (ch[-1][0], ch[-1][1] + " · " + last[1])
    path.write_text("\n".join(f"{chapter_time(t)} {n}" for t, n in ch) + "\n", encoding="utf-8")
    return len(ch)


# ---- one video ---------------------------------------------------------------------------------------------
def probe(fp, path):
    r = run([fp, "-v", "error", "-print_format", "json", "-show_streams", "-show_format", str(path)])
    j = json.loads(r.stdout)
    v = next(s for s in j["streams"] if s["codec_type"] == "video")
    a = next(s for s in j["streams"] if s["codec_type"] == "audio")
    return {"width": v["width"], "height": v["height"], "fps": v["r_frame_rate"], "vcodec": v["codec_name"], "acodec": a["codec_name"],
            "pix_fmt": v.get("pix_fmt"), "video_seconds": float(v["duration"]), "audio_seconds": float(a["duration"]),
            "frames": int(v.get("nb_frames", 0)), "sample_rate": int(a["sample_rate"]), "size_bytes": int(j["format"]["size"]),
            "faststart": None}


def is_faststart(path):
    """True when the 'moov' box comes before 'mdat' (the file can start playing while it downloads)."""
    with open(path, "rb") as f:
        pos, size = 0, os.path.getsize(path)
        while pos < size:
            f.seek(pos); head = f.read(16)
            if len(head) < 8: break
            n, kind = int.from_bytes(head[:4], "big"), head[4:8]
            if n == 1: n = int.from_bytes(head[8:16], "big")
            if kind == b"moov": return True
            if kind == b"mdat": return False
            if n < 8: break
            pos += n
    return False


def outputs(vid, draft):
    tag = ".draft" if (draft and os.environ.get("VIDEO_NARRATOR") != "ai") else ""
    return OUT / f"{vid}{tag}.mp4", OUT / f"{vid}{tag}.srt", OUT / f"{vid}{tag}.chapters.txt", OUT / f"{vid}{tag}.build.json"


def inputs_mtime(vid, draft):
    deps = [STORYBOARDS / f"{vid}.json", SLIDES / vid / "manifest.json"]
    if video_animate is not None: deps.append(video_animate.manifest_path(vid))
    if not draft:
        deps += list(RECORDINGS.glob(f"{vid}.*"))
    return max((p.stat().st_mtime for p in deps if p.exists()), default=0)


def up_to_date(vid, draft):
    mp4, srt, chap, rep = outputs(vid, draft)
    if not all(p.exists() for p in (mp4, srt, chap, rep)): return False
    try:
        if json.loads(rep.read_text()).get("build_version") != BUILD_VERSION: return False
    except Exception:
        return False
    return mp4.stat().st_mtime >= inputs_mtime(vid, draft)


def prepare(vid):
    """Make sure the storyboard and the slides are current."""
    here = pathlib.Path(__file__).resolve().parent
    import video_storyboard
    if not video_storyboard.up_to_date(vid):
        subprocess.run([sys.executable, str(here / "video_storyboard.py"), vid], check=True, stdout=subprocess.DEVNULL)
    subprocess.run([sys.executable, str(here / "video_slides.py"), vid], check=True, stdout=subprocess.DEVNULL)
    sb = load_storyboard(vid)
    miss = [s["n"] for s in sb["slides"] if not (SLIDES / vid / f"{s['n']:03d}.png").exists()]
    if miss:
        raise SystemExit(f"{vid}: {len(miss)} slide image(s) are missing; run: video/production/make.sh slides {vid}")
    return sb


def build_one(vid, draft, opts):
    ff, fp = (find_tool("ffmpeg"), find_tool("ffprobe")) if opts.get("no_encode") else need_ffmpeg()
    t_start = time.time()
    sb = prepare(vid)
    mp4, srt, chap, rep = outputs(vid, draft)
    OUT.mkdir(parents=True, exist_ok=True)
    work = CACHE / "build" / f"{vid}{'.draft' if draft else ''}"
    shutil.rmtree(work, ignore_errors=True)
    work.mkdir(parents=True)
    try:
        raw, durs, info = assemble_audio(sb, "draft" if draft else "final", work, ff, opts)
        plan, starts, total_frames = frame_plan(sb, durs)
        total = total_frames / FPS
        if opts.get("no_encode"):
            # everything except ffmpeg's part: cut list, subtitles, chapters
            ncues = write_srt(sb, starts, durs, srt, DRAFT_GAP if draft else 0.0)
            nch = write_chapters(sb, starts, total, chap)
            (work / "plan.json").write_text(json.dumps({"seconds": total, "frames": total_frames, "plan": plan, "starts": starts,
                                                         "durations": durs, "audio": info}, indent=1), encoding="utf-8")
            print(f"{vid}: not encoded (--no-encode). Planned length {fmt_dur(total)}, {len(plan) - 1} cuts, {ncues} subtitle cues, "
                  f"{nch} chapters. Narration: {rel(raw)}", flush=True)
            return True
        norm = work / "narration.wav"
        meas = loudnorm(ff, raw, norm, total)
        anim = None
        if video_animate is not None and not opts.get("no_anim") and video_animate.is_animated(vid):
            # the video has an animation layer (video/production/make.sh animate): bring its clips up to date and use them
            man, _, problems = video_animate.animate(vid, quiet=True)
            if problems or not man.get("complete") or len(man["beats"]) != len(sb["beats"]):
                print(f"  {vid}: the animation is incomplete ({len(problems)} clip(s) failed); building with still slides instead", flush=True)
            else:
                stamp = draft_stamp(work) if (draft and os.environ.get("VIDEO_NARRATOR") != "ai") else None
                anim = encode_animated(ff, sb, man, durs, norm, mp4, work, stamp)
        if anim is None:
            slide_dir = watermark_slides(sb, work) if draft else SLIDES / vid
            encode(ff, sb, slide_dir, plan, norm, mp4, total_frames, work)
        ncues = write_srt(sb, starts, durs, srt, DRAFT_GAP if draft else 0.0)
        nch = write_chapters(sb, starts, total, chap)
        pr = probe(fp, mp4)
        pr["faststart"] = is_faststart(mp4)
        try: info["final"] = json.loads((work / "audio_final.json").read_text())      # what seal_audio() measured on the encoded track
        except Exception: pass
        if anim and pr["frames"] != total_frames:
            print(f"  {vid}: the animated video has {pr['frames']} frames, expected {total_frames}", flush=True)
        ok = (not anim or pr["frames"] == total_frames) and (pr["width"], pr["height"]) == (W, H) and pr["fps"] in (f"{FPS}/1", str(FPS)) and pr["vcodec"] == "h264" and pr["acodec"] == "aac" \
            and abs(pr["video_seconds"] - pr["audio_seconds"]) <= 0.1 and pr["faststart"]
        report = {"id": vid, "build_version": BUILD_VERSION, "draft": draft, "title": sb["title"], "seconds": round(total, 3), "beats": len(durs),
                  "slides_used": len({n for n, _ in plan}), "cuts": len(plan) - 1, "subtitle_cues": ncues, "chapters": nch,
                  "input_loudness_lufs": (meas or {}).get("input_i"), "audio": info, "probe": pr, "checks_passed": ok, "animated": bool(anim), "animation": anim, "beat_starts": [round(x, 2) for x in starts],
                  "built_in_seconds": round(time.time() - t_start, 1), "script_sha1": sb["script_sha1"]}
        rep.write_text(json.dumps(report, indent=1), encoding="utf-8")
        print(f"{vid}: {mp4.name}  {fmt_dur(total)}  {pr['size_bytes'] / 1e6:.1f} MB  {pr['width']}x{pr['height']} {pr['fps']} fps {pr['vcodec']}/{pr['acodec']}"
              f"  video {pr['video_seconds']:.3f} s, audio {pr['audio_seconds']:.3f} s  faststart={'yes' if pr['faststart'] else 'NO'}"
              f"  {'animated' if anim else 'stills'}  {'OK' if ok else 'CHECK FAILED'}  (built in {time.time() - t_start:.0f} s)", flush=True)
        if not draft and info.get("takes_seconds"):
            print(f"      recording {fmt_dur(info['takes_seconds'])} -> kept {fmt_dur(info['kept_seconds'])}; "
                  f"{len(info['missing_beats'])} beat(s) missing")
        return ok
    finally:
        if not opts.get("keep_temp"):
            shutil.rmtree(work, ignore_errors=True)


def main():
    argv = sys.argv[1:]
    if "--speech-selftest" in argv:        # text only: nothing is spoken, rendered or built
        bad = speech_selftest()
        print("\n".join("FAIL  " + x for x in bad) if bad else f"speech self-test: {len(SPEECH_CASES)} sentences, prose, the voice cache key, the voice's pace bounds and splitting, subtitle cues: all correct")
        return 1 if bad else 0
    if "--audio-selftest" in argv:         # a synthetic track through the last steps of the sound: nothing is spoken, no video is built
        bad, note = audio_selftest()
        print("\\n".join("FAIL  " + x for x in bad) if bad else f"audio self-test: true peak at or below {PEAK_CEILING:g} dBTP, loudness kept: correct")
        print("  " + note)
        return 1 if bad else 0
    opts = {"allow_missing": "--allow-missing" in argv, "keep_temp": "--keep-temp" in argv or "--no-encode" in argv,
            "no_encode": "--no-encode" in argv, "no_anim": "--no-anim" in argv}
    for flag in ("--voice", "--rate"):
        if flag in argv:
            k = argv.index(flag); opts[flag[2:]] = argv[k + 1]; del argv[k:k + 2]
    draft, force = "--draft" in argv, "--force" in argv
    args = [a for a in argv if not a.startswith("--")]
    if not args:
        print(__doc__); return 2
    explicit = "all" not in args
    if draft:
        have = all_script_ids
    else:
        have = lambda: sorted({p.name[:4] for p in RECORDINGS.glob("V[0-9][0-9][0-9].timing.json")})
    ids = expand_ids(args, have=have)
    if not ids:
        print("nothing to build" + ("" if draft else ": no recordings in video/production/recordings/"))
        return 0
    if not opts["no_encode"]:
        need_ffmpeg()
    built = skipped = failed = 0
    for vid in ids:
        if not force and not explicit and up_to_date(vid, draft):
            skipped += 1; continue
        try:
            ok = build_one(vid, draft, opts)
            built += 1
            if not ok: failed += 1
        except SystemExit as e:
            print(e); failed += 1
        except Exception as e:
            print(f"{vid}: FAILED: {e}"); failed += 1
    print(f"{'drafts' if draft else 'videos'}: {built} built, {skipped} up to date, {failed} with problems")
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main())
