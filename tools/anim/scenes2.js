// More explainer scenes: schematic diagrams whose every label comes from the script.
//   flow    a sequence between actors (a relay, a handshake, a credential helper, a token exchange)
//   gates   something travels through checkpoints, each of which can stop it (hooks, rules, a response sequence)
//   layers  stacked layers and what they add up to (rulesets, permission levels, precedence)
//   walk    a table read row by row (base / ours / theirs / result, a lease check, a listing)
//   match   patterns and the paths they match: last or first match wins (CODEOWNERS, attributes, includeIf, ssh config)
//   decide  a decision tree or a state diagram with its own questions, leaves and transitions
//   stores  boxes that hold things, and what moves between them (worktrees, LFS, packs, a bundle, two .git layouts)
//   bars    a few numbers as bars (pack sizes over maintenance runs)
// The type in these scenes is never smaller than 28 units (about 26 px on the 1080p frame).  A text that does not fit shrinks to that size, then
// it is wrapped where the scene has room for a second line (wrapW), and only then cut with "…"; every cut is reported by the layout check.
// They follow their own growth with the stage camera (camera=off keeps the final framing).
(function () {
  "use strict";
  const A = window.A, svg = A.svg, lerp = A.lerp, Scenes = window.Scenes;
  const NEUTRAL = "#c9d1d9", DIM = "#8b949e", INK = "#0b0d12", RED = "#ff5c5c", GREEN = "#3fb950", WHITE = "#f0f6fc", AMBER = "#e3b341", SOFT = "#d5dce4", LINE = "#30363d";
  const FS = 28;
  const width = (str, size, mono) => (mono ? A.mono_w(str, size) : A.sans_w(str, size));
  // a text fitted to a width: it shrinks down to "min", then it is cut
  function fit(str, size, maxw, mono, min) {
    str = String(str == null ? "" : str); min = min || FS;
    let s = size;
    if (width(str, s, mono) > maxw) s = Math.max(min, Math.floor((s * maxw) / width(str, s, mono)));
    const full = str;
    while (str.length > 2 && width(str, s, mono) > maxw) str = str.slice(0, -2).trimEnd() + "…";
    if (str !== full) Scenes.cut(str, full);                           // the layout check (--look, the self-test) reports every text that was cut
    return { str, size: s, w: width(str, s, mono) };
  }
  function T(parent, x, y, str, o) {
    o = o || {};
    const f = fit(str, o.size || FS, o.max || 1e9, o.mono !== false && !!o.mono, o.min);
    const el = A.text(parent, x, y, f.str, { mono: !!o.mono, size: f.size, weight: o.weight || 600, fill: o.fill || SOFT, anchor: o.anchor || "middle", italic: o.italic, spacing: o.spacing });
    el._w = f.w; return el;
  }
  // words broken into lines of at most "chars" characters (at most "max" lines; the rest is cut)
  function wrap(str, chars, max) {
    const out = [""];
    for (const w of String(str).split(/\s+/)) { if ((out[out.length - 1] + " " + w).trim().length > chars && out[out.length - 1]) out.push(w); else out[out.length - 1] = (out[out.length - 1] + " " + w).trim(); }
    if (out.length > max) { out.length = max; out[max - 1] = Scenes.cut(out[max - 1].replace(/.{0,2}$/, "…"), str); }
    return out;
  }
  // a text broken into at most "max" lines no wider than maxw: at a space, else after / _ - . , : = or, when nothing else helps, anywhere.
  // What is still left over is cut (and reported).  A path or a long option breaks where a reader expects it.
  function wrapW(str, size, maxw, mono, max) {
    const out = []; let rest = String(str == null ? "" : str).trim(); max = max || 2;
    while (rest && out.length < max - 1 && width(rest, size, mono) > maxw) {
      let n = rest.length; while (n > 1 && width(rest.slice(0, n), size, mono) > maxw) n--;
      let at = rest.lastIndexOf(" ", n);
      if (at < n * 0.35) { const m = /^.*[\/_\-.,:=]/.exec(rest.slice(0, n)); at = m && m[0].length >= n * 0.35 ? m[0].length : n; }
      out.push(rest.slice(0, at).trimEnd()); rest = rest.slice(at).trimStart();
    }
    if (rest) { const f = fit(rest, size, maxw, mono, size); if (f.str !== rest) Scenes.cut(f.str, String(str)); out.push(f.str); }
    return out.length ? out : [""];
  }
  const COL = (K, kind) => ({ ok: GREEN, pass: GREEN, good: GREEN, bad: RED, fail: RED, stop: RED, wait: AMBER, pending: AMBER, skip: AMBER, hl: K.pal.accent2, bypass: K.pal.accent2, dim: DIM, ghost: DIM }[kind] || null);
  // a round verdict mark: tick, cross, or a ring that stays open; draw(t) lets it appear
  function mark(K, parent, x, y, kind, s) {
    s = s || 1;
    const g = svg("g", {}, parent), col = COL(K, kind) || NEUTRAL, good = col === GREEN, bad = col === RED;
    svg("circle", { cx: x, cy: y, r: 19 * s, fill: INK, stroke: col, "stroke-width": 4, "stroke-dasharray": good || bad ? null : "7 6" }, g);
    const glyph = good ? K.tick(g, x, y, 1.05 * s, col) : bad ? K.cross(g, x, y, 0.95 * s, col) : null;
    const n = K.tl.node(g, { o: 0, s: 1 });
    return { g, n, draw: (t) => { n.to(t, 0.2, { o: 1 }, "out"); if (glyph) K.tl.add(t + 0.1, 0.25, (p) => glyph.setAttribute("stroke-dashoffset", (1 - p).toFixed(3)), "out"); K.tl.sound(t + 0.12, "pop", bad ? 0.9 : 0.6); return t + 0.4; } };
  }
  // a pill with a word
  function pill(parent, cx, cy, str, o) {
    o = o || {};
    const f = fit(str, o.size || FS, o.max || 1e9, !!o.mono), w = f.w + (o.pad || 34), h = o.h || f.size * 1.75, g = svg("g", {}, parent);
    A.rect(g, cx - w / 2, cy - h / 2, w, h, { r: o.r == null ? h / 2 : o.r, fill: o.fill || INK, stroke: o.stroke || NEUTRAL, sw: o.sw == null ? 3 : o.sw, dash: o.dash });
    A.text(g, cx, cy + 1, f.str, { mono: !!o.mono, size: f.size, weight: o.weight || 700, fill: o.color || o.stroke || WHITE });
    return { g, w, h };
  }
  // a box with a title: {g, x, y, w, h, n, show(t)}
  function box(K, parent, x, y, w, h, o) {
    o = o || {};
    const g = svg("g", {}, parent), col = o.stroke || "#59636e";
    if (o.slab === false) A.rect(g, x, y, w, h, { r: 14, fill: o.fill || "#0e1218", stroke: col, sw: 3, dash: o.dash });
    else A.slab(g, x, y, w, h, { depth: o.depth || 12, stroke: col, fill: o.fill || "#0e1218" });
    if (o.title) T(g, x + 24, y + 40, o.title, { size: o.size || 30, weight: 800, fill: o.color || WHITE, anchor: "start", max: w - 48 - (o.sub && o.subRight ? width(o.sub, FS) + 20 : 0) });
    if (o.sub) T(g, o.subRight ? x + w - 22 : x + 24, o.subRight ? y + 40 : y + 78, o.sub, { size: FS, weight: 500, fill: DIM, anchor: o.subRight ? "end" : "start", max: w - 48 });
    const n = K.tl.node(g, { o: 0, y: 24 });
    return { g, x, y, w, h, n, show: (t) => { n.to(t, 0.42, { o: 1, y: 0 }, "out"); K.tl.sound(t + 0.1, "pop", 0.7); K.grow(x - 10, y - 24, x + w + 24, y + h + 24); return t + 0.42; } };
  }
  const num = (i) => String(i + 1);
  const fadeTo = (K, el, t, from, to, dur) => K.tl.add(t, dur || 0.3, (p) => el.setAttribute("opacity", lerp(from, to, p).toFixed(3)), "inOut");

  // =================================================================================================
  // flow: actors with lifelines; one message per step.
  //   params: {actors: [name], subs: [words under a name], msgs: [[from, to, label, mark]] (from / to: the actor's number; the same number twice: a note on
  //            that actor; mark: ok | fail | wait), boundary: N (a dashed line after actor N), zones: [left, right] (the two sides of that line), mono: "on", title}
  Scenes.defs.flow = {
    free: true, follow: true,
    steps: (P) => ["actors"].concat((P.msgs || []).map((_, i) => num(i))),
    build(K, P) {
      const tl = K.tl, pal = K.pal, actors = P.actors || ["A", "B"], n = actors.length, msgs = P.msgs || [], m = msgs.length, mono = P.mono === "on";
      const X0 = n > 3 ? 190 : 250, X1 = K.W - X0, xs = actors.map((_, i) => (n === 1 ? K.W / 2 : X0 + (i * (X1 - X0)) / (n - 1)));
      const gap = n > 1 ? xs[1] - xs[0] : 600, bw = Math.min(400, gap - 44), hasSub = (P.subs || []).some((x) => x && x !== "-"), top = 136;
      // a name too long for its box at the smallest size takes two lines, and every box grows by one line
      const nameLines = actors.map((nm) => { nm = nm.replace(/^\*/, ""); return width(nm, FS, false) <= bw - 30 ? [nm] : wrapW(nm, FS + 1, bw - 30, false, 2); });
      const two = nameLines.some((l) => l.length > 1) ? 34 : 0, bh = (hasSub ? 112 : 76) + two;
      const y0 = top + bh + 78, pitch = Math.min(96, Math.max(66, (K.H - 78 - y0) / Math.max(1, m - 1 || 1))), yEnd = y0 + (m - 1) * pitch + 54;
      const heads = actors.map((nm, i) => {
        const g = svg("g", {}, K.main), main = /^\*/.test(nm); nm = nm.replace(/^\*/, "");
        A.rect(g, xs[i] - bw / 2, top, bw, bh, { r: 14, fill: "#11151c", stroke: main ? pal.accent : NEUTRAL, sw: 3.5 });
        const nl = nameLines[i], ncy = hasSub ? top + 38 + two / 2 : top + bh / 2 + 1;
        nl.forEach((l, k) => T(g, xs[i], ncy + (k - (nl.length - 1) / 2) * 34, l, { size: nl.length > 1 ? FS + 1 : 31, weight: 800, fill: main ? pal.accent : WHITE, max: bw - 30 }));
        const sub = (P.subs || [])[i]; if (sub && sub !== "-") T(g, xs[i], top + 80 + two, sub, { size: FS, weight: 500, fill: DIM, max: bw - 26 });
        const life = svg("line", { x1: xs[i], y1: top + bh + 4, x2: xs[i], y2: yEnd, stroke: "#3a424d", "stroke-width": 4, "stroke-dasharray": "3 11", "stroke-linecap": "round" }, K.back);
        K.spot(nm, xs[i], top + bh / 2);
        return { n: tl.node(g, { o: 0, y: -20 }), ln: tl.node(life, { o: 0 }) };
      });
      // the line between two sides (a trust boundary, "the network")
      let bn = null;
      if (P.boundary && +P.boundary >= 1 && +P.boundary < n) {
        const g = svg("g", {}, K.back), bx = (xs[+P.boundary - 1] + xs[+P.boundary]) / 2, z = P.zones || [];
        svg("line", { x1: bx, y1: top - 14, x2: bx, y2: yEnd + 20, stroke: AMBER, "stroke-width": 4, "stroke-dasharray": "14 10" }, g);
        if (z[0]) T(g, bx - 26, yEnd + 6, z[0], { size: FS, weight: 800, fill: AMBER, anchor: "end", max: bx - 80 });
        if (z[1]) T(g, bx + 26, yEnd + 6, z[1], { size: FS, weight: 800, fill: AMBER, anchor: "start", max: K.W - bx - 80 });
        bn = tl.node(g, { o: 0 });
      }
      const rows = msgs.map(([a, b, label, mk], k) => {
        const ia = Math.max(0, Math.min(n - 1, +a - 1)), ib = Math.max(0, Math.min(n - 1, +b - 1)), y = y0 + k * pitch, g = svg("g", {}, K.main), col = COL(K, mk) || NEUTRAL;
        if (ia === ib) {                                                 // a note on one actor: something it does by itself
          // the note is centred on its actor; one that would leave the frame there moves inward instead of being cut
          const pw = Math.min(620, width(label, FS, mono)) + 34, cx = Math.max(30 + pw / 2, Math.min(K.W - 30 - (mk ? 50 : 0) - pw / 2, xs[ia]));
          const p = pill(g, cx, y, label, { mono, max: 620, stroke: mk ? col : pal.accent2, r: 12, color: WHITE, weight: 600 });
          const mm = mk ? mark(K, K.main, cx + p.w / 2 + 30, y, mk, 0.8) : null;
          return { n: tl.node(g, { o: 0, s: 0.85 }), note: true, mm, y, xa: cx - p.w / 2, xb: cx + p.w / 2 };
        }
        const dir = ib > ia ? 1 : -1, xa = xs[ia] + dir * 10, xb = xs[ib] - dir * 14;
        const line = svg("path", { d: `M${xa},${y} H${xb}`, fill: "none", stroke: col, "stroke-width": 5, "stroke-linecap": "round", pathLength: 1, "stroke-dasharray": "1 1", "stroke-dashoffset": 1 }, g);
        const head = svg("path", { d: `M${xb - dir * 18},${y - 11} L${xb},${y} L${xb - dir * 18},${y + 11}`, fill: "none", stroke: col, "stroke-width": 5, "stroke-linecap": "round", "stroke-linejoin": "round", opacity: 0 }, g);
        const lg = svg("g", {}, g), f = fit(label, FS + 1, Math.max(260, Math.abs(xb - xa) - (mk ? 110 : 50)), mono), lx = (xa + xb) / 2 - (mk ? dir * 22 : 0);
        A.rect(lg, lx - f.w / 2 - 12, y - 52, f.w + 24, 42, { r: 8, fill: "#0b0d12", o: 0.9 });
        A.text(lg, lx, y - 30, f.str, { mono, size: f.size, weight: 700, fill: mk === "fail" ? RED : WHITE });
        const ln = tl.node(lg, { o: 0, y: 8 });
        const mm = mk ? mark(K, K.main, xb - dir * 46, y - 31, mk, 0.8) : null;
        return { line, head, ln, mm, xa, xb, y, n: tl.node(g, { o: 1 }) };
      });
      const steps = [(t) => { t = K.title(t, P.title); heads.forEach((h, i) => { h.n.to(t + i * 0.14, 0.4, { o: 1, y: 0 }, "out"); h.ln.to(t + 0.3 + i * 0.14, 0.4, { o: 1 }, "out"); tl.sound(t + i * 0.14 + 0.08, "pop", 0.6); });
        if (bn) bn.to(t + 0.4 + n * 0.14, 0.4, { o: 1 }, "out");
        K.grow(xs[0] - bw / 2 - 10, top - 20, xs[n - 1] + bw / 2 + 10, bn ? yEnd + 30 : Math.min(yEnd, y0 + 40)); return t + 0.5 + n * 0.14; }];
      rows.forEach((r, k) => steps.push((t) => {
        K.grow(xs[0] - bw / 2 - 10, top - 20, xs[n - 1] + bw / 2 + 10, bn ? yEnd + 30 : r.y + 60);
        if (r.note) { r.n.to(t, 0.35, { o: 1, s: 1 }, "back"); tl.sound(t + 0.05, "pop", 0.7); if (r.mm) r.mm.draw(t + 0.3); return t + 0.6; }
        tl.add(t, 0.45, (p) => { r.line.setAttribute("stroke-dashoffset", (1 - p).toFixed(4)); r.head.setAttribute("opacity", p > 0.9 ? 1 : 0); }, "inOut");
        K.fly(t, r.xa, r.y, r.xb, r.y, { dur: 0.45, lift: 0, r: 11 });
        r.ln.to(t + 0.1, 0.35, { o: 1, y: 0 }, "out");
        if (r.mm) r.mm.draw(t + 0.5);
        return t + (r.mm ? 0.95 : 0.65);
      }));
      return { steps, fit: () => {}, stage: [30, 118, K.W - 60, K.H - 150] };
    },
  };

  // =================================================================================================
  // gates: a packet travels through checkpoints; each can let it pass, stop it, be skipped or be bypassed.
  //   params: {gates: [[name, owner, verdict, note]] (verdict: pass | stop | skip | bypass | wait | done), packet: what travels, zones: [a, b], split: N (the first
  //            N gates belong to the first zone), result: the words at the end, title}
  Scenes.defs.gates = {
    free: true, follow: true,
    steps: (P) => ["setup"].concat((P.gates || []).map((_, i) => num(i))).concat(P.result ? ["result"] : []),
    build(K, P) {
      const tl = K.tl, pal = K.pal, gates = P.gates || [], n = gates.length, RY = 430;
      const XL = 150, XR = K.W - (P.result ? 360 : 150), sp = n > 1 ? (XR - XL - 200) / (n - 1) : 0, gx = gates.map((_, i) => (n === 1 ? (XL + XR) / 2 : XL + 100 + i * sp));
      const GW = Math.min(200, Math.max(120, sp - 70)), GH = 190, tw = Math.max(GW, Math.min(sp - 24, 330)) || 330;
      // Many gates stand close together: a name that does not fit in one line at the smallest size takes two or three (then everything above the gates
      // moves up one line), and a note takes up to four lines instead of two (then the zone bands reach further down).
      const nameL = gates.map((g) => (width(g[0], FS, false) <= tw ? [g[0]] : wrapW(g[0], FS, tw, false, 3))), NU = (Math.max(1, ...nameL.map((l) => l.length)) - 1) * 34;
      const noteL = gates.map((g) => (g[3] ? wrap(g[3], Math.max(12, Math.floor(tw / 15)), 4) : []));
      const ownL = gates.map((g) => (!g[1] || g[1] === "-" ? [] : width(g[1], FS, false) <= tw ? [g[1]] : wrapW(g[1], FS, tw, false, 2)));
      const noteY = (i) => (ownL[i].length ? 46 + ownL[i].length * 34 : 40);      // where the note of gate i starts, below the gate
      const noteEnd = Math.max(0, ...gates.map((g, i) => (noteL[i].length ? noteY(i) + (noteL[i].length - 1) * 34 + 22 : ownL[i].length > 1 ? 38 + 34 + 22 : 0))), DOWN = Math.max(0, GH / 2 + noteEnd - 222);
      const rail = svg("line", { x1: XL - 70, y1: RY, x2: XR + 60, y2: RY, stroke: LINE, "stroke-width": 7, "stroke-linecap": "round" }, K.back);
      const rn = tl.node(rail, { o: 0 });
      const lit = svg("line", { x1: XL - 70, y1: RY, x2: XL - 70, y2: RY, stroke: pal.accent, "stroke-width": 7, "stroke-linecap": "round" }, K.back);
      // zones: the gates of one side stand on a band of their own
      const zn = [];
      if (P.zones && P.zones.length && n > 1) {
        const k = Math.max(1, Math.min(n - 1, +P.split || Math.ceil(n / 2))), cut = (gx[k - 1] + gx[k]) / 2;
        [[XL - 80, cut - 14, P.zones[0]], [cut + 14, XR + 70, P.zones[1]]].forEach(([a, b, name], i) => { if (!name) return; const g = svg("g", {}, K.back);
          A.rect(g, a, RY - 250 - NU, b - a, 480 + NU + DOWN, { r: 22, fill: i ? "#101a17" : "#12141c", stroke: "#3a424d", sw: 2.5, dash: "4 10" });
          T(g, a + 26, RY - 214 - NU, name.toUpperCase(), { size: FS, weight: 800, fill: DIM, anchor: "start", spacing: 2, max: b - a - 50 }); zn.push(tl.node(g, { o: 0 })); });
      }
      const pk = P.packet ? pill(K.main, 0, 0, P.packet, { mono: true, stroke: pal.accent2, r: 10, max: Math.max(560, K.W - 2 * XL - 40), weight: 600, color: WHITE }) : null;
      const pkn = pk ? tl.node(pk.g, { x: XL - 60 + pk.w / 2, y: RY - 300 - NU, o: 0 }) : null;
      const dotg = svg("g", {}, K.top); const dot = svg("circle", { r: 17, fill: pal.accent2, filter: "url(#glow)" }, dotg);
      const dn = tl.node(dotg, { x: XL - 70, y: RY, o: 0, s: 1 });
      const made = gates.map(([name, owner, verdict, note], i) => {
        const g = svg("g", {}, K.main), x = gx[i];
        const frame = svg("path", { d: `M${x - GW / 2},${RY + GH / 2} V${RY - GH / 2 + 16} a16,16 0 0 1 16,-16 H${x + GW / 2 - 16} a16,16 0 0 1 16,16 V${RY + GH / 2}`, fill: "#11151c", "fill-opacity": 0.6, stroke: NEUTRAL, "stroke-width": 6, "stroke-linecap": "round" }, g);
        nameL[i].forEach((l, k, all) => T(g, x, RY - GH / 2 - 34 - (all.length - 1 - k) * 34, l, { size: all.length > 1 ? FS : 30, weight: 800, fill: WHITE, max: tw }));
        ownL[i].forEach((l, k) => T(g, x, RY + GH / 2 + 38 + k * 34, l, { size: FS, weight: 500, fill: DIM, max: tw }));
        const ng = svg("g", {}, g); if (note) noteL[i].forEach((l, k) => T(ng, x, RY + GH / 2 + noteY(i) + k * 34, l, { size: FS, weight: 600, fill: pal.accent2, italic: true, max: tw + 10 }));
        const nn = tl.node(ng, { o: 0 });
        const mk = mark(K, K.top, x, RY - GH / 2 - 84 - NU, verdict === "done" ? "pass" : verdict, 1);
        const word = { skip: "skipped", bypass: "bypass", wait: "waits" }[verdict], wp = word ? pill(K.top, x, RY - GH / 2 - 84 - NU, word, { stroke: COL(K, verdict), size: FS, h: 44 }) : null;
        const wn = wp ? tl.node(wp.g, { o: 0, s: 0.6 }) : null;
        K.spot(name, x, RY);
        return { n: tl.node(g, { o: 0, y: 26 }), frame, nn, mk, wn, x, verdict };
      });
      const end = P.result ? svg("g", {}, K.main) : null;
      let stopped = false, at = XL - 70;
      const bad = gates.some((g) => g[2] === "stop");
      if (end) { const col = bad ? RED : GREEN; wrap(P.result, 14, 3).forEach((l, k, all) => T(end, XR + 204, RY - (all.length - 1) * 19 + k * 38, l, { size: 30, weight: 800, fill: col, max: 260 })); }
      const en = end ? tl.node(end, { o: 0, x: -20 }) : null;
      const steps = [(t) => { t = K.title(t, P.title); zn.forEach((z, i) => z.to(t + i * 0.15, 0.4, { o: 1 }, "out")); rn.to(t + 0.1, 0.4, { o: 1 }, "out");
        made.forEach((g, i) => { g.n.to(t + 0.25 + i * 0.12, 0.4, { o: 1, y: 0 }, "out"); tl.sound(t + 0.3 + i * 0.12, "pop", 0.55); });
        t += 0.5 + n * 0.12; if (pkn) pkn.to(t, 0.35, { o: 1 }, "out"); dn.to(t + 0.1, 0.3, { o: 1 }, "out");
        K.grow(XL - 90, RY - 270 - NU, P.result ? K.W - 16 : K.W - 120, RY + 250 + DOWN); return t + 0.5; }];
      made.forEach((g, i) => steps.push((t) => {
        if (stopped) { g.n.to(t, 0.35, { o: 0.32 }, "inOut"); return t + 0.35; }                 // never reached
        const from = at; at = g.x;
        dn.to(t, 0.55, { x: g.x }, "inOut"); tl.add(t, 0.55, (p) => lit.setAttribute("x2", lerp(from, g.x, p).toFixed(1)), "inOut"); tl.sound(t + 0.05, "whoosh", 0.5);
        t += 0.6;
        const col = COL(K, g.verdict === "done" ? "pass" : g.verdict) || NEUTRAL;
        tl.at(t, (p) => g.frame.setAttribute("stroke", p ? col : NEUTRAL));
        if (g.wn) { g.wn.to(t, 0.3, { o: 1, s: 1 }, "back"); tl.sound(t + 0.05, "pop", 0.6); } else g.mk.draw(t);
        g.nn.to(t + 0.15, 0.35, { o: 1 }, "out");
        if (g.verdict === "stop") { stopped = true; tl.at(t, (p) => { dot.setAttribute("fill", p ? RED : pal.accent2); lit.setAttribute("stroke", p ? RED : pal.accent); }); dn.pulse(t, 0.45, "x", -14); }
        if (g.verdict === "wait") stopped = true;
        return t + 0.6;
      }));
      if (end) steps.push((t) => { if (!stopped) { dn.to(t, 0.5, { x: XR + 50 }, "inOut"); const from = at; tl.add(t, 0.5, (p) => lit.setAttribute("x2", lerp(from, XR + 50, p).toFixed(1)), "inOut"); t += 0.4; }
        en.to(t, 0.4, { o: 1, x: 0 }, "out"); tl.sound(t + 0.1, "pop", 0.8); return t + 0.6; });
      return { steps, fit: () => {}, stage: [30, 118, K.W - 60, K.H - 150] };
    },
  };

  // =================================================================================================
  // layers: stacked layers, each with its items, and what they add up to.
  //   params: {layers: [[name, "item+item"]], verdicts: [pass | fail | bypass per layer], probe: what is being judged (drawn above), result: "item+item",
  //            rule: the words in front of the result, winner: N (that layer wins: the others fade), title}
  Scenes.defs.layers = {
    free: true, follow: true,
    steps: (P) => (P.layers || []).map((_, i) => num(i)).concat(P.result || P.winner ? ["result"] : []),
    build(K, P) {
      const tl = K.tl, pal = K.pal, layers = P.layers || [], n = layers.length, hasRes = !!(P.result || P.winner);
      const X = 110, W = K.W - 220, top = P.probe ? 232 : 150, RESH = 132, rh = Math.min(118, (K.H - 50 - top - (hasRes ? RESH + 40 : 0)) / Math.max(1, n) - 14), NW = 430;
      const probe = P.probe ? pill(K.main, K.W / 2, 176, P.probe, { mono: true, stroke: pal.accent2, r: 10, max: W - 100, weight: 600, color: WHITE, h: 56 }) : null;
      const pn = probe ? tl.node(probe.g, { o: 0, y: -14 }) : null;
      // items as pills, on one line or two; what still does not fit is counted ("+2 more")
      const chips = (g, x, y, list, maxw, col, lines) => {
        const items = String(list || "").split("+").map((x) => x.trim()).filter(Boolean); if (!items.length) return;
        const size = FS + 1, wOf = (it) => Math.min(maxw - 20, A.sans_w(it, size) + 34), rowsOut = [[]]; let used = 0, left = 0;
        for (let k = 0; k < items.length; k++) { const w = wOf(items[k]);
          if (used + w > maxw && rowsOut[rowsOut.length - 1].length) { if (rowsOut.length >= (lines || 1)) { left = items.length - k; break; } rowsOut.push([]); used = 0; }
          rowsOut[rowsOut.length - 1].push(items[k]); used += w + 14; }
        if (left) { const lastRow = rowsOut[rowsOut.length - 1]; let more = `+${left} more`; while (lastRow.length > 1 && lastRow.reduce((a, it) => a + wOf(it) + 14, 0) + A.sans_w(more, size) + 34 > maxw) { lastRow.pop(); left++; more = `+${left} more`; } lastRow.push(more); }
        rowsOut.forEach((row, r) => { let cx = x; const cy = y + (r - (rowsOut.length - 1) / 2) * 56;
          for (const it of row) { const p = pill(g, 0, 0, it, { size, stroke: col || NEUTRAL, max: maxw - 54, weight: 600, color: WHITE, h: 48 }); p.g.setAttribute("transform", `translate(${cx + p.w / 2},${cy})`); cx += p.w + 14; } });
      };
      const rows = layers.map(([name, items], i) => {
        const y = top + i * (rh + 14), g = svg("g", {}, K.main), v = (P.verdicts || [])[i];
        const frame = A.rect(g, X, y, W, rh, { r: 14, fill: "#11151c", stroke: "#59636e", sw: 3 });
        T(g, X + 26, y + rh / 2 + 1, name, { size: 30, weight: 800, fill: WHITE, anchor: "start", max: NW - 40 });
        svg("line", { x1: X + NW, y1: y + 14, x2: X + NW, y2: y + rh - 14, stroke: LINE, "stroke-width": 3 }, g);
        chips(g, X + NW + 24, y + rh / 2, items, W - NW - 48 - (v ? 70 : 0), null, rh >= 112 ? 2 : 1);
        const mk = v ? mark(K, K.main, X + W - 44, y + rh / 2, v, 0.95) : null;
        K.spot(name, X + W / 2, y + rh / 2);
        return { n: tl.node(g, { o: 0, x: -30 }), frame, mk, y };
      });
      const ry = top + n * (rh + 14) + 26, res = hasRes ? svg("g", {}, K.main) : null;
      if (res) { A.rect(res, X, ry, W, RESH, { r: 14, fill: INK, stroke: pal.accent2, sw: 4 });
        const rule = P.rule || (P.winner ? "wins" : "together"); T(res, X + 26, ry + RESH / 2 + 1, rule, { size: 30, weight: 800, fill: pal.accent2, anchor: "start", max: NW - 40 });
        svg("line", { x1: X + NW, y1: ry + 14, x2: X + NW, y2: ry + RESH - 14, stroke: LINE, "stroke-width": 3 }, res);
        chips(res, X + NW + 24, ry + RESH / 2, P.result || (layers[+P.winner - 1] || [])[1], W - NW - 48, pal.accent2, 2); }
      const rsn = res ? tl.node(res, { o: 0, y: 24 }) : null;
      const steps = rows.map((r, i) => (t) => { if (i === 0) { t = K.title(t, P.title); if (pn) { pn.to(t, 0.4, { o: 1, y: 0 }, "out"); t += 0.35; } }
        r.n.to(t, 0.4, { o: 1, x: 0 }, "out"); tl.sound(t + 0.06, "pop", 0.7); K.grow(X - 10, P.probe ? 130 : top - 20, X + W + 10, r.y + rh + 20);
        if (r.mk) r.mk.draw(t + 0.4); return t + (r.mk ? 0.85 : 0.5); });
      if (res) steps.push((t) => { K.grow(X - 10, top - 20, X + W + 10, ry + RESH + 20);
        const w = +P.winner; if (w >= 1 && w <= n) rows.forEach((r, i) => { if (i === w - 1) { tl.at(t, (p) => { r.frame.setAttribute("stroke", p ? pal.accent2 : "#59636e"); r.frame.setAttribute("stroke-width", p ? 5 : 3); }); r.n.pulse(t, 0.5, "x", 12); } else r.n.to(t, 0.4, { o: 0.4 }, "inOut"); });
        rsn.to(t + 0.3, 0.45, { o: 1, y: 0 }, "out"); tl.sound(t + 0.35, "pop", 0.9); return t + 0.85; });
      return { steps, fit: () => {}, stage: [30, 118, K.W - 60, K.H - 150] };
    },
  };

  // =================================================================================================
  // walk: a table that is read row by row.
  //   params: {columns: [name], rows: [[cell, ...]], marks: {"row.col": ok | bad | wait | hl | dim}, pick: N (that row is the answer), mono: "off", title}
  Scenes.defs.walk = {
    free: true, follow: true,
    steps: (P) => ["header"].concat((P.rows || []).map((_, i) => num(i))).concat(P.pick ? ["pick"] : []),
    build(K, P) {
      const tl = K.tl, pal = K.pal, cols = P.columns || [], rows = (P.rows || []).slice(0, 9), nc = Math.max(cols.length, ...rows.map((r) => r.length), 1), mono = P.mono !== "off";
      const AV = K.W - 200, top = 150, availRow = (K.H - 70 - top - 64) / Math.max(1, rows.length);
      const wantAt = (size) => Array.from({ length: nc }, (_, c) => Math.max(width(cols[c] || "", FS, false) + 20, ...rows.map((r) => width(r[c] || "", size, mono))) + 56);
      // A table too wide for the frame: first the cells take the smallest size, then the widest columns give way and their cells wrap
      // into as many lines as the rows have room for (three with up to four rows, two with five or six); what is still too long is cut.
      let CS = 30, want = wantAt(CS), sum = want.reduce((a, b) => a + b, 0), LN = 1;
      if (sum > AV) { CS = FS; want = wantAt(CS); sum = want.reduce((a, b) => a + b, 0); }
      if (sum > AV) {
        LN = availRow >= 126 ? 3 : availRow >= 94 ? 2 : 1;
        const floor = want.map((w, c) => Math.max(width(cols[c] || "", FS, false) + 76, (w - 56) / LN + 56 + (LN > 1 ? 40 : 0)));
        let lo = 0, hi = Math.max(...want);                          // the widest column width "cap" with which the table fits
        for (let i = 0; i < 40; i++) { const cap = (lo + hi) / 2; if (want.reduce((a, w, c) => a + Math.max(Math.min(w, cap), Math.min(w, floor[c])), 0) > AV) hi = cap; else lo = cap; }
        want = want.map((w, c) => Math.max(Math.min(w, lo), Math.min(w, floor[c]))); sum = want.reduce((a, b) => a + b, 0);
      }
      const k = sum > AV ? AV / sum : Math.min(1.25, AV / sum), cw = want.map((w) => w * k), TW = cw.reduce((a, b) => a + b, 0), X = (K.W - TW) / 2;
      const cells = rows.map((r) => r.map((cell, c) => (LN > 1 && width(cell, CS, mono) > cw[c] - 40 ? wrapW(cell, CS, cw[c] - 40, mono, LN) : [cell])));
      const used = Math.max(1, ...cells.map((r) => Math.max(1, ...r.map((l) => l.length))));
      const cx = cw.map((_, c) => X + cw.slice(0, c).reduce((a, b) => a + b, 0)), RH = Math.min(used > 1 ? 38 + 32 * used : 70, availRow);
      const hg = svg("g", {}, K.main); A.rect(hg, X, top, TW, 60, { r: 12, fill: "#161b22", stroke: "#59636e", sw: 3 });
      cols.forEach((c, i) => T(hg, cx[i] + 26, top + 31, c, { size: FS, weight: 800, fill: i === nc - 1 && P.last === "result" ? pal.accent2 : NEUTRAL, anchor: "start", max: cw[i] - 40 }));
      const hn = tl.node(hg, { o: 0, y: -16 });
      const made = rows.map((r, i) => { const y = top + 68 + i * RH, g = svg("g", {}, K.main);
        const bar = A.rect(g, X, y, TW, RH - 8, { r: 10, fill: "#11151c", stroke: LINE, sw: 2.5 }), hl = A.rect(g, X, y, TW, RH - 8, { r: 10, fill: pal.accent, o: 0 });
        r.forEach((cell, c) => { const mk = (P.marks || {})[`${i + 1}.${c + 1}`], col = COL(K, mk);
          cells[i][c].forEach((l, q, all) => T(g, cx[c] + 26, y + (RH - 8) / 2 + 1 + (q - (all.length - 1) / 2) * 32, l, { mono, size: CS, weight: mk && mk !== "dim" ? 700 : 500, fill: col || SOFT, anchor: "start", max: cw[c] - 40 })); });
        return { n: tl.node(g, { o: 0, x: -34 }), bar, hl, y }; });
      let cur = null;
      const steps = [(t) => { t = K.title(t, P.title); hn.to(t, 0.4, { o: 1, y: 0 }, "out"); K.grow(X - 10, top - 20, X + TW + 10, top + 80); return t + 0.5; }];
      made.forEach((r, i) => steps.push((t) => { if (cur) fadeTo(K, cur.hl, t, 0.16, 0, 0.3); cur = r;
        r.n.to(t, 0.4, { o: 1, x: 0 }, "out"); fadeTo(K, r.hl, t + 0.1, 0, 0.16, 0.3); tl.sound(t + 0.06, "pop", 0.75); K.grow(X - 10, top - 20, X + TW + 10, r.y + RH + 12); return t + 0.55; }));
      if (P.pick) steps.push((t) => { const w = Math.max(1, Math.min(made.length, +P.pick)) - 1; if (cur) fadeTo(K, cur.hl, t, 0.16, 0, 0.3);
        made.forEach((r, i) => { if (i === w) { tl.at(t + 0.2, (p) => { r.bar.setAttribute("stroke", p ? pal.accent2 : LINE); r.bar.setAttribute("stroke-width", p ? 5 : 2.5); }); fadeTo(K, r.hl, t + 0.2, 0, 0.2, 0.3); r.n.pulse(t + 0.2, 0.5, "x", 12); } else r.n.to(t, 0.4, { o: 0.42 }, "inOut"); });
        tl.sound(t + 0.25, "pop", 0.9); return t + 0.8; });
      return { steps, fit: () => {}, stage: [30, 118, K.W - 60, K.H - 150] };
    },
  };

  // =================================================================================================
  // match: a list of patterns and the paths they are asked about; the script says which lines match, the scene shows which one wins.
  //   params: {header: the file, rules: [[pattern, value]], paths: [[path, "1+5"]] (the numbers of the lines that match), wins: last | first | all,
  //            none_text: what a path gets that nothing matches, numbers: [the line numbers to print], title}
  Scenes.defs.match = {
    free: true, follow: true,
    steps: (P) => ["rules"].concat((P.paths || []).map((_, i) => num(i))),
    build(K, P) {
      const tl = K.tl, pal = K.pal, rules = (P.rules || []).slice(0, 8), paths = (P.paths || []).slice(0, 5), wins = P.wins || "last";
      const LX = 60, LW = 900, top = 150, RH = Math.min(64, (K.H - 70 - top - 70) / Math.max(1, rules.length)), LH = 70 + rules.length * RH + 14;
      const card = box(K, K.main, LX, top, LW, LH, { title: P.header || "rules", stroke: pal.accent, color: pal.accent, slab: true, sub: wins === "first" ? "first match wins" : wins === "all" ? "every match counts" : "last match wins", subRight: true });
      const pw = Math.max(...rules.map((r) => A.mono_w(r[0], 30))), pcol = Math.min(pw + 30, LW * 0.5);
      const rr = rules.map(([pat, val], i) => { const y = top + 70 + i * RH, g = svg("g", {}, card.g), nmb = String((P.numbers || [])[i] || i + 1);
        const hl = A.rect(g, LX + 12, y, LW - 24, RH - 6, { r: 8, fill: pal.accent2, o: 0 });
        T(g, LX + 56, y + (RH - 6) / 2 + 1, nmb, { mono: true, size: FS, fill: DIM, weight: 500, anchor: "end" });
        T(g, LX + 80, y + (RH - 6) / 2 + 1, pat, { mono: true, size: 30, fill: WHITE, weight: 600, anchor: "start", max: pcol });
        T(g, LX + 80 + pcol + 30, y + (RH - 6) / 2 + 1, val, { mono: true, size: 29, fill: pal.accent2, weight: 500, anchor: "start", max: LW - 80 - pcol - 60 });
        return { hl, y: y + (RH - 6) / 2 }; });
      const PX = LX + LW + 150, PW = K.W - PX - 50, PH = Math.min(128, (K.H - 60 - top) / Math.max(1, paths.length) - 16);
      const pp = paths.map(([path, hits], i) => { const y = top + i * (PH + 16), g = svg("g", {}, K.main), ids = String(hits || "").split("+").map((x) => +x).filter((x) => x >= 1 && x <= rules.length);
        const win = wins === "first" ? ids[0] : ids[ids.length - 1], val = !ids.length ? P.none_text || "no match" : wins === "all" ? ids.map((x) => rules[x - 1][1]).join("  ") : rules[win - 1][1];
        A.rect(g, PX, y, PW, PH, { r: 12, fill: "#11151c", stroke: NEUTRAL, sw: 3 });
        T(g, PX + 22, y + PH * 0.3 + 2, path, { mono: true, size: 30, fill: WHITE, weight: 700, anchor: "start", max: PW - 44 });
        const vg = svg("g", {}, g); T(vg, PX + 22, y + PH * 0.72, val, { mono: !!ids.length, size: 29, fill: ids.length ? pal.accent2 : DIM, weight: 600, italic: !ids.length, anchor: "start", max: PW - 44 });
        const ar = ids.length ? K.arrow(K.back, LX + LW + 18, rr[win - 1].y, PX - 10, y + PH / 2, { stroke: pal.accent2, sw: 4 }) : null;
        K.spot(path, PX + PW / 2, y + PH / 2);
        return { n: tl.node(g, { o: 0, x: 30 }), vn: tl.node(vg, { o: 0 }), ar, arn: null, ids, win, y }; });
      let lit = [];
      const steps = [(t) => { t = K.title(t, P.title); return card.show(t) + 0.1; }];
      pp.forEach((p, i) => steps.push((t) => {
        for (const h of lit) fadeTo(K, h, t, 0.3, 0, 0.25); lit = [];
        pp.slice(0, i).forEach((q) => { if (q.ar) fadeTo(K, q.ar.g, t, 1, 0.3, 0.3); });
        p.n.to(t, 0.4, { o: 1, x: 0 }, "out"); tl.sound(t + 0.05, "pop", 0.75); K.grow(LX - 10, top - 24, PX + PW + 10, Math.max(top + LH, p.y + PH) + 24); t += 0.5;
        p.ids.forEach((id, k) => { const h = rr[id - 1].hl, keep = wins === "all" || id === p.win;
          if (keep) { fadeTo(K, h, t + k * 0.28, 0, 0.3, 0.25); lit.push(h); } else tl.add(t + k * 0.28, 0.7, (q) => h.setAttribute("opacity", (0.26 * q).toFixed(3)), "there");
          tl.sound(t + k * 0.28 + 0.02, "tick", 0.8); });
        t += p.ids.length * 0.28 + 0.2;
        if (p.ar) t = p.ar.draw(t, 0.4);
        p.vn.to(t - 0.1, 0.35, { o: 1 }, "out"); return t + 0.4;
      }));
      return { steps, fit: () => {}, stage: [30, 118, K.W - 60, K.H - 150] };
    },
  };
  Scenes.util = { fit, T, wrap, wrapW, width, COL, mark, pill, box, num, fadeTo, FS };
})();
