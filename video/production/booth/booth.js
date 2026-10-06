// Recording booth. Plain JavaScript, no libraries.
// The microphone is recorded as ONE continuous file. Every key press is logged with its time on that file's clock;
// the builder turns the log into "keep this stretch for beat N" and cuts everything else (retakes, pauses, countdown).
(function () {
  "use strict";
  const $ = (id) => document.getElementById(id);
  const beats = BOOTH.beats, sections = BOOTH.sections;
  const last = beats.length - 1;
  let state = "idle";            // idle | countdown | rec | paused | saving | saved
  let cur = 0, startBeat = 0, events = [], rec = null, chunks = [], stream = null, t0 = 0, beatT0 = 0;
  let holdTimer = null, tick = null, audioCtx = null, analyser = null, mime = "", recorded = new Set(), peak = 0, peakAt = 0;
  const dbg = (window.__booth = { errors: [], saved: null, get state() { return state; }, get cur() { return cur; }, get events() { return events; } });
  window.addEventListener("error", (e) => dbg.errors.push(String(e.message)));
  window.addEventListener("unhandledrejection", (e) => dbg.errors.push("promise: " + String(e.reason)));

  document.documentElement.style.setProperty("--accent", BOOTH.palette.accent);
  document.documentElement.style.setProperty("--bg1", BOOTH.palette.bg1);
  document.documentElement.style.setProperty("--bg2", BOOTH.palette.bg2);
  $("vid").textContent = BOOTH.id;
  $("title").textContent = BOOTH.title;

  const now = () => (performance.now() - t0) / 1000;
  const pad = (n) => String(n).padStart(3, "0");
  const fmt = (s) => Math.floor(s / 60) + ":" + String(Math.floor(s % 60)).padStart(2, "0");
  const esc = (s) => s.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;");
  const rich = (t) => esc(t).replace(/`([^`]+)`/g, "<code>$1</code>");
  const log = (type, extra) => events.push(Object.assign({ t: +now().toFixed(3), type: type }, extra || {}));
  const HOLD_TEXT = { title: "Title card", section: "Section card", pause: "Pause", page: "Next page of the output", visual: "Look at the slide" };

  function sectionOf(i) {
    let k = 0;
    for (let s = 0; s < sections.length; s++) if (sections[s].beat <= i) k = s;
    return k;
  }
  function sectionRange(s) {
    const a = s === 0 ? 0 : sections[s].beat;
    const b = s + 1 < sections.length ? sections[s + 1].beat - 1 : last;
    return [a, b];
  }

  function setState(s) {
    state = s;
    const el = $("state");
    el.className = "state" + (s === "rec" || s === "countdown" ? " rec" : s === "paused" ? " paused" : s === "saved" ? " saved" : "");
    el.textContent = { idle: "not recording", countdown: "get ready", rec: "● recording", paused: "paused", saving: "saving…", saved: "saved" }[s];
    $("start").disabled = !(s === "idle" || s === "saved");
    $("start").textContent = s === "saved" ? "Record again from the selected section" : "Start recording";
    $("pause").disabled = !(s === "rec" || s === "paused");
    $("pause").textContent = s === "paused" ? "Continue (P)" : "Pause (P)";
    $("retake").disabled = s !== "rec";
    $("next").disabled = s !== "rec";
    $("finish").disabled = !(s === "rec" || s === "paused");
    drawSections();
  }

  function drawSections() {
    const box = $("sections");
    box.innerHTML = "<h3>SECTIONS</h3>";
    const live = sectionOf(cur), sel = sectionOf(startBeat);
    sections.forEach((s, k) => {
      const [a, b] = sectionRange(k);
      let need = 0, have = 0;
      for (let i = a; i <= b; i++) if (beats[i].type === "narration") { need++; if (recorded.has(i)) have++; }
      const btn = document.createElement("button");
      btn.innerHTML = '<span class="dot ' + (need && have === need ? "done" : have ? "part" : "") + '"></span><span>' + (k + 1) + ". " + esc(s.name.charAt(0) + s.name.slice(1).toLowerCase()) + "</span>";
      btn.title = have + " of " + need + " beats recorded";
      if (state === "idle" || state === "saved") {
        if (k === sel) btn.className = "sel";
        btn.onclick = () => { startBeat = a; cur = a; render(); drawSections(); };
      } else {
        btn.disabled = true;
        if (k === live) btn.className = "live";
      }
      box.appendChild(btn);
    });
    const note = document.createElement("div");
    note.className = "note";
    note.innerHTML = "Green: recorded. Yellow: partly recorded.<br>Before you start, click a section to begin there. A new take replaces the old one for the beats you read again.";
    box.appendChild(note);
  }

  function render() {
    const b = beats[cur];
    $("slide").src = "slides/" + pad(b.slide) + ".png";
    if (cur < last) { const im = new Image(); im.src = "slides/" + pad(beats[cur + 1].slide) + ".png"; }
    $("secname").textContent = b.section;
    $("beatno").textContent = "beat " + (cur + 1) + " / " + beats.length;
    const el = $("now");
    if (b.type === "narration") { el.className = "now"; el.innerHTML = rich(b.tele); }
    else { el.className = "now hold"; el.textContent = (HOLD_TEXT[b.why] || "Silence") + ": stay silent for " + b.hold + " seconds. It moves on by itself."; }
    el.scrollTop = 0;
    let nx = "";
    for (let i = cur + 1, n = 0; i <= last && n < 2; i++) if (beats[i].type === "narration") { nx += "<p>" + rich(beats[i].tele) + "</p>"; n++; }
    $("after").innerHTML = nx || "<p>(end of the video)</p>";
  }

  function enterBeat() {
    clearTimeout(holdTimer);
    beatT0 = now();
    render();
    const b = beats[cur];
    if (b.type !== "narration") holdTimer = setTimeout(advance, b.hold * 1000);
  }

  function advance() {
    if (state !== "rec") return;
    clearTimeout(holdTimer);
    if (cur >= last) { finish(); return; }
    log("advance", { beat: cur, next: cur + 1 });
    cur += 1;
    enterBeat();
  }

  function retake() {
    if (state !== "rec") return;
    clearTimeout(holdTimer);
    // on a silent card, "say it again" means the paragraph just read
    let target = cur;
    if (beats[cur].type !== "narration") { while (target > startBeat && beats[target].type !== "narration") target--; }
    if (target === cur) log("retake", { beat: cur }); else log("goto", { beat: target });
    cur = target;
    flash("Retake: read this beat again.");
    enterBeat();
  }

  function back() {
    if (state !== "rec" || cur <= startBeat) return;
    clearTimeout(holdTimer);
    let target = cur - 1;
    while (target > startBeat && beats[target].type !== "narration") target--;
    log("goto", { beat: target });
    cur = target;
    flash("Back one beat: read it again.");
    enterBeat();
  }

  function togglePause() {
    if (state === "rec") {
      clearTimeout(holdTimer);
      log("pause", { beat: cur });
      setState("paused");
      flash("Paused. Press P to continue; this beat starts again from its first word.");
    } else if (state === "paused") {
      setState("rec");
      log("resume", { beat: cur });
      flash("");
      enterBeat();
    }
  }

  function flash(text, err) {
    const m = $("msg");
    m.className = "msg" + (err ? " err" : "");
    m.innerHTML = text;
  }

  function pickMime() {
    const c = ["audio/webm;codecs=opus", "audio/webm", "audio/mp4;codecs=mp4a.40.2", "audio/mp4", "audio/ogg;codecs=opus"];
    for (const m of c) if (window.MediaRecorder && MediaRecorder.isTypeSupported(m)) return m;
    return "";
  }

  async function start() {
    if (!(state === "idle" || state === "saved")) return;
    if (!navigator.mediaDevices || !window.MediaRecorder) { flash("This browser cannot record. Use Google Chrome.", true); return; }
    try {
      stream = await navigator.mediaDevices.getUserMedia({ audio: { echoCancellation: false, noiseSuppression: false, autoGainControl: false, channelCount: 1 } });
    } catch (e) {
      flash("The microphone is not available (" + esc(e.name) + "). Click the lock or microphone icon in the address bar, allow the microphone, and press Start again.", true);
      return;
    }
    mime = pickMime();
    events = []; chunks = []; dbg.saved = null;
    cur = startBeat;
    rec = new MediaRecorder(stream, mime ? { mimeType: mime, audioBitsPerSecond: 192000 } : {});
    mime = rec.mimeType || mime;
    rec.ondataavailable = (e) => { if (e.data && e.data.size) chunks.push(e.data); };
    rec.onstart = () => { t0 = performance.now(); countdown(3); };
    rec.onerror = (e) => flash("Recorder error: " + esc(String(e.error || e)), true);
    startMeter();
    setState("countdown");
    flash("");
    render();
    rec.start(1000);
    clearInterval(tick);
    tick = setInterval(clock, 200);
  }

  function countdown(n) {
    const c = $("count");
    if (state !== "countdown") { c.className = "count"; return; }
    if (n === 0) {
      c.className = "count";
      setState("rec");
      log("begin", { beat: cur });
      enterBeat();
      return;
    }
    c.className = "count on"; c.textContent = n;
    setTimeout(() => countdown(n - 1), BOOTH.countdown_ms || 1000);
  }

  function clock() {
    if (state === "rec" || state === "paused" || state === "countdown") {
      $("clock").textContent = fmt(now());
      const b = beats[cur];
      $("beattime").textContent = state === "rec" ? (now() - beatT0).toFixed(0) + " s (about " + Math.round(b.est) + " s)" : "";
    }
  }

  function startMeter() {
    try {
      audioCtx = new (window.AudioContext || window.webkitAudioContext)();
      const src = audioCtx.createMediaStreamSource(stream);
      analyser = audioCtx.createAnalyser();
      analyser.fftSize = 2048;
      src.connect(analyser);
      const buf = new Float32Array(analyser.fftSize);
      const draw = () => {
        if (!analyser) return;
        analyser.getFloatTimeDomainData(buf);
        let sum = 0, mx = 0;
        for (let i = 0; i < buf.length; i++) { sum += buf[i] * buf[i]; const a = Math.abs(buf[i]); if (a > mx) mx = a; }
        const db = 20 * Math.log10(Math.sqrt(sum / buf.length) + 1e-7);
        const pct = Math.max(0, Math.min(100, (db + 60) / 60 * 100));
        const t = performance.now();
        if (pct > peak || t - peakAt > 1500) { peak = pct; peakAt = t; }
        $("level").style.width = pct + "%";
        $("peak").style.left = peak + "%";
        const h = $("meterhint");
        if (mx > 0.98) { h.textContent = "too loud: move back a little"; h.className = "hint bad"; }
        else if (db < -50) { h.textContent = "very quiet / silence"; h.className = "hint"; }
        else { h.textContent = "level: " + db.toFixed(0) + " dB"; h.className = "hint"; }
        requestAnimationFrame(draw);
      };
      draw();
    } catch (e) { $("meterhint").textContent = "level meter unavailable"; }
  }

  function stopMedia() {
    clearInterval(tick); clearTimeout(holdTimer);
    analyser = null;
    if (audioCtx) { try { audioCtx.close(); } catch (e) {} audioCtx = null; }
    if (stream) stream.getTracks().forEach((t) => t.stop());
    stream = null;
    $("level").style.width = "0"; $("meterhint").textContent = "microphone off";
  }

  function finish() {
    if (!(state === "rec" || state === "paused")) return;
    clearTimeout(holdTimer);
    log("finish", { beat: cur, complete: state === "rec" });
    const duration = now();
    setState("saving");
    flash("Saving the take. Do not close this page.");
    rec.onstop = () => save(new Blob(chunks, { type: mime || "audio/webm" }), duration);
    rec.stop();
  }

  async function save(blob, duration) {
    stopMedia();
    const ext = /mp4/.test(mime) ? "m4a" : /ogg/.test(mime) ? "ogg" : "webm";
    const timing = { video: BOOTH.id, storyboard_sha1: BOOTH.sha, mime: mime, duration: +duration.toFixed(3), start_beat: startBeat,
      beat_hashes: beats.map((b) => b.h), events: events, user_agent: navigator.userAgent };
    try {
      const r1 = await fetch("api/audio?ext=" + ext, { method: "POST", headers: { "X-Booth": "1", "Content-Type": "application/octet-stream" }, body: blob });
      if (!r1.ok) throw new Error("audio upload failed: HTTP " + r1.status);
      timing.token = (await r1.json()).token;
      const r2 = await fetch("api/timing", { method: "POST", headers: { "X-Booth": "1", "Content-Type": "application/json" }, body: JSON.stringify(timing) });
      if (!r2.ok) throw new Error("timing upload failed: HTTP " + r2.status);
      const res = await r2.json();
      dbg.saved = res;
      await loadState();
      selectFirstIncomplete();
      setState("saved");
      flash("Saved <b>" + esc(res.file) + "</b> (" + fmt(duration) + ", " + res.kept + " beats kept, " + res.discarded + " retakes cut). " +
        (res.missing ? res.missing + " texts of this video are not recorded yet. The first incomplete section is selected on the left: press the Start button to go on, now or later. "
                     : "Every beat is recorded. Now run: <code>video/production/make.sh build " + BOOTH.id + "</code>"));
    } catch (e) {
      dbg.errors.push("save: " + e.message);
      setState("saved");
      const a = URL.createObjectURL(blob), j = URL.createObjectURL(new Blob([JSON.stringify(timing, null, 1)], { type: "application/json" }));
      flash("Saving failed (" + esc(e.message) + "). Is the booth program still running in the Terminal? Your take is not lost: download " +
        '<a download="' + BOOTH.id + ".rescue." + ext + '" href="' + a + '">the audio</a> and <a download="' + BOOTH.id + '.rescue.timing.json" href="' + j +
        '">the timing</a>, then see "Troubleshooting" in the README.', true);
    }
  }

  async function loadState() {
    try {
      const r = await fetch("api/state");
      const s = await r.json();
      recorded = new Set(s.recorded || []);
      if (s.stale) flash("The script changed after " + s.stale + " beat(s) were recorded. They are shown as not recorded; read them again.", true);
    } catch (e) { /* the page still works without it */ }
    drawSections();
  }

  $("start").onclick = start;
  $("pause").onclick = togglePause;
  $("retake").onclick = retake;
  $("next").onclick = advance;
  $("finish").onclick = finish;
  document.addEventListener("keydown", (e) => {
    if (e.target && /^(INPUT|TEXTAREA|SELECT)$/.test(e.target.tagName)) return;
    const k = e.code;
    if (["Space", "ArrowRight", "ArrowLeft", "Backspace", "ArrowUp", "KeyP"].includes(k)) e.preventDefault(); else return;
    if (e.repeat) return;
    if (document.activeElement && document.activeElement.tagName === "BUTTON") document.activeElement.blur();
    if (k === "Space" || k === "ArrowRight") advance();
    else if (k === "ArrowLeft" || k === "Backspace") retake();
    else if (k === "ArrowUp") back();
    else if (k === "KeyP") togglePause();
  });
  window.addEventListener("beforeunload", (e) => { if (state === "rec" || state === "paused" || state === "saving") { e.preventDefault(); e.returnValue = ""; } });

  // start where the recording is incomplete
  function selectFirstIncomplete() {
    let first = 0;
    for (let k = 0; k < sections.length; k++) {
      const [a, b] = sectionRange(k);
      let miss = false;
      for (let i = a; i <= b; i++) if (beats[i].type === "narration" && !recorded.has(i)) miss = true;
      if (miss) { first = a; break; }
    }
    startBeat = first; cur = first;
    render();
  }
  loadState().then(() => {
    selectFirstIncomplete();
    setState("idle");
    dbg.ready = true;
  });
})();
