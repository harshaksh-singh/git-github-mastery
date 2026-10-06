#!/usr/bin/env node
// Screenshot many local HTML pages with ONE headless Chrome, over the DevTools protocol.
// No npm packages: Node's built-in WebSocket and child_process only.
//
//   node tools/video_shoot.mjs jobs.json results.json
//
// jobs.json:    {"chrome": "...", "profile": "dir", "width": 1920, "height": 1080, "jobs": [{"html": "/abs/a.html", "png": "/abs/a.png"}]}
// results.json: [{"png": "...", "ok": true, "fit": {...}}]   (fit = whatever the page left in window.__fit)
import { spawn } from "node:child_process";
import { readFileSync, writeFileSync, mkdirSync, rmSync } from "node:fs";
import { pathToFileURL } from "node:url";
import { dirname } from "node:path";

const [jobsPath, resultsPath] = process.argv.slice(2);
const cfg = JSON.parse(readFileSync(jobsPath, "utf8"));
const W = cfg.width || 1920, H = cfg.height || 1080;
mkdirSync(cfg.profile, { recursive: true });

const chrome = spawn(cfg.chrome, [
  "--headless=new", "--remote-debugging-port=0", `--user-data-dir=${cfg.profile}`, "--hide-scrollbars",
  "--force-device-scale-factor=1", `--window-size=${W},${H}`, "--disable-gpu", "--no-first-run", "--no-default-browser-check",
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
ws.onmessage = (ev) => {
  const msg = JSON.parse(ev.data);
  if (msg.id && pending.has(msg.id)) {
    const { resolve, reject } = pending.get(msg.id); pending.delete(msg.id);
    msg.error ? reject(new Error(msg.error.message)) : resolve(msg.result);
  } else if (msg.method) {
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
await send("Emulation.setDeviceMetricsOverride", { width: W, height: H, deviceScaleFactor: 1, mobile: false }, sessionId);

const results = [];
for (const job of cfg.jobs) {
  const r = { png: job.png, ok: false };
  try {
    const loaded = waitFor("Page.loadEventFired");
    await send("Page.navigate", { url: pathToFileURL(job.html).href }, sessionId);
    await loaded;
    const ev = await send("Runtime.evaluate", {
      expression: "(document.fonts && document.fonts.ready ? document.fonts.ready : Promise.resolve())" +
        ".then(() => new Promise(r => requestAnimationFrame(() => requestAnimationFrame(r))))" +
        ".then(() => JSON.stringify(window.__fit || {}))",
      awaitPromise: true, returnByValue: true,
    }, sessionId);
    try { r.fit = JSON.parse(ev.result.value); } catch { r.fit = {}; }
    const shot = await send("Page.captureScreenshot", {
      format: "png", clip: { x: 0, y: 0, width: W, height: H, scale: 1 }, captureBeyondViewport: false,
    }, sessionId);
    mkdirSync(dirname(job.png), { recursive: true });
    writeFileSync(job.png, Buffer.from(shot.data, "base64"));
    r.ok = true;
  } catch (e) {
    r.error = String(e.message || e);
  }
  results.push(r);
  if (results.length % 50 === 0) writeFileSync(resultsPath, JSON.stringify(results));
}
writeFileSync(resultsPath, JSON.stringify(results));
try { await send("Browser.close"); } catch {}
cleanup(results.every((r) => r.ok) ? 0 : 1);
