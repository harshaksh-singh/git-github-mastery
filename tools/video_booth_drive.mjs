#!/usr/bin/env node
// Self-test helper: drive the recording booth in headless Chrome with a SYNTHETIC microphone.
// navigator.mediaDevices.getUserMedia is replaced by a 330 Hz tone made with Web Audio, so the test never asks macOS or
// Chrome for the real microphone.  Everything after that call is the real page: MediaRecorder, level meter, keys, upload.
// It presses the same keys a narrator would: Space, Left Arrow (retake), P (pause), then clicks Finish.
//   node tools/video_booth_drive.mjs http://localhost:8765/ /path/to/profile result.json
import { spawn } from "node:child_process";
import { writeFileSync, mkdirSync, rmSync } from "node:fs";

const [url, profile, resultPath, chromePath] = process.argv.slice(2);
const CHROME = chromePath || "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome";
mkdirSync(profile, { recursive: true });
const chrome = spawn(CHROME, ["--headless=new", "--remote-debugging-port=0", `--user-data-dir=${profile}`, "--no-first-run",
  "--autoplay-policy=no-user-gesture-required", "--mute-audio",
  "--disable-gpu", "--window-size=1500,900", "about:blank"], { stdio: ["ignore", "ignore", "pipe"] });
const out = { ok: false, steps: [], consoleErrors: [] };
function done(code) {
  writeFileSync(resultPath, JSON.stringify(out, null, 1));
  try { chrome.kill("SIGKILL"); } catch {}
  try { rmSync(profile, { recursive: true, force: true }); } catch {}
  process.exit(code);
}
setTimeout(() => { out.error = "timeout"; done(2); }, 120000);
const wsUrl = await new Promise((resolve, reject) => {
  let buf = "";
  chrome.stderr.on("data", (d) => { buf += d; const m = buf.match(/DevTools listening on (ws:\/\/\S+)/); if (m) resolve(m[1]); });
  chrome.once("exit", () => reject(new Error("Chrome exited before it was ready")));
});
const ws = new WebSocket(wsUrl);
await new Promise((r) => (ws.onopen = r));
let id = 1; const pending = new Map();
ws.onmessage = (ev) => {
  const m = JSON.parse(ev.data);
  if (m.id && pending.has(m.id)) { const p = pending.get(m.id); pending.delete(m.id); m.error ? p.reject(new Error(m.error.message)) : p.resolve(m.result); }
  else if (m.method === "Runtime.exceptionThrown") out.consoleErrors.push(m.params.exceptionDetails.text + " " + (m.params.exceptionDetails.exception?.description || ""));
  else if (m.method === "Log.entryAdded" && m.params.entry.level === "error") out.consoleErrors.push(m.params.entry.text + " " + (m.params.entry.url || ""));
};
const send = (method, params = {}, sessionId) => new Promise((resolve, reject) => { const i = id++; pending.set(i, { resolve, reject }); ws.send(JSON.stringify({ id: i, method, params, sessionId })); });
const { targetId } = await send("Target.createTarget", { url: "about:blank" });
const { sessionId: S } = await send("Target.attachToTarget", { targetId, flatten: true });
for (const d of ["Page", "Runtime", "Log"]) await send(d + ".enable", {}, S);
const js = async (expr) => (await send("Runtime.evaluate", { expression: expr, returnByValue: true, awaitPromise: true }, S)).result.value;
const sleep = (ms) => new Promise((r) => setTimeout(r, ms));
const waitFor = async (expr, ms = 20000) => { const t = Date.now(); while (Date.now() - t < ms) { if (await js(expr)) return true; await sleep(100); } throw new Error("timeout waiting for: " + expr); };
const KEYS = { Space: [" ", 32], ArrowLeft: ["ArrowLeft", 37], ArrowUp: ["ArrowUp", 38], KeyP: ["p", 80] };
const key = async (code) => {
  const [k, vk] = KEYS[code];
  await send("Input.dispatchKeyEvent", { type: "keyDown", code, key: k, windowsVirtualKeyCode: vk }, S);
  await send("Input.dispatchKeyEvent", { type: "keyUp", code, key: k, windowsVirtualKeyCode: vk }, S);
  out.steps.push({ key: code, cur: await js("window.__booth.cur"), state: await js("window.__booth.state") });
};
try {
  await send("Page.addScriptToEvaluateOnNewDocument", { source: `
    navigator.mediaDevices.getUserMedia = async function () {
      const ctx = new AudioContext();
      const osc = ctx.createOscillator(), gain = ctx.createGain(), dest = ctx.createMediaStreamDestination();
      osc.frequency.value = 330; gain.gain.value = 0.25;
      osc.connect(gain); gain.connect(dest); osc.start();
      window.__fakeMic = true;
      return dest.stream;
    };` }, S);
  await send("Page.navigate", { url }, S);
  await waitFor("window.__booth && window.__booth.ready === true");
  out.title = await js("document.title");
  out.sections = await js("document.querySelectorAll('#sections button').length");
  out.slideLoaded = await waitFor("document.getElementById('slide').naturalWidth === 1920").catch(() => false);
  out.teleprompter = await js("document.getElementById('now').textContent.slice(0, 80)");
  await js("document.getElementById('start').click()");
  await waitFor("window.__booth.state === 'rec'", 15000);
  await waitFor("window.__booth.cur >= 2", 15000);          // title and section cards advance by themselves
  out.firstNarration = await js("document.getElementById('now').textContent.slice(0, 60)");
  out.meter = await js("document.getElementById('meterhint').textContent");
  if (process.env.BOOTH_SHOT) {                            // optional: a picture of the booth while it records
    const shot = await send("Page.captureScreenshot", { format: "png" }, S);
    writeFileSync(process.env.BOOTH_SHOT, Buffer.from(shot.data, "base64"));
  }
  await sleep(700); await key("Space");                    // beat 2 kept
  await sleep(500); await key("ArrowLeft");                // beat 3: false start, retake
  await sleep(700); await key("Space");                    // beat 3 kept (second attempt)
  await sleep(400); await key("KeyP");                     // beat 4: pause in the middle
  await sleep(600); await key("KeyP");                     //         continue: beat 4 starts again
  await sleep(700); await key("Space");                    // beat 4 kept
  await sleep(500); await key("ArrowUp");                  // back to beat 4: read it once more
  await sleep(700); await key("Space");                    // beat 4 kept again (this one wins)
  await sleep(600);
  await js("document.getElementById('finish').click()");   // beat 5 ends with Finish
  await waitFor("window.__booth.state === 'saved'", 30000);
  out.saved = await js("window.__booth.saved");
  out.pageErrors = await js("window.__booth.errors");
  out.events = await js("window.__booth.events");
  out.message = await js("document.getElementById('msg').textContent");
  out.ok = !!out.saved && out.pageErrors.length === 0 && out.consoleErrors.length === 0;
} catch (e) {
  out.error = String(e.message || e);
  try { out.pageErrors = await js("window.__booth && window.__booth.errors"); out.state = await js("window.__booth && window.__booth.state"); out.message = await js("document.getElementById('msg').textContent"); } catch {}
}
done(out.ok ? 0 : 1);
