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

What happens: the retakes and pauses logged by the booth are cut out of the recording, every beat's slide is shown for
exactly as long as the narrator spent on that beat, the thumbnail (or title card) is shown for one second first,
and the sound is normalised to about -16 LUFS.
"""
import os
import array, json, math, os, re, shutil, subprocess, sys, time, wave
from concurrent.futures import ThreadPoolExecutor

sys.path.insert(0, str(__import__("pathlib").Path(__file__).resolve().parent))
from video_common import *   # noqa: F401,F403
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
            "LAB": "lab", "eval": "eval", "evals": "evals"}
REF_HEADS = ("origin", "upstream", "refs", "heads", "tags", "remotes", "feature", "feat", "fix", "hotfix", "release", "bugfix", "pull", "HEAD")
NOT_PATHS = {"and/or", "either/or", "i/o", "ci/cd", "n/a", "read/write", "yes/no", "true/false", "client/server", "he/she", "km/h", "24/7", "tcp/ip"}
NUM_WORD = {"0": "zero", "1": "one", "2": "two", "3": "three", "4": "four", "5": "five", "6": "six", "7": "seven", "8": "eight", "9": "nine", "10": "ten"}


def _say_token(w):
    """One word-like piece (letters, digits, _ and -) as it should be said."""
    if w in SAY_WORD: return SAY_WORD[w]
    if "_" in w: return " ".join(_say_token(x) for x in w.split("_") if x)
    if re.fullmatch(r"[a-z]+[A-Z][A-Za-z]*", w): return re.sub(r"(?<=[a-z])(?=[A-Z])", " ", w)          # camelCase config keys
    return w


def _say_path(m):
    """labs/shell -> labs slash shell     origin/main, refs/heads/main -> origin main, refs heads main"""
    tok = m.group(0)
    end = ""
    while tok and tok[-1] in ".-": tok, end = tok[:-1], tok[-1] + end     # a full stop after a path is the sentence's
    return _say_path_tok(tok) + end


def _say_path_tok(tok):
    if tok.lower() in NOT_PATHS or re.fullmatch(r"\d+/\d+", tok):
        return tok
    parts = [p for p in tok.split("/")]
    lead = tok.startswith("/")
    refish = parts[0] in REF_HEADS and not lead and "." not in tok
    pathish = lead or tok.count("/") >= 2 or bool(re.search(r"[._$~\d-]", tok)) or parts[0] in ("labs", "textbook", "video", "tools", "src", "docs", "config", "prompts", "tests", "home", "usr", "bin", "etc", "tmp")
    if not (refish or pathish):
        return tok
    said = [_say_dotted(p) for p in parts if p]
    return (" " if refish else " slash ").join(said) if said else tok


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


def speakable(text):
    """Text for the computer voice.  It changes only what is SPOKEN (subtitles and slides keep the script's spelling):
    symbols and Git spellings the synthesiser reads badly are written out, and PAUSE marks short silences."""
    t = re.sub("[\U0001F7E0-\U0001F7EB\U0001F534\U0001F535✅❌⚠️]", " ", text)
    t = re.sub(r"<([A-Za-z0-9_ -]+)>", r"\1", t)
    t = t.replace("…", ". ").replace("→", " to ").replace("·", ", ").replace("`", "").replace("↪", " ")
    t = re.sub(r"\be\.g\.,?", "for example,", t); t = re.sub(r"\bi\.e\.,?", "that is,", t)
    # list prefixes: "Root cause: ..." gets a breath before and after
    t = re.sub(r"(?<=[.!?\"”)])\s+(Root cause|Fix|Prevention|Mechanism|Symptom|Diagnosis|Correct fix)\s*:\s*", lambda m: f" {PAUSE} {m.group(1)}. {PAUSE} ", t)
    t = re.sub(r"^(Root cause|Fix|Prevention|Mechanism|Symptom|Diagnosis|Correct fix)\s*:\s*", lambda m: f"{m.group(1)}. {PAUSE} ", t)
    # object IDs: "commit" and the first four characters, spelled out
    def oid(m):
        h = m.group(2)
        if not (re.search(r"[a-f]", h) and re.search(r"\d", h)): return m.group(0)
        four = " ".join(h[:4])
        return (m.group(1) or "") + (four if m.group(1) else "commit " + four)
    t = re.sub(r"(\b[Cc]ommits?\s+|\b[Tt]ree\s+|\b[Bb]lob\s+|\b[Tt]ag\s+|\bID\s+|\band\s+(?=[0-9a-f]{7}\b))?\b([0-9a-f]{7,40})\b", oid, t)
    # ranges and revision suffixes
    t = re.sub(r"(?<=[\w)}/])\.\.\.(?=[\w/@{(])", " three dots ", t)
    t = re.sub(r"(?<=[\w)}/])\.\.(?=[\w/@{(])", " two dots ", t)
    t = re.sub(r"@\{(\d+)\}", lambda m: " at " + NUM_WORD.get(m.group(1), m.group(1)), t)
    t = re.sub(r"@\{([^}]+)\}", r" at \1", t)
    t = re.sub(r"(?<=\w)~(\d+)", lambda m: " tilde " + NUM_WORD.get(m.group(1), m.group(1)), t)
    t = re.sub(r"(?<=\w)~", " tilde", t); t = t.replace("~/", "home slash ")
    t = re.sub(r"(?<=\w)\^(\d+)", lambda m: " caret " + NUM_WORD.get(m.group(1), m.group(1)), t)
    t = re.sub(r"(?<=\w)\^(?!\w)", " caret", t)
    # options: --force-with-lease -> dash dash force with lease     -m -> dash m
    t = re.sub(r"(?<![\w-])--([A-Za-z][\w-]*)(=?)", lambda m: "dash dash " + " ".join(_say_token(x) for x in m.group(1).split("-") if x) + (" equals " if m.group(2) else ""), t)
    t = re.sub(r"(?<![\w-])-([A-Za-z0-9]{1,2})(?![\w-])", lambda m: "dash " + " ".join(m.group(1)) if not m.group(1).isdigit() else "dash " + m.group(1), t)
    t = t.replace("$LAB", "lab").replace("$HOME", "home").replace("&&", " and ").replace("->", " points to ").replace("=>", " gives ")
    t = re.sub(r"\*\.(\w+)", lambda m: "star dot " + SAY_EXT.get(m.group(1).lower(), m.group(1)), t)
    t = re.sub(r"(?<!\w)#(\d+)", r"number \1", t)
    # paths and refs, then dotted names, then single words
    t = re.sub(r"(?<![\w.])/?[\w.$~-]+(?:/[\w.$~*-]+)+/?", _say_path, t)
    t = re.sub(r"(?<![\w/])\.[A-Za-z][\w-]*(?:\.[A-Za-z]\w*)*", lambda m: _say_dotted(m.group(0)), t)                      # .git  .gitignore
    t = re.sub(r"\b[A-Za-z][\w-]*(?:\.[A-Za-z][\w-]*)+\b", lambda m: _say_dotted(m.group(0)), t)                           # README.md  user.name
    t = re.sub(r"\bSHA-?(\d+)", r"shah \1", t)
    t = re.sub(r"\b[A-Za-z][A-Za-z0-9]*(?:_[A-Za-z0-9]+)*\b", lambda m: _say_token(m.group(0)), t)
    t = re.sub(r"\s+", " ", t).strip()
    t = re.sub(rf"\s*{PAUSE}(\s*{PAUSE})*\s*", f" {PAUSE} ", t).strip()
    return t


def spoken_chunks(sb, b):
    """What the voice is given for one beat: [text or seconds of silence, ...].  A list that is read in one beat gets a
    breath between its items; PAUSE marks from speakable() become short silences."""
    pieces = [b["text"]]
    slide = next((s for s in sb["slides"] if s["n"] == b["slide"]), None)
    if slide and slide.get("kind") == "bullets" and len(slide.get("items", [])) >= 2:
        items = [re.sub(r"\s+", " ", html_unescape(re.sub(r"<[^>]+>", "", it))).strip().rstrip(".;") + "." for it in slide["items"]]
        if re.sub(r"\s+", " ", " ".join(items)) == re.sub(r"\s+", " ", b["text"]).strip():
            pieces = items
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


def tts(spoken, voice, rate):
    """Speak one piece of already prepared text (see speakable) with the macOS voice -> cached 48 kHz mono WAV path."""
    d = CACHE / "tts"
    d.mkdir(parents=True, exist_ok=True)
    p = d / f"{sha1(f'{voice}|{rate}|{spoken}')}.wav"
    if p.exists() and p.stat().st_size > 44:
        return p
    tmp = p.with_suffix(f".{os.getpid()}.{id(spoken) % 100000}.tmp.wav")
    # The macOS synthesiser now and then hangs on one paragraph and never returns.  A paragraph takes a few seconds, so after
    # two minutes the attempt is abandoned and repeated; three attempts, then the build of this video fails with a clear message.
    err = ""
    for attempt in range(3):
        try:
            r = subprocess.run(["say", "-v", voice, "-r", str(rate), "-o", str(tmp), f"--data-format=LEI16@{SR}", "--", spoken],
                               capture_output=True, text=True, timeout=120)
        except subprocess.TimeoutExpired:
            err = "say did not finish within 120 s"
            try: tmp.unlink()
            except OSError: pass
            continue
        if r.returncode == 0 and tmp.exists() and tmp.stat().st_size > 44:
            os.replace(tmp, p)
            return p
        err = r.stderr.strip()[:300] or "no sound file was written"
    raise RuntimeError(f"say failed: {err}")


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
    """Two-pass EBU R128 normalisation to -16 LUFS (true peak -1.5 dB)."""
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
    tmp = out.with_suffix(".part.mp4")
    run([ff, "-y", "-v", "error", "-f", "concat", "-safe", "0", "-i", str(lst), "-i", str(audio),
         # colour conversion first (once per slide), then the frame-rate filter repeats the converted picture
         "-vf", f"scale={W}:{H}:flags=lanczos:out_color_matrix=bt709:out_range=tv,format=yuv420p,fps={FPS}", "-frames:v", str(total_frames),
         "-c:v", "libx264", "-preset", "veryfast", "-tune", "stillimage", "-crf", "20", "-g", str(FPS * 5), "-pix_fmt", "yuv420p",
         "-colorspace", "bt709", "-color_primaries", "bt709", "-color_trc", "bt709", "-color_range", "tv",
         "-r", str(FPS), "-video_track_timescale", "15360",
         "-af", f"apad,atrim=0:{total:.6f}", "-c:a", "aac", "-b:a", "160k", "-ar", str(SR), "-ac", "1",
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
    tmp = out.with_suffix(".part.mp4")
    run([ff, "-y", "-v", "error", "-f", "concat", "-safe", "0", "-i", str(lst), "-i", str(audio), "-map", "0:v", "-map", "1:a", "-c:v", "copy",
         "-af", f"apad,atrim=0:{seconds:.6f}", "-c:a", "aac", "-b:a", "160k", "-ar", str(SR), "-ac", "1", "-t", f"{seconds:.6f}",
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
    out = []
    for c in cues:
        if len(c) > 42:
            mid, best = len(c) / 2, None
            for m in re.finditer(" ", c):
                if best is None or abs(m.start() - mid) < abs(best - mid): best = m.start()
            if best is not None and max(best, len(c) - best - 1) <= 60: c = c[:best] + "\n" + c[best + 1:]
        out.append(c)
    return out


def write_srt(sb, starts, durs, path, tail=0.0):
    n, lines = 0, []
    for b, t0, d in zip(sb["beats"], starts, durs):
        if b["type"] != "narration": continue
        cues = cue_chunks(b["text"])
        span = max(0.4, d - tail)
        total = sum(len(c) for c in cues) or 1
        t = t0
        for c in cues:
            dt = span * len(c) / total
            n += 1
            lines += [str(n), f"{srt_time(t)} --> {srt_time(t + dt - 0.04)}", c, ""]
            t += dt
    path.write_text("\n".join(lines), encoding="utf-8")
    return n


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
