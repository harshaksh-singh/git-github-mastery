#!/usr/bin/env python3
"""Recording booth for one video: a local web page with slide, teleprompter, level meter and a microphone recorder.

    python3 tools/video_booth.py V008              build the page, start the server, open Google Chrome
    python3 tools/video_booth.py V008 --port 8770  another port (default 8765; the next free one is taken if busy)
    python3 tools/video_booth.py V008 --no-open    do not open a browser
    python3 tools/video_booth.py V008 --reset      move the existing takes of V008 to recordings/archive/ and start clean

The server listens on 127.0.0.1 only.  A browser allows the microphone on http://localhost without a certificate.
Takes are saved in video/production/recordings/:  V008.webm (first take), V008.take02.webm ..., V008.timing.json
"""
import datetime, http.server, json, os, re, secrets, shutil, socket, subprocess, sys, threading, urllib.parse

sys.path.insert(0, str(__import__("pathlib").Path(__file__).resolve().parent))
from video_common import *   # noqa: F401,F403
import video_takes

MAX_UPLOAD = 2 * 1024 ** 3


def build_page(vid, countdown_ms=1000):
    sb = load_storyboard(vid)
    data = {
        "id": vid, "title": sb["title"], "palette": sb["palette"], "sha": sb["script_sha1"], "countdown_ms": countdown_ms,
        "sections": [{"name": s["name"], "beat": s["beat"]} for s in sb["sections"]],
        "beats": [{"i": b["i"], "section": b["section"], "type": b["type"], "why": b.get("why", ""), "hold": b.get("hold", 0),
                   "tele": b["tele"], "est": b["est"], "slide": b["slide"], "h": b["h"]} for b in sb["beats"]],
    }
    tpl = (BOOTH / "booth.html").read_text(encoding="utf-8")
    page = (tpl.replace("__ID__", vid)
               .replace("__CSS__", (BOOTH / "booth.css").read_text(encoding="utf-8"))
               .replace("__DATA__", json.dumps(data, ensure_ascii=False).replace("</", "<\\/"))
               .replace("__JS__", (BOOTH / "booth.js").read_text(encoding="utf-8")))
    out = BOOTH / "pages"
    out.mkdir(parents=True, exist_ok=True)
    (out / f"{vid}.html").write_text(page, encoding="utf-8")
    return out / f"{vid}.html", sb


def archive(vid):
    files = [p for p in RECORDINGS.glob(f"{vid}.*") if p.is_file()]
    if not files:
        return None
    dest = RECORDINGS / "archive" / f"{vid}-{datetime.datetime.now():%Y%m%d-%H%M%S}"
    dest.mkdir(parents=True, exist_ok=True)
    for p in files:
        shutil.move(str(p), str(dest / p.name))
    return dest


class Handler(http.server.BaseHTTPRequestHandler):
    server_version = "booth/1"
    vid = page = sb = None
    lock = threading.Lock()

    def log_message(self, fmt, *args):
        if "/slides/" not in self.path:
            sys.stderr.write("  %s %s\n" % (self.command, self.path))

    def _send(self, code, body, ctype="application/json"):
        if isinstance(body, (dict, list)):
            body = json.dumps(body).encode("utf-8")
        self.send_response(code)
        self.send_header("Content-Type", ctype)
        self.send_header("Content-Length", str(len(body)))
        self.send_header("Cache-Control", "no-store")
        self.end_headers()
        self.wfile.write(body)

    def _local(self):
        host = (self.headers.get("Host") or "").split(":")[0]
        return host in ("localhost", "127.0.0.1")

    def do_GET(self):
        if not self._local():
            return self._send(403, {"error": "local use only"})
        path = urllib.parse.urlparse(self.path).path
        if path in ("/", "/index.html"):
            return self._send(200, self.page.read_bytes(), "text/html; charset=utf-8")
        m = re.fullmatch(r"/slides/(\d{3})\.png", path)
        if m:
            p = SLIDES / self.vid / f"{m.group(1)}.png"
            if p.exists():
                return self._send(200, p.read_bytes(), "image/png")
            return self._send(404, {"error": "no such slide"})
        if path == "/favicon.ico":
            self.send_response(204); self.end_headers(); return
        if path == "/api/state":
            use, stale, missing = video_takes.resolve(self.sb, video_takes.load_timing(self.vid))
            return self._send(200, {"video": self.vid, "recorded": sorted(use), "stale": len(stale), "missing": len(missing)})
        return self._send(404, {"error": "not found"})

    def do_POST(self):
        if not self._local() or self.headers.get("X-Booth") != "1":
            return self._send(403, {"error": "local use only"})
        url = urllib.parse.urlparse(self.path)
        n = int(self.headers.get("Content-Length") or 0)
        if n <= 0 or n > MAX_UPLOAD:
            return self._send(400, {"error": "empty or too large"})
        RECORDINGS.mkdir(parents=True, exist_ok=True)
        if url.path == "/api/audio":
            ext = urllib.parse.parse_qs(url.query).get("ext", ["webm"])[0]
            if ext not in ("webm", "m4a", "ogg", "wav"):
                return self._send(400, {"error": "bad extension"})
            token = secrets.token_hex(8)
            tmp = RECORDINGS / f".incoming-{token}.{ext}"
            left = n
            with open(tmp, "wb") as f:
                while left > 0:
                    chunk = self.rfile.read(min(left, 1 << 20))
                    if not chunk:
                        break
                    f.write(chunk); left -= len(chunk)
            if left:
                tmp.unlink(missing_ok=True)
                return self._send(400, {"error": "upload cut short"})
            return self._send(200, {"token": f"{token}.{ext}", "bytes": n})
        if url.path == "/api/timing":
            try:
                t = json.loads(self.rfile.read(n).decode("utf-8"))
                token = t.pop("token")
                if not re.fullmatch(r"[0-9a-f]{16}\.(webm|m4a|ogg|wav)", token):
                    raise ValueError("bad token")
                tmp = RECORDINGS / f".incoming-{token}"
                if not tmp.exists():
                    raise ValueError("audio not found")
                segs, discarded = video_takes.segments_from_events(t.get("events", []))
            except Exception as e:
                return self._send(400, {"error": str(e)})
            with self.lock:
                timing = video_takes.load_timing(self.vid) or {"video": self.vid, "version": 1, "takes": []}
                k = len(timing["takes"]) + 1
                ext = token.split(".")[1]
                while True:
                    name = f"{self.vid}.{ext}" if k == 1 else f"{self.vid}.take{k:02d}.{ext}"
                    if not (RECORDINGS / name).exists():
                        break
                    k += 1
                os.replace(tmp, RECORDINGS / name)
                take = {"file": name, "saved_at": datetime.datetime.now().isoformat(timespec="seconds"), "mime": t.get("mime", ""),
                        "duration": t.get("duration"), "storyboard_sha1": t.get("storyboard_sha1"), "start_beat": t.get("start_beat", 0),
                        "segments": segs, "discarded": discarded, "beat_hashes": t.get("beat_hashes", []), "events": t.get("events", []),
                        "user_agent": t.get("user_agent", "")}
                timing["takes"].append(take)
                p = video_takes.timing_path(self.vid)
                tmpj = p.with_suffix(".json.tmp")
                tmpj.write_text(json.dumps(timing, indent=1), encoding="utf-8")
                os.replace(tmpj, p)
            use, stale, missing = video_takes.resolve(self.sb, timing)
            print(f"  saved {name}: {len(segs)} beats kept, {discarded} retakes cut, {len(missing)} beats still to record")
            return self._send(200, {"file": name, "kept": len(segs), "discarded": discarded, "missing": len(missing)})
        return self._send(404, {"error": "not found"})


def main():
    argv = sys.argv[1:]
    port = 8765
    if "--port" in argv:
        port = int(argv[argv.index("--port") + 1]); del argv[argv.index("--port"):argv.index("--port") + 2]
    cd = 1000
    if "--countdown-ms" in argv:
        cd = int(argv[argv.index("--countdown-ms") + 1]); del argv[argv.index("--countdown-ms"):argv.index("--countdown-ms") + 2]
    args = [a for a in argv if not a.startswith("--")]
    if len(args) != 1:
        print(__doc__); return 2
    vid = vid_norm(args[0])
    if not script_path(vid):
        print(f"{vid}: no script in video/scripts/"); return 1
    here = pathlib.Path(__file__).resolve().parent
    # the page needs a current storyboard and its slides
    import video_storyboard
    if not video_storyboard.up_to_date(vid):
        subprocess.run([sys.executable, str(here / "video_storyboard.py"), vid], check=True)
    subprocess.run([sys.executable, str(here / "video_slides.py"), vid], check=True)
    if "--reset" in argv:
        d = archive(vid)
        print(f"moved the old takes to {rel(d)}" if d else "no takes to move")
    page, sb = build_page(vid, cd)
    Handler.vid, Handler.page, Handler.sb = vid, page, sb
    srv = None
    for p in range(port, port + 20):
        try:
            srv = http.server.ThreadingHTTPServer(("127.0.0.1", p), Handler)
            port = p; break
        except OSError:
            continue
    if srv is None:
        print("no free port between %d and %d" % (port, port + 19)); return 1
    url = f"http://localhost:{port}/"
    use, stale, missing = video_takes.resolve(sb, video_takes.load_timing(vid))
    n = sum(1 for b in sb["beats"] if b["type"] == "narration")
    print(f"Recording booth for {vid}: {sb['title']}")
    print(f"  {n} beats to read, about {fmt_dur(sb['est_seconds'])} at {WPM} words per minute; {n - len(missing)} already recorded")
    print(f"  open {url} in Google Chrome   (stop this program with Ctrl+C when you have finished)", flush=True)
    if "--no-open" not in argv:
        subprocess.run(["open", "-a", "Google Chrome", url], capture_output=True)
    try:
        srv.serve_forever()
    except KeyboardInterrupt:
        print("\nbooth stopped")
    return 0


if __name__ == "__main__":
    sys.exit(main())
