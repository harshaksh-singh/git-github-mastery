// Explainer scenes for the course videos: parameterised SVG scenes with named steps.
// A scene is built once per page; earlier steps are replayed instantly, the requested steps are animated.
// Colour meaning (the same in every scene):
//   commits            neutral grey outline            current branch / HEAD   the part's accent, filled
//   other branches     light outline                   remote-tracking labels  dashed outline
//   new or in focus    accent2 glow                    unreachable ("ghost")   dashed, faded
//   destructive action red, with a warning triangle    success                 green tick
//   tags               a tag-shaped chip (pointed, with a hole)        special refs (ORIG_HEAD ...)  small hollow square chip
//   a failed check     red cross                                       a pending check or review     amber ring
(function () {
  "use strict";
  const A = window.A, svg = A.svg, lerp = A.lerp;
  const NEUTRAL = "#c9d1d9", DIM = "#8b949e", INK = "#0b0d12", RED = "#ff5c5c", GREEN = "#3fb950", WHITE = "#f0f6fc", AMBER = "#e3b341";
  const SPECIAL_REF = /^(ORIG|MERGE|FETCH|CHERRY_PICK|REVERT|REBASE|BISECT|AUTO_MERGE)_HEAD$/;
  const Scenes = (window.Scenes = { defs: {} });

  // ---- commit graph ------------------------------------------------------------------------------
  class Graph {
    constructor(K, parent, o) {
      this.K = K; this.tl = K.tl; this.pal = K.pal;
      this.o = Object.assign({ dx: 190, dy: 150, r: 24, ox: 0, oy: 0, prefer: {}, order: ["right", "below", "above", "left"] }, o || {});
      this.g = svg("g", {}, parent);
      this.eL = svg("g", {}, this.g); this.nL = svg("g", {}, this.g); this.lL = svg("g", {}, this.g);
      this.c = {}; this.chips = {}; this.shown = {}; this.vis = new Set(); this.notes = {}; this.map = {};
      this.ext = [1e9, 1e9, -1e9, -1e9];
      (K.graphs = K.graphs || []).push(this);
      this.tl.after.push(() => this.redraw());
    }
    xy(col, row) { return { x: this.o.ox + col * this.o.dx, y: this.o.oy + row * this.o.dy }; }
    grow(b) { const e = this.ext; e[0] = Math.min(e[0], b[0]); e[1] = Math.min(e[1], b[1]); e[2] = Math.max(e[2], b[2]); e[3] = Math.max(e[3], b[3]); }
    commit(id, col, row, parents, opt) {
      opt = opt || {};
      const p = this.xy(col, row), inside = (opt.text || id).length <= 2, r = inside ? this.o.r + 4 : this.o.r;
      const g = svg("g", {}, this.nL);
      const ring = svg("circle", { r: r + 13, fill: "none", stroke: this.pal.accent2, "stroke-width": 5, opacity: 0, filter: "url(#glow)" }, g);
      const circle = svg("circle", { r, fill: INK, stroke: NEUTRAL, "stroke-width": 5 }, g);
      const label = inside ? A.text(g, 0, 1, opt.text || id, { size: 26, fill: WHITE }) : A.text(g, 0, r + 24, opt.text || id, { size: 21, fill: DIM, weight: 500 });
      const n = this.tl.node(g, { x: p.x, y: p.y, s: 0, o: 0 });
      const c = { id, col, row, r, inside, g, ring, circle, label, n, parents: parents || [], edges: [], ringV: 0, ghost: 0, hot: 0 };
      for (const pa of c.parents) c.edges.push({ from: pa, p: 0, hot: 0, el: svg("path", { fill: "none", stroke: NEUTRAL, "stroke-width": 5, "stroke-linecap": "round", pathLength: 1, "stroke-dasharray": "1 1" }, this.eL) });
      this.c[id] = c;
      return c;
    }
    show(t, id, o) {
      o = o || {};
      const c = this.c[id];
      {                                                               // only commits that are shown claim room in the frame
        const p = this.xy(c.col, c.row), r = c.r;
        this.grow([p.x - r - 8, p.y - r - 8, p.x + r + 8, p.y + r + (c.inside ? 8 : 40)]);
        if (!c.inside) this.grow([p.x - A.mono_w(id, 21) / 2, p.y, p.x + A.mono_w(id, 21) / 2, p.y + r + 38]);
      }
      for (const e of c.edges) this.tl.add(t, 0.26, (p) => { e.p = p; }, "inOut");
      const t1 = c.edges.length ? t + 0.16 : t;
      c.n.to(t1, 0.34, { s: 1, o: 1 }, "back");
      if (!o.quiet) this.tl.sound(t1 + 0.04, "pop", o.gain || 0.8);
      if (o.glow) this.focus(t1 + 0.1, id, 0.7);
      this.vis.add(id);
      return t1 + 0.34;
    }
    showAll(t, ids, gap) { let end = t; (ids || Object.keys(this.c)).forEach((id, i) => { end = this.show(t + i * (gap == null ? 0.24 : gap), id); }); return end; }
    focus(t, id, dur) {                                               // a ring that swells and fades: "look here"
      const c = this.c[id]; dur = dur || 0.9;
      this.tl.add(t, dur, (p) => { c.ringV = p; }, "there");
      c.n.pulse(t, dur, "s", 0.16);
      return t + dur;
    }
    heat(t, id, on, dur) { const c = this.c[id]; return this.tl.add(t, dur || 0.3, (p) => { c.hot = on ? p : 1 - p; }, "inOut"); }
    heatEdge(t, child, parent, on, dur) { const e = this.c[child].edges.find((x) => x.from === parent); return this.tl.add(t, dur || 0.35, (p) => { e.hot = on ? p : 1 - p; }, "inOut"); }
    ghost(t, id, on) {
      const c = this.c[id];
      return this.tl.add(t, 0.45, (p) => { c.ghost = on === false ? 1 - p : p; }, "inOut");
    }
    move(t, id, col, row, dur) { const p = this.xy(col, row); const c = this.c[id]; c.col = col; c.row = row; this.grow([p.x - 60, p.y - 40, p.x + 60, p.y + 70]); return c.n.to(t, dur || 0.6, { x: p.x, y: p.y }, "inOut"); }
    redraw() {
      for (const id in this.c) {
        const c = this.c[id], v = c.n.v, gh = c.ghost;
        c.ring.setAttribute("opacity", (c.ringV * 0.95).toFixed(3));
        c.circle.setAttribute("stroke", c.hot > 0 ? A.mix(NEUTRAL, this.pal.accent2, c.hot) : NEUTRAL);
        c.circle.setAttribute("stroke-dasharray", gh > 0.5 ? "7 7" : "none");
        c.g.setAttribute("opacity", (Math.min(1, v.o) * lerp(1, 0.38, gh)).toFixed(3));
        for (const e of c.edges) {
          const a = this.c[e.from].n.v, dx = v.x - a.x, dy = v.y - a.y, d = Math.hypot(dx, dy) || 1;
          const r0 = this.c[e.from].r + 4, r1 = c.r + 4;
          const x0 = a.x + (dx / d) * r0, y0 = a.y + (dy / d) * r0, x1 = v.x - (dx / d) * r1, y1 = v.y - (dy / d) * r1;
          e.el.setAttribute("d", `M${x0.toFixed(1)},${y0.toFixed(1)} L${x1.toFixed(1)},${y1.toFixed(1)}`);
          e.el.setAttribute("stroke-dashoffset", (1 - e.p).toFixed(4));
          e.el.setAttribute("stroke", e.hot > 0 ? A.mix(NEUTRAL, this.pal.accent2, e.hot) : NEUTRAL);
          e.el.setAttribute("stroke-dasharray", gh > 0.5 || this.c[e.from].ghost > 0.5 ? "0.06 0.06" : "1 1");
          e.el.setAttribute("opacity", (e.p > 0.001 ? lerp(1, 0.35, Math.max(gh, this.c[e.from].ghost)) * Math.min(1, a.o * 2) : 0).toFixed(3));
        }
      }
      for (const k in this.chips) this.chips[k].paint();
      if (this.box) this.applyCam();
    }
    // ---- labels ----
    chip(name, kind) {
      if (this.chips[name]) return this.chips[name];
      const pal = this.pal, big = kind !== "head" && kind !== "special";
      const size = big ? 22 : 17, h = big ? 40 : 30;
      let w = A.mono_w(name, size) + (big ? 26 : 18);
      const g = svg("g", {}, this.lL);
      let body;
      if (kind === "tag") {                                          // a tag: the shape of a luggage tag, pointed at the left, with a hole
        const pt = 20; w += pt - 4;
        const x0 = -w / 2, x1 = w / 2, hh = h / 2;
        svg("path", { d: `M${x0},0 L${x0 + pt},${-hh} H${x1 - 7} a7,7 0 0 1 7,7 V${hh - 7} a7,7 0 0 1 -7,7 H${x0 + pt} Z`, fill: "#232b38", stroke: WHITE, "stroke-width": 3, "stroke-linejoin": "round" }, g);
        svg("circle", { cx: x0 + pt - 3, cy: 0, r: 4.5, fill: INK, stroke: WHITE, "stroke-width": 2 }, g);
        A.text(g, pt / 2 + 3, 1, name, { size, fill: WHITE });
        const ch = { name, kind, g, w, h, n: this.tl.node(g, { o: 0, s: 0.4 }), cur: 0, danger: 0, paint: () => {} };
        this.chips[name] = ch; return ch;
      }
      if (kind === "special") {                                      // ORIG_HEAD, MERGE_HEAD ...: a small hollow chip with square corners (HEAD's size, not a branch)
        A.rect(g, -w / 2, -h / 2, w, h, { r: 2, fill: INK, stroke: WHITE, sw: 2.5 });
        A.text(g, 0, 1, name, { size, fill: WHITE, weight: 500 });
        const ch = { name, kind, g, w, h, n: this.tl.node(g, { o: 0, s: 0.4 }), cur: 0, danger: 0, paint: () => {} };
        this.chips[name] = ch; return ch;
      }
      if (kind === "note") {
        const tw = A.sans_w(name, 24);
        body = A.text(g, 0, 0, name, { mono: false, size: 24, weight: 500, fill: "#aeb8c4", italic: true });
        const tip = svg("path", { d: "M-9,0 L0,-12 L9,0 Z", fill: "#aeb8c4" }, g);
        const ch = { name, kind, g, w: tw + 8, h: 32, n: this.tl.node(g, { o: 0 }), cur: 0, side: "below" };
        ch.paint = () => { tip.setAttribute("transform", ch.side === "above" ? "translate(0,22) rotate(180)" : "translate(0,-20)"); tip.setAttribute("opacity", ch.side === "below" || ch.side === "above" ? 1 : 0); };
        this.chips[name] = ch; return ch;
      }
      const filled = svg("rect", { x: -w / 2, y: -h / 2, width: w, height: h, rx: 9, fill: kind === "head" ? WHITE : pal.accent }, g);
      const outline = svg("rect", { x: -w / 2, y: -h / 2, width: w, height: h, rx: 9, fill: INK, stroke: kind === "remote" ? DIM : NEUTRAL, "stroke-width": 3,
        "stroke-dasharray": kind === "remote" ? "8 6" : null }, g);
      body = A.text(g, 0, 1, name, { size, fill: INK });
      const ch = { name, kind, g, w, h, n: this.tl.node(g, { o: 0, s: 0.4 }), cur: kind === "head" ? 1 : 0, danger: 0 };
      ch.paint = () => {
        outline.setAttribute("opacity", (1 - ch.cur).toFixed(3));
        filled.setAttribute("fill", ch.danger > 0 ? A.mix(kind === "head" ? WHITE : pal.accent, RED, ch.danger) : kind === "head" ? WHITE : pal.accent);
        body.setAttribute("fill", ch.cur > 0.5 ? INK : kind === "remote" ? "#aeb8c4" : WHITE);
      };
      this.chips[name] = ch; return ch;
    }
    kindOf(name) {
      if (name === "HEAD") return "head";
      if ((this.o.tags || []).includes(name) || /^v\d+(\.\d+)+[\w.-]*$/.test(name)) return "tag";
      if ((this.o.special || []).includes(name) || SPECIAL_REF.test(name)) return "special";
      return /^(origin|upstream)\//.test(name) || (this.o.remote || []).includes(name) ? "remote" : "branch";
    }
    layout(map, notes) {
      const o = this.o, res = {}, placed = [], segs = [], obst = [];
      for (const id of this.vis) {
        const c = this.c[id], p = this.xy(c.col, c.row);
        obst.push([p.x - c.r - 4, p.y - c.r - 4, p.x + c.r + 4, p.y + c.r + 4]);
        if (!c.inside) obst.push([p.x - A.mono_w(id, 21) / 2 - 2, p.y + c.r + 10, p.x + A.mono_w(id, 21) / 2 + 2, p.y + c.r + 38]);
        for (const pa of c.parents) if (this.vis.has(pa)) { const q = this.xy(this.c[pa].col, this.c[pa].row); segs.push([q.x, q.y, p.x, p.y]); }
      }
      const hit = (b) => {
        for (const q of obst.concat(placed)) if (b[0] < q[2] && b[2] > q[0] && b[1] < q[3] && b[3] > q[1]) return true;
        for (const s of segs) { const n = Math.ceil(Math.hypot(s[2] - s[0], s[3] - s[1]) / 10); for (let i = 0; i <= n; i++) { const x = lerp(s[0], s[2], i / n), y = lerp(s[1], s[3], i / n); if (x > b[0] && x < b[2] && y > b[1] && y < b[3]) return true; } }
        return false;
      };
      const head = map.HEAD, byCommit = {};
      for (const name in map) {
        if (name === "HEAD") continue;
        (byCommit[map[name]] = byCommit[map[name]] || []).push(name === head ? [name, "HEAD"] : [name]);
      }
      if (head && !(head in map) && this.c[head]) (byCommit[head] = byCommit[head] || []).unshift(["HEAD"]);
      for (const nk in notes || {}) (byCommit[notes[nk].at] = byCommit[notes[nk].at] || []).push([nk]);
      const ids = Object.keys(byCommit).filter((id) => this.c[id]).sort((a, b) => this.c[a].col - this.c[b].col || this.c[a].row - this.c[b].row);
      for (const id of ids) {
        const c = this.c[id], p = this.xy(c.col, c.row), rows = byCommit[id];
        const rank = (r) => (r.length > 1 ? 0 : { branch: 1, remote: 2, tag: 3, special: 4, note: 5 }[this.chip(r[0], this.kindOf(r[0])).kind] || 1);
        rows.sort((a, b) => rank(a) - rank(b));                       // the current branch first, then other branches, remote-tracking names, tags, special refs, notes
        const dims = rows.map((r) => r.map((nm) => this.chip(nm, this.kindOf(nm))));
        const rw = dims.map((r) => r.reduce((s, ch) => s + ch.w, 0) + 6 * (r.length - 1));
        const idGap = c.inside ? 0 : 30, RH = 46;
        const isNote = dims.every((r) => r[0].kind === "note");
        let order = (o.prefer[rows[0][0]] ? [o.prefer[rows[0][0]]] : []).concat(isNote ? ["below", "above", "right", "left"] : o.order);
        let best = null;
        for (const cand of order) {
          const boxes = [];
          dims.forEach((r, k) => {
            let cx, cy;
            const side = rows.length > 1 && !c.inside ? Math.max(c.r + 16, A.mono_w(id, 21) / 2 + 14) : c.r + 16;
            if (cand === "right") { cx = p.x + side + rw[k] / 2; cy = p.y + (k - (rows.length - 1) / 2) * RH; }
            else if (cand === "left") { cx = p.x - side - rw[k] / 2; cy = p.y + (k - (rows.length - 1) / 2) * RH; }
            else if (cand === "below") { cx = p.x; cy = p.y + c.r + idGap + (isNote ? 42 : 34) + k * RH; }
            else { cx = p.x; cy = p.y - c.r - 32 - k * RH; }
            boxes.push([cx - rw[k] / 2 - 5, cy - 22, cx + rw[k] / 2 + 5, cy + 22, k]);
          });
          const bad = boxes.some(hit);
          if (!best || !bad) best = { boxes, cand };
          if (!bad) break;
        }
        best.boxes.forEach((b) => {
          placed.push(b); this.grow(b);
          let x = b[0] + 5;
          dims[b[4]].forEach((ch) => { res[ch.name] = { x: x + ch.w / 2, y: (b[1] + b[3]) / 2 + (ch.kind === "head" ? 0 : 0), side: best.cand }; x += ch.w + 6; });
        });
      }
      return res;
    }
    // move every label to where "map" says it belongs: new ones pop in, the others slide
    refs(t, map, o) {
      o = o || {};
      const res = this.layout(map, this.notes), head = map.HEAD;
      let end = t, k = 0;
      for (const name in this.shown) if (!(name in res)) { const ch = this.chips[name]; ch.n.to(t, 0.25, { o: 0, s: 0.6 }, "in"); delete this.shown[name]; }
      for (const name in res) {
        const ch = this.chips[name], q = res[name], was = this.shown[name];
        if (ch.kind === "note") ch.side = q.side;
        if (!was) {
          if (!ch.used) { ch.used = true; ch.n.base.x = ch.n.v.x = ch.n.plan.x = q.x; ch.n.base.y = ch.n.v.y = ch.n.plan.y = q.y; }
          else ch.n.to(t, 0.001, { x: q.x, y: q.y }, "lin");
          end = Math.max(end, ch.n.to(t + 0.07 * k, ch.kind === "note" ? 0.4 : 0.32, { o: 1, s: 1 }, ch.kind === "note" ? "out" : "back")); k++;
        } else if (Math.abs(was.x - q.x) > 0.5 || Math.abs(was.y - q.y) > 0.5) {
          const far = Math.hypot(q.x - was.x, q.y - was.y) > 90 && ch.kind !== "note";
          const dur = o.dur || (far ? 0.75 : 0.4), v = ch.n.v, fx = was.x, fy = was.y, lift = far ? (o.lift == null ? 34 : o.lift) * (q.side === "below" && was.side === "below" ? -1 : 1) : 0;
          this.tl.add(t, dur, (p) => { v.x = lerp(fx, q.x, p); v.y = lerp(fy, q.y, p) - lift * 4 * p * (1 - p); }, o.ease || "inOut");
          ch.n.plan.x = q.x; ch.n.plan.y = q.y;
          if (far && !o.quiet) this.tl.sound(t + 0.05, "whoosh", 0.7);
          end = Math.max(end, t + dur);
        }
        if (ch.kind === "branch") { const cur = name === head ? 1 : 0; if (ch.curPlan !== cur) { const f = ch.curPlan || 0; this.tl.add(t, 0.3, (p) => { ch.cur = lerp(f, cur, p); }, "inOut"); ch.curPlan = cur; } }
        this.shown[name] = q;
      }
      this.map = Object.assign({}, map);
      return end;
    }
    note(t, key, at) { this.notes[key] = { at }; this.chip(key, "note"); return this.refs(t, this.map); }
    unnote(t, key) { delete this.notes[key]; return this.refs(t, this.map); }
    // scale and centre the whole graph in a box
    fit(x, y, w, h, maxScale) {
      this.box = [x, y, w, h, maxScale || 1.5];
      this.cam = this.frame(this.ext); this.final = Object.assign({}, this.cam); this.camPlan = Object.assign({}, this.cam);
      this.applyCam();
      this.scale = this.cam.s;
      return this.cam.s;
    }
    // where the camera must stand to centre the extent "e" in the box given to fit(); "cap" limits the zoom
    frame(e, cap) {
      const [x, y, w, h, ms] = this.box, bw = e[2] - e[0], bh = e[3] - e[1];
      if (!(bw > 0 && bh > 0)) return { tx: 0, ty: 0, s: 1 };                                                              // nothing shown yet
      const s = Math.min(w / bw, h / bh, ms, cap || 1e9);
      return { s, tx: x + (w - bw * s) / 2 - e[0] * s, ty: y + (h - bh * s) / 2 - e[1] * s };
    }
    applyCam() { const c = this.cam; this.g.setAttribute("transform", `translate(${c.tx.toFixed(1)},${c.ty.toFixed(1)}) scale(${c.s.toFixed(4)})`); }
    // a gentle re-fit: the frame follows what is on screen so far (never more than 25 % closer than the final framing)
    camTo(t, e, dur) {
      if (!this.box) return t;
      const to = this.frame(e, this.final.s * 1.25), from = this.camPlan, cam = this.cam;
      if (dur === 0) { Object.assign(cam, to); this.camBase = Object.assign({}, to); this.camPlan = to; this.applyCam(); return t; }
      if (Math.abs(to.tx - from.tx) < 2 && Math.abs(to.ty - from.ty) < 2 && Math.abs(to.s - from.s) < 0.004) return t;
      this.camPlan = to;
      return this.tl.add(t, dur || 0.8, (p) => { cam.tx = lerp(from.tx, to.tx, p); cam.ty = lerp(from.ty, to.ty, p); cam.s = lerp(from.s, to.s, p); }, "inOut");
    }
  }
  Scenes.Graph = Graph;

  // ---- shared furniture: the frame of a scene ----------------------------------------------------
  function kit(tl, cfg) {
    const host = document.getElementById("scene");
    const W = 1728, H = cfg.h || 860;
    host.innerHTML = "";
    const root = svg("svg", { width: W, height: H, viewBox: `0 0 ${W} ${H}` }, host);
    A.defs(root);
    const K = { tl, cfg, pal: cfg.palette, W, H, root, back: svg("g", {}, root), main: svg("g", {}, root), top: svg("g", {}, root), cmds: [], caps: [] };
    // parameters every scene understands: captions=off, cmd=off, say_<step>=text|off, cmd_<step>=text|off (the step being built is K.step)
    const PP = cfg.params || {};
    K.step = null; K.said = {};
    const over = (kind) => (PP[kind] && typeof PP[kind] === "object" ? PP[kind][K.step] : undefined);
    // one command line at the bottom of the scene; a new command replaces the old one
    K.cmd = (t, text, o) => {
      o = o || {};
      const ovc = over("cmds");
      if (PP.cmd === "off" || ovc === "off") return t;
      if (ovc) { if (K.said["c" + K.step]) return t; K.said["c" + K.step] = 1; text = ovc; }
      const size = 30, w = A.mono_w("$ " + text, size) + 64 + (o.danger ? 46 : 0), g = svg("g", {}, K.top), col = o.danger ? RED : K.pal.accent;
      A.rect(g, -w / 2, -32, w, 64, { r: 14, fill: "#0b0d12", stroke: col, sw: 3 });
      let x = -w / 2 + 32;
      if (o.danger) { svg("path", { d: `M${x + 15},-17 l17,31 h-34 z`, fill: "none", stroke: RED, "stroke-width": 4, "stroke-linejoin": "round" }, g); A.text(g, x + 15, 3, "!", { size: 22, fill: RED }); x += 46; }
      A.text(g, x, 1, "$", { size, fill: col, anchor: "start" });
      const body = A.text(g, x + A.mono_w("$ ", size), 1, text, { size, fill: WHITE, anchor: "start" });
      const clip = svg("clipPath", { id: "cc" + K.cmds.length }, g), cr = svg("rect", { x: x + A.mono_w("$ ", size), y: -30, width: 0, height: 60 }, clip);
      body.setAttribute("clip-path", `url(#cc${K.cmds.length})`);
      const n = tl.node(g, { x: W / 2, y: H - 46, o: 0, s: 0.9 });
      for (const old of K.cmds) if (old.plan.o > 0) old.to(t, 0.2, { o: 0, y: H - 20 }, "in");
      n.to(t + 0.12, 0.25, { o: 1, s: 1 }, "out");
      const d = Math.min(0.7, text.length / 34), full = A.mono_w(text, size) + 4;
      tl.add(t + 0.3, d, (p) => { cr.setAttribute("width", (Math.round(text.length * p) * size * 0.6021 + (p >= 1 ? 4 : 0)).toFixed(1)); }, "lin");
      for (let i = 0; i < 5; i++) tl.sound(t + 0.3 + (d * i) / 5, "tick", 0.6);
      K.cmds.push(n);
      return t + 0.3 + d + 0.12;
    };
    K.cmdOff = (t) => { for (const old of K.cmds) if (old.plan.o > 0) old.to(t, 0.25, { o: 0 }, "in"); return t + 0.25; };
    // a short caption under the title: one idea at a time
    K.say = (t, text, o) => {
      o = o || {};
      const slot = o.slot || "main", ovs = over("say");
      if (PP.captions === "off" || ovs === "off") return t + 0.3;
      if (ovs) { if (K.said["s" + K.step + slot]) return t + 0.3; K.said["s" + K.step + slot] = 1; text = ovs; }
      const g = svg("g", {}, K.top);
      let size = o.size || 32;
      const room = (o.anchor || "middle") === "middle" ? 2 * Math.min(o.x == null ? W / 2 : o.x, W - (o.x == null ? W / 2 : o.x)) - 40 : W - 80;
      if (A.sans_w(text, size) > room) size = Math.max(20, Math.floor((size * room) / A.sans_w(text, size)));       // a long caption shrinks to fit
      A.text(g, 0, 0, text, { mono: false, size, weight: 600, fill: o.fill || "#d5dce4", anchor: o.anchor || "middle" });
      const n = tl.node(g, { x: o.x == null ? W / 2 : o.x, y: (o.y == null ? 96 : o.y) + 14, o: 0 });
      for (const old of K.caps) if (old.slot === slot && old.n.plan.o > 0) old.n.to(t, 0.2, { o: 0 }, "in");
      n.to(t + 0.15, 0.4, { o: 1, y: o.y == null ? 96 : o.y }, "out");
      K.caps.push({ n, slot });
      return t + 0.55;
    };
    K.title = (t, text) => {
      if (!text || text === "off") return t;
      const g = svg("g", {}, K.top);
      A.rect(g, 0, 8, 8, 36, { r: 4, fill: K.pal.accent });
      A.text(g, 24, 27, text.toUpperCase(), { mono: false, size: 26, weight: 800, fill: K.pal.accent, anchor: "start", spacing: 3 });
      const n = tl.node(g, { o: 0, x: -20 }); n.to(t, 0.4, { o: 1, x: 0 }, "out");
      return t + 0.3;
    };
    K.fadeIn = (t, el, o) => { o = o || {}; const n = tl.node(el, { o: 0, y: o.dy == null ? 20 : o.dy, s: o.s0 || 1, x: 0 }); n.to(t, o.dur || 0.4, { o: 1, y: 0, s: 1 }, o.ease || "out"); return n; };
    K.arrow = (parent, x0, y0, x1, y1, o) => {                     // a line that draws itself and ends in a dot
      o = o || {};
      const col = o.stroke || DIM, g = svg("g", {}, parent);
      const mx = (x0 + x1) / 2;
      const d = o.d || (o.straight ? `M${x0},${y0} L${x1},${y1}` : `M${x0},${y0} C${mx},${y0} ${mx},${y1} ${x1},${y1}`);
      const path = svg("path", { d, fill: "none", stroke: col, "stroke-width": o.sw || 4, "stroke-linecap": "round", pathLength: 1, "stroke-dasharray": o.dashed ? "0.03 0.03" : "1 1", "stroke-dashoffset": o.dashed ? 0 : 1 }, g);
      const dot = svg("circle", { cx: x1, cy: y1, r: 7, fill: col, opacity: 0 }, g);
      return { g, path, dot, draw: (t, dur) => { if (o.dashed) { const n = tl.node(g, { o: 0 }); n.to(t, dur || 0.4, { o: 1 }); dot.setAttribute("opacity", 1); return t + (dur || 0.4); }
        tl.add(t, dur || 0.4, (p) => { path.setAttribute("stroke-dashoffset", (1 - p).toFixed(4)); dot.setAttribute("opacity", p > 0.85 ? 1 : 0); }, "inOut"); return t + (dur || 0.4); },
        color: (t, c) => tl.at(t, (p) => { path.setAttribute("stroke", p ? c : col); dot.setAttribute("fill", p ? c : col); }) };
    };
    // a little packet that flies from one place to another (objects travelling over the network, content between trees)
    K.fly = (t, x0, y0, x1, y1, o) => {
      o = o || {};
      const g = svg("g", {}, K.top);
      if (o.label) { const fs = o.size || 22, w = A.mono_w(o.label, fs) + 30, h = fs * 1.9; A.rect(g, -w / 2, -h / 2, w, h, { r: 10, fill: o.fill || K.pal.accent2 }).setAttribute("filter", "url(#sh)"); A.text(g, 0, 1, o.label, { size: fs, fill: INK }); }
      else svg("circle", { r: o.r || 15, fill: o.fill || K.pal.accent2, filter: "url(#glow)" }, g);
      const n = tl.node(g, { x: x0, y: y0, o: 0, s: 0.6 }), dur = o.dur || 0.7, lift = o.lift == null ? 70 : o.lift, v = n.v;
      n.to(t, 0.12, { o: 1, s: 1 }, "out");
      tl.add(t + 0.06, dur, (p) => { v.x = lerp(x0, x1, p); v.y = lerp(y0, y1, p) - lift * 4 * p * (1 - p); }, "inOut");
      n.to(t + 0.06 + dur - 0.08, 0.16, { o: 0, s: 0.7 }, "in");
      tl.sound(t + 0.08, "whoosh", 0.7);
      return t + dur + 0.1;
    };
    K.tick = (parent, x, y, s, col) => svg("path", { d: `M${x - 9 * s},${y} l${6 * s},${7 * s} l${12 * s},${-14 * s}`, fill: "none", stroke: col || GREEN, "stroke-width": 4.5 * s, "stroke-linecap": "round", "stroke-linejoin": "round", pathLength: 1, "stroke-dasharray": "1 1", "stroke-dashoffset": 1 }, parent);
    K.cross = (parent, x, y, s, col) => svg("path", { d: `M${x - 8 * s},${y - 8 * s} l${16 * s},${16 * s} M${x + 8 * s},${y - 8 * s} l${-16 * s},${16 * s}`, fill: "none", stroke: col || RED, "stroke-width": 4.5 * s, "stroke-linecap": "round", pathLength: 1, "stroke-dasharray": "1 1", "stroke-dashoffset": 1 }, parent);
    K.drawTick = (t, el) => { tl.add(t, 0.25, (p) => el.setAttribute("stroke-dashoffset", (1 - p).toFixed(3)), "out"); tl.sound(t + 0.05, "pop", 0.7); return t + 0.25; };
    return K;
  }
  Scenes.kit = kit;

  // =================================================================================================
  // (a) commit graph: grows commit by commit; labels slide when they move.
  //     params: {commits:[{id,col,row,parents}], states:[{refs:{name:id}, head, notes:[{text,at}], add:[ids], ghost:[ids], caption}]}
  Scenes.defs.graph = {
    steps: (P) => P.states.map((s, i) => (i === 0 ? "grow" : "state-" + i)),
    build(K, P) {
      const G = new Graph(K, K.main, { dx: P.dx || 190, dy: P.dy || 150, prefer: P.prefer || {}, tags: P.tags || [], special: P.special || [], remote: P.remote || [] });
      K.G = G;
      const top = P.title ? 70 : 0;                                   // a title (title=...) takes the top-left corner
      for (const c of P.commits) G.commit(c.id, c.col, c.row, c.parents, { text: c.text });
      const mapOf = (s) => { const m = Object.assign({}, s.refs); if (s.head) m.HEAD = s.head; return m; };
      const ghosts = new Set();
      const steps = P.states.map((s, i) => (t) => {
        if (i === 0 && P.title) t = K.title(t, P.title);
        if (s.caption) t = K.say(t, s.caption, { y: 34 + top, size: 30, fill: K.pal.accent }) - 0.3;
        const add = s.add || [], t0 = t;
        add.forEach((id, k) => { t = Math.max(t, G.show(t + (k ? 0.02 : 0), id, { glow: i > 0 })) - 0.12; });
        if (add.length) t += 0.12;
        const together = i > 0 && add.length > 0;
        if (s.ghost) {                                                // the state lists its unreachable commits: others that were ghosts become solid again
          for (const id of s.ghost) if (!ghosts.has(id)) { ghosts.add(id); G.ghost(t, id); }
          for (const id of Array.from(ghosts)) if (!s.ghost.includes(id)) { ghosts.delete(id); G.ghost(t, id, false); }
        }
        for (const m of s.moves || []) G.move(t, m.id, m.col, m.row);
        for (const k in G.notes) if (!(s.notes || []).some((n) => n.text === k)) delete G.notes[k];
        for (const n of s.notes || []) { G.notes[n.text] = { at: n.at }; G.chip(n.text, "note"); }
        t = together ? Math.max(t, G.refs(t0 + 0.05, mapOf(s))) : G.refs(t, mapOf(s));
        return t;
      });
      // every state is laid out once before fitting so that the scale never changes mid-scene
      const capH = P.states.some((s) => s.caption) ? 70 : 0;
      return { steps, fit: () => G.fit(60, 20 + capH + top, K.W - 120, K.H - 40 - capH - (capH ? 30 : 0) - top, 2.1),
        focus: (t, keys) => { let end = t; keys.forEach((k, i) => { const id = G.c[k] ? k : G.map[k] && G.c[G.map[k]] ? G.map[k] : G.notes[k] ? G.notes[k].at : null; const ch = G.chips[k];
          if (ch && ch.n.plan.o > 0) { ch.n.pulse(t + i * 0.25, 0.8, "s", 0.2); end = t + i * 0.25 + 0.8; }
          if (id) end = Math.max(end, G.focus(t + i * 0.25, id, 1.0)); }); if (keys.length) K.tl.sound(t + 0.05, "pop", 0.5); return end; } };
    },
  };

  // (b) fast-forward versus three-way merge.   params: {mode: "ff"|"three-way"|"versus", main, feature}
  // The commits of a merge picture.  common=A,B (history both sides share; the last one is the merge base), main_only=C, feature_only=D,E,
  // merge_id=M.  A number instead of a list ("feature_only=3") takes the next letters.  Real short IDs are drawn under the commits.
  function mergeIds(P, mode) {
    const given = [P.common, P.main_only, P.feature_only].filter(Array.isArray).flat().concat(P.merge_id || "M");
    const letters = "ABCDEFGHIJKL".split("").filter((x) => !given.includes(x));
    const take = (v, dflt) => { if (v == null) v = dflt; if (Array.isArray(v)) return v.slice(0, 5); return letters.splice(0, Math.max(0, Math.min(5, +v || 0))); };
    const common = take(P.common, 2), ours = mode === "ff" ? [] : take(P.main_only, 1), theirs = take(P.feature_only, 2);
    return { common: common.length ? common : letters.splice(0, 1), ours, theirs: theirs.length ? theirs : letters.splice(0, 1), merge: P.merge_id || "M" };
  }
  function ffPart(K, G, P, o) {
    const m = P.main || "main", f = P.feature || "feature";
    const say = P.captions === "off" ? (t) => t + 0.3 : K.say;
    const I = mergeIds(P, "ff"), all = I.common.concat(I.theirs), base = I.common[I.common.length - 1], tip = all[all.length - 1];
    all.forEach((id, i) => G.commit(id, i, 0, i ? [all[i - 1]] : []));
    G.o.prefer[m] = "above"; G.o.prefer[f] = "above";
    const path = I.theirs.map((id, i) => [id, i ? I.theirs[i - 1] : base]);
    return {
      setup: (t) => { t = G.showAll(t); return G.refs(t - 0.1, { [m]: base, [f]: tip, HEAD: m }); },
      check: (t) => { G.focus(t, base, 0.9); path.forEach(([c, p], i) => G.heatEdge(t + 0.3 + i * 0.2, c, p, true)); G.heat(t + 0.3, base, true);
        return say(t + 0.4, `${m} is an ancestor of ${f}: nothing to combine`, o.say) + 0.3; },
      ff: (t) => { if (o.cmd && P.captions !== "off") t = K.cmd(t, `git merge ${f}`); t = G.refs(t, { [m]: tip, [f]: tip, HEAD: m }, { dur: 0.9 });
        path.forEach(([c, p]) => G.heatEdge(t, c, p, false)); G.heat(t, base, false);
        return say(t - 0.3, "Fast-forward: one label moved, no new commit", o.say) + 0.2; },
    };
  }
  function twPart(K, G, P, o) {
    const m = P.main || "main", f = P.feature || "feature", BL = P.base || "merge base";
    const say = P.captions === "off" ? (t) => t + 0.3 : K.say;
    const I = mergeIds(P, "three-way"), nc = I.common.length, B = I.common[nc - 1], M = I.merge;
    I.common.forEach((id, i) => G.commit(id, i, 0, i ? [I.common[i - 1]] : []));
    I.ours.forEach((id, i) => G.commit(id, nc + i, 0, [i ? I.ours[i - 1] : B]));
    I.theirs.forEach((id, i) => G.commit(id, nc + i, 1, [i ? I.theirs[i - 1] : B]));
    const C = I.ours.length ? I.ours[I.ours.length - 1] : B, E = I.theirs[I.theirs.length - 1];
    G.commit(M, nc + Math.max(I.ours.length, I.theirs.length), 0, [C, E]);                    // the merge commit stands to the right of both parents
    G.o.prefer[m] = "above"; G.o.prefer[f] = "below"; G.o.prefer[BL] = P.base ? "below" : "above";
    const before = I.common.concat(I.ours, I.theirs);
    const pathO = I.ours.map((id, i) => [id, i ? I.ours[i - 1] : B]).reverse(), pathT = I.theirs.map((id, i) => [id, i ? I.theirs[i - 1] : B]).reverse();
    return {
      setup: (t) => { t = G.showAll(t, before); return G.refs(t - 0.1, { [m]: C, [f]: E, HEAD: m }); },
      base: (t) => { if (C !== B) G.heat(t, C, true); G.heat(t, E, true);
        pathO.forEach(([c, p], i) => G.heatEdge(t + 0.25 + i * 0.2, c, p, true)); pathT.forEach(([c, p], i) => G.heatEdge(t + 0.25 + i * 0.2, c, p, true));
        const w = 0.25 + 0.2 * Math.max(pathO.length, pathT.length);
        G.heat(t + w + 0.05, B, true); G.focus(t + w + 0.1, B, 1.0); t = G.note(t + w + 0.25, BL, B);
        return say(t - 0.3, "Both histories meet at the merge base", o.say) + 0.3; },
      merge: (t) => { if (o.cmd && P.captions !== "off") t = K.cmd(t, `git merge ${f}`); G.focus(t, B, 0.7); G.focus(t + 0.12, C, 0.7); G.focus(t + 0.24, E, 0.7);
        t = G.show(t + 0.6, M, { glow: true }); t = G.refs(t - 0.1, { [m]: M, [f]: E, HEAD: m });
        for (const [c, p] of pathO.concat(pathT)) G.heatEdge(t, c, p, false); for (const c of [B, C, E]) G.heat(t, c, false);
        return say(t - 0.3, "Three-way merge: a new commit with two parents", o.say) + 0.2; },
    };
  }
  Scenes.defs.merge = {
    steps: (P) => (P.mode === "ff" ? ["setup", "check", "fast-forward"] : P.mode === "three-way" ? ["setup", "merge-base", "merge"] : ["setup", "check", "fast-forward", "merge-base", "merge"]),
    build(K, P) {
      const mode = P.mode || "versus";
      if (mode === "ff" || mode === "three-way") {
        const G = new Graph(K, K.main, { dx: 230, dy: 190, r: 28 });
        const S = mode === "ff" ? ffPart(K, G, P, { cmd: true, say: {} }) : twPart(K, G, P, { cmd: true, say: {} });
        const title = (t) => K.title(t, P.title || (mode === "ff" ? "Fast-forward merge" : "Three-way merge"));
        const steps = mode === "ff" ? [(t) => S.setup(title(t)), S.check, S.ff] : [(t) => S.setup(title(t)), S.base, S.merge];
        return { steps, fit: () => G.fit(120, 150, K.W - 240, K.H - 300, 1.9) };
      }
      const gl = svg("g", {}, K.main), gr = svg("g", {}, K.main);
      const L = new Graph(K, gl, { dx: 170, dy: 150 }), R = new Graph(K, gr, { dx: 170, dy: 150 });
      const sayL = { x: 430, y: 760, size: 27, slot: "L" }, sayR = { x: 1300, y: 760, size: 27, slot: "R" };
      const a = ffPart(K, L, P, { cmd: false, say: sayL }), b = twPart(K, R, P, { cmd: false, say: sayR });
      const div = svg("line", { x1: 864, y1: 90, x2: 864, y2: 800, stroke: "#30363d", "stroke-width": 3, "stroke-dasharray": "4 12", "stroke-linecap": "round" }, K.back);
      const heads = [["Fast-forward", 430], ["Three-way merge", 1300]].map(([s, x]) => { const g = svg("g", {}, K.top); A.text(g, x, 60, s, { mono: false, size: 40, weight: 800, fill: WHITE }); return g; });
      const dimmer = (G) => { const n = K.tl.node(G.g.parentNode, { o: 1 }); return n; };
      const nl = dimmer(L), nr = dimmer(R);
      return {
        steps: [
          (t) => { K.fadeIn(t, div, { dy: 0 }); K.fadeIn(t, heads[0], { dy: -16 }); K.fadeIn(t + 0.1, heads[1], { dy: -16 }); const e = a.setup(t + 0.2); return Math.max(e, b.setup(t + 0.5)); },
          (t) => { nr.to(t, 0.3, { o: 0.35 }); return a.check(t + 0.1); },
          (t) => { if (P.captions !== "off") t = K.cmd(t, `git merge ${P.feature || "feature"}`); return a.ff(t); },
          (t) => { nr.to(t, 0.3, { o: 1 }); nl.to(t, 0.3, { o: 0.35 }); return b.base(t + 0.2); },
          (t) => { t = b.merge(t); nl.to(t, 0.4, { o: 1 }); return t + 0.3; },
        ],
        fit: () => { L.fit(30, 140, 790, 580, 1.35); R.fit(900, 140, 790, 580, 1.35); },
      };
    },
  };

  // (c) rebase: commits are lifted, copied onto the new base as NEW commits, the originals fade to ghosts
  Scenes.defs.rebase = {
    steps: () => ["setup", "lift", "copy", "ghost", "move"],
    build(K, P) {
      const b = P.branch || "feature", onto = P.onto || "main";
      const G = new Graph(K, K.main, { dx: 210, dy: 210, r: 26 });
      G.commit("A", 0, 1); G.commit("B", 1, 1, ["A"]); G.commit("C", 2, 1, ["B"]); G.commit("D", 2, 0, ["B"]); G.commit("E", 3, 0, ["D"]);
      G.commit("D2", 3, 1, ["C"], { text: "D′" }); G.commit("E2", 4, 1, ["D2"], { text: "E′" });
      G.o.prefer[onto] = "below"; G.o.prefer[b] = "above"; G.o.prefer["new IDs"] = "below"; G.o.prefer["still in the reflog"] = "above";
      const at = (id) => G.xy(G.c[id].col, G.c[id].row);
      return {
        steps: [
          (t) => { t = K.title(t, P.title || `Rebase ${b} onto ${onto}`); t = G.showAll(t, ["A", "B", "C", "D", "E"]); return G.refs(t - 0.1, { [onto]: "C", [b]: "E", HEAD: b }); },
          (t) => { t = K.cmd(t, `git rebase ${onto}`); for (const id of ["D", "E"]) { G.heat(t, id, true); G.c[id].n.to(t, 0.4, { y: at(id).y - 22 }, "out"); } G.focus(t + 0.1, "D", 0.8); G.focus(t + 0.25, "E", 0.8);
            return K.say(t + 0.2, "Git lifts the commits that are only on " + b) + 0.2; },
          (t) => { let e = t; [["D", "D2"], ["E", "E2"]].forEach(([src, dst], i) => { const t0 = t + i * 1.0; const s = at(src), d = at(dst);
              K.fly(t0, s.x * G.scale + G.tx, (s.y - 22) * G.scale + G.ty, d.x * G.scale + G.tx, d.y * G.scale + G.ty, { dur: 0.7, r: 22 * G.scale, lift: 40 });
              e = G.show(t0 + 0.6, dst, { glow: true }); });
            return K.say(e - 0.6, "Each one is replayed on top of " + onto + " as a new commit") + 0.2; },
          (t) => { for (const id of ["D", "E"]) { G.ghost(t, id); G.heat(t, id, false); G.c[id].n.to(t, 0.4, { y: at(id).y }, "inOut"); } t = G.note(t + 0.3, "new IDs", "E2"); return K.say(t - 0.3, "Same changes, new parents, so new commit IDs") + 0.2; },
          (t) => { delete G.notes["new IDs"]; t = G.refs(t, { [onto]: "C", [b]: "E2", HEAD: b }, { dur: 0.9 }); t = G.note(t, "still in the reflog", "E"); return K.say(t - 0.3, "The label moves; the originals are no longer on any branch") + 0.2; },
        ],
        refit: false,
        fit: () => { const s = G.fit(140, 150, K.W - 280, K.H - 330, 1.4); const m = /translate\(([-\d.]+),([-\d.]+)\)/.exec(G.g.getAttribute("transform")); G.tx = +m[1]; G.ty = +m[2]; },
      };
    },
  };

  // (g) the reflog rescue: a label yanked back, the lost commits found again
  Scenes.defs.reflog = {
    steps: () => ["setup", "reset", "reflog", "rescue"],
    danger: ["reset"],
    build(K, P) {
      const b = P.branch || "main";
      const G = new Graph(K, K.main, { dx: 215, dy: 150, r: 26 });
      G.commit("A", 0, 0); G.commit("B", 1, 0, ["A"]); G.commit("C", 2, 0, ["B"]); G.commit("D", 3, 0, ["C"]);
      G.o.prefer[b] = "above"; G.o.prefer["no label points here"] = "below";
      const panel = svg("g", {}, K.main), rows = [["HEAD@{0}", "reset: moving to HEAD~2", "B"], ["HEAD@{1}", "commit: add retry", "D"], ["HEAD@{2}", "commit: tune limits", "C"]];
      const pw = 880, px = (K.W - pw) / 2, py = 470;
      A.rect(panel, px, py, pw, 230, { r: 16, fill: "#0b0d12", stroke: "#30363d", sw: 2 }).setAttribute("filter", "url(#sh)");
      A.text(panel, px + 30, py + 34, "$ git reflog", { size: 25, fill: K.pal.accent, anchor: "start" });
      const lines = rows.map((r, i) => { const g = svg("g", {}, panel); const hl = A.rect(g, px + 16, py + 62 + i * 52, pw - 32, 46, { r: 8, fill: K.pal.accent, o: 0 });
        A.text(g, px + 30, py + 85 + i * 52, r[2], { size: 25, fill: WHITE, anchor: "start" }); A.text(g, px + 80, py + 85 + i * 52, r[0], { size: 25, fill: K.pal.accent2, anchor: "start", weight: 500 });
        A.text(g, px + 250, py + 85 + i * 52, r[1], { size: 25, fill: "#b6bfc9", anchor: "start", weight: 500 }); return { g, hl }; });
      const pn = K.tl.node(panel, { o: 0, y: 30 });
      const ln = lines.map((l) => K.tl.node(l.g, { o: 0 }));
      return {
        steps: [
          (t) => { t = K.title(t, P.title || "The reflog rescue"); t = G.showAll(t); return G.refs(t - 0.1, { [b]: "D", HEAD: b }); },
          (t) => { t = K.cmd(t, "git reset --hard HEAD~2", { danger: true }); const ch = G.chips[b], hd = G.chips.HEAD;
            K.tl.add(t, 0.3, (p) => { ch.danger = p; hd.danger = p; }, "out");
            t = G.refs(t + 0.1, { [b]: "B", HEAD: b }, { dur: 0.5, ease: "back", lift: 60 }); G.ghost(t - 0.2, "C"); G.ghost(t - 0.1, "D");
            K.tl.add(t + 0.3, 0.5, (p) => { ch.danger = 1 - p; hd.danger = 1 - p; }, "inOut");
            t = G.note(t + 0.2, "no label points here", "D"); return t + 0.2; },
          (t) => { K.cmdOff(t); pn.to(t, 0.4, { o: 1, y: 0 }, "out"); ln.forEach((n, i) => { n.to(t + 0.4 + i * 0.22, 0.25, { o: 1 }, "out"); K.tl.sound(t + 0.42 + i * 0.22, "tick", 0.8); });
            t += 1.2; K.tl.add(t, 0.35, (p) => { lines[1].hl.setAttribute("opacity", (0.28 * p).toFixed(3)); }, "out"); G.focus(t + 0.15, "D", 1.1); G.heat(t + 0.15, "D", true);
            return K.say(t, "Every move of HEAD was written down: the commit is still there") + 0.4; },
          (t) => { t = K.cmd(t, "git reset --hard HEAD@{1}"); delete G.notes["no label points here"]; G.ghost(t, "C", false); G.ghost(t + 0.1, "D", false);
            t = G.refs(t + 0.15, { [b]: "D", HEAD: b }, { dur: 0.9 }); G.heat(t, "D", false); return K.say(t - 0.4, "The label goes back. Nothing was lost.") + 0.2; },
        ],
        fit: () => G.fit(200, 130, K.W - 400, 300, 1.35),
      };
    },
  };

  // (d) the three trees: working tree, index, HEAD.  A file's content flows between them.
  //     params: {file, names: [working tree, index, HEAD], subs: [...], order: "reverse", ref: "main", commits: [id, id], versions: [v1, v2, v3], chips: [wt, index, head], title}
  Scenes.defs.trees = {
    steps: () => ["setup", "edit", "add", "commit", "restore", "reset"],
    danger: ["restore", "reset"],
    build(K, P) {
      const file = P.file || "app.py", tl = K.tl, pal = K.pal;
      const VC = { 1: NEUTRAL, 2: pal.accent, 3: pal.accent2 };
      const names = (P.names || []).concat(["Working tree", "Index", "HEAD"].slice((P.names || []).length)).slice(0, 3);
      const subs = (P.subs || []).concat(["files on disk", "the staging area", "the last commit"].slice((P.subs || []).length)).slice(0, 3);
      const vers = (P.versions || []).concat(["version 1", "version 2", "version 3"].slice((P.versions || []).length)).slice(0, 3);
      const XS = P.order === "reverse" ? [1138, 644, 150] : [150, 644, 1138];      // order=reverse: HEAD on the left, the working tree on the right
      const SW = 440, SH = 390, SY = 215;
      // the path on the file card: shrunk to fit, and broken after a directory when it is still too long
      const fitPath = (g, x, y, avail) => {
        let size = 27, lines = [file];
        if (A.mono_w(file, size) > avail) size = Math.max(19, Math.floor(avail / (file.length * 0.6021)));
        if (A.mono_w(file, size) > avail && file.includes("/")) {
          const cut = file.lastIndexOf("/", Math.max(1, Math.floor(avail / (21 * 0.6021)) - 1));
          const k = cut > 0 ? cut : file.indexOf("/");
          lines = [file.slice(0, k + 1), file.slice(k + 1)];
          size = Math.min(23, Math.floor(avail / (Math.max(lines[0].length, lines[1].length) * 0.6021)));
        }
        lines.forEach((l, i) => A.text(g, x, y + (lines.length > 1 ? -13 + i * 27 : 0), l, { size, fill: "#b6bfc9", anchor: "start", weight: 500 }));
      };
      const trees = [0, 1, 2].map((i) => {
        const x = XS[i], g = svg("g", {}, K.main);
        // an isometric stack: two sheets behind the front slab hint at depth
        for (let k = 2; k >= 1; k--) A.slab(g, x + k * 14, SY - k * 14, SW, SH, { depth: 0, stroke: "#30363d", fill: "#0d1016", shadow: false });
        A.slab(g, x, SY, SW, SH, { depth: 18, stroke: i === 2 ? pal.accent : DIM, fill: "#11151c" });
        const nsz = Math.min(40, Math.floor((40 * (SW - 40)) / Math.max(SW - 40, A.sans_w(names[i], 40) * 1.12)));
        const ssz = Math.min(26, Math.floor((26 * (SW - 30)) / Math.max(SW - 30, A.sans_w(subs[i], 26) * 1.08)));
        A.text(g, x + SW / 2, SY + 50, names[i], { mono: false, size: nsz, weight: 800, fill: i === 2 ? pal.accent : WHITE });
        A.text(g, x + SW / 2, SY + 94, subs[i], { mono: false, size: ssz, weight: 500, fill: DIM });
        // the file card
        const fx = x + 40, fy = SY + 140, fw = SW - 80, fh = 200;
        A.rect(g, fx, fy, fw, fh, { r: 12, fill: "#0b0d12", stroke: "#30363d", sw: 2 });
        fitPath(g, fx + 22, fy + 44, fw - 44);
        const chips = {};
        for (const v of [1, 2, 3]) { const cg = svg("g", {}, g); A.rect(cg, -fw / 2 + 22, -36, fw - 44, 72, { r: 12, fill: VC[v] });
          const label = v === 1 && P.chips && P.chips[i] ? P.chips[i] : vers[v - 1];      // chips=a,b,c: what each box holds at the start, when the three differ
          const vs = Math.min(31, Math.floor((fw - 70) / (label.length * 0.6021)));
          A.text(cg, 0, 1, label, { size: vs, fill: INK });
          chips[v] = tl.node(cg, { x: fx + fw / 2, y: fy + 130, o: 0, s: 1 }); }
        // "modified" sits on the top edge of the card, so that it never meets the path
        const badge = svg("g", {}, g), bw = A.sans_w("modified", 22) + 34;
        A.rect(badge, fx + fw - bw - 14, fy - 19, bw, 38, { r: 19, fill: INK, stroke: pal.accent2, sw: 2.5 });
        A.text(badge, fx + fw - 14 - bw / 2, fy + 1, "modified", { mono: false, size: 22, weight: 700, fill: pal.accent2, italic: true });
        return { g, x, cx: fx + fw / 2, cy: fy + 130, chips, ver: 0, badge: tl.node(badge, { o: 0 }), n: tl.node(g, { o: 0, y: 50 }) };
      });
      const setV = (t, tr, v, o) => { o = o || {}; if (tr.ver) tr.chips[tr.ver].to(t, 0.22, { o: 0, s: 0.92 }, "in"); tr.chips[v].to(t + 0.1, 0.32, { o: 1, s: 1 }, "back"); tr.chips[v].plan.s = 1; tr.ver = v; if (!o.quiet) tl.sound(t + 0.14, "pop", 0.8); return t + 0.42; };
      const flow = (t, a, b, v, o) => { const lab = vers[v - 1]; t = K.fly(t, a.cx, a.cy, b.cx, b.cy, Object.assign({ label: lab, fill: (o && o.danger) ? RED : VC[v], dur: 0.75, lift: 110, size: Math.min(29, Math.floor(330 / (lab.length * 0.6021))) }, o || {})); return setV(t - 0.2, b, v); };
      // the little history under the HEAD box: two commits and the name that points at the newest one
      const ids = P.commits && P.commits.length >= 2 ? P.commits.slice(0, 2) : null, ref = P.ref || null;
      const hist = svg("g", {}, K.main), GAP = ids ? 200 : 180, hx = trees[2].x + (ref ? 96 : 130), hy = SY + SH + (ids ? 52 : 62), R = ids ? 21 : 27;
      const dots = [0, 1].map((i) => { const g = svg("g", {}, hist); if (i) svg("line", { x1: -GAP + R + 4, y1: 0, x2: -R - 4, y2: 0, stroke: NEUTRAL, "stroke-width": 5 }, g); svg("circle", { r: R, fill: INK, stroke: NEUTRAL, "stroke-width": 5 }, g);
        if (ids) A.text(g, 0, R + 20, ids[i], { size: 20, fill: DIM, weight: 500 }); else A.text(g, 0, 1, "c" + (i + 1), { size: 24, fill: WHITE });
        return tl.node(g, { x: hx + i * GAP, y: hy, o: 0, s: 0.3 }); });
      const hg = svg("g", {}, hist), rw = ref ? A.mono_w(ref, 22) + 26 : 100;
      if (ref) {                                                         // the branch, filled because it is current, with HEAD's small white chip beside it
        const tw = rw + 6 + 64;
        A.rect(hg, -tw / 2, -20, rw, 40, { r: 9, fill: pal.accent }); A.text(hg, -tw / 2 + rw / 2, 1, ref, { size: 22, fill: INK });
        A.rect(hg, -tw / 2 + rw + 6, -15, 64, 30, { r: 8, fill: WHITE }); A.text(hg, -tw / 2 + rw + 38, 1, "HEAD", { size: 17, fill: INK });
      } else { A.rect(hg, -50, -20, 100, 40, { r: 9, fill: pal.accent }); A.text(hg, 0, 1, "HEAD", { size: 23, fill: INK }); }
      const hyc = hy + (ids ? R + 62 : 56);
      const hn = tl.node(hg, { x: hx, y: hyc, o: 0 });
      const [WT, IX, HD] = trees;
      const mover = ref ? ref : "the current branch";
      return {
        steps: [
          (t) => { t = K.title(t, P.title || "The three trees"); trees.forEach((tr, i) => { tr.n.to(t + i * 0.18, 0.5, { o: 1, y: 0 }, "out"); tl.sound(t + i * 0.18 + 0.1, "pop", 0.6); }); t += 0.8;
            trees.forEach((tr, i) => setV(t + i * 0.1, tr, 1, { quiet: true })); dots[0].to(t + 0.2, 0.3, { o: 1, s: 1 }, "back"); hn.to(t + 0.35, 0.3, { o: 1 }, "out");
            return K.say(t + 0.2, P.chips ? "One file, held in three places" : "Three copies of every tracked file. Right now they agree.") + 0.2; },
          (t) => { t = K.say(t, "You edit the file: only the working tree changes"); setV(t - 0.3, WT, 2); WT.badge.to(t - 0.1, 0.3, { o: 1 }); return t + 0.3; },
          (t) => { t = K.cmd(t, "git add " + file); t = flow(t, WT, IX, 2); WT.badge.to(t - 0.3, 0.2, { o: 0 }); return K.say(t - 0.3, "add copies the working tree into the index") + 0.2; },
          (t) => { t = K.cmd(t, "git commit"); t = flow(t, IX, HD, 2); dots[1].to(t - 0.2, 0.35, { o: 1, s: 1 }, "back"); hn.to(t - 0.1, 0.5, { x: hx + GAP }, "inOut");
            return K.say(t - 0.2, `commit turns the index into a new snapshot; ${mover} moves to it`) + 0.2; },
          (t) => { const iv = IX.ver || 1;                                // the edit that is about to be lost: a new one, unless one is already waiting unstaged
            if (WT.ver === iv) { t = setV(t, WT, Math.min(3, iv + 1)); WT.badge.to(t - 0.3, 0.25, { o: 1 }); t += 0.2; }
            const lost = vers[WT.ver - 1];
            t = K.cmd(t, "git restore " + file, { danger: true }); t = flow(t, IX, WT, iv); WT.badge.to(t - 0.3, 0.2, { o: 0 });
            return K.say(t - 0.3, `restore copies the index back over your edit. ${lost.charAt(0).toUpperCase() + lost.slice(1)} is gone.`) + 0.2; },
          (t) => { t = K.cmd(t, "git reset --hard HEAD~1", { danger: true }); hn.to(t, 0.5, { x: hx }, "back"); dots[1].to(t + 0.2, 0.4, { o: 0.3 }, "inOut");
            t = setV(t + 0.4, HD, 1); t = flow(t - 0.1, HD, IX, 1, { danger: true }); t = flow(t - 0.15, IX, WT, 1, { danger: true });
            return K.say(t - 0.3, "reset --hard: HEAD moves back, then overwrites the index and the files") + 0.2; },
        ],
        fit: () => {},
      };
    },
  };

  // (e) the object model: commit -> tree -> blobs, and two snapshots that share blobs
  //     params: {commits: [id, id], trees: [id, id], files: [{name, id, new}], messages: [m1, m2]}   (one file has "new": its second blob)
  Scenes.defs.objects = {
    steps: () => ["commit", "tree", "blobs", "second-commit", "shared", "compare"],
    build(K, P) {
      const tl = K.tl, pal = K.pal;
      const files = (P.files && P.files.length ? P.files : [{ name: "README.md", id: "91c0e2b" }, { name: "app.py", id: "7e4a6f0", new: "2f9b8a1" }, { name: "config.yaml", id: "c3d95d4" }]).slice(0, 4);
      const ci = P.commits || ["a1f3c9e", "e07b552"], ti = P.trees || ["4b82d10", "d6f17aa"], msg = P.messages || ["First snapshot", "Edit " + (files.find((f) => f.new) || files[0]).name];
      const changed = Math.max(0, files.findIndex((f) => f.new)), nf = files.length;
      const pad = Math.max(...files.map((f) => f.name.length));
      const card = (x, y, w, h, kind, id, lines, col) => {
        const g = svg("g", {}, K.main);
        A.slab(g, x, y, w, h, { depth: 14, stroke: col, fill: "#11151c" });
        A.text(g, x + 20, y + 34, kind, { mono: false, size: 25, weight: 800, fill: col, anchor: "start", spacing: 2 });
        A.text(g, x + w - 18, y + 34, id, { size: 24, fill: DIM, anchor: "end", weight: 500 });
        const rows = lines.map((s, i) => { const hl = A.rect(g, x + 10, y + 61 + i * 37, w - 20, 36, { r: 7, fill: pal.accent2, o: 0 }); A.text(g, x + 20, y + 80 + i * 37, s, { size: 26, fill: "#d5dce4", anchor: "start", weight: 500 }); return hl; });
        const n = tl.node(g, { o: 0, y: 26 });
        return { g, n, x, y, w, h, rows, show: (t) => { n.to(t, 0.42, { o: 1, y: 0 }, "out"); tl.sound(t + 0.1, "pop", 0.75); return t + 0.42; } };
      };
      const CX = 30, TX = 560, BX = 1250, CW = 420, TW = 560, BW = 430;
      const th = 80 + nf * 37, y2 = 150 + Math.max(th, 170) + 150;
      const ent = (k) => files.map((f, i) => `${f.name.padEnd(pad)}  ${(k && i === changed ? f.new : f.id).slice(0, 7)}`);
      const c1 = card(CX, 150, CW, 170, "COMMIT", ci[0], ["tree    " + ti[0].slice(0, 4) + "...", msg[0].slice(0, 22)], NEUTRAL);
      const t1 = card(TX, 150, TW, th, "TREE", ti[0], ent(0), pal.accent);
      const c2 = card(CX, y2, CW, 206, "COMMIT", ci[1], ["tree    " + ti[1].slice(0, 4) + "...", "parent  " + ci[0].slice(0, 4) + "...", msg[1].slice(0, 22)], NEUTRAL);
      const t2 = card(TX, y2, TW, th, "TREE", ti[1], ent(1), pal.accent);
      const bh = 112, room = K.H - 110 - 100, gapY = Math.min(170, (room - bh) / nf);
      const bl = files.map((f, i) => card(BX, 118 + i * gapY, BW, bh, "BLOB", f.id, [f.name + (i === changed ? "  (old)" : "")], pal.accent2));
      const nb = card(BX, 118 + nf * gapY, BW, bh, "BLOB", files[changed].new || "2f9b8a1", [files[changed].name + "  (new)"], pal.accent2);
      const ar = (a, b, ay, by, o) => K.arrow(K.back, a.x + a.w + 14, a.y + (ay == null ? a.h / 2 : ay), b.x - 8, b.y + (by == null ? b.h / 2 : by), o);
      const rowY = (i) => 80 + i * 37;
      const a_ct1 = ar(c1, t1, 80, 80), a_ct2 = ar(c2, t2, 80, 80);
      const a_t1 = files.map((f, i) => ar(t1, bl[i], rowY(i)));
      const a_t2new = ar(t2, nb, rowY(changed));
      const shared = files.map((f, i) => i).filter((i) => i !== changed);
      const a_t2sh = shared.map((i) => ar(t2, bl[i], rowY(i), null, { stroke: pal.accent2 }));
      const par = K.arrow(K.back, CX + 120, y2 - 6, CX + 120, 150 + 170 + 22, { straight: true });
      const flash = (t, card_, i, dur) => tl.add(t, dur || 1.0, (p) => card_.rows[i].setAttribute("opacity", (0.3 * p).toFixed(3)), "there");
      const tag = (x, y, text, col) => { const g = svg("g", {}, K.top), w = A.sans_w(text, 24) + 30; A.rect(g, -w / 2, -20, w, 40, { r: 20, fill: col }); A.text(g, 0, 1, text, { mono: false, size: 24, weight: 800, fill: INK }); return tl.node(g, { x, y, o: 0, s: 0.6 }); };
      const tagNew = tag(BX + 190, nb.y + 34, "new blob", pal.accent), tagSame = shared.map((i) => tag(BX + 206, bl[i].y + 34, "same object", pal.accent2));   // on the card's title line, between "BLOB" and its ID
      return {
        steps: [
          (t) => { t = K.title(t, P.title || "What a commit points at"); t = c1.show(t); return K.say(t - 0.2, "A commit is a small object: a message and one pointer", { y: 70 }) + 0.2; },
          (t) => { t = a_ct1.draw(t, 0.4); t = t1.show(t - 0.1); return K.say(t - 0.2, "It points at a tree: the list of names in that snapshot", { y: 70 }) + 0.2; },
          (t) => { a_t1.forEach((a, i) => a.draw(t + i * 0.2, 0.4)); bl.forEach((b, i) => b.show(t + 0.25 + i * 0.2)); return K.say(t + 0.6, "Each name points at a blob: the content of one file", { y: 70 }) + 0.4; },
          (t) => { t = c2.show(t); par.draw(t - 0.2, 0.3); t = a_ct2.draw(t, 0.35); t = t2.show(t - 0.1); t = a_t2new.draw(t, 0.4); t = nb.show(t - 0.15);
            return K.say(t - 0.3, "A second commit after one edit: a new tree and ONE new blob", { y: 70 }) + 0.2; },
          (t) => { a_t2sh.forEach((a, i) => a.draw(t + i * 0.25, 0.6)); t += 0.5 + 0.25 * a_t2sh.length; shared.forEach((i, k) => { bl[i].n.pulse(t + k * 0.15, 0.6, "y", -14); }); tl.sound(t, "pop", 0.8);
            return K.say(t, "The unchanged files are not stored again: both trees share those blobs", { y: 70 }) + 0.5; },
          (t) => { K.say(t, "Read the rows: one new ID, the others identical", { y: 70 });
            flash(t + 0.3, t1, changed, 1.4); flash(t + 0.5, t2, changed, 1.4); nb.n.pulse(t + 0.6, 0.6, "y", -12); tagNew.to(t + 0.7, 0.35, { o: 1, s: 1 }, "back"); tl.sound(t + 0.72, "pop", 0.8);
            shared.forEach((i, k) => { const t0 = t + 1.7 + k * 0.7; flash(t0, t1, i, 1.2); flash(t0 + 0.1, t2, i, 1.2); bl[i].n.pulse(t0 + 0.2, 0.6, "y", -12); tagSame[k].to(t0 + 0.3, 0.35, { o: 1, s: 1 }, "back"); tl.sound(t0 + 0.32, "pop", 0.8); });
            return t + 1.7 + shared.length * 0.7 + 0.8; },
        ],
        fit: () => {},
      };
    },
  };

  // (j) the lab sandbox: your real setup and the lab are two separate boxes; lab commands never reach the real one
  Scenes.defs.sandbox = {
    steps: () => ["room", "inside", "outside", "enter", "doors", "shield"],
    build(K, P) {
      const tl = K.tl, pal = K.pal, W = K.W;
      const mac = svg("g", {}, K.back);
      A.rect(mac, 40, 96, W - 80, 650, { r: 26, fill: "#0d1016", stroke: "#3a424d", sw: 3, dash: "3 12" }).setAttribute("stroke-linecap", "round");
      A.text(mac, 76, 136, "your Mac", { mono: false, size: 30, weight: 800, fill: DIM, anchor: "start" });
      const mn = tl.node(mac, { o: 0 });
      const box = (x, y, w, h, col, title, sub, items, depth) => {
        const g = svg("g", {}, K.main);
        A.slab(g, x, y, w, h, { depth, stroke: col, fill: "#11151c" });
        A.text(g, x + 30, y + 48, title, { mono: false, size: 36, weight: 800, fill: col === pal.accent ? pal.accent : WHITE, anchor: "start" });
        A.text(g, x + 30, y + 90, sub, { mono: false, size: 25, weight: 500, fill: DIM, anchor: "start" });
        const rows = items.map((s, i) => { const r = svg("g", {}, g); A.rect(r, x + 26, y + 124 + i * 70, w - 52, 58, { r: 10, fill: "#0b0d12", stroke: "#30363d", sw: 2 });
          svg("circle", { cx: x + 56, cy: y + 153 + i * 70, r: 8, fill: col }, r); A.text(r, x + 82, y + 154 + i * 70, s, { size: 25, fill: "#d5dce4", anchor: "start", weight: 500 }); return tl.node(r, { o: 0, x: 24 }); });
        return { g, x, y, w, h, rows, n: tl.node(g, { o: 0, y: 36 }) };
      };
      const real = box(110, 200, 600, 360, NEUTRAL, "Your real setup", "outside the room", P.real || ["~/.gitconfig", "your repositories", "your credentials"], 14);
      const lab = box(1010, 170, 610, 360, pal.accent, P.name || "The lab sandbox", "$LAB: the sealed room", P.inside || ["its own Git configuration", "a clock the replays control", "one directory per replay"], 22);
      // a padlock on the real box
      const lock = svg("g", {}, K.top); svg("path", { d: "M-22,0 v-20 a22,22 0 0 1 44,0 v20", fill: "none", stroke: WHITE, "stroke-width": 9, "stroke-linecap": "round" }, lock);
      A.rect(lock, -34, 0, 68, 54, { r: 10, fill: WHITE }); svg("circle", { cx: 0, cy: 24, r: 8, fill: INK }, lock); A.rect(lock, -3, 24, 6, 16, { r: 3, fill: INK });
      const ln = tl.node(lock, { x: real.x + real.w - 60, y: real.y + 40, o: 0, s: 0.4 });
      const never = svg("g", {}, K.top); A.text(never, real.x + real.w / 2, real.y + real.h + 40, "never read, never written", { mono: false, size: 28, weight: 700, fill: WHITE, italic: true });
      const nn = tl.node(never, { o: 0, y: -10 });
      // the two commands and their doors
      const doors = [["labs/shell", "real clock", lab.x + 150], ["labs/run", "fixed clock", lab.x + 460]].map(([cmd, clock, cx], i) => {
        const g = svg("g", {}, K.main), w = A.mono_w(cmd, 28) + 44, y = 660;
        A.rect(g, cx - w / 2, y - 30, w, 60, { r: 12, fill: INK, stroke: pal.accent, sw: 3 }); A.text(g, cx, y + 1, cmd, { size: 28, fill: WHITE });
        const arrow = K.arrow(K.back, cx, y - 36, cx, lab.y + lab.h + 12, { straight: true, stroke: pal.accent, sw: 5 });
        const cg = svg("g", {}, K.main); svg("circle", { cx: cx - A.sans_w(clock, 24) / 2 - 22, cy: y + 62, r: 13, fill: "none", stroke: i ? pal.accent2 : DIM, "stroke-width": 3.5 }, cg);
        svg("path", { d: `M${cx - A.sans_w(clock, 24) / 2 - 22},${y + 54} v8 h6`, fill: "none", stroke: i ? pal.accent2 : DIM, "stroke-width": 3, "stroke-linecap": "round" }, cg);
        A.text(cg, cx + 8, y + 63, clock, { mono: false, size: 24, weight: 700, fill: i ? pal.accent2 : "#aeb8c4" });
        return { n: tl.node(g, { o: 0, y: 20 }), arrow, cn: tl.node(cg, { o: 0 }), cx, y };
      });
      // the shield in front of the real box
      const sh = svg("path", { d: `M${real.x + real.w + 46},${real.y - 6} q34,${real.h / 2 + 6} 0,${real.h + 12}`, fill: "none", stroke: pal.accent2, "stroke-width": 8, "stroke-linecap": "round", filter: "url(#glow)", opacity: 0 }, K.top);
      let shV = 0; tl.after.push(() => sh.setAttribute("opacity", shV.toFixed(3)));
      const bounce = (t, label, y) => {
        const g = svg("g", {}, K.top), w = A.mono_w(label, 24) + 30; A.rect(g, -w / 2, -22, w, 44, { r: 10, fill: pal.accent }).setAttribute("filter", "url(#sh)"); A.text(g, 0, 1, label, { size: 24, fill: INK });
        const x0 = lab.x - 20 - w / 2, x1 = real.x + real.w + 70 + w / 2, n = tl.node(g, { x: x0, y, o: 0, s: 0.7 }), v = n.v;
        n.to(t, 0.15, { o: 1, s: 1 }, "out");
        tl.add(t + 0.1, 0.5, (p) => { v.x = lerp(x0, x1, p); }, "in");
        tl.add(t + 0.55, 0.5, (p) => { shV = p; }, "there"); tl.sound(t + 0.58, "pop", 1.0);
        tl.add(t + 0.6, 0.7, (p) => { v.x = lerp(x1, x0 + 40, p); v.y = y - 50 * 4 * p * (1 - p); v.r = -14 * Math.sin(Math.PI * p); }, "out");
        n.to(t + 1.25, 0.2, { o: 0, s: 0.7 }, "in");
        return t + 1.45;
      };
      let introduced = false;                                   // the title and the outline of the Mac arrive with whichever step comes first
      const intro = (t) => { if (introduced) return t; introduced = true; t = K.title(t, P.title || "The lab is a sealed room"); mn.to(t, 0.5, { o: 1 }, "out"); return t + 0.3; };
      return {
        steps: [
          (t) => { t = intro(t); lab.n.to(t + 0.1, 0.55, { o: 1, y: 0 }, "out"); tl.sound(t + 0.2, "pop", 0.8); return t + 0.7; },
          (t) => { t = intro(t); lab.rows.forEach((r, i) => { r.to(t + i * 0.3, 0.35, { o: 1, x: 0 }, "out"); tl.sound(t + i * 0.3 + 0.05, "pop", 0.7); }); return t + 0.3 * lab.rows.length + 0.3; },
          (t) => { t = intro(t); real.n.to(t, 0.55, { o: 1, y: 0 }, "out"); tl.sound(t + 0.1, "pop", 0.8); real.rows.forEach((r, i) => r.to(t + 0.4 + i * 0.2, 0.35, { o: 1, x: 0 }, "out")); ln.to(t + 1.1, 0.35, { o: 1, s: 1 }, "back"); return t + 1.5; },
          (t) => { doors.forEach((d, i) => { d.n.to(t + i * 0.35, 0.35, { o: 1, y: 0 }, "out"); d.arrow.draw(t + 0.25 + i * 0.35, 0.45); tl.sound(t + i * 0.35 + 0.3, "whoosh", 0.7); }); return K.say(t + 0.8, "Both commands walk into the room, and nowhere else", { y: 800, size: 30 }) + 0.2; },
          (t) => { doors.forEach((d, i) => { d.cn.to(t + i * 0.4, 0.4, { o: 1 }, "out"); d.n.pulse(t + i * 0.4, 0.5, "y", -8); }); tl.sound(t + 0.1, "pop", 0.7); return K.say(t + 0.5, "Two doors, two clocks: only labs/run gives the book's IDs", { y: 800, size: 30 }) + 0.3; },
          (t) => { t = intro(t); t = bounce(t, "read config", real.y + 120); t = bounce(t - 0.4, "git config set --global", real.y + 240); nn.to(t - 0.6, 0.4, { o: 1, y: 0 }, "out"); ln.pulse(t - 0.6, 0.5, "s", 0.25);
            return K.say(t - 0.5, "Nothing a lab does can reach your real configuration", { y: 800, size: 30 }) + 0.4; },
        ],
        fit: () => {},
      };
    },
  };

  // (f) remotes: your clone, origin and a teammate; fetch, pull and push move commits and remote-tracking labels
  //     params: {teammate: "Asha" | "none" (only "you" and "origin" are drawn), branch, ids: [4 commits], note (under "origin"), title}
  Scenes.defs.remotes = {
    steps: () => ["setup", "teammate-push", "fetch", "pull", "commit", "push"],
    build(K, P) {
      const tl = K.tl, pal = K.pal, solo = P.teammate === "none", mate = P.teammate || "teammate", br = P.branch || "main", rb = "origin/" + br;
      const ids = (P.ids || []).concat(["A", "B", "C", "D"].slice((P.ids || []).length)).slice(0, 4), [c0, c1, c2, c3] = ids;
      const long = ids.some((x) => x.length > 2);
      const boxes = solo ? [["your clone", 70, 290, 760], ["origin", 898, 290, 760]] : [["your clone", 40, 400, 780], ["origin", 474, 90, 780], [mate + "'s clone", 908, 400, 780]];
      const PH = 300;
      const reps = boxes.map(([name, x, y, w], i) => {
        const g = svg("g", {}, K.main);
        A.slab(g, x, y, w, PH, { depth: i === 1 ? 22 : 14, stroke: i === 1 ? pal.accent : "#59636e", fill: "#0e1218" });
        A.text(g, x + 24, y + 34, name, { mono: false, size: 28, weight: 800, fill: i === 1 ? pal.accent : WHITE, anchor: "start" });
        if (i === 1) A.text(g, x + w - 24, y + 34, P.note || "the shared server", { mono: false, size: 22, weight: 500, fill: DIM, anchor: "end" });
        const G = new Graph(K, g, { dx: long ? 170 : 150, dy: 100, r: 21, ox: x + (long ? 100 : 110), oy: y + (long ? 170 : 190), order: ["above", "below"] });
        ids.forEach((id, k) => G.commit(id, k, 0, k ? [ids[k - 1]] : []));
        G.o.prefer[rb] = "below";
        return { g, G, x, y, w, n: tl.node(g, { o: 0, y: 40 }), at: (id) => { const p = G.xy(G.c[id].col, 0); return [p.x, p.y]; } };
      });
      const [me, origin, tm] = reps;
      const send = (t, a, b, id) => { const p = a.at(id), q = b.at(id); return K.fly(t, p[0], p[1], q[0], q[1], { label: id, dur: 0.85, lift: 90 }); };
      const cap = solo ? { y: 150, size: 30 } : { y: 30, x: 1180, size: 27 };
      const who = P.teammate && !solo ? mate : "A teammate";
      return {
        steps: [
          (t) => { t = K.title(t, P.title || "Remotes"); reps.forEach((r, i) => r.n.to(t + [0.15, 0, 0.3][i], 0.5, { o: 1, y: 0 }, "out")); t += 0.7;
            reps.forEach((r) => { r.G.show(t, c0, { quiet: true }); r.G.show(t + 0.15, c1, { quiet: true }); }); t += 0.5;
            me.G.refs(t, { [br]: c1, HEAD: br, [rb]: c1 }); const e = origin.G.refs(t, { [br]: c1 }); return (tm ? tm.G.refs(t, { [br]: c1, HEAD: br }) : e) + 0.1; },
          (t) => { if (tm) { t = tm.G.show(t, c2, { glow: true }); t = tm.G.refs(t - 0.1, { [br]: c2, HEAD: br }); t = send(t, tm, origin, c2); }
            else { const q = origin.at(c2); t = K.fly(t, K.W + 60, origin.y - 70, q[0], q[1], { label: c2, dur: 0.95, lift: 40 }); }      // the teammate is outside the picture: the commit arrives from off-screen
            t = origin.G.show(t - 0.25, c2, tm ? {} : { glow: true }); t = origin.G.refs(t - 0.1, { [br]: c2 });
            return K.say(t - 0.4, `${who} pushes commit ${c2}. Your clone has not heard about it.`, cap) + 0.2; },
          (t) => { t = K.cmd(t, "git fetch"); t = send(t, origin, me, c2); t = me.G.show(t - 0.25, c2); t = me.G.refs(t - 0.1, { [br]: c1, HEAD: br, [rb]: c2 });
            return K.say(t - 0.4, `fetch downloads ${c2} and moves only ${rb}`, cap) + 0.2; },
          (t) => { t = K.cmd(t, "git pull"); t = me.G.refs(t, { [br]: c2, HEAD: br, [rb]: c2 }); return K.say(t - 0.4, "pull = fetch, then bring your branch up", cap) + 0.2; },
          (t) => { t = K.cmd(t, "git commit"); t = me.G.show(t, c3, { glow: true }); t = me.G.refs(t - 0.1, { [br]: c3, HEAD: br, [rb]: c2 });
            return K.say(t - 0.4, `Your new commit ${c3} exists only in your clone`, cap) + 0.2; },
          (t) => { t = K.cmd(t, "git push"); t = send(t, me, origin, c3); t = origin.G.show(t - 0.25, c3); origin.G.refs(t - 0.1, { [br]: c3 }); t = me.G.refs(t + 0.1, { [br]: c3, HEAD: br, [rb]: c3 });
            return K.say(t - 0.4, `push uploads ${c3}; origin's ${br} and your ${rb} move`, cap) + 0.2; },
        ],
        fit: () => {},
      };
    },
  };

  // (h) a pull request: branch, push, review, checks, merge
  //     params: {feature, main, title, number, review: approved|missing|changes|unknown, checks: passed|failing|pending|unknown,
  //              check_names: [a, b], layers: "on" (says which layer owns each part: Git, GitHub, GitHub Actions)}
  //     When the review or a check is not green, the merge step shows a blocked merge: no merge commit, a BLOCKED stamp.
  Scenes.defs.pr = {
    steps: () => ["branch", "push", "review", "checks", "merge"],
    build(K, P) {
      const tl = K.tl, pal = K.pal, f = P.feature || "feature", m = P.main || "main";
      const rvS = P.review || "approved", ckS = P.checks || "passed", blocked = rvS !== "approved" || ckS !== "passed";
      const names = ["branch", "push", "review", "checks", "merge"], X0 = 220, DX = 322, Y = P.title ? 136 : 120, DY = P.title ? 16 : 0;
      const rail = svg("line", { x1: X0, y1: Y, x2: X0 + 4 * DX, y2: Y, stroke: "#30363d", "stroke-width": 6, "stroke-linecap": "round" }, K.back);
      const fill = svg("line", { x1: X0, y1: Y, x2: X0, y2: Y, stroke: pal.accent, "stroke-width": 6, "stroke-linecap": "round" }, K.back);
      const stages = names.map((s, i) => { const g = svg("g", {}, K.main); const c = svg("circle", { r: 30, fill: INK, stroke: "#59636e", "stroke-width": 5 }, g);
        const num = A.text(g, 0, 1, String(i + 1), { size: 26, fill: DIM }); const lab = A.text(g, 0, 62, s, { mono: false, size: 28, weight: 700, fill: DIM });
        const n = tl.node(g, { x: X0 + i * DX, y: Y, o: 0, s: 0.6 }); return { n, c, num, lab, on: 0 }; });
      let prog = 0;
      const stage = (t, i, stop) => { const from = prog, to = stop ? prog : Math.max(prog, i); prog = to; tl.add(t, 0.45, (p) => { fill.setAttribute("x2", (X0 + lerp(from, to, p) * DX).toFixed(1)); }, "inOut");
        const s = stages[i], col = stop ? RED : pal.accent; tl.at(t + 0.3, (p) => { s.c.setAttribute("stroke", p ? col : "#59636e"); s.c.setAttribute("fill", p ? (stop ? INK : col) : INK); s.num.setAttribute("fill", p ? (stop ? RED : INK) : DIM); s.lab.setAttribute("fill", p ? WHITE : DIM); });
        s.n.pulse(t + 0.3, 0.45, "s", 0.22); tl.sound(t + 0.32, "pop", 0.8); return t + 0.5; };
      const gg = svg("g", {}, K.main);
      const G = new Graph(K, gg, { dx: 170, dy: 170, r: 24, ox: 130, oy: 420 + DY });
      G.commit("A", 0, 0); G.commit("B", 1, 0, ["A"]); G.commit("C", 2, 1, ["B"]); G.commit("D", 3, 1, ["C"]); G.commit("M", 4, 0, ["B", "D"]);
      G.o.prefer[m] = "above"; G.o.prefer[f] = "below"; G.o.prefer["origin/" + f] = "below";
      // the pull request card
      const px = 980, py = 300 + DY, pw = 660, ph = 400, card = svg("g", {}, K.main);
      A.slab(card, px, py, pw, ph, { depth: 16, stroke: pal.accent, fill: "#0e1218" });
      A.text(card, px + 26, py + 40, "Pull request #" + (P.number || "42"), { mono: false, size: 30, weight: 800, fill: WHITE, anchor: "start" });
      A.text(card, px + 26, py + 84, `${f}  ->  ${m}`, { size: Math.min(24, Math.floor((pw - 60) / ((f.length + m.length + 6) * 0.6021))), fill: pal.accent2, anchor: "start", weight: 500 });
      const cn = tl.node(card, { o: 0, y: 40 });
      // a small pill that says which layer owns a thing (layers=on)
      const layer = (parent, xr, y, text) => { const g = svg("g", {}, parent), w = A.sans_w(text, 20) + 26; A.rect(g, xr - w, y - 17, w, 34, { r: 17, fill: INK, stroke: DIM, sw: 2 }); A.text(g, xr - w / 2, y + 1, text, { mono: false, size: 20, weight: 700, fill: "#aeb8c4" }); if (P.layers !== "on") g.setAttribute("display", "none"); return g; };
      const row = (y, label, lay) => { const g = svg("g", {}, card); A.rect(g, px + 22, py + y, pw - 44, 58, { r: 10, fill: "#0b0d12", stroke: "#30363d", sw: 2 }); const ring = svg("circle", { cx: px + 56, cy: py + y + 29, r: 14, fill: "none", stroke: "#59636e", "stroke-width": 4 }, g);
        A.text(g, px + 88, py + y + 30, label, { mono: false, size: 25, weight: 600, fill: "#d5dce4", anchor: "start" }); layer(g, px + pw - 36, py + y + 29, lay);
        const tk = K.tick(g, px + 56, py + y + 29, 0.9), cr = K.cross(g, px + 56, py + y + 29, 0.8), qm = A.text(g, px + 56, py + y + 30, "?", { size: 22, fill: AMBER }); qm.setAttribute("opacity", 0);
        return { n: tl.node(g, { o: 0, x: 24 }), ring, tk, cr, qm }; };
      const cn_ = P.check_names || ["tests", "lint"];
      const RV = { approved: "Review: approved by a teammate", missing: "Review: required, not given yet", changes: "Review: changes requested", unknown: "Review: approved?" };
      const rv = row(120, RV[rvS] || RV.approved, "GitHub"), ck1 = row(190, "Check: " + cn_[0], "GitHub Actions"), ck2 = row(260, "Check: " + (cn_[1] || "lint"), "GitHub Actions");
      // how a row ends: a green tick, a red cross, an amber ring that stays open, or an amber question mark
      const done = (t, r, st) => {
        const good = st === "approved" || st === "passed", bad = st === "failing" || st === "changes", col = good ? GREEN : bad ? RED : AMBER;
        tl.at(t, (p) => r.ring.setAttribute("stroke", p ? col : "#59636e"));
        if (good) return K.drawTick(t, r.tk);
        if (bad) { tl.add(t, 0.25, (p) => r.cr.setAttribute("stroke-dashoffset", (1 - p).toFixed(3)), "out"); tl.sound(t + 0.05, "pop", 0.7); return t + 0.25; }
        if (st === "unknown") tl.add(t, 0.25, (p) => r.qm.setAttribute("opacity", p.toFixed(3)), "out"); else tl.at(t, (p) => r.ring.setAttribute("stroke-dasharray", p ? "7 6" : "none"));
        tl.sound(t + 0.05, "pop", 0.5); return t + 0.25; };
      const stamp = svg("g", {}, card), sw = blocked ? 176 : 164;
      A.rect(stamp, px + pw - sw - 26, py + 22, sw, 46, { r: 23, fill: blocked ? INK : pal.accent, stroke: blocked ? RED : "none", sw: blocked ? 3 : 0 });
      A.text(stamp, px + pw - 26 - sw / 2, py + 46, blocked ? "BLOCKED" : "MERGED", { mono: false, size: 23, weight: 800, fill: blocked ? RED : INK, spacing: 2 });
      const sn = tl.node(stamp, { o: 0, s: 1 });
      const gl = layer(K.main, 130 + 64, 300 + DY, "Git"), gln = tl.node(gl, { o: 0 });
      const ptw = A.sans_w("Pull request #" + (P.number || "42"), 30);
      layer(card, px + 26 + ptw + 22 + A.sans_w("GitHub", 20) + 26, py + 40, "GitHub");
      const cross5 = K.cross(stages[4].n.el, 0, 0, 1.1, RED);
      return {
        steps: [
          (t) => { t = K.title(t, P.title); stages.forEach((s, i) => s.n.to(t + i * 0.07, 0.3, { o: 1, s: 1 }, "back")); K.fadeIn(t, rail, { dy: 0 }); t += 0.5; G.show(t, "A", { quiet: true }); G.show(t + 0.15, "B", { quiet: true }); t = G.refs(t + 0.5, { [m]: "B", HEAD: m });
            gln.to(t, 0.3, { o: 1 }, "out");
            t = stage(t, 0); t = K.cmd(t, "git switch -c " + f); t = G.refs(t, { [m]: "B", [f]: "B", HEAD: f }); t = G.show(t, "C", { glow: true }); t = G.show(t - 0.1, "D", { glow: true }); return G.refs(t - 0.15, { [m]: "B", [f]: "D", HEAD: f }) + 0.2; },
          (t) => { t = stage(t, 1); t = K.cmd(t, "git push -u origin " + f); t = G.refs(t, { [m]: "B", [f]: "D", HEAD: f, ["origin/" + f]: "D" }); cn.to(t - 0.1, 0.5, { o: 1, y: 0 }, "out"); tl.sound(t, "pop", 0.8); return t + 0.6; },
          (t) => { t = stage(t, 2); K.cmdOff(t); rv.n.to(t, 0.35, { o: 1, x: 0 }, "out"); return done(t + 0.6, rv, rvS) + 0.3; },
          (t) => { t = stage(t, 3); ck1.n.to(t, 0.35, { o: 1, x: 0 }, "out"); ck2.n.to(t + 0.15, 0.35, { o: 1, x: 0 }, "out"); t = done(t + 0.7, ck1, ckS); return done(t + 0.25, ck2, ckS === "failing" ? "passed" : ckS) + 0.3; },
          (t) => { if (blocked) {                                           // the button stays grey: no merge commit, main stays where it was
              t = stage(t, 4, true); tl.add(t - 0.2, 0.25, (p) => { cross5.setAttribute("stroke-dashoffset", (1 - p).toFixed(3)); stages[4].num.setAttribute("opacity", (1 - p).toFixed(3)); }, "out");
              sn.to(t - 0.1, 0.3, { o: 1 }, "out"); sn.pulse(t - 0.1, 0.4, "x", 9); return t + 0.5; }
            t = stage(t, 4); t = G.show(t, "M", { glow: true }); t = G.refs(t - 0.1, { [m]: "M", [f]: "D", HEAD: f, ["origin/" + f]: "D" }); sn.to(t - 0.2, 0.3, { o: 1 }, "out"); sn.pulse(t - 0.2, 0.4, "y", -10); return t + 0.4; },
        ],
        fit: () => {},
      };
    },
  };

  // (i) a CI pipeline: event -> workflow -> job on a runner -> steps -> result
  Scenes.defs.ci = {
    steps: () => ["event", "workflow", "runner", "steps", "result"],
    build(K, P) {
      const tl = K.tl, pal = K.pal, stepNames = P.steps || ["checkout", "set up Python", "install", "run tests"];
      // the trigger: event=push|pull_request|schedule|workflow_dispatch|release names it in the workflow file; trigger=... is how the caption says it;
      // subject=... is the word under the commit; result=failed ends the run with a red cross on the last step
      const EV = { push: ["a push", "commit"], pull_request: ["a pull request", "the merge result"], schedule: ["a schedule", "default branch"], workflow_dispatch: ["a click on Run workflow", "chosen branch"], release: ["a published release", "tagged commit"] };
      const evn = P.event || "push", trig = P.trigger || (EV[evn] || EV.push)[0], subj = P.subject || (EV[evn] || EV.push)[1], failed = P.result === "failed" || P.result === "failing", RES = failed ? RED : GREEN;
      const ev = svg("g", {}, K.main);
      svg("circle", { cx: 150, cy: 330, r: 34, fill: INK, stroke: NEUTRAL, "stroke-width": 6 }, ev);
      A.text(ev, 150, 400, subj, { size: Math.min(23, Math.floor(270 / (subj.length * 0.6021))), fill: DIM, weight: 500 });
      A.rect(ev, 30, 222, 240, 46, { r: 10, fill: pal.accent }); A.text(ev, 150, 246, evn, { size: Math.min(24, Math.floor(220 / (evn.length * 0.6021))), fill: INK });
      A.text(ev, 150, 180, "EVENT", { mono: false, size: 22, weight: 800, fill: DIM, spacing: 3 });
      const en = tl.node(ev, { o: 0, y: 24 });
      const wf = svg("g", {}, K.main), wx = 400, wy = 240, ww = 380, wh = 190;
      A.slab(wf, wx, wy, ww, wh, { depth: 14, stroke: pal.accent2, fill: "#11151c" });
      A.text(wf, wx + ww / 2, wy - 60, "WORKFLOW", { mono: false, size: 22, weight: 800, fill: DIM, spacing: 3 });
      [".github/workflows/" + (P.file || "ci.yml"), "on: " + evn, "jobs:", "  " + (P.job || "test") + ": ..."].forEach((s, i) => A.text(wf, wx + 20, wy + 36 + i * 38, s, { size: i ? 23 : 21, fill: i ? "#d5dce4" : pal.accent2, anchor: "start", weight: 500 }));
      const wn = tl.node(wf, { o: 0, y: 24 });
      const run = svg("g", {}, K.main), rx = 960, ry = 130, rw = 660, rh = 560;
      A.slab(run, rx, ry + rh - 90, rw, 90, { depth: 26, stroke: "#59636e", fill: "#0d1016" });
      A.text(run, rx + 30, ry + rh - 44, "runner: " + (P.runner || "ubuntu-latest"), { size: 24, fill: "#b6bfc9", anchor: "start", weight: 500 });
      for (let i = 0; i < 3; i++) svg("circle", { cx: rx + rw - 40 - i * 30, cy: ry + rh - 45, r: 7, fill: i ? "#30363d" : pal.accent }, run);
      A.text(run, rx + rw / 2, ry - 46, "RUNNER: A FRESH MACHINE", { mono: false, size: 22, weight: 800, fill: DIM, spacing: 3 });
      const rn = tl.node(run, { o: 0, y: 30 });
      const job = svg("g", {}, K.main), jx = rx + 40, jy = ry + 20, jw = rw - 80, jh = rh - 150;
      A.slab(job, jx, jy, jw, jh, { depth: 12, stroke: pal.accent, fill: "#11151c" });
      A.text(job, jx + 24, jy + 36, "job: " + (P.job || "test"), { size: 26, fill: pal.accent, anchor: "start" });
      const jn = tl.node(job, { o: 0, y: -40 });
      const rows = stepNames.slice(0, 5).map((s, i) => { const g = svg("g", {}, job), y = jy + 70 + i * 66; A.rect(g, jx + 20, y, jw - 40, 54, { r: 9, fill: "#0b0d12", stroke: "#30363d", sw: 2 });
        const ring = svg("circle", { cx: jx + 52, cy: y + 27, r: 13, fill: "none", stroke: "#59636e", "stroke-width": 4 }, g); A.text(g, jx + 84, y + 28, s, { size: 24, fill: "#d5dce4", anchor: "start", weight: 500 });
        const tk = K.tick(g, jx + 52, y + 27, 0.85), cr = K.cross(g, jx + 52, y + 27, 0.75); const bar = A.rect(g, jx + 20, y, 0, 54, { r: 9, fill: pal.accent, o: 0.16 }); return { n: tl.node(g, { o: 0, x: 20 }), ring, tk, cr, bar, w: jw - 40 }; });
      const a1 = K.arrow(K.back, 250, 330, wx - 10, 330, { straight: true }), a2 = K.arrow(K.back, wx + ww + 18, 330, jx - 10, 330, { straight: true });
      const back = K.arrow(K.back, rx - 8, ry + rh - 45, 150, 428, { stroke: RES, d: `M${rx - 8},${ry + rh - 45} H170 Q150,${ry + rh - 45} 150,${ry + rh - 65} V428` });
      const res = svg("g", {}, K.top); svg("circle", { cx: 190, cy: 300, r: 22, fill: RES }, res); const rt = failed ? K.cross(res, 190, 300, 0.9, INK) : K.tick(res, 190, 300, 1, INK); const resn = tl.node(res, { o: 0 });
      return {
        steps: [
          (t) => { t = K.title(t, P.title || "A CI run, end to end"); en.to(t, 0.45, { o: 1, y: 0 }, "out"); tl.sound(t + 0.1, "pop", 0.8); return K.say(t + 0.2, "An event starts everything: here, " + trig, { y: 760 }) + 0.2; },
          (t) => { t = a1.draw(t, 0.4); wn.to(t - 0.1, 0.45, { o: 1, y: 0 }, "out"); tl.sound(t, "pop", 0.8); return K.say(t + 0.1, "GitHub finds the workflow files that listen for that event", { y: 760 }) + 0.2; },
          (t) => { t = a2.draw(t, 0.45); rn.to(t - 0.2, 0.5, { o: 1, y: 0 }, "out"); jn.to(t + 0.25, 0.5, { o: 1, y: 0 }, "out"); tl.sound(t + 0.3, "pop", 0.8); return K.say(t + 0.3, "Each job gets a runner: a clean machine that is thrown away afterwards", { y: 760 }) + 0.3; },
          (t) => { K.say(t, "The job's steps run in order, top to bottom", { y: 760 }); rows.forEach((r, i) => { const t0 = t + 0.3 + i * 0.62; r.n.to(t0, 0.25, { o: 1, x: 0 }, "out");
              const bad = failed && i === rows.length - 1;
              tl.add(t0 + 0.2, 0.35, (p) => r.bar.setAttribute("width", (r.w * p).toFixed(1)), "inOut"); tl.at(t0 + 0.5, (p) => r.ring.setAttribute("stroke", p ? (bad ? RED : GREEN) : "#59636e")); K.drawTick(t0 + 0.5, bad ? r.cr : r.tk); });
            return t + 0.3 + rows.length * 0.62 + 0.3; },
          (t) => { t = back.draw(t, 0.6); resn.to(t - 0.1, 0.3, { o: 1 }, "out"); resn.pulse(t - 0.1, 0.5, "y", -12); K.drawTick(t, rt); return K.say(t, failed ? "The result is attached to the commit as a failed check" : "The result is attached to the commit as a check", { y: 760 }) + 0.4; },
        ],
        fit: () => {},
      };
    },
  };

  // (k) content addressing: the ID is computed from the content.  Same input, same ID; one byte different, another ID.
  //     params: {differs: "byte"|"date"|"parcel", left, right, title}
  Scenes.defs.hash = {
    steps: () => ["one", "same", "different"],
    build(K, P) {
      const tl = K.tl, pal = K.pal;
      const PRE = {
        byte: { title: "Content addressing", left: "a file on your laptop", right: "the same file on a server", lines: ["model: small-v2", "timeout_s: 60"], alt: "timeout_s: 61", fn: "hash", ids: ["422e9c0", "9b1f0d7"],
          same: "Identical content, identical ID: in every repository, on every machine", diff: "One byte differs: a completely different ID" },
        date: { title: "Why the clock is fixed", left: "the commit in the book", right: "the same commands on your Mac", lines: ["tree    4b825dc", "author  Lab User", "date    Mon 7 Sep 10:07"], alt: "date    Tue 8 Sep 15:42", fn: "hash", ids: ["c672627", "5d01e9a"],
          same: "A replay pins the clock: the same bytes, so the same ID as the book", diff: "Typed by hand, the real clock gives another time: another ID" },
        parcel: { title: "An address computed from the content", left: "warehouse in Pune", right: "warehouse in Oslo", lines: ["parcel: 3 blue mugs"], alt: "parcel: 3 blue mugs, 1 chipped", fn: "address", ids: ["shelf 7e4a", "shelf 2f9b"],
          same: "Identical parcels land at identical addresses, without a phone call", diff: "An altered parcel no longer belongs at its address" },
      };
      const D = Object.assign({}, PRE[P.differs] || PRE.byte);
      // lines=a,b,c (the content), alt=... (the last line, changed), ids=first,second, fn=..., same=..., diff=... replace the sample values
      if (P.lines && P.lines.length) D.lines = P.lines.slice(0, 5);
      for (const k of ["alt", "fn", "same", "diff"]) if (P[k]) D[k] = P[k];
      if (P.ids && P.ids.length >= 2) D.ids = P.ids.slice(0, 2);
      const lines = D.lines, last = lines.length - 1;
      const LS = Math.min(28, Math.floor(590 / (Math.max(D.alt.length, ...lines.map((l) => l.length)) * 0.6021)));
      const CW = 640, CH = 96 + lines.length * 44, XS = [120, 968], Y = 150, MY = Y + CH + 70, IY = MY + 190;
      const side = (i) => {
        const x = XS[i], g = svg("g", {}, K.main);
        A.slab(g, x, Y, CW, CH, { depth: 16, stroke: i ? "#59636e" : NEUTRAL, fill: "#11151c" });
        A.text(g, x + 26, Y + 40, [P.left || D.left, P.right || D.right][i], { mono: false, size: 28, weight: 800, fill: WHITE, anchor: "start" });
        const hl = A.rect(g, x + 14, Y + 62 + last * 44, CW - 28, 42, { r: 8, fill: pal.accent2, o: 0 });
        const txt = lines.map((s, k) => A.text(g, x + 26, Y + 84 + k * 44, s, { size: LS, fill: "#d5dce4", anchor: "start", weight: 500 }));
        const alt = A.text(g, x + 26, Y + 84 + last * 44, D.alt, { size: LS, fill: pal.accent2, anchor: "start" }); alt.setAttribute("opacity", 0);
        const cx = x + CW / 2;
        const a1 = K.arrow(K.back, cx, Y + CH + 10, cx, MY - 10, { straight: true });
        const m = svg("g", {}, K.main); A.rect(m, cx - 150, MY, 300, 78, { r: 39, fill: INK, stroke: pal.accent, sw: 4 }); A.text(m, cx, MY + 40, D.fn + "( )", { size: 32, fill: pal.accent });
        const a2 = K.arrow(K.back, cx, MY + 88, cx, IY - 52, { straight: true, stroke: pal.accent });
        const idg = svg("g", {}, K.main), iw = Math.max(300, A.mono_w(D.ids[1], 44) + 70); const box = A.rect(idg, cx - iw / 2, IY - 42, iw, 84, { r: 16, fill: INK, stroke: NEUTRAL, sw: 4 });
        const idt = A.text(idg, cx, IY + 2, D.ids[0], { size: 44, fill: WHITE });
        return { g, cx, hl, last: txt[last], alt, a1, a2, idt, box, n: tl.node(g, { o: 0, y: 30 }), mn: tl.node(m, { o: 0, s: 0.6, x: 0, y: 0 }), idn: tl.node(idg, { o: 0, s: 1 }), shown: false, ver: 0 };
      };
      const S = [side(0), side(1)];
      const HEX = "0123456789abcdef";
      const scramble = (t, sd, to) => { const from = sd.cur || D.ids[0]; sd.cur = to;
        tl.add(t, 0.7, (p) => { let out = ""; for (let i = 0; i < to.length; i++) out += /[0-9a-f]/.test(to[i]) && p < 1 && i >= Math.floor(p * to.length) ? HEX[(i * 7 + Math.floor(p * 23) * 5 + to.charCodeAt(i)) % 16] : (p > 0 ? to[i] : from[i] || ""); sd.idt.textContent = p > 0 ? out : from; }, "lin");
        for (let i = 0; i < 6; i++) tl.sound(t + i * 0.1, "tick", 0.7); return t + 0.7; };
      const run = (t, sd, id, quiet) => { t = sd.a1.draw(t, 0.3); sd.mn.to(t - 0.1, 0.3, { o: 1, s: 1 }, "back"); sd.mn.pulse(t + 0.25, 0.4, "y", 6); t = sd.a2.draw(t + 0.35, 0.3); sd.idn.to(t - 0.1, 0.3, { o: 1 }, "out"); if (!quiet) tl.sound(t, "pop", 0.8); sd.cur = D.ids[0]; return id === D.ids[0] ? t + 0.3 : scramble(t, sd, id); };
      const showCard = (t, sd) => { sd.n.to(t, 0.45, { o: 1, y: 0 }, "out"); tl.sound(t + 0.1, "pop", 0.8); sd.shown = true; return t + 0.5; };
      const setVer = (t, sd, v) => { if (sd.ver === v) return t; sd.ver = v;
        tl.add(t, 0.35, (p) => { const q = v ? p : 1 - p; sd.last.setAttribute("opacity", (1 - q).toFixed(3)); sd.alt.setAttribute("opacity", q.toFixed(3)); sd.hl.setAttribute("opacity", (0.22 * q).toFixed(3)); }, "inOut");
        tl.add(t, 0.5, (p) => sd.hl.setAttribute("opacity", (0.22 * (v ? 1 : 0) + 0.3 * p).toFixed(3)), "there"); return t + 0.45; };
      const sign = ["=", "≠"].map((ch, i) => { const g = svg("g", {}, K.top); A.text(g, 0, 0, ch, { mono: false, size: 120, weight: 900, fill: i ? pal.accent2 : pal.accent }); return tl.node(g, { x: K.W / 2, y: IY, o: 0, s: 0.4 }); });
      const setSign = (t, i) => { sign[1 - i].to(t, 0.2, { o: 0, s: 0.4 }, "in"); sign[i].to(t + 0.1, 0.35, { o: 1, s: 1 }, "back"); tl.sound(t + 0.15, "pop", 0.9); return t + 0.45; };
      const colour = (t, i) => tl.at(t, (p) => { S[1].box.setAttribute("stroke", p ? (i ? pal.accent2 : pal.accent) : NEUTRAL); if (!i) S[0].box.setAttribute("stroke", p ? pal.accent : NEUTRAL); });
      return {
        steps: [
          (t) => { t = K.title(t, P.title || D.title); t = showCard(t, S[0]); return run(t, S[0], D.ids[0]) + 0.1; },
          (t) => { if (!S[1].shown) { t = showCard(t, S[1]); t = run(t, S[1], D.ids[0]); } else { t = setVer(t, S[1], 0); t = scramble(t + 0.1, S[1], D.ids[0]); }
            colour(t, 0); t = setSign(t, 0); return K.say(t - 0.3, D.same, { y: 800, size: 30 }) + 0.2; },
          (t) => { if (!S[1].shown) { t = showCard(t, S[1]); t = run(t, S[1], D.ids[0], true) - 0.2; }
            t = setVer(t, S[1], 1); t = scramble(t + 0.1, S[1], D.ids[1]); colour(t, 1); t = setSign(t, 1); return K.say(t - 0.3, D.diff, { y: 800, size: 30 }) + 0.2; },
        ],
        fit: () => {},
      };
    },
  };

  // ---- entry point --------------------------------------------------------------------------------
  // cfg: {scene, params, from, to, focus:[keys], palette, h}
  Scenes.run = function (tl, cfg) {
    const def = Scenes.defs[cfg.scene];
    if (!def) throw new Error("unknown scene " + cfg.scene);
    const P = cfg.params || {}, all = def.steps(P);
    const names = cfg.steps && cfg.steps.length ? cfg.steps : all;          // this video may use a subset of the scene's steps
    const from = Math.max(0, cfg.from || 0), to = cfg.to == null ? names.length : cfg.to;
    const gap = cfg.gap == null ? 0.35 : cfg.gap;
    const fn = (sc, name) => { const i = all.indexOf(name); if (i < 0) throw new Error(`scene ${cfg.scene} has no step "${name}"`); return sc.steps[i]; };
    // Labels claim room as the steps are built, and some steps need the final scale.  So the scene is built twice:
    // once on a hidden scratch element to learn how much room every state needs, then for real.
    const host = document.getElementById("scene"), scratch = document.createElement("div");
    host.id = "scene-real"; scratch.id = "scene"; scratch.style.cssText = "position:absolute;left:-9999px;top:0;visibility:hidden";
    document.body.appendChild(scratch);
    const K2 = kit(A.stage(), cfg), sc2 = def.build(K2, P);
    sc2.fit && sc2.fit();
    const stepExts = [];                                                    // what every graph covers after each step: the camera follows it
    let tt = 0; for (const n of names.slice(0, cfg.fit_to || names.length)) { K2.step = n; tt = fn(sc2, n)(tt) + gap; stepExts.push((K2.graphs || []).map((g) => g.ext.slice())); }
    const exts = (K2.graphs || []).map((g) => g.ext.slice());
    scratch.remove(); host.id = "scene";
    const K = kit(tl, cfg), sc = def.build(K, P);
    (K.graphs || []).forEach((g, i) => { if (exts[i]) g.ext = exts[i]; });
    sc.fit && sc.fit();
    // A scene that grows is not framed for its final size from the first frame: the camera starts on what the first step shows
    // and re-fits gently when a later step needs more room.  camera=off (or a scene with refit: false) keeps the final framing throughout.
    const refit = sc.refit !== false && P.camera !== "off" && stepExts.length > 0;
    const cam = (i, t, dur) => { let end = t; if (!refit) return end; const e = stepExts[Math.min(i, stepExts.length - 1)];
      (K.graphs || []).forEach((g, k) => { if (g.box && e[k]) end = Math.max(end, g.camTo(t, e[k], dur)); }); return end; };
    cam(0, 0, 0);
    let t = 0;
    // a step is over when its own motion AND the camera's re-fit are over: the picture that is held afterwards is the settled one
    // When the camera has to move, it gets a head start of 0.35 s, so that what the step adds arrives inside the frame.
    const play = (i, last) => { K.step = names[i]; const c = i ? cam(i, t, 0.8) : t; t = Math.max(fn(sc, names[i])(t + (c > t ? 0.35 : 0)), c) + (last ? 0 : gap); };
    for (let i = 0; i < from; i++) play(i, false);
    tl.start = t;
    for (let i = from; i < to; i++) play(i, i === to - 1);
    if (cfg.focus && sc.focus) t = sc.focus(t, cfg.focus);
    tl.t = Math.max(t, tl.start);
    tl.info = { steps: names, from, to };
  };
})();
