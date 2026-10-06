#!/usr/bin/env python3
"""Table of the production state of every video.

    python3 tools/video_status.py            all videos
    python3 tools/video_status.py V008 V040  some videos
    python3 tools/video_status.py --todo     only videos that are not finished
"""
import json, sys

sys.path.insert(0, str(__import__("pathlib").Path(__file__).resolve().parent))
from video_common import *   # noqa: F401,F403
import video_takes


def row(vid):
    r = {"id": vid, "script": bool(script_path(vid)), "story": "-", "slides": "-", "anim": "-", "rec": "-", "draft": "-", "final": "-", "est": "", "dur": "", "note": ""}
    sp = STORYBOARDS / f"{vid}.json"
    sb = None
    if sp.exists():
        try:
            sb = json.loads(sp.read_text(encoding="utf-8"))
            src = script_path(vid)
            fresh = src and sb.get("script_sha1") == sha1(src.read_text(encoding="utf-8"))
            r["story"] = "yes" if fresh else "old"
            r["est"] = fmt_dur(sb["est_seconds"])
        except Exception:
            r["story"] = "bad"
    if sb:
        mp = SLIDES / vid / "manifest.json"
        if mp.exists():
            have = len(list((SLIDES / vid).glob("[0-9][0-9][0-9].png")))
            r["slides"] = str(have) if have == len(sb["slides"]) else f"{have}/{len(sb['slides'])}"
        ap = ANIM / vid / "anim.json"
        if ap.exists():
            try:
                am = json.loads(ap.read_text(encoding="utf-8"))
                r["anim"] = str(len(am["clips"])) if am.get("complete") and am.get("script_sha1") == sb.get("script_sha1") else "old"
            except Exception:
                r["anim"] = "bad"
        timing = video_takes.load_timing(vid)
        if timing and timing.get("takes"):
            use, stale, missing = video_takes.resolve(sb, timing)
            n = sum(1 for b in sb["beats"] if b["type"] == "narration")
            r["rec"] = "yes" if not missing else f"{n - len(missing)}/{n}"
            if stale: r["note"] = f"{len(stale)} beats changed since recording"
    for key, tag in (("draft", ".draft"), ("final", "")):
        mp4, rep = OUT / f"{vid}{tag}.mp4", OUT / f"{vid}{tag}.build.json"
        if mp4.exists():
            r[key] = "yes"
            try:
                j = json.loads(rep.read_text())
                r[key] = fmt_dur(j["seconds"])
                if not j.get("checks_passed"): r["note"] = (r["note"] + " " + key + " failed its checks").strip()
                if sb and j.get("script_sha1") != sb.get("script_sha1"): r[key] += "*"
            except Exception:
                pass
    return r


def main():
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    ids = expand_ids(args) if args else sorted(set(all_script_ids()) | {p.stem for p in STORYBOARDS.glob("V[0-9][0-9][0-9].json")})
    rows = [row(v) for v in ids]
    if "--todo" in sys.argv:
        rows = [r for r in rows if r["final"] == "-"]
    print(f"{'video':6} {'script':6} {'storyboard':10} {'slides':>7} {'anim':>5} {'recording':>9} {'draft':>8} {'final':>8} {'estimate':>8}  note")
    for r in rows:
        print(f"{r['id']:6} {'yes' if r['script'] else '-':6} {r['story']:10} {r['slides']:>7} {r['anim']:>5} {r['rec']:>9} {r['draft']:>8} {r['final']:>8} {r['est']:>8}  {r['note']}")
    n = len(rows)
    c = lambda k: sum(1 for r in rows if r[k] not in ("-", "old", "bad"))
    print(f"\n{n} videos: {sum(1 for r in rows if r['script'])} scripts, {c('story')} storyboards, {c('slides')} with slides, "
          f"{c('rec')} with a recording, {c('draft')} drafts, {c('final')} finished")
    print("anim = animation clips of the video (old: the script changed; the next build renders the missing ones); "
          "recording a/b = beats recorded so far; a duration with * was built from an older version of the script; estimate = at 150 words per minute")
    return 0


if __name__ == "__main__":
    sys.exit(main())
