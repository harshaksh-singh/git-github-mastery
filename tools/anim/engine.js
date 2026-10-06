// Animation engine for the course videos.  No packages, no real-time clock.
//
// Everything on a page is a pure function of one number: the time t handed to window.__anim.seek(t).
// tools/video_animshoot.mjs calls seek(i / 30) for frame i and takes a screenshot, so a render is
// repeatable frame for frame.  Nothing here uses CSS transitions, setTimeout or requestAnimationFrame.
(function () {
  "use strict";
  const A = (window.A = {});
  const clamp = (x, a, b) => Math.max(a, Math.min(b, x));
  const lerp = (a, b, p) => a + (b - a) * p;
  A.clamp = clamp; A.lerp = lerp;

  A.ease = {
    lin: (p) => p,
    in: (p) => p * p * p,
    out: (p) => 1 - Math.pow(1 - p, 3),
    inOut: (p) => (p < 0.5 ? 4 * p * p * p : 1 - Math.pow(-2 * p + 2, 3) / 2),
    back: (p) => { const c = 1.9; return 1 + (c + 1) * Math.pow(p - 1, 3) + c * Math.pow(p - 1, 2); },   // small overshoot
    there: (p) => Math.sin(Math.PI * p),                         // 0 -> 1 -> 0, for pulses
    hop: (p) => 4 * p * (1 - p),
  };

  // ---- timeline ---------------------------------------------------------------------------------
  // Tweens are added in time order while a scene is built.  seek() first rewinds every tween (last one
  // first, so the earliest "from" value wins) and then replays the ones that have started.
  class Timeline {
    constructor() { this.tw = []; this.sfx = []; this.after = []; this.t = 0; }
    add(t0, dur, fn, ease) {
      this.tw.push({ t0, dur: Math.max(dur, 1e-6), fn, ease: A.ease[ease || "inOut"] });
      this.t = Math.max(this.t, t0 + dur);
      return t0 + dur;
    }
    at(t0, fn) { return this.add(t0, 0, fn, "lin"); }           // a switch: fn(0) before t0, fn(1) from t0 on
    sound(t, name, gain) { this.sfx.push([Math.round(t * 1000) / 1000, name, gain == null ? 1 : gain]); }
    get end() { return this.t; }
    seek(t) {
      const tw = this.tw;
      for (let i = tw.length - 1; i >= 0; i--) tw[i].fn(0);
      for (let i = 0; i < tw.length; i++) {
        const w = tw[i];
        if (t >= w.t0) w.fn(w.ease(clamp((t - w.t0) / w.dur, 0, 1)));
      }
      for (const f of this.after) f(t);
    }
  }
  A.Timeline = Timeline;

  // ---- animated nodes ---------------------------------------------------------------------------
  // A Node wraps one element with a few numbers (x, y, scale, rotation, opacity).  to() reads the value
  // planned so far as its starting point, so steps can be written one after the other.
  class Node {
    constructor(el, init, tl) {
      this.el = el; this.tl = tl; this.svg = el instanceof SVGElement;
      this.v = Object.assign({ x: 0, y: 0, s: 1, r: 0, o: 1 }, init || {});
      this.plan = Object.assign({}, this.v);
      this.base = Object.assign({}, this.v);
      tl.nodes.push(this);
    }
    to(t0, dur, target, ease) {
      const from = {}, to = {};
      for (const k in target) { from[k] = this.plan[k]; to[k] = target[k]; this.plan[k] = target[k]; }
      const v = this.v;
      return this.tl.add(t0, dur, (p) => { for (const k in to) v[k] = lerp(from[k], to[k], p); }, ease);
    }
    pulse(t0, dur, key, amount) {                              // there and back again
      const v = this.v, base = this.plan[key];
      return this.tl.add(t0, dur, (p) => { v[key] = base + amount * p; }, "there");
    }
    apply() {
      const v = this.v, el = this.el;
      if (this.svg) {
        el.setAttribute("transform", `translate(${v.x.toFixed(2)},${v.y.toFixed(2)}) rotate(${v.r.toFixed(2)}) scale(${v.s.toFixed(4)})`);
        el.setAttribute("opacity", clamp(v.o, 0, 1).toFixed(3));
      } else {
        el.style.transform = (v.x || v.y || v.s !== 1 || v.r) ? `translate(${v.x.toFixed(2)}px,${v.y.toFixed(2)}px) rotate(${v.r.toFixed(2)}deg) scale(${v.s.toFixed(4)})` : "none";
        el.style.opacity = clamp(v.o, 0, 1).toFixed(3);
      }
    }
  }
  A.Node = Node;

  A.stage = function () {
    const tl = new Timeline();
    tl.nodes = [];
    tl.node = (el, init) => new Node(el, init, tl);
    tl.after.push(() => { for (const n of tl.nodes) n.apply(); });
    const origSeek = tl.seek.bind(tl);
    tl.seek = (t) => { for (const n of tl.nodes) Object.assign(n.v, n.base); origSeek(t); };
    return tl;
  };

  // ---- SVG kit ------------------------------------------------------------------------------------
  const NS = "http://www.w3.org/2000/svg";
  A.svg = function (tag, attrs, parent, text) {
    const e = document.createElementNS(NS, tag);
    for (const k in attrs || {}) if (attrs[k] != null) e.setAttribute(k, attrs[k]);
    if (text != null) e.textContent = text;
    if (parent) parent.appendChild(e);
    return e;
  };
  A.MONO = "Menlo,monospace";
  A.SANS = '"Helvetica Neue",Helvetica,Arial,sans-serif';
  A.text = function (parent, x, y, str, o) {
    o = o || {};
    return A.svg("text", { x, y, "text-anchor": o.anchor || "middle", "font-family": o.mono === false ? A.SANS : A.MONO,
      "font-size": o.size || 26, "font-weight": o.weight || 700, fill: o.fill || "#e6edf3", "dominant-baseline": "central",
      "letter-spacing": o.spacing || null, "font-style": o.italic ? "italic" : null, style: "white-space:pre" }, parent, str);
  };
  A.rect = function (parent, x, y, w, h, o) {
    o = o || {};
    return A.svg("rect", { x, y, width: w, height: h, rx: o.r == null ? 12 : o.r, fill: o.fill || "#0b0d12", stroke: o.stroke || "none",
      "stroke-width": o.sw || 0, "stroke-dasharray": o.dash || null, opacity: o.o == null ? null : o.o }, parent);
  };
  A.mono_w = (str, size) => str.length * size * 0.6021;
  A.sans_w = (str, size) => { let w = 0; for (const c of str) w += /[ilI.,:;'|!]/.test(c) ? 0.28 : /[mwMW@]/.test(c) ? 0.86 : /[A-Z]/.test(c) ? 0.68 : /[ ]/.test(c) ? 0.29 : 0.54; return w * size; };
  // mix two #rrggbb colours
  A.mix = function (c1, c2, p) {
    const h = (c) => [1, 3, 5].map((i) => parseInt(c.slice(i, i + 2), 16));
    const a = h(c1), b = h(c2);
    return "#" + a.map((v, i) => Math.round(lerp(v, b[i], p)).toString(16).padStart(2, "0")).join("");
  };
  // a path that draws itself: returns fn(p)
  A.drawer = function (path) {
    const len = path.getTotalLength ? path.getTotalLength() : 100;
    path.setAttribute("stroke-dasharray", `${len} ${len}`);
    return (p) => path.setAttribute("stroke-dashoffset", (len * (1 - p)).toFixed(2));
  };
  // soft drop shadow filter and an isometric slab (pseudo-3D: a face with two shaded sides, nothing more)
  A.defs = function (svg) {
    const d = A.svg("defs", {}, svg);
    d.innerHTML = '<filter id="sh" x="-30%" y="-30%" width="160%" height="180%"><feGaussianBlur in="SourceAlpha" stdDeviation="9"/><feOffset dy="10"/>' +
      '<feComponentTransfer><feFuncA type="linear" slope=".5"/></feComponentTransfer><feMerge><feMergeNode/><feMergeNode in="SourceGraphic"/></feMerge></filter>' +
      '<filter id="glow" x="-60%" y="-60%" width="220%" height="220%"><feGaussianBlur stdDeviation="7" result="b"/><feMerge><feMergeNode in="b"/><feMergeNode in="SourceGraphic"/></feMerge></filter>';
    return d;
  };
  A.slab = function (parent, x, y, w, h, o) {              // top-left of the front face; depth goes up and to the right
    o = o || {};
    const d = o.depth == null ? 16 : o.depth, c = o.stroke || "#8b949e", fill = o.fill || "#11151c";
    const g = A.svg("g", { filter: o.shadow === false ? null : "url(#sh)" }, parent);
    A.svg("path", { d: `M${x},${y} l${d},${-d} h${w} l${-d},${d} z`, fill: A.mix(fill, c, 0.35), stroke: c, "stroke-width": 2, "stroke-linejoin": "round" }, g);
    A.svg("path", { d: `M${x + w},${y} l${d},${-d} v${h} l${-d},${d} z`, fill: A.mix(fill, c, 0.18), stroke: c, "stroke-width": 2, "stroke-linejoin": "round" }, g);
    A.svg("rect", { x, y, width: w, height: h, fill, stroke: c, "stroke-width": o.sw || 3, rx: 3 }, g);
    return g;
  };

  // ---- slide effects (HTML slides drawn by tools/video_slides.py) --------------------------------------
  const $$ = (sel, root) => Array.from((root || document).querySelectorAll(sel));
  const rise = (tl, el, t0, o) => {
    o = o || {};
    const n = tl.node(el, { o: 0, y: o.dy == null ? 26 : o.dy, s: o.s0 || 1 });
    n.to(t0, o.dur || 0.42, { o: o.to == null ? 1 : o.to, y: 0, s: 1 }, o.ease || "out");
    return n;
  };
  A.rise = rise;

  const FX = (A.fx = {});

  FX.title = function (tl, cfg) {
    const img = document.querySelector("body > img");
    if (img) {
      const n = tl.node(img, { o: 0, s: 1.045 });
      img.style.transformOrigin = "50% 50%";
      n.to(0, 0.9, { o: 1, s: 1 }, "out");
      return;
    }
    FX.card(tl, cfg);
  };

  FX.card = function (tl, cfg) {                                  // title card without thumbnail, and section cards
    let t = 0.05;
    const nb = document.querySelector(".numbox"); if (nb) rise(tl, nb, t, { dy: -20 });
    $$(".card .row > *").forEach((e, i) => { e.style.display = "inline-block"; rise(tl, e, t + 0.06 * i, { dy: 0, s0: 0.8, ease: "back", dur: 0.36 }); });
    const big = document.querySelector(".card .big");
    if (big) { big.style.transformOrigin = "0 60%"; rise(tl, big, t + 0.16, { dy: 46, dur: 0.5 }); tl.sound(t + 0.2, "whoosh", 0.6); }
    const sub = document.querySelector(".card .sub"); if (sub) rise(tl, sub, t + 0.34, { dy: 20 });
    $$(".ticks i").forEach((e, i) => { e.style.transformOrigin = "0 50%"; const n = tl.node(e, { o: 0, s: 0.2 }); n.to(t + 0.4 + 0.035 * i, 0.22, { o: 1, s: 1 }, "out"); });
    progress(tl, cfg, 0.2);
  };

  function progress(tl, cfg, t0) {                                // the progress bar creeps from where the last slide left it
    const bar = document.querySelector(".prog i");
    if (!bar || cfg.progress_from == null) return;
    const to = parseFloat(bar.style.width), from = cfg.progress_from * 100;
    tl.add(t0 || 0, 0.5, (p) => { bar.style.width = lerp(from, to, p).toFixed(3) + "%"; }, "inOut");
  }
  A.progress = progress;

  // ---- small animated glyphs shown beside a key point (300 x 300 each) ---------------------------------
  // Each glyph lists its parts as [element, how it arrives]; "draw" strokes itself, "pop" scales in, "fade" fades.
  const GL = (A.glyphs = {});
  const NEU = "#c9d1d9", DARK = "#0b0d12";
  const P_ = (g, d, col, w) => A.svg("path", { d, fill: "none", stroke: col || NEU, "stroke-width": w || 9, "stroke-linecap": "round", "stroke-linejoin": "round" }, g);
  const C_ = (g, x, y, r, fill, stroke, w) => A.svg("circle", { cx: x, cy: y, r, fill: fill || DARK, stroke: stroke || NEU, "stroke-width": w == null ? 9 : w }, g);
  GL.commit = (g, pal) => [[P_(g, "M14,150 H92"), "draw"], [P_(g, "M208,150 H286"), "draw"], [C_(g, 150, 150, 56, DARK, pal.accent, 11), "pop"], [C_(g, 150, 150, 20, pal.accent, "none", 0), "pop"]];
  GL.branch = (g, pal) => [[P_(g, "M52,214 H150"), "draw"], [P_(g, "M150,214 L236,110"), "draw"], [C_(g, 52, 214, 26), "pop"], [C_(g, 150, 214, 26), "pop"], [C_(g, 236, 110, 26, DARK, pal.accent), "pop"],
    [(() => { const k = A.svg("g", {}, g); A.rect(k, 150, 28, 128, 46, { r: 10, fill: pal.accent }); A.text(k, 214, 52, "main", { size: 28, fill: DARK }); return k; })(), "pop"]];
  GL.merge = (g, pal) => [[P_(g, "M40,150 H112"), "draw"], [P_(g, "M112,150 C150,150 150,82 190,82 S230,150 262,150"), "draw"], [P_(g, "M112,150 C150,150 150,218 190,218 S230,150 262,150"), "draw"],
    [C_(g, 40, 150, 22), "pop"], [C_(g, 112, 150, 22, DARK, pal.accent2), "pop"], [C_(g, 190, 82, 22), "pop"], [C_(g, 190, 218, 22), "pop"], [C_(g, 262, 150, 26, pal.accent, pal.accent), "pop"]];
  GL.folder = (g, pal) => [[P_(g, "M36,96 a14,14 0 0 1 14,-14 h62 l24,26 h114 a14,14 0 0 1 14,14 v114 a14,14 0 0 1 -14,14 h-200 a14,14 0 0 1 -14,-14 z"), "draw"],
    [P_(g, "M36,136 H264", pal.accent), "draw"], [A.text(g, 150, 192, ".git", { size: 46, fill: pal.accent }), "fade"]];
  GL.file = (g, pal) => [[P_(g, "M78,36 h98 l48,48 v180 h-146 z"), "draw"], [P_(g, "M176,36 v48 h48"), "draw"], [P_(g, "M106,132 h90", pal.accent), "draw"], [P_(g, "M106,172 h90", pal.accent2), "draw"], [P_(g, "M106,212 h56", pal.accent2), "draw"]];
  GL.lock = (g, pal) => [[P_(g, "M100,138 v-36 a50,50 0 0 1 100,0 v36", NEU, 13), "draw"], [A.rect(g, 68, 138, 164, 126, { r: 20, fill: DARK, stroke: pal.accent, sw: 10 }), "pop"],
    [C_(g, 150, 190, 15, pal.accent, "none", 0), "pop"], [P_(g, "M150,196 v30", pal.accent, 11), "draw"]];
  GL.warning = (g, pal) => [[P_(g, "M150,40 L272,252 H28 Z", "#ff5c5c", 13), "draw"], [P_(g, "M150,116 v72", "#ff5c5c", 16), "draw"], [C_(g, 150, 218, 9, "#ff5c5c", "none", 0), "pop"]];
  GL.clock = (g, pal) => { const out = [[C_(g, 150, 150, 108, DARK, NEU, 10), "draw"]];
    for (let i = 0; i < 12; i++) { const a = (i * Math.PI) / 6; out.push([P_(g, `M${150 + 88 * Math.sin(a)},${150 - 88 * Math.cos(a)} L${150 + 98 * Math.sin(a)},${150 - 98 * Math.cos(a)}`, i % 3 ? "#59636e" : NEU, 6), "fade"]); }
    out.push([P_(g, "M150,150 V84", pal.accent, 12), "hand1"], [P_(g, "M150,150 H200", pal.accent2, 10), "hand2"], [C_(g, 150, 150, 9, pal.accent, "none", 0), "pop"]); return out; };
  GL.hash = (g, pal) => [[P_(g, "M112,52 L92,196", pal.accent, 13), "draw"], [P_(g, "M196,52 L176,196", pal.accent, 13), "draw"], [P_(g, "M60,98 H232", pal.accent, 13), "draw"], [P_(g, "M52,150 H224", pal.accent, 13), "draw"],
    [A.text(g, 150, 250, "2e76f67", { size: 40, fill: NEU, weight: 500 }), "fade"]];
  GL.snapshot = (g, pal) => [0, 1, 2].map((k) => [A.svg("path", { d: `M150,${214 - k * 56} l110,-46 l-110,-46 l-110,46 z`, fill: k === 2 ? pal.accent + "33" : DARK, stroke: k === 2 ? pal.accent : NEU, "stroke-width": 9, "stroke-linejoin": "round" }, g), "pop"]);
  GL.terminal = (g, pal) => [[A.rect(g, 28, 56, 244, 188, { r: 18, fill: DARK, stroke: NEU, sw: 9 }), "pop"], [P_(g, "M28,100 H272", NEU, 7), "draw"], [C_(g, 58, 79, 7, "#ff5f57", "none", 0), "fade"], [C_(g, 82, 79, 7, "#febc2e", "none", 0), "fade"],
    [P_(g, "M64,142 l32,26 l-32,26", pal.accent, 11), "draw"], [A.rect(g, 116, 180, 54, 13, { r: 4, fill: pal.accent2 }), "blink"]];
  GL.cloud = (g, pal) => [[P_(g, "M82,196 a46,46 0 0 1 4,-92 a62,62 0 0 1 120,-12 a52,52 0 0 1 14,104 z"), "draw"], [P_(g, "M124,268 V214 m-20,22 l20,-22 l20,22", pal.accent, 10), "draw"], [P_(g, "M186,214 V268 m-20,-22 l20,22 l20,-22", pal.accent2, 10), "draw"]];
  GL.book = (g, pal) => [[P_(g, "M150,84 C120,62 70,60 36,72 V232 C70,220 120,222 150,244"), "draw"], [P_(g, "M150,84 C180,62 230,60 264,72 V232 C230,220 180,222 150,244"), "draw"], [P_(g, "M150,84 V244", pal.accent, 9), "draw"],
    [P_(g, "M66,116 q30,-8 58,4", pal.accent2, 7), "draw"], [P_(g, "M66,152 q30,-8 58,4", pal.accent2, 7), "draw"], [P_(g, "M176,120 q30,-12 58,-4", pal.accent2, 7), "draw"], [P_(g, "M176,156 q30,-12 58,-4", pal.accent2, 7), "draw"]];
  GL.target = (g, pal) => [[C_(g, 150, 150, 110, DARK, NEU, 9), "draw"], [C_(g, 150, 150, 70, DARK, NEU, 9), "draw"], [C_(g, 150, 150, 30, pal.accent, pal.accent, 9), "pop"], [P_(g, "M262,38 L162,138 m0,-34 v34 h34", pal.accent2, 11), "draw"]];
  GL.ladder = (g, pal) => { const out = [[P_(g, "M96,274 V26"), "draw"], [P_(g, "M204,274 V26"), "draw"]]; for (let i = 0; i < 5; i++) out.push([P_(g, `M96,${246 - i * 48} H204`, i === 4 ? pal.accent : pal.accent2, 10), "draw"]); return out; };
  GL.server = (g, pal) => [[A.rect(g, 44, 50, 212, 84, { r: 14, fill: DARK, stroke: NEU, sw: 9 }), "pop"], [A.rect(g, 44, 166, 212, 84, { r: 14, fill: DARK, stroke: pal.accent, sw: 9 }), "pop"], [C_(g, 84, 92, 9, pal.accent, "none", 0), "blink"], [C_(g, 84, 208, 9, pal.accent2, "none", 0), "blink"],
    [P_(g, "M124,92 h100", "#59636e", 8), "draw"], [P_(g, "M124,208 h100", "#59636e", 8), "draw"]];
  A.glyph = function (tl, root, name, pal, t0) {
    if (!GL[name]) return t0;
    const g = A.svg("g", {}, root), parts = GL[name](g, pal);
    let t = t0;
    parts.forEach(([el, how], i) => {
      if (how === "draw") {
        el.setAttribute("pathLength", 1); el.setAttribute("stroke-dasharray", "1 1");
        tl.add(t, 0.38, (p) => el.setAttribute("stroke-dashoffset", (1 - p).toFixed(4)), "inOut"); t += 0.12;
      } else if (how === "pop") {
        const bb = el.getBBox(), cx = bb.x + bb.width / 2, cy = bb.y + bb.height / 2, w = A.svg("g", {}, g);
        g.insertBefore(w, el); w.appendChild(el);
        tl.add(t, 0.34, (p) => { w.setAttribute("transform", `translate(${cx},${cy}) scale(${p.toFixed(4)}) translate(${-cx},${-cy})`); w.setAttribute("opacity", Math.min(1, p * 2).toFixed(3)); }, "back"); t += 0.11;
      } else if (how === "hand1" || how === "hand2") {
        const turn = how === "hand1" ? 360 : 60;
        tl.add(t0 + 0.3, 1.1, (p) => { el.setAttribute("transform", `rotate(${(-turn * (1 - p)).toFixed(2)} 150 150)`); el.setAttribute("opacity", Math.min(1, p * 4).toFixed(3)); }, "out");
      } else {
        tl.add(t, 0.3, (p) => el.setAttribute("opacity", p.toFixed(3)), "out"); t += how === "blink" ? 0.1 : 0.04;
      }
    });
    tl.sound(t0 + 0.15, "pop", 0.5);
    return t + 0.3;
  };

  // key points: four layouts (statement, question, contrast, number) drawn by tools/video_animate.py
  FX.keypoint = function (tl, cfg) {
    const q = (sel) => document.querySelector(sel), pal = cfg.palette;
    let t = 0.08;
    const badge = q(".kp-badge"); if (badge) { rise(tl, badge, t, { dy: 0, s0: 0.7, ease: "back", dur: 0.34 }); t += 0.08; }
    const rule = q(".kp-rule");
    if (rule) { rule.style.transformOrigin = getComputedStyle(rule).marginLeft === getComputedStyle(rule).marginRight && q(".kp-question") ? "50% 50%" : "0 50%"; tl.add(t, 0.4, (p) => { rule.style.transform = `scaleX(${p.toFixed(4)})`; }, "out"); }
    const hd = q(".kp-hd"); if (hd) { rise(tl, hd, t + 0.08, { dy: 26, dur: 0.44 }); t += 0.12; }
    const qm = q(".kp-qmark");
    if (qm) { const n = tl.node(qm, { o: 0, s: 0.5, r: -24 }); n.to(t, 0.7, { o: 0.14, s: 1, r: 8 }, "back"); }
    const num = q(".kp-num .n");
    if (num) {
      const N = +num.dataset.n, n = tl.node(num, { o: 0, s: 0.6 });
      n.to(t + 0.05, 0.4, { o: 1, s: 1 }, "back");
      tl.add(t + 0.1, Math.min(0.9, 0.25 + N * 0.08), (p) => { num.textContent = String(Math.round(N * p)); }, "out");
      tl.sound(t + 0.12, "pop", 0.9);
      const u = q(".kp-num .u"); if (u) rise(tl, u, t + 0.5, { dy: 14 });
      t += 0.25;
    }
    const cards = $$(".kp-card");
    if (cards.length) {
      cards.forEach((c, i) => { const n = tl.node(c, { o: 0, x: i ? 60 : -60 }); n.to(t + 0.1 + i * 0.5, 0.5, { o: 1, x: 0 }, "out"); tl.sound(t + 0.15 + i * 0.5, "pop", 0.8); });
      const mid = q(".kp-mid span"); if (mid) { const n = tl.node(mid, { o: 0, s: 0.3 }); n.to(t + 0.45, 0.35, { o: 1, s: 1 }, "back"); }
      t += 0.9;
    }
    const bd = q(".kp-bd"); if (bd) { rise(tl, bd, t + 0.12, { dy: 34, dur: 0.5 }); t += 0.3; }
    const art = q(".kp-art svg"); if (art) A.glyph(tl, art, art.dataset.glyph, pal, t - 0.1);
    // the key terms take the accent colour and underline themselves once the sentence has arrived
    $$(".hi").forEach((el, i) => {
      const t0 = t + 0.35 + i * 0.3;
      tl.add(t0, 0.5, (p) => { el.style.color = A.mix("#ffffff", pal.accent, p); el.style.backgroundSize = `${(100 * p).toFixed(1)}% .085em`; }, "inOut");
    });
    $$(".kp code").forEach((el, i) => { const n = tl.node(el, { s: 0.86, o: 0.3 }); el.style.display = "inline-block"; n.to(t + 0.2 + i * 0.1, 0.3, { s: 1, o: 1 }, "back"); });
    tl.sound(0.16, "pop", 0.7);
    progress(tl, cfg);
  };

  FX.callout = function (tl, cfg) {
    let t = 0.08;
    $$(".call > *").forEach((e) => {
      if (e.classList.contains("q")) {
        e.style.transformOrigin = "0 50%";
        const edge = e.style; edge.borderLeftColor = "transparent";
        const col = getComputedStyle(document.querySelector(".bar")).backgroundColor;
        tl.at(t, (p) => { edge.borderLeftColor = p ? col : "transparent"; });
        const n = tl.node(e, { o: 0, x: -36 }); n.to(t, 0.5, { o: 1, x: 0 }, "out");
        tl.sound(t + 0.05, "pop", 0.8);
        t += 0.3;
      } else { rise(tl, e, t, { dy: 18 }); t += 0.14; }
    });
    progress(tl, cfg);
  };

  // bullets: state {shown, current}; from = state before (null = the list is new)
  FX.bullets = function (tl, cfg) {
    const items = $$(".bul .it"), from = cfg.from, to = cfg.to;
    const lead = document.querySelector(".bul .lead");
    let t = 0.06;
    const opac = (st, i) => (i >= st.shown ? 0 : st.current == null ? 1 : st.current === i ? 1 : 0.5);
    if (!from && lead) { rise(tl, lead, t, { dy: 22 }); t += 0.2; }
    items.forEach((el, i) => {
      el.classList.remove("hid", "old", "cur");
      const a = from ? opac(from, i) : 0, b = opac(to, i);
      const isCur = to.current === i, wasCur = from && from.current === i;
      const mk = el.querySelector(".mk");
      if (to.current != null) el.classList.toggle("cur", isCur);
      if (a === 0 && b === 0) { el.style.visibility = "hidden"; return; }
      el.style.opacity = b;
      if (a === 0) {                                                  // the item arrives
        const n = tl.node(el, { o: 0, x: -40 });
        n.to(t, 0.4, { o: b, x: 0 }, "out");
        if (mk) { const m = tl.node(mk, { s: 0.2 }); m.to(t, 0.36, { s: 1 }, "back"); }
        tl.sound(t + 0.04, "pop", 0.9);
        t += 0.13;
      } else if (a !== b || wasCur !== isCur) {
        const n = tl.node(el, { o: a }); n.to(0.02, 0.3, { o: b }, "inOut");
      }
    });
    progress(tl, cfg);
  };

  // tables: state {shown}; rows beyond "shown" wait as faint ghosts
  FX.table = function (tl, cfg) {
    const rows = $$("tbody tr").concat($$(".cards .cardrow"));
    const from = cfg.from, to = cfg.to, GH = 0.1;
    let t = 0.05;
    if (!from) {
      const head = document.querySelector("thead");
      if (head) { rise(tl, head, t, { dy: -14, dur: 0.34 }); t += 0.16; }
    }
    const table = document.querySelector("table");
    const dimmed = (el) => (table && table.classList.contains("has-hl") && !el.classList.contains("hl")) || (el.classList.contains("cardrow") && el.parentNode.classList.contains("has-hl") && !el.classList.contains("hl"));
    rows.forEach((el, i) => {
      const cells = el.tagName === "TR" ? Array.from(el.children) : [el];
      cells.forEach((c) => { c.style.opacity = "1"; });              // opacity is driven here, not by the has-hl rule
      const full = dimmed(el) ? 0.5 : 1;
      const a = !from ? 0 : i < from.shown ? null : GH, b = i < to.shown ? full : GH;
      if (a === null) { el.style.opacity = full; return; }
      const n = tl.node(el, { o: a, x: a === 0 || b > GH ? -30 : 0 });
      if (b > GH) { n.to(t, 0.4, { o: b, x: 0 }, "out"); if (from || i < 6) tl.sound(t + 0.03, "pop", from ? 0.9 : 0.45); t += from ? 0.14 : 0.07; }
      else { n.to(t, 0.3, { o: b, x: 0 }, "out"); t += 0.03; }
    });
    const pg = document.querySelector(".pgn"); if (pg && !from) rise(tl, pg, t, { dy: 0 });
    progress(tl, cfg);
  };

  // terminal: lines are grouped in blocks (a command and what it printed); state = number of blocks shown
  FX.terminal = function (tl, cfg) {
    const pre = document.querySelector(".term pre"), term = document.querySelector(".term");
    const lines = $$(".ln", pre), from = cfg.from, to = cfg.to;
    let t = 0.05;
    if (!from) {                                                   // the window itself arrives
      term.style.transformOrigin = "50% 60%";
      const n = tl.node(term, { o: 0, s: 0.965, y: 18 });
      n.to(0, 0.34, { o: 1, s: 1, y: 0 }, "out");
      t = 0.3;
    }
    const b0 = from ? from.blocks : 0, b1 = to.blocks;
    const budget = cfg.budget || 2.6;                               // seconds this clip may take
    // work out the natural length, then squeeze if it would run over the budget
    const todo = lines.filter((l) => +l.dataset.b >= b0 && +l.dataset.b < b1);
    let natural = 0;
    for (const l of todo) natural += l.dataset.t === "cmd" || l.dataset.t === "more" ? 0.12 + Math.min(1.3, +l.dataset.n / 30) + 0.16 : 0.055;
    const k = Math.min(1, (budget - t) / Math.max(natural, 0.01));
    const cur = document.createElement("i"); cur.className = "cur"; cur.style.visibility = "hidden";
    let cursorOn = null;
    lines.forEach((l) => {
      const b = +l.dataset.b, kind = l.dataset.t;
      if (b < b0) return;
      if (b >= b1) { l.style.visibility = "hidden"; return; }
      if (kind === "cmd" || kind === "more") {
        const typed = l.querySelector(".ty"), n = +l.dataset.n;
        const dur = Math.min(1.3, n / 30) * k;
        const startT = t;
        tl.at(startT, (p) => { l.style.visibility = p ? "visible" : "hidden"; });
        t += 0.12 * k;
        if (typed) {
          typed.style.display = "inline-block"; typed.style.overflow = "hidden"; typed.style.verticalAlign = "top"; typed.style.whiteSpace = "pre";
          const t0 = t;
          tl.add(t0, dur, (p) => { typed.style.width = Math.round(n * p) + "ch"; }, "lin");
          const ticks = Math.max(1, Math.min(8, Math.round(dur / 0.09)));
          for (let i = 0; i < ticks; i++) tl.sound(t0 + (dur * i) / ticks, "tick", 0.5 + 0.3 * ((i * 7) % 3) / 2);
          const c = cur.cloneNode(); l.appendChild(c);
          const endT = t0 + dur + 0.14 * k;
          tl.at(startT, (p) => { c.style.visibility = p ? "visible" : "hidden"; });
          tl.at(endT, (p) => { if (p) c.style.visibility = "hidden"; });
          t = t0 + dur + 0.16 * k;
        }
      } else {
        const n = tl.node(l, { o: 0 });
        l.style.display = "inline-block"; l.style.verticalAlign = "top";
        n.to(t, 0.12, { o: 1 }, "out");
        t += 0.055 * k;
      }
    });
    if (todo.some((l) => l.dataset.t !== "cmd" && l.dataset.t !== "more") && from) tl.sound(t - 0.05, "pop", 0.35);
    progress(tl, cfg);
    tl.t = Math.max(tl.t, t + 0.1);
  };

  // an ASCII drawing that could not be turned into a scene: it is revealed line by line, left to right, like a plotter
  FX.draw = function (tl, cfg) {
    const dia = document.querySelector(".dia"), pre = dia.querySelector("pre");
    const n0 = tl.node(dia, { o: 0, s: 0.98 }); n0.to(0, 0.3, { o: 1, s: 1 }, "out");
    const lines = $$(".ln", pre);
    const total = Math.min(1.5, 0.25 + lines.length * 0.09), each = Math.min(0.5, total * 0.6);
    lines.forEach((l, i) => {
      l.style.display = "inline-block";
      const t0 = 0.22 + (lines.length > 1 ? (i * (total - each)) / (lines.length - 1) : 0);
      tl.add(t0, each, (p) => { l.style.clipPath = `inset(-4px ${(100 * (1 - p)).toFixed(2)}% -4px 0)`; }, "inOut");
    });
    tl.sound(0.25, "whoosh", 0.5);
    progress(tl, cfg);
  };

  FX.still = function (tl, cfg) {};                                 // one frame: used when only a caption or a highlight changes

  // ---- entry point --------------------------------------------------------------------------------
  A.run = function (cfg) {
    const tl = A.stage();
    const still = cfg.fx === "still", fx = still ? cfg.base : cfg.fx;
    if (fx === "scene") window.Scenes.run(tl, cfg);
    else if (FX[fx]) FX[fx](tl, cfg);
    else throw new Error("unknown fx " + fx);
    // scenes replay earlier steps instantly and start later; a "still" is the finished picture, one frame long
    const start = still ? tl.end : tl.start || 0;
    let dur = Math.max(0, tl.end - start);
    if (!still) dur += cfg.tail == null ? 0.1 : cfg.tail;
    window.__anim = {
      duration: Math.round(dur * 1000) / 1000,
      sfx: tl.sfx.filter((s) => s[0] >= start - 1e-6).map((s) => [Math.round((s[0] - start) * 1000) / 1000, s[1], s[2]]),
      info: tl.info || {},
      seek: (t) => tl.seek(start + t),
    };
    tl.seek(start);
  };
})();
