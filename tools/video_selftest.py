#!/usr/bin/env python3
"""Check the recording booth and the builder without a human and without a microphone.

    python3 tools/video_selftest.py          uses V008
    python3 tools/video_selftest.py V040

What it proves:
  1. the retake / pause / go-back logic that decides which audio is kept (pure logic, exact numbers);
  2. the booth server: page, slides, state, refusal of requests that do not come from the page, saving a take;
  3. the booth page in headless Chrome with a SYNTHETIC microphone (a tone made in the page; the real microphone is
     never requested): MediaRecorder records it, the page reacts to Space / Left / P / Up, saves a real .webm through
     the server, and reports no JavaScript error;
  4. the builder on a synthetic recording of the whole video that contains a retake, a pause, a go-back and a second
     take for one section: every sample of discarded audio must be gone and every beat must carry its own audio;
  5. if ffmpeg is installed: the MP4 itself (1920x1080, 30 fps, H.264 + AAC, audio and video equally long, faststart);
  6. the animation layer (tools/video_animtest.py): graph parser, tags, scene library, repeatable frames, frame counts of
     every clip, the timeline, and an animated MP4 whose length equals its audio within a tenth of a second.

Nothing here touches video/production/recordings or video/production/out: the test works in video/production/.cache/selftest.
It does NOT prove that a real microphone works in your browser; only a person can do that (see the README).
"""
import array, json, math, os, shutil, socket, subprocess, sys, time, urllib.request, wave

sys.path.insert(0, str(__import__("pathlib").Path(__file__).resolve().parent))
TEST = __import__("pathlib").Path(__file__).resolve().parent.parent / "video" / "production" / ".cache" / "selftest"
os.environ["VIDEO_RECORDINGS_DIR"] = str(TEST / "recordings")
os.environ["VIDEO_OUT_DIR"] = str(TEST / "out")
from video_common import *   # noqa: E402,F401,F403
import video_takes           # noqa: E402

SR = 48000
results = []


def check(name, ok, detail=""):
    results.append(ok)
    print(f"  {'PASS' if ok else 'FAIL'}  {name}" + (f"   [{detail}]" if detail else ""), flush=True)
    return ok


def free_port():
    s = socket.socket(); s.bind(("127.0.0.1", 0)); p = s.getsockname()[1]; s.close(); return p


def fetch(url, data=None, headers=None):
    req = urllib.request.Request(url, data=data, headers=headers or {}, method="POST" if data is not None else "GET")
    try:
        with urllib.request.urlopen(req, timeout=20) as r:
            return r.status, r.read()
    except urllib.error.HTTPError as e:
        return e.code, e.read()


def tone(seconds, amp, freq=440.0):
    n = int(round(seconds * SR))
    return array.array("h", (int(amp * math.sin(2 * math.pi * freq * k / SR)) for k in range(n)))


def main():
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    vid = vid_norm(args[0]) if args else "V008"
    here = pathlib.Path(__file__).resolve().parent
    shutil.rmtree(TEST, ignore_errors=True)
    (TEST / "recordings").mkdir(parents=True); (TEST / "out").mkdir(parents=True)

    print("1. cut logic")
    ev = [{"t": 3.0, "type": "begin", "beat": 0}, {"t": 5.0, "type": "advance", "beat": 0, "next": 1},
          {"t": 6.5, "type": "advance", "beat": 1, "next": 2}, {"t": 8.0, "type": "retake", "beat": 2},
          {"t": 9.0, "type": "retake", "beat": 2}, {"t": 12.0, "type": "advance", "beat": 2, "next": 3},
          {"t": 13.0, "type": "pause", "beat": 3}, {"t": 20.0, "type": "resume", "beat": 3},
          {"t": 24.0, "type": "advance", "beat": 3, "next": 4}, {"t": 25.0, "type": "goto", "beat": 3},
          {"t": 29.0, "type": "advance", "beat": 3, "next": 4}, {"t": 31.0, "type": "finish", "beat": 4, "complete": True}]
    segs, disc = video_takes.segments_from_events(ev)
    want = [(0, 3.0, 5.0), (1, 5.0, 6.5), (2, 9.0, 12.0), (3, 25.0, 29.0), (4, 29.0, 31.0)]
    check("retake, pause, go-back: the right stretches are kept", [(s["beat"], s["start"], s["end"]) for s in segs] == want, f"{disc} stretches cut")
    segs2, _ = video_takes.segments_from_events(ev[:-1] + [{"t": 31.0, "type": "pause", "beat": 4}, {"t": 33.0, "type": "finish", "beat": 4, "complete": False}])
    check("Finish while paused keeps nothing of the unfinished beat", [s["beat"] for s in segs2] == [0, 1, 2, 3])

    print(f"2. booth server ({vid})")
    port = free_port()
    env = dict(os.environ)
    srv = subprocess.Popen([sys.executable, str(here / "video_booth.py"), vid, "--port", str(port), "--no-open", "--countdown-ms", "150"],
                           env=env, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True)
    base = f"http://localhost:{port}/"
    try:
        up = False
        for _ in range(240):
            try:
                if fetch(base + "api/state")[0] == 200: up = True; break
            except Exception:
                time.sleep(0.5)
            if srv.poll() is not None: break
        if not check("server starts and answers on localhost", up):
            print(srv.stdout.read() if srv.poll() is not None else ""); return 1
        sb = load_storyboard(vid)
        st, page = fetch(base)
        check("page is served and contains the storyboard", st == 200 and b"const BOOTH" in page and sb["title"].encode()[:20] in page, f"{len(page) // 1024} KB")
        st, png = fetch(base + "slides/001.png")
        check("slides are served", st == 200 and png[:8] == b"\x89PNG\r\n\x1a\n")
        check("unknown paths are refused", fetch(base + "slides/../../../etc/passwd")[0] == 404 and fetch(base + "api/nothing")[0] == 404)
        check("a POST that does not come from the booth page is refused", fetch(base + "api/audio?ext=webm", b"x")[0] == 403)
        import http.client as hc
        c = hc.HTTPConnection("127.0.0.1", port); c.request("GET", "/", headers={"Host": "evil.example"}); r = c.getresponse()
        check("a request with a foreign Host header is refused", r.status == 403); c.close()
        node = shutil.which("node")
        if node:
            chk = subprocess.run([node, "--check", str(BOOTH / "booth.js")], capture_output=True, text=True)
            check("booth.js has no syntax error (node --check)", chk.returncode == 0, chk.stderr.strip()[:200])

        print("3. booth page in headless Chrome with a synthetic microphone (a tone; the real microphone is not used)")
        drive_ok = False
        if node and pathlib.Path(CHROME).exists():
            res_path = TEST / "drive.json"
            subprocess.run([node, str(here / "video_booth_drive.mjs"), base, str(TEST / "chrome-profile"), str(res_path), CHROME],
                           capture_output=True, text=True, timeout=180)
            res = json.loads(res_path.read_text()) if res_path.exists() else {"error": "driver did not run"}
            check("page loads, shows sections, slide and teleprompter", bool(res.get("slideLoaded")) and res.get("sections") == len(sb["sections"]),
                  f"{res.get('sections')} sections; first narration: {str(res.get('firstNarration'))[:40]!r}")
            check("no JavaScript error in the page or the console", not res.get("pageErrors") and not res.get("consoleErrors") and not res.get("error"),
                  "; ".join((res.get("pageErrors") or []) + (res.get("consoleErrors") or []) + ([res["error"]] if res.get("error") else []))[:300])
            saved = res.get("saved") or {}
            f = RECORDINGS / saved.get("file", "missing")
            drive_ok = check("MediaRecorder take saved through the server", f.exists() and f.stat().st_size > 2000,
                             f"{saved.get('file')} {f.stat().st_size if f.exists() else 0} bytes, level meter said {res.get('meter')!r}")
            timing = video_takes.load_timing(vid) or {"takes": []}
            got = [(s["beat"]) for s in (timing["takes"][0]["segments"] if timing["takes"] else [])]
            types = [e["type"] for e in (timing["takes"][0]["events"] if timing["takes"] else [])]
            check("key presses were logged: advance, retake, pause, resume, go back, finish",
                  all(t in types for t in ("begin", "advance", "retake", "pause", "resume", "goto", "finish")), " ".join(types))
            check("the kept beats are consecutive from the first, one stretch each", len(got) >= 5 and got == list(range(len(got))), str(got))
            segs = timing["takes"][0]["segments"] if timing["takes"] else []
            ok_t = all(b["start"] < b["end"] for b in segs) and all(segs[i]["end"] <= segs[i + 1]["start"] + 1e-6 or segs[i]["beat"] > segs[i + 1]["beat"] for i in range(len(segs) - 1))
            check("kept stretches do not overlap and exclude the countdown", ok_t and segs and segs[0]["start"] >= 0.4, f"first starts at {segs[0]['start'] if segs else '?'} s")
            ff = find_tool("ffprobe")
            if ff and f.exists():
                pr = subprocess.run([ff, "-v", "error", "-show_entries", "stream=codec_name,sample_rate", "-of", "csv=p=0", str(f)], capture_output=True, text=True)
                check("the saved take is readable audio (ffprobe)", pr.returncode == 0 and "opus" in pr.stdout, pr.stdout.strip())
            else:
                head = f.read_bytes()[:4] if f.exists() else b""
                check("the saved take starts with a WebM header", head == b"\x1a\x45\xdf\xa3", "ffprobe not installed: container signature checked instead")
        else:
            print("  SKIP  node or Google Chrome not found")

        print("4. builder on a synthetic recording with retakes, a pause, a go-back and a second take")
        # start clean: move the Chrome take away through the same code the --reset option uses
        import video_booth
        video_booth.archive(vid)
        beats = sb["beats"]
        hashes = [b["h"] for b in beats]
        BAD = 30000

        def amp(i, take): return 1500 + 37 * (i % 300) + (9000 if take == 2 else 0)

        def make_take(first, last, take, tricks):
            """One continuous WAV + its event log.  Discarded audio is a loud tone (BAD); kept audio is a quiet tone whose
            loudness encodes the beat number."""
            audio, events, t = array.array("h"), [], 0.0
            def add(seconds, a):
                nonlocal t
                audio.extend(tone(seconds, a)); t = len(audio) / SR
            add(0.6, BAD)                                            # countdown
            events.append({"t": round(t, 3), "type": "begin", "beat": first})
            i = first
            while i <= last:
                d = 0.25 + 0.05 * (i % 4)
                if i in tricks.get("retake", ()):                    # two false starts
                    add(0.3, BAD); events.append({"t": round(t, 3), "type": "retake", "beat": i})
                    add(0.2, BAD); events.append({"t": round(t, 3), "type": "retake", "beat": i})
                if i in tricks.get("pause", ()):
                    add(0.2, BAD); events.append({"t": round(t, 3), "type": "pause", "beat": i})
                    add(0.9, BAD); events.append({"t": round(t, 3), "type": "resume", "beat": i})
                add(d, amp(i, take))
                if i in tricks.get("goback", ()) and i > first:      # finished, then went back one beat and read both again
                    events.append({"t": round(t, 3), "type": "advance", "beat": i, "next": i + 1})
                    add(0.15, BAD); events.append({"t": round(t, 3), "type": "goto", "beat": i - 1})
                    add(0.3, amp(i - 1, take)); events.append({"t": round(t, 3), "type": "advance", "beat": i - 1, "next": i})
                    add(d, amp(i, take))
                if i == last:
                    events.append({"t": round(t, 3), "type": "finish", "beat": i, "complete": True})
                else:
                    events.append({"t": round(t, 3), "type": "advance", "beat": i, "next": i + 1})
                i += 1
            add(0.5, BAD)                                            # the recorder runs a little longer than the last beat
            return audio, events

        def upload(audio, events, start):
            tmp = TEST / "take.wav"
            with wave.open(str(tmp), "wb") as w:
                w.setnchannels(1); w.setsampwidth(2); w.setframerate(SR); w.writeframes(audio.tobytes())
            st, body = fetch(base + "api/audio?ext=wav", tmp.read_bytes(), {"X-Booth": "1", "Content-Type": "application/octet-stream"})
            tok = json.loads(body)["token"]
            st2, body2 = fetch(base + "api/timing", json.dumps({"token": tok, "video": vid, "mime": "audio/wav", "duration": len(audio) / SR,
                              "storyboard_sha1": sb["script_sha1"], "start_beat": start, "beat_hashes": hashes, "events": events}).encode(),
                              {"X-Booth": "1", "Content-Type": "application/json"})
            return st == 200 and st2 == 200, json.loads(body2) if st2 == 200 else {}

        n = len(beats)
        a1, e1 = make_take(0, n - 1, 1, {"retake": {3, 17}, "pause": {6, 20}, "goback": {9}})
        ok1, r1 = upload(a1, e1, 0)
        check("take 1 (whole video) saved by the server", ok1 and r1.get("file") == f"{vid}.wav" and r1.get("missing") == 0, json.dumps(r1))
        sec = sb["sections"][3]
        s_first, s_last = sec["beat"], sb["sections"][4]["beat"] - 1
        a2, e2 = make_take(s_first, s_last, 2, {"retake": {s_first + 1}})
        ok2, r2 = upload(a2, e2, s_first)
        check(f"take 2 (section {sec['name']} only) saved as a second file", ok2 and r2.get("file") == f"{vid}.take02.wav", json.dumps(r2))
        st, body = fetch(base + "api/state")
        check("the booth reports every beat as recorded", st == 200 and len(json.loads(body)["recorded"]) == n)

        have_ff = bool(find_tool("ffmpeg") and find_tool("ffprobe"))
        cmd = [sys.executable, str(here / "video_build.py"), vid, "--force", "--keep-temp"] + ([] if have_ff else ["--no-encode"])
        t0 = time.time()
        b = subprocess.run(cmd, env=env, capture_output=True, text=True)
        check("builder runs" + ("" if have_ff else " (cut list only: ffmpeg is not installed)"), b.returncode == 0, (b.stdout + b.stderr).strip().splitlines()[-1][:200] if (b.stdout + b.stderr).strip() else "")
        raw = CACHE / "build" / vid / "narration.raw.wav"
        if raw.exists():
            with wave.open(str(raw), "rb") as w:
                a = array.array("h"); a.frombytes(w.readframes(w.getnframes()))
            check("no sample of discarded audio (false starts, pauses, countdown) is left", max(abs(x) for x in a) < 20000, f"loudest sample {max(abs(x) for x in a)}")
            pos, good, wrong = SR, 0, []
            use, _, _ = video_takes.resolve(sb, video_takes.load_timing(vid))
            for bt in beats:
                i = bt["i"]
                f_, s_, e_ = use[i]
                ln = int(round(e_ * SR)) - int(round(s_ * SR))
                seg = a[pos + 600:pos + ln - 600]
                expect = amp(i, 2 if s_first <= i <= s_last else 1)
                pk = max(abs(x) for x in seg) if len(seg) else 0
                if abs(pk - expect) <= 3: good += 1
                else: wrong.append((i, pk, expect))
                pos += ln
            check("every beat carries its own audio, in order; the re-recorded section comes from take 2", not wrong and pos == len(a),
                  f"{good}/{n} beats right" + (f", first wrong {wrong[:3]}" if wrong else ""))
            kept = (len(a) - SR) / SR
            check("the first second is silence for the thumbnail", max(abs(x) for x in a[:SR]) == 0, f"recorded {(len(a1) + len(a2)) / SR:.1f} s, kept {kept:.1f} s")
        else:
            check("the cut narration was written", False)
        srt = OUT / f"{vid}.srt"; chap = OUT / f"{vid}.chapters.txt"
        check("subtitles written, numbered and in time order", srt.exists() and srt.read_text().startswith("1\n00:00:0"), f"{srt.read_text().count(' --> ')} cues" if srt.exists() else "")
        ch = chap.read_text().splitlines() if chap.exists() else []
        check("chapters start at 0:00 (short chapters are merged: YouTube wants 10 s or more each)", len(ch) >= 1 and ch[0].startswith("0:00 "), f"{len(ch)} chapters in this {kept:.0f}-second test video")

        print("5. encoded video")
        if have_ff:
            rep = json.loads((OUT / f"{vid}.build.json").read_text())
            p = rep["probe"]
            check("MP4 is 1920x1080, 30 fps, H.264 + AAC", (p["width"], p["height"], p["fps"], p["vcodec"], p["acodec"]) == (1920, 1080, "30/1", "h264", "aac"),
                  f"{p['width']}x{p['height']} {p['fps']} {p['vcodec']}/{p['acodec']}")
            check("audio and video lengths agree within 0.1 s", abs(p["video_seconds"] - p["audio_seconds"]) <= 0.1, f"video {p['video_seconds']:.3f} s, audio {p['audio_seconds']:.3f} s")
            check("length equals one second of thumbnail plus the kept audio", abs(p["video_seconds"] - (1 + kept)) <= 0.1, f"{p['video_seconds']:.2f} s")
            check("faststart (the index is at the front of the file)", bool(p["faststart"]))
            print(f"       built in {time.time() - t0:.0f} s: {rel(OUT / (vid + '.mp4'))}")
        else:
            print("  SKIP  ffmpeg is not installed: the MP4 could not be encoded. Everything before the encoder was tested.")
    finally:
        srv.terminate()
        try: srv.wait(5)
        except Exception: srv.kill()

    print("6. animation layer (tools/video_animtest.py)")
    if "--no-anim" in sys.argv:
        print("  SKIP  --no-anim was given")
    else:
        # in a process of its own: it works in a sandbox directory that must be chosen before the tools are imported
        env = {k: v for k, v in os.environ.items() if not k.startswith("VIDEO_")}
        pr = subprocess.Popen([sys.executable, str(here / "video_animtest.py")], stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True, env=env)
        seen, finished = 0, False
        for line in pr.stdout:
            print(line.rstrip(), flush=True)
            if line.startswith("  PASS"): results.append(True); seen += 1
            elif line.startswith("  FAIL"): results.append(False); seen += 1
            elif line.startswith("  animation layer:"): finished = True
        pr.wait()
        if not finished or seen == 0:                # a crash must never look like a pass
            check("the animation self-test ran to its end", False, f"exit status {pr.returncode}")
    bad = results.count(False)
    print(f"\n{len(results) - bad} checks passed, {bad} failed.  Test files: {rel(TEST)}")
    print("Not tested here: a real microphone and a real person at the keyboard.")
    return 1 if bad else 0


if __name__ == "__main__":
    sys.exit(main())
