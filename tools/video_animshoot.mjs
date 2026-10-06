#!/usr/bin/env node
// Capture animated pages frame by frame with ONE headless Chrome, over the DevTools protocol.
// Time is driven from here: for frame i the page's window.__anim.seek(i / fps) is called, then a screenshot is taken.
// Nothing depends on the real clock, so the same page always gives the same frames.  No npm packages.
//
//   node tools/video_animshoot.mjs jobs.json results.json
//
// jobs.json:    {"chrome": "...", "profile": "dir", "fps": 30, "jobs": [{"id": "x", "html": "/abs/a.html", "dir": "/abs/frames/x",
//                 "width": 1920, "height": 1080, "format": "jpeg"|"png", "transparent": false, "max_frames": 600}]}
// results.json: [{"id": "x", "ok": true, "frames": 37, "duration": 1.2, "sfx": [[t, name, gain]], "info": {...}, "errors": []}]
import { spawn } from "node:child_process";
import { readFileSync, writeFileSync, mkdirSync, rmSync } from "node:fs";
import { pathToFileURL } from "node:url";
import { join } from "node:path";

const [jobsPath, resultsPath] = process.argv.slice(2);
const cfg = JSON.parse(readFileSync(jobsPath, "utf8"));
const FPS = cfg.fps || 30;
mkdirSync(cfg.profile, { recursive: true });

const chrome = spawn(cfg.chrome, [
  "--headless=new", "--remote-debugging-port=0", `--user-data-dir=${cfg.profile}`, "--hide-scrollbars",
  "--force-device-scale-factor=1", "--window-size=1920,1080", "--disable-gpu", "--no-first-run", "--no-default-browser-check",
  "--disable-extensions", "--disable-background-networking", "--allow-file-access-from-files", "about:blank",
], { stdio: ["ignore", "ignore", "pipe"] });

function cleanup(code) {
  try { chrome.kill("SIGKILL"); } catch {}
  try { rmSync(cfg.profile, { recursive: true, force: true }); } catch {}
  process.exit(code);
}
process.on("SIGINT", () => cleanup(130));
process.on("SIGTERM", () => cleanup(143));

const wsUrl = await new Promise((resolve, reject) => {
  let buf = "";
  const timer = setTimeout(() => reject(new Error("Chrome did not start within 30 s")), 30000);
  chrome.stderr.on("data", (d) => {
    buf += d.toString();
    const m = buf.match(/DevTools listening on (ws:\/\/\S+)/);
    if (m) { clearTimeout(timer); resolve(m[1]); }
  });
  chrome.on("exit", () => reject(new Error("Chrome exited early: " + buf.slice(-400))));
}).catch((e) => { console.error(String(e)); cleanup(3); });

const ws = new WebSocket(wsUrl);
await new Promise((res, rej) => { ws.onopen = res; ws.onerror = () => rej(new Error("websocket failed")); });
let nextId = 1;
const pending = new Map();
const waiters = [];
let pageErrors = [];
ws.onmessage = (ev) => {
  const msg = JSON.parse(ev.data);
  if (msg.id && pending.has(msg.id)) {
    const { resolve, reject } = pending.get(msg.id); pending.delete(msg.id);
    msg.error ? reject(new Error(msg.error.message)) : resolve(msg.result);
  } else if (msg.method) {
    if (msg.method === "Runtime.exceptionThrown") {
      const d = msg.params.exceptionDetails;
      pageErrors.push(((d.exception && d.exception.description) || d.text || "error").slice(0, 400));
    }
    for (let i = waiters.length - 1; i >= 0; i--) {
      if (waiters[i].method === msg.method) { waiters[i].resolve(msg.params); waiters.splice(i, 1); }
    }
  }
};
const send = (method, params = {}, sessionId) => new Promise((resolve, reject) => {
  const id = nextId++;
  pending.set(id, { resolve, reject });
  ws.send(JSON.stringify({ id, method, params, ...(sessionId ? { sessionId } : {}) }));
});
const waitFor = (method, ms = 20000) => new Promise((resolve, reject) => {
  const w = { method, resolve };
  waiters.push(w);
  setTimeout(() => { const i = waiters.indexOf(w); if (i >= 0) { waiters.splice(i, 1); reject(new Error("timeout waiting for " + method)); } }, ms);
});

const { targetId } = await send("Target.createTarget", { url: "about:blank" });
const { sessionId } = await send("Target.attachToTarget", { targetId, flatten: true });
await send("Page.enable", {}, sessionId);
await send("Runtime.enable", {}, sessionId);

const results = [];
let size = "", transparent = null;
for (const job of cfg.jobs) {
  const r = { id: job.id, ok: false, frames: 0, errors: [] };
  pageErrors = [];
  try {
    const W = job.width || 1920, H = job.height || 1080;
    if (size !== `${W}x${H}`) { await send("Emulation.setDeviceMetricsOverride", { width: W, height: H, deviceScaleFactor: 1, mobile: false }, sessionId); size = `${W}x${H}`; }
    if (transparent !== !!job.transparent) {
      await send("Emulation.setDefaultBackgroundColorOverride", job.transparent ? { color: { r: 0, g: 0, b: 0, a: 0 } } : {}, sessionId);
      transparent = !!job.transparent;
    }
    const loaded = waitFor("Page.loadEventFired");
    await send("Page.navigate", { url: pathToFileURL(job.html).href }, sessionId);
    await loaded;
    const ev = await send("Runtime.evaluate", {
      expression: "(document.fonts && document.fonts.ready ? document.fonts.ready : Promise.resolve())" +
        ".then(() => new Promise(r => requestAnimationFrame(() => requestAnimationFrame(r))))" +
        ".then(() => JSON.stringify(window.__anim ? {d: window.__anim.duration, sfx: window.__anim.sfx, info: window.__anim.info, fit: window.__fit || {}} : {missing: true}))",
      awaitPromise: true, returnByValue: true,
    }, sessionId);
    const meta = JSON.parse(ev.result.value);
    if (meta.missing) throw new Error("the page defined no window.__anim" + (pageErrors.length ? ": " + pageErrors[0] : ""));
    const n = Math.min(job.max_frames || 900, Math.max(1, Math.round(meta.d * FPS) + 1));
    Object.assign(r, { duration: meta.d, sfx: meta.sfx || [], info: meta.info || {}, fit: meta.fit });
    mkdirSync(job.dir, { recursive: true });
    const fmt = job.format === "png" || job.transparent ? "png" : "jpeg";
    for (let i = 0; i < n; i++) {
      await send("Runtime.evaluate", { expression: `window.__anim.seek(${(i / FPS).toFixed(6)})`, returnByValue: true }, sessionId);
      const shot = await send("Page.captureScreenshot", {
        format: fmt, ...(fmt === "jpeg" ? { quality: 96 } : {}), clip: { x: 0, y: 0, width: W, height: H, scale: 1 }, captureBeyondViewport: false, optimizeForSpeed: true,
      }, sessionId);
      writeFileSync(join(job.dir, String(i).padStart(5, "0") + (fmt === "png" ? ".png" : ".jpg")), Buffer.from(shot.data, "base64"));
      r.frames = i + 1;
    }
    r.errors = pageErrors.slice(0, 5);
    r.ok = r.frames === n && pageErrors.length === 0;
  } catch (e) {
    r.errors = [String(e.message || e)].concat(pageErrors.slice(0, 4));
  }
  results.push(r);
  if (results.length % 20 === 0) writeFileSync(resultsPath, JSON.stringify(results));
}
writeFileSync(resultsPath, JSON.stringify(results));
try { await send("Browser.close"); } catch {}
cleanup(results.every((r) => r.ok) ? 0 : 1);
