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
  // more names Git resolves or writes for itself and that are not branches: HEAD@{1}, main~2, refs/bisect/bad, refs/stash, BISECT_EXPECTED_REV ...
  // (refs/pull/1/head, refs/stash and AUTO_MERGE written without "special:" stay branch chips, as v1 drew them)
  const SPECIAL_MORE = /@\{|[~^]\d*$|^refs\/(bisect|original|replace|notes|rewritten)\/|^[A-Z]+(_[A-Z]+)*_(HEAD|REV)$/;
  // marks on a commit (Graph.mark): the word on the badge and its colour.  Any other word is drawn as it is, in the second accent colour.
  const MARKS = { good: ["good", GREEN], bad: ["bad", RED], skip: ["skip", AMBER], pass: ["pass", GREEN], fail: ["FAIL", RED], left: ["<", null], right: [">", null], same: ["=", null],
    dangling: ["dangling", AMBER], damaged: ["damaged", RED], missing: ["missing", RED], test: ["test this", null], first_bad: ["first bad", RED], pruned: ["pruned", RED],
    conflict: ["conflict", RED], rejected: ["rejected", RED] };
  const DISPLAY = (name) => name.replace(/#.*$/, "");               // "origin/main#local" is drawn as "origin/main": two labels may share a short name
  const Scenes = (window.Scenes = { defs: {}, cuts: {} });        // cuts: every text a scene had to cut short with "…" -> the text in full (the layout check reports them)

  // ---- commit graph ------------------------------------------------------------------------------
  class Graph {
    constructor(K, parent, o) {
      this.K = K; this.tl = K.tl; this.pal = K.pal;
      this.o = Object.assign({ dx: 190, dy: 150, r: 24, ox: 0, oy: 0, prefer: {}, order: ["right", "below", "above", "left"] }, o || {});
      this.g = svg("g", {}, parent);
      this.sL = svg("g", {}, this.g);                                  // shaded sets (a range such as A..B) lie under everything
      this.eL = svg("g", {}, this.g); this.nL = svg("g", {}, this.g); this.lL = svg("g", {}, this.g);
      this.c = {}; this.chips = {}; this.shown = {}; this.vis = new Set(); this.notes = {}; this.map = {}; this.sets = {};
      this.ext = [1e9, 1e9, -1e9, -1e9];
      (K.graphs = K.graphs || []).push(this);
      this.tl.after.push(() => this.redraw());
    }
    xy(col, row) { return { x: this.o.ox + col * this.o.dx, y: this.o.oy + row * this.o.dy }; }
    grow(b) { const e = this.ext; e[0] = Math.min(e[0], b[0]); e[1] = Math.min(e[1], b[1]); e[2] = Math.max(e[2], b[2]); e[3] = Math.max(e[3], b[3]); }
    commit(id, col, row, parents, opt) {
      opt = opt || {};
      if (opt.kind) return this.oddCommit(id, col, row, parents, opt);
      const p = this.xy(col, row), inside = (opt.text || id).length <= 2, r = inside ? this.o.r + 4 : this.o.r;
      const g = svg("g", {}, this.nL);
      const ring = svg("circle", { r: r + 13, fill: "none", stroke: this.pal.accent2, "stroke-width": 5, opacity: 0, filter: "url(#glow)" }, g);
      const circle = svg("circle", { r, fill: INK, stroke: NEUTRAL, "stroke-width": 5 }, g);
      const label = inside ? A.text(g, 0, 1, opt.text || id, { size: 26, fill: WHITE }) : A.text(g, 0, r + 24, opt.text || id, { size: 21, fill: DIM, weight: 500 });
      const n = this.tl.node(g, { x: p.x, y: p.y, s: 0, o: 0 });
      const c = { id, col, row, r, inside, g, ring, circle, label, n, parents: parents || [], edges: [], ringV: 0, ghost: 0, hot: 0, dim: 0, lw: inside ? 0 : A.mono_w(id, 21), below: inside ? 8 : 40 };
      if (opt.sub) {                                                  // a second line under the commit: its tree ID, a date, a size
        A.text(g, 0, r + (inside ? 22 : 48), opt.sub, { size: 20, fill: this.pal.accent, weight: 500 });
        c.sub = opt.sub; c.lw = Math.max(c.lw, A.mono_w(opt.sub, 20)); c.below += inside ? 30 : 24;
      }
      for (const pa of c.parents) c.edges.push({ from: pa, p: 0, hot: 0, el: svg("path", { fill: "none", stroke: NEUTRAL, "stroke-width": 5, "stroke-linecap": "round", pathLength: 1, "stroke-dasharray": "1 1" }, this.eL) });
      this.c[id] = c;
      return c;
    }
    // commits that are not an ordinary "circle with an ID": kind "anon" (a plain dot: a commit nobody names), "placeholder" (a circle with a
    // thin solid outline and a word in italics under it: a commit whose ID is never printed; opt.dashed: the dashed slot of a commit that is
    // not made yet, as at a rebase that stopped), "elision" (three dots: "14 more" commits not drawn)
    oddCommit(id, col, row, parents, opt) {
      const p = this.xy(col, row), kind = opt.kind, text = opt.text == null ? "" : opt.text;
      const r = kind === "elision" ? 20 : kind === "anon" ? Math.round(this.o.r * 0.72) : this.o.r;
      const g = svg("g", {}, this.nL);
      const ring = svg("circle", { r: r + 13, fill: "none", stroke: this.pal.accent2, "stroke-width": 5, opacity: 0, filter: "url(#glow)" }, g);
      let circle;
      if (kind === "elision") { circle = svg("circle", { r, fill: "none", stroke: "none" }, g); for (const dx of [-13, 0, 13]) svg("circle", { cx: dx, cy: 0, r: 4.5, fill: NEUTRAL }, g); }
      else circle = svg("circle", { r, fill: INK, stroke: NEUTRAL, "stroke-width": kind === "anon" ? 4 : kind === "placeholder" && !opt.dashed ? 2.5 : 5 }, g);
      const label = A.text(g, 0, r + 24, text, { mono: false, size: 22, fill: "#aeb8c4", weight: 500, italic: true });
      const n = this.tl.node(g, { x: p.x, y: p.y, s: 0, o: 0 });
      const c = { id, col, row, r, inside: !text, g, ring, circle, label, n, parents: parents || [], edges: [], ringV: 0, ghost: 0, hot: 0, dim: 0, kind, dashed: !!opt.dashed, lw: text ? A.sans_w(text, 22) : 0, below: text ? 40 : 8 };
      for (const pa of c.parents) c.edges.push({ from: pa, p: 0, hot: 0, el: svg("path", { fill: "none", stroke: NEUTRAL, "stroke-width": 5, "stroke-linecap": "round", pathLength: 1, "stroke-dasharray": "1 1" }, this.eL) });
      this.c[id] = c;
      return c;
    }
    show(t, id, o) {
      o = o || {};
      const c = this.c[id];
      {                                                               // only commits that are shown claim room in the frame
        const p = this.xy(c.col, c.row), r = c.r;
        this.grow([p.x - r - 8, p.y - r - 8, p.x + r + 8, p.y + r + c.below]);
        if (c.lw) this.grow([p.x - c.lw / 2, p.y, p.x + c.lw / 2, p.y + r + c.below - 2]);
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
    // a badge above a commit: good, bad, skip, pass, fail, left (<), right (>), same (=), dangling, damaged, missing ... or any short word
    mark(t, id, what) {
      const c = this.c[id]; if (!c) return t;
      if (c.mark && c.mark.what === what) return t;
      if (c.mark) { c.mark.n.to(t, 0.2, { o: 0, s: 0.5 }, "in"); c.mark = null; }
      if (!what || what === "none" || what === "off") return t + 0.2;
      const M = MARKS[what] || [what, null], col = M[1] || this.pal.accent2, word = M[0], sym = word.length === 1;
      const size = sym ? 26 : 21, w = (sym ? 20 : A.sans_w(word, size)) + 24, h = 34, g = svg("g", {}, c.g);
      A.rect(g, -w / 2, -h / 2, w, h, { r: h / 2, fill: INK, stroke: col, sw: 3 });
      A.text(g, 0, 1, word, { mono: sym, size, weight: 800, fill: col });
      c.mark = { what, w, n: this.tl.node(g, { x: 0, y: -(c.r + 33), o: 0, s: 0.4 }) };
      c.mark.n.to(t, 0.3, { o: 1, s: 1 }, "back");
      const p = this.xy(c.col, c.row); this.grow([p.x - w / 2 - 4, p.y - c.r - 54, p.x + w / 2 + 4, p.y - c.r - 12]);
      if (what === "damaged" || what === "missing") this.tl.at(t, (q) => { c.broken = q; });
      return t + 0.3;
    }
    // "not in this clone" (behind a shallow boundary, a blob a partial clone left out): hatched, dotted outline
    absent(t, id, on) {
      const c = this.c[id]; if (!c) return t;
      if (!this.K.root.querySelector("#hatch")) {
        const pt = svg("pattern", { id: "hatch", width: 9, height: 9, patternUnits: "userSpaceOnUse", patternTransform: "rotate(45)" }, this.K.root.querySelector("defs"));
        svg("rect", { width: 9, height: 9, fill: INK }, pt); svg("line", { x1: 0, y1: 0, x2: 0, y2: 9, stroke: "#59636e", "stroke-width": 5 }, pt);
      }
      c.absentUsed = true;
      return this.tl.add(t, 0.4, (p) => { c.absent = on === false ? 1 - p : p; }, "inOut");
    }
    // "reachable only from the reflog": dashed like a ghost but not faded (something still names it)
    kept(t, id, on) { const c = this.c[id]; if (!c) return t; return this.tl.add(t, 0.4, (p) => { c.kept = on === false ? 1 - p : p; }, "inOut"); }
    // the object is deleted (pruned): the commit and its edges leave the picture
    gone(t, id) {
      const c = this.c[id]; if (!c || c.isGone) return t;
      c.isGone = true; this.vis.delete(id);
      const es = c.edges.concat(Object.values(this.c).flatMap((x) => x.edges.filter((e) => e.from === id)));
      for (const e of es) this.tl.add(t, 0.35, (p) => { e.p = Math.min(e.p, 1 - p); }, "in");
      c.n.to(t + 0.1, 0.4, { s: 0, o: 0 }, "in");
      return t + 0.5;
    }
    // a commit that was gone is named again by a later state: it comes back with its edges
    back(t, id) {
      const c = this.c[id]; if (!c || !c.isGone) return t;
      c.isGone = false; this.vis.add(id);
      const es = c.edges.filter((e) => this.vis.has(e.from)).concat(Object.values(this.c).filter((x) => this.vis.has(x.id)).flatMap((x) => x.edges.filter((e) => e.from === id)));
      for (const e of es) this.tl.add(t, 0.3, (p) => { e.p = Math.max(e.p, p); }, "inOut");
      c.n.to(t + 0.14, 0.34, { s: 1, o: 1 }, "back"); this.tl.sound(t + 0.18, "pop", 0.7);
      return t + 0.5;
    }
    // the camera looks only at these commits (a long history that scrolls); null = at everything shown so far
    viewOn(ids) {
      if (!ids || !ids.length) { this.view = null; return; }
      const e = [1e9, 1e9, -1e9, -1e9];
      for (const id of ids) { const c = this.c[id]; if (!c) continue; const p = this.xy(c.col, c.row);
        e[0] = Math.min(e[0], p.x - 130); e[1] = Math.min(e[1], p.y - 120); e[2] = Math.max(e[2], p.x + 130); e[3] = Math.max(e[3], p.y + 130); }
      for (const nm in this.shown) { const at = nm === "HEAD" ? (this.map[this.map.HEAD] || this.map.HEAD) : this.map[nm] || (this.notes[nm] || {}).at, q = this.shown[nm], ch = this.chips[nm];       // with the labels of those commits
        if (ids.includes(at) && ch) { e[0] = Math.min(e[0], q.x - ch.w / 2 - 24); e[2] = Math.max(e[2], q.x + ch.w / 2 + 24); e[1] = Math.min(e[1], q.y - 40); e[3] = Math.max(e[3], q.y + 40); } }
      this.view = e;
    }
    // "not visited": solid but dark, as opposed to ghost() ("unreachable": dashed and see-through)
    dim(t, id, on) { const c = this.c[id]; if (!c) return t; return this.tl.add(t, 0.4, (p) => { c.dim = on === false ? 1 - p : p; }, "inOut"); }
    // a translucent band behind a set of commits: a range such as A..B.  key names the set; alt = the other colour (for A...B)
    shade(t, key, ids, alt) {
      const old = this.sets[key];
      if (old && ids && old.ids.join() === ids.join()) return t;
      if (old) { const g0 = old.g; this.tl.add(t, 0.3, (p) => g0.setAttribute("opacity", (0.24 * (1 - p)).toFixed(3)), "in"); delete this.sets[key]; }
      ids = (ids || []).filter((id) => this.c[id]);
      if (!ids.length) return t + 0.3;
      const g = svg("g", { opacity: 0 }, this.sL), col = alt ? this.pal.accent : this.pal.accent2, R = this.o.r + 22;
      for (const id of ids) {
        const c = this.c[id], p = this.xy(c.col, c.row);
        svg("circle", { cx: p.x, cy: p.y, r: R, fill: col }, g);
        for (const pa of c.parents) if (ids.includes(pa)) { const q = this.xy(this.c[pa].col, this.c[pa].row); svg("line", { x1: q.x, y1: q.y, x2: p.x, y2: p.y, stroke: col, "stroke-width": 2 * R, "stroke-linecap": "round" }, g); }
        this.grow([p.x - R, p.y - R, p.x + R, p.y + R]);
      }
      this.sets[key] = { g, ids };
      return this.tl.add(t + 0.1, 0.45, (p) => g.setAttribute("opacity", (0.24 * p).toFixed(3)), "out");
    }
    move(t, id, col, row, dur) { const p = this.xy(col, row); const c = this.c[id]; c.col = col; c.row = row; this.grow([p.x - 60, p.y - 40, p.x + 60, p.y + 70]); return c.n.to(t, dur || 0.6, { x: p.x, y: p.y }, "inOut"); }
    redraw() {
      for (const id in this.c) {
        const c = this.c[id], v = c.n.v, gh = c.ghost;
        c.ring.setAttribute("opacity", (c.ringV * 0.95).toFixed(3));
        const base = c.broken ? RED : c.dim > 0 ? A.mix(NEUTRAL, "#454d57", c.dim) : NEUTRAL;
        if (c.kind !== "elision") {
          c.circle.setAttribute("stroke", c.hot > 0 ? A.mix(base, this.pal.accent2, c.hot) : base);
          c.circle.setAttribute("stroke-dasharray", gh > 0.5 || c.kept > 0.5 ? "7 7" : c.absent > 0.5 ? "2 7" : (c.kind === "placeholder" && c.dashed) || c.broken ? "5 7" : "none");
          if (c.absentUsed) { c.circle.setAttribute("fill", c.absent > 0.5 ? "url(#hatch)" : INK); c.circle.setAttribute("stroke-linecap", c.absent > 0.5 ? "round" : "butt"); }
        }
        if (c.dim > 0 || c.dimmed) { c.dimmed = true; c.label.setAttribute("fill", A.mix(c.inside ? WHITE : c.kind ? "#aeb8c4" : DIM, "#4f5863", c.dim)); }
        c.g.setAttribute("opacity", (Math.min(1, v.o) * lerp(1, 0.38, gh)).toFixed(3));
        for (const e of c.edges) {
          const a = this.c[e.from].n.v, dx = v.x - a.x, dy = v.y - a.y, d = Math.hypot(dx, dy) || 1;
          const r0 = this.c[e.from].r + 4, r1 = c.r + 4;
          const x0 = a.x + (dx / d) * r0, y0 = a.y + (dy / d) * r0, x1 = v.x - (dx / d) * r1, y1 = v.y - (dy / d) * r1;
          e.el.setAttribute("d", `M${x0.toFixed(1)},${y0.toFixed(1)} L${x1.toFixed(1)},${y1.toFixed(1)}`);
          e.el.setAttribute("stroke-dashoffset", (1 - e.p).toFixed(4));
          const ed = Math.max(c.dim, this.c[e.from].dim), eb = ed > 0 ? A.mix(NEUTRAL, "#454d57", ed) : NEUTRAL;
          e.el.setAttribute("stroke", e.hot > 0 ? A.mix(eb, this.pal.accent2, e.hot) : eb);
          const dotted = gh > 0.5 || this.c[e.from].ghost > 0.5 || c.kind === "elision" || this.c[e.from].kind === "elision" || c.absent > 0.5 || this.c[e.from].absent > 0.5 || c.kept > 0.5;
          e.el.setAttribute("stroke-dasharray", dotted ? (e.p < 0.999 ? `${(0.06 * e.p).toFixed(4)} 0.06` : "0.06 0.06") : "1 1");
          if (dotted && e.p < 0.999) e.el.setAttribute("stroke-dashoffset", 0);
          e.el.setAttribute("opacity", (e.p > 0.001 ? lerp(1, 0.35, Math.max(gh, this.c[e.from].ghost)) * Math.min(1, a.o * 2) : 0).toFixed(3));
        }
      }
      for (const k in this.chips) this.chips[k].paint();
      if (this.box) this.applyCam();
    }
    // ---- labels ----
    chip(name, kind) {
      if (this.chips[name]) return this.chips[name];
      const pal = this.pal, big = kind !== "head" && kind !== "special", key = name;
      const size = big ? 22 : 17, h = big ? 40 : 30;
      if (name.includes("#")) name = DISPLAY(name);
      let w = A.mono_w(name, size) + (big ? 26 : 18);
      const g = svg("g", {}, this.lL);
      let body;
      if (kind === "role" || kind === "setnote") {                   // a role on a commit (base, ours, theirs, P, C): a small pill; the name of a shaded set: plain code
        const role = kind === "role", tw = role ? A.sans_w(name, 22) + 26 : A.mono_w(name, 22) + 8;
        if (role) A.rect(g, -tw / 2, -17, tw, 34, { r: 17, fill: INK, stroke: pal.accent2, sw: 2.5 });
        A.text(g, 0, 1, name, { mono: !role, size: 22, weight: role ? 800 : 700, fill: pal.accent2 });
        const ch = { name: key, kind, g, w: tw, h: 34, n: this.tl.node(g, { o: 0, s: 0.4 }), cur: 0, danger: 0, paint: () => {} };
        this.chips[key] = ch; return ch;
      }
      if (kind === "tag") {                                          // a tag: the shape of a luggage tag, pointed at the left, with a hole
        const pt = 20; w += pt - 4;
        const x0 = -w / 2, x1 = w / 2, hh = h / 2;
        svg("path", { d: `M${x0},0 L${x0 + pt},${-hh} H${x1 - 7} a7,7 0 0 1 7,7 V${hh - 7} a7,7 0 0 1 -7,7 H${x0 + pt} Z`, fill: "#232b38", stroke: WHITE, "stroke-width": 3, "stroke-linejoin": "round" }, g);
        svg("circle", { cx: x0 + pt - 3, cy: 0, r: 4.5, fill: INK, stroke: WHITE, "stroke-width": 2 }, g);
        A.text(g, pt / 2 + 3, 1, name, { size, fill: WHITE });
        const ch = { name: key, kind, g, w, h, n: this.tl.node(g, { o: 0, s: 0.4 }), cur: 0, danger: 0, paint: () => {} };
        this.chips[key] = ch; return ch;
      }
      if (kind === "atag") {                                         // an annotated tag: the tag ref, then the tag object it points at, then the commit
        const oid = key.includes("#") ? key.slice(key.indexOf("#") + 1) : "", ot = oid ? "tag " + oid : "tag object", pt = 20;
        const tw = A.mono_w(name, size) + 26 + pt - 4, ow = A.mono_w(ot, 19) + 22, gapx = 34, hh = h / 2;
        const tg = svg("g", {}, g), og = svg("g", {}, g), ar = svg("path", { fill: "none", stroke: WHITE, "stroke-width": 3, "stroke-linecap": "round", "stroke-linejoin": "round" }, g);
        svg("path", { d: `M${-tw / 2},0 L${-tw / 2 + pt},${-hh} H${tw / 2 - 7} a7,7 0 0 1 7,7 V${hh - 7} a7,7 0 0 1 -7,7 H${-tw / 2 + pt} Z`, fill: "#232b38", stroke: WHITE, "stroke-width": 3, "stroke-linejoin": "round" }, tg);
        svg("circle", { cx: -tw / 2 + pt - 3, cy: 0, r: 4.5, fill: INK, stroke: WHITE, "stroke-width": 2 }, tg);
        A.text(tg, pt / 2 + 3, 1, name, { size, fill: WHITE });
        A.rect(og, -ow / 2, -hh, ow, h, { r: 3, fill: "#11151c", stroke: pal.accent, sw: 3 });
        A.text(og, 0, 1, ot, { size: 19, fill: pal.accent, weight: 700 });
        const ch = { name: key, kind, g, w: tw + gapx + ow, h, n: this.tl.node(g, { o: 0, s: 0.4 }), cur: 0, danger: 0, side: "right" };
        ch.paint = () => {                                             // the object stands between the ref and the commit, whichever side the chip is on
          const flip = ch.side === "left" ? -1 : 1, W2 = ch.w / 2;
          og.setAttribute("transform", `translate(${(flip * (-W2 + ow / 2)).toFixed(1)},0)`); tg.setAttribute("transform", `translate(${(flip * (W2 - tw / 2)).toFixed(1)},0)`);
          const x0 = flip * (W2 - tw) - flip * 4, x1 = flip * (-W2 + ow) + flip * 6;
          ar.setAttribute("d", `M${x0},0 H${x1} m${flip * 9},-8 l${-flip * 9},8 l${flip * 9},8`);
        };
        this.chips[key] = ch; return ch;
      }
      if (kind === "special") {                                      // ORIG_HEAD, MERGE_HEAD ...: a small hollow chip with square corners (HEAD's size, not a branch)
        A.rect(g, -w / 2, -h / 2, w, h, { r: 2, fill: INK, stroke: WHITE, sw: 2.5 });
        A.text(g, 0, 1, name, { size, fill: WHITE, weight: 500 }).setAttribute("data-small", "chip");
        const ch = { name: key, kind, g, w, h, n: this.tl.node(g, { o: 0, s: 0.4 }), cur: 0, danger: 0, paint: () => {} };
        this.chips[key] = ch; return ch;
      }
      if (kind === "note") {
        const tw = A.sans_w(name, 24);
        body = A.text(g, 0, 0, name, { mono: false, size: 24, weight: 500, fill: "#aeb8c4", italic: true });
        const tip = svg("path", { d: "M-9,0 L0,-12 L9,0 Z", fill: "#aeb8c4" }, g);
        const ch = { name: key, kind, g, w: tw + 8, h: 32, n: this.tl.node(g, { o: 0 }), cur: 0, side: "below" };
        ch.paint = () => { tip.setAttribute("transform", ch.side === "above" ? "translate(0,22) rotate(180)" : "translate(0,-20)"); tip.setAttribute("opacity", ch.side === "below" || ch.side === "above" ? 1 : 0); };
        this.chips[key] = ch; return ch;
      }
      const filled = svg("rect", { x: -w / 2, y: -h / 2, width: w, height: h, rx: 9, fill: kind === "head" ? WHITE : pal.accent }, g);
      const outline = svg("rect", { x: -w / 2, y: -h / 2, width: w, height: h, rx: 9, fill: INK, stroke: kind === "remote" ? DIM : NEUTRAL, "stroke-width": 3,
        "stroke-dasharray": kind === "remote" ? "8 6" : null }, g);
      body = A.text(g, 0, 1, name, { size, fill: INK });
      if (!big) body.setAttribute("data-small", "chip");
      const ch = { name: key, kind, g, w, h, n: this.tl.node(g, { o: 0, s: 0.4 }), cur: kind === "head" ? 1 : 0, danger: 0 };
      ch.paint = () => {
        outline.setAttribute("opacity", (1 - ch.cur).toFixed(3));
        filled.setAttribute("fill", ch.danger > 0 ? A.mix(kind === "head" ? WHITE : pal.accent, RED, ch.danger) : kind === "head" ? WHITE : pal.accent);
        body.setAttribute("fill", ch.cur > 0.5 ? INK : kind === "remote" ? "#aeb8c4" : WHITE);
      };
      this.chips[key] = ch; return ch;
    }
    kindOf(name) {
      if (name === "HEAD") return "head";
      const given = this.o.kinds && this.o.kinds[name];               // branch:name, remote:name, special:name in the notation say it outright
      if (given) return given;
      if ((this.o.tags || []).includes(name) || /^v\d+(\.\d+)+[\w.-]*$/.test(name)) return "tag";
      if ((this.o.special || []).includes(name) || SPECIAL_REF.test(name) || SPECIAL_MORE.test(DISPLAY(name))) return "special";
      return /^(origin|upstream)\//.test(name) || (this.o.remote || []).includes(name) ? "remote" : "branch";
    }
    layout(map, notes) {
      const o = this.o, res = {}, placed = [], segs = [], obst = [];
      for (const id of this.vis) {
        const c = this.c[id], p = this.xy(c.col, c.row);
        obst.push([p.x - c.r - 4, p.y - c.r - 4, p.x + c.r + 4, p.y + c.r + 4]);
        if (c.lw) obst.push([p.x - c.lw / 2 - 2, p.y + c.r + 10, p.x + c.lw / 2 + 2, p.y + c.r + c.below - 2]);
        if (c.mark) obst.push([p.x - c.mark.w / 2 - 4, p.y - c.r - 54, p.x + c.mark.w / 2 + 4, p.y - c.r - 12]);
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
        const rank = (r) => (r.length > 1 ? 0 : { branch: 1, remote: 2, tag: 3, atag: 3, special: 4, role: 4.5, note: 5, setnote: 6 }[this.chip(r[0], this.kindOf(r[0])).kind] || 1);
        rows.sort((a, b) => rank(a) - rank(b));                       // the current branch first, then other branches, remote-tracking names, tags, special refs, notes
        const dims = rows.map((r) => r.map((nm) => this.chip(nm, this.kindOf(nm))));
        const rw = dims.map((r) => r.reduce((s, ch) => s + ch.w, 0) + 6 * (r.length - 1));
        const idGap = (c.inside ? 0 : 30) + (c.sub ? (c.inside ? 30 : 24) : 0), RH = 46;
        const isNote = dims.every((r) => r[0].kind === "note" || r[0].kind === "role" || r[0].kind === "setnote");
        let order = (o.prefer[rows[0][0]] ? [o.prefer[rows[0][0]]] : []).concat(isNote ? ["below", "above", "right", "left"] : o.order);
        let best = null;
        for (const cand of order) {
          const boxes = [];
          dims.forEach((r, k) => {
            let cx, cy;
            const side = rows.length > 1 && !c.inside ? Math.max(c.r + 16, c.lw / 2 + 14) : c.r + 16;
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
        if (ch.kind === "note" || ch.kind === "atag") ch.side = q.side;
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
      const to = this.frame(e, e.free ? undefined : this.final.s * 1.25), from = this.camPlan, cam = this.cam;
      if (dur === 0) { Object.assign(cam, to); this.camBase = Object.assign({}, to); this.camPlan = to; this.applyCam(); return t; }
      if (Math.abs(to.tx - from.tx) < 2 && Math.abs(to.ty - from.ty) < 2 && Math.abs(to.s - from.s) < 0.004) return t;
      this.camPlan = to;
      return this.tl.add(t, dur || 0.8, (p) => { cam.tx = lerp(from.tx, to.tx, p); cam.ty = lerp(from.ty, to.ty, p); cam.s = lerp(from.s, to.s, p); }, "inOut");
    }
  }
  Scenes.Graph = Graph;

  // ---- shared furniture: the frame of a scene ----------------------------------------------------
  function kit(tl, cfg, follow) {
    const host = document.getElementById("scene");
    const W = 1728, H = cfg.h || 860;
    host.innerHTML = "";
    const root = svg("svg", { width: W, height: H, viewBox: `0 0 ${W} ${H}` }, host);
    A.defs(root);
    // A scene whose camera follows its growth draws its content on a "stage" that can be moved and scaled; the title, the caption
    // and the command line stay where they are (K.ui).  Without a camera everything is drawn straight on the root, as in v1.
    const stage = follow ? svg("g", {}, root) : root;
    const K = { tl, cfg, pal: cfg.palette, W, H, root, back: svg("g", {}, stage), main: svg("g", {}, stage), top: svg("g", {}, stage), cmds: [], caps: [], titles: [], spots: {},
      ext: [1e9, 1e9, -1e9, -1e9] };
    K.stage = follow ? stage : null;
    K.ui = follow ? svg("g", {}, root) : K.top;
    K.grow = (x0, y0, x1, y1) => { const e = K.ext; e[0] = Math.min(e[0], x0); e[1] = Math.min(e[1], y0); e[2] = Math.max(e[2], x1); e[3] = Math.max(e[3], y1); };
    K.spot = (name, x, y) => { K.spots[String(name).toLowerCase()] = [x, y]; };
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
      // "!git reset --hard" (cmd:!... in a graph, cmd_<step>=!... in any scene): the "!" asks for the warning triangle and is not part of the command
      if (/^!/.test(text)) { text = text.replace(/^!\s*/, ""); o = Object.assign({}, o, { danger: true }); }
      K.lastCmd = text;
      const size = 30, w = A.mono_w("$ " + text, size) + 64 + (o.danger ? 46 : 0), g = svg("g", {}, K.ui), col = o.danger ? RED : K.pal.accent;
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
      if (slot === "main") K.lastSay = o;                           // a caption given later by a "say:" tag takes the same place
      const g = svg("g", {}, K.ui);
      let size = o.size || 32;
      const room = (o.anchor || "middle") === "middle" ? 2 * Math.min(o.x == null ? W / 2 : o.x, W - (o.x == null ? W / 2 : o.x)) - 40 : W - 80;
      if (A.sans_w(text, size) > room) size = Math.max(20, Math.floor((size * room) / A.sans_w(text, size)));       // a long caption shrinks to fit
      if (o.plate) { const tw = A.sans_w(text, size) + 44; A.rect(g, -tw / 2, -size * 0.85, tw, size * 1.7, { r: 12, fill: "#0b0d12", o: 0.86 }); }
      A.text(g, 0, 0, text, { mono: false, size, weight: 600, fill: o.fill || "#d5dce4", anchor: o.anchor || "middle" });
      const n = tl.node(g, { x: o.x == null ? W / 2 : o.x, y: (o.y == null ? 96 : o.y) + 14, o: 0 });
      for (const old of K.caps) if (old.slot === slot && old.n.plan.o > 0) old.n.to(t, 0.2, { o: 0 }, "in");
      n.to(t + 0.15, 0.4, { o: 1, y: o.y == null ? 96 : o.y }, "out");
      K.caps.push({ n, slot });
      return t + 0.55;
    };
    K.title = (t, text) => {
      const ovt = PP.titles && typeof PP.titles === "object" ? PP.titles[K.step] : undefined;     // title_<step>=text|off: the title changes with that step
      if (ovt !== undefined) { if (K.said["t" + K.step]) return t; K.said["t" + K.step] = 1; text = ovt; }
      for (const old of K.titles) if (old.plan.o > 0) old.to(t, 0.25, { o: 0 }, "in");
      if (!text || text === "off") return t;
      const g = svg("g", {}, K.ui);
      A.rect(g, 0, 8, 8, 36, { r: 4, fill: K.pal.accent });
      A.text(g, 24, 27, text.toUpperCase(), { mono: false, size: 26, weight: 800, fill: K.pal.accent, anchor: "start", spacing: 3 });
      const n = tl.node(g, { o: 0, x: -20 }); n.to(t, 0.4, { o: 1, x: 0 }, "out");
      K.titles.push(n);
      return t + 0.3;
    };
    // a caption that replaces the current one while the scene is held ("[ANIMATION] say: text"; "say: off" removes it)
    K.resay = (t, text) => {
      const o = Object.assign({}, K.lastSay || { y: K.capY || 96, plate: true });
      for (const old of K.caps) if (old.slot === "main" && old.n.plan.o > 0) old.n.to(t, 0.2, { o: 0 }, "in");
      if (!text || text === "off") return t + 0.2;
      const keep = K.step; K.step = null; const end = K.say(t, text, o); K.step = keep; return end;
    };
    // "look here": a short arrow that lands on a named spot of the scene (point_<step>=name), with a ring
    K.point = (t, x, y) => {
      for (const old of K.points || []) if (old.plan.o > 0) old.to(t, 0.2, { o: 0 }, "in");
      const g = svg("g", {}, K.ui), col = K.pal.accent2;
      svg("circle", { r: 30, fill: "none", stroke: col, "stroke-width": 5, filter: "url(#glow)" }, g);
      svg("path", { d: "M92,92 L46,46 M46,46 h30 M46,46 v30", fill: "none", stroke: col, "stroke-width": 8, "stroke-linecap": "round", "stroke-linejoin": "round" }, g);
      const n = tl.node(g, { x: x + 26, y: y + 26, o: 0, s: 1 }); n.to(t, 0.35, { x, y, o: 1 }, "out"); n.pulse(t + 0.35, 0.6, "s", 0.12);
      (K.points = K.points || []).push(n); tl.sound(t + 0.1, "pop", 0.6);
      return t + 0.9;
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
  Scenes.cut = (shown, full) => { Scenes.cuts[shown] = String(full); return shown; };

  // =================================================================================================
  // (a) commit graph: grows commit by commit; labels slide when they move.
  //     params: {commits:[{id,col,row,parents}], states:[{refs:{name:id}, head, notes:[{text,at}], add:[ids], ghost:[ids], caption}]}
  Scenes.defs.graph = {
    steps: (P) => P.states.map((s, i) => s.name || (i === 0 ? "grow" : "state-" + i)),
    build(K, P) {
      // one panel (v1) or several side by side: {panels: [{name, commits, kinds}], states: [{p: [state of panel 0, state of panel 1 ...], caption, cmd, title, name}]}
      const multi = Array.isArray(P.panels), pans = multi ? P.panels : [{ commits: P.commits, kinds: P.kinds }], settle = multi || P.settle === "on";
      const top = P.title || P.states.some((s) => s.title) ? 70 : 0;   // a title (title=...) takes the top-left corner
      const hasSay = P.say && typeof P.say === "object", hasCmd = P.cmds && typeof P.cmds === "object";
      const capH = P.states.some((s) => s.caption) || hasSay || P.captions === "room" ? 70 : 0;
      const cmdH = P.states.some((s) => s.cmd) || hasCmd ? 92 : 0;
      K.capY = 34 + top;
      // the frame of every panel
      const area = [60, 20 + capH + top, K.W - 120, K.H - 40 - capH - (capH ? 30 : 0) - top - cmdH];
      const rowsLayout = P.layout === "rows", n = pans.length, gapP = 26;
      const need = pans.map((pn) => 1.25 + Math.max(0, ...pn.commits.map((c) => c.row))), needSum = need.reduce((a, b) => a + b, 0), share = (k) => (area[3] - gapP * (n - 1)) * (need[k] / needSum);
      const boxOf = (k) => !multi ? area : rowsLayout ? [area[0] - 20, area[1] + need.slice(0, k).reduce((a, _, j) => a + share(j) + gapP, 0), area[2] + 40, share(k)]
        : [area[0] - 20 + k * ((area[2] + 40 + gapP) / n), area[1], (area[2] + 40 + gapP) / n - gapP, area[3]];
      const frames = [];
      const Gs = pans.map((pn, k) => {
        const G = new Graph(K, K.main, Object.assign({ dx: +P.dx || (multi ? 170 : 190), dy: +P.dy || (multi ? 140 : 150), prefer: P.prefer || {}, tags: P.tags || [], special: P.special || [], remote: P.remote || [], kinds: pn.kinds || null },
          multi ? { order: ["above", "below", "right", "left"] } : {}));
        for (const c of pn.commits) G.commit(c.id, c.col, c.row, c.parents, { text: c.text, kind: c.kind, sub: c.sub });
        if (multi) {
          const b = boxOf(k), g = svg("g", {}, K.back), main = /^\*/.test(pn.name || "") || /^origin\b|^the server|^upstream\b/i.test(pn.name || ""), nm = (pn.name || "").replace(/^\*/, "");
          if (P.boxes === "repos") A.slab(g, b[0] + 2, b[1] + 16, b[2] - 20, b[3] - 18, { depth: main ? 18 : 12, stroke: main ? K.pal.accent : "#59636e", fill: "#0e1218" });
          else A.rect(g, b[0], b[1], b[2], b[3], { r: 18, fill: "#0d1016", stroke: "#3a424d", sw: 2.5 });
          const room = rowsLayout ? 300 : b[2] - 60, fs = A.sans_w(nm, 30) <= room ? 30 : Math.max(22, Math.floor((30 * room) / A.sans_w(nm, 30)));
          if (rowsLayout && A.sans_w(nm, fs) > room) { const words = nm.split(" "), half = Math.ceil(words.length / 2);       // a long name takes two lines beside the graph
            [words.slice(0, half).join(" "), words.slice(half).join(" ")].forEach((l, j) => A.text(g, b[0] + 26, b[1] + b[3] / 2 - 16 + j * 34, l, { mono: false, size: 26, weight: 800, fill: main ? K.pal.accent : WHITE, anchor: "start" })); }
          else A.text(g, b[0] + 26, rowsLayout ? b[1] + b[3] / 2 : b[1] + (P.boxes === "repos" ? 52 : 38), nm, { mono: false, size: fs, weight: 800, fill: main ? K.pal.accent : WHITE, anchor: "start" });
          frames.push(K.tl.node(g, { o: 0, y: 24 }));
          K.spot(nm, b[0] + b[2] / 2, b[1] + b[3] / 2);
        }
        return G;
      });
      K.G = Gs[0];
      if (!multi && P.states.some((s) => s.view && s.view.length)) {      // a history that scrolls: what leaves the frame fades at its left and right edge
        const d = K.root.querySelector("defs"), lg = svg("linearGradient", { id: "vf", x1: 0, x2: 1, y1: 0, y2: 0 }, d);
        [[0, 0], [0.05, 1], [0.95, 1], [1, 0]].forEach(([o, a]) => svg("stop", { offset: o, "stop-color": "#fff", "stop-opacity": a }, lg));
        const m = svg("mask", { id: "viewfade", maskUnits: "userSpaceOnUse", x: 0, y: 0, width: K.W, height: K.H }, d); svg("rect", { x: 0, y: 0, width: K.W, height: K.H, fill: "url(#vf)" }, m);
        K.main.setAttribute("mask", "url(#viewfade)");
      }
      const mapOf = (s) => { const m = Object.assign({}, s.refs); if (s.head) m.HEAD = s.head; return m; };
      const ghosts = Gs.map(() => new Set()), lists = Gs.map(() => ({ dim: new Set(), absent: new Set(), kept: new Set() })), marks = Gs.map(() => ({})), sets = Gs.map(() => ({}));
      const pos = (G, id) => { const c = G.c[id], q = G.xy(c.col, c.row), cm = G.box ? G.camPlan : { tx: 0, ty: 0, s: 1 }; return [q.x * cm.s + cm.tx, q.y * cm.s + cm.ty, cm.s]; };
      const one = (G, k, s, t, i) => {
        const add = s.add || [], t0 = t;
        // a commit that another panel already shows travels from there (a fetch, a push, a clone)
        let fl = 0;
        if (multi && i > 0 && P.fly !== "off") add.forEach((id) => { const src = Gs.findIndex((H, j) => j !== k && H.c[id] && H.vis.has(id) && !G.vis.has(id));
          if (src >= 0 && !G.c[id].kind) { const a = pos(Gs[src], id), b = pos(G, id); K.fly(t + 0.3 + fl * 0.25, a[0], a[1], b[0], b[1], { label: id.length > 2 ? id : null, r: 20 * a[2], dur: 0.8, lift: 70 }); fl++; } });
        if (fl) t += 0.3 + fl * 0.25 + 0.55;
        add.forEach((id, j) => { t = Math.max(t, G.show(t + (j ? 0.02 : 0), id, { glow: i > 0 })) - 0.12; });
        if (add.length) t += 0.12;
        const together = i > 0 && add.length > 0 && !fl;
        if (s.ghost) {                                                // the state lists its unreachable commits: others that were ghosts become solid again
          for (const id of s.ghost) if (!ghosts[k].has(id)) { ghosts[k].add(id); G.ghost(t, id); }
          for (const id of Array.from(ghosts[k])) if (!s.ghost.includes(id)) { ghosts[k].delete(id); G.ghost(t, id, false); }
        }
        for (const [key, fn] of [["dim", "dim"], ["absent", "absent"], ["reflog", "kept"]]) if (s[key]) {      // the same rule for "not visited", "not in this clone", "only in the reflog"
          const cur = lists[k][fn];
          for (const id of s[key]) if (!cur.has(id)) { cur.add(id); G[fn](t, id); }
          for (const id of Array.from(cur)) if (!s[key].includes(id)) { cur.delete(id); G[fn](t, id, false); }
        }
        for (const id of s.back || []) t = Math.max(t, G.back(t, id) - 0.15);
        for (const id of s.gone || []) G.gone(t, id);
        if (s.marks) {
          let j = 0;
          for (const id in marks[k]) if (!(id in s.marks)) { G.mark(t, id, null); delete marks[k][id]; }
          for (const id in s.marks) if (marks[k][id] !== s.marks[id]) { marks[k][id] = s.marks[id]; G.mark(t + 0.08 * j++, id, s.marks[id]); }
          if (j) { K.tl.sound(t + 0.05, "pop", 0.6); t += 0.2; }
        }
        for (const m of s.moves || []) G.move(t, m.id, m.col, m.row);
        for (const nk in G.notes) if (!(s.notes || []).some((x) => x.text === nk) && !(s.roles || []).some((x) => x.text + "#" + x.at === nk) && !Object.values(s.sets || {}).some((x) => x.label && x.label + "#set" === nk)) delete G.notes[nk];
        for (const x of s.notes || []) { G.notes[x.text] = { at: x.at }; G.chip(x.text, "note"); }
        for (const x of s.roles || []) { G.notes[x.text + "#" + x.at] = { at: x.at }; G.chip(x.text + "#" + x.at, "role"); }
        if (s.sets) {
          for (const key of ["range", "range2"]) { const v = s.sets[key]; G.shade(t, key, v ? v.ids : null, key === "range2");
            if (v && v.label && v.ids.length) { G.notes[v.label + "#set"] = { at: v.ids[v.ids.length - 1] }; G.chip(v.label + "#set", "setnote"); } }
          sets[k] = s.sets;
        }
        const tr = together ? Math.max(t, G.refs(t0 + 0.05, mapOf(s))) : G.refs(t, mapOf(s));
        if ("view" in s) G.viewOn(s.view);
        // settle=on (implied by everything beyond the v1 notation): a state lasts until its fades, rings and departures are over.  Without it a
        // state ends with its last label, as in v1, and the picture that is held can show a ring or a fade half-way (kept: the videos of batch one show it).
        return settle ? Math.max(tr, Math.min(K.tl.t, tr + 1.2)) : tr;
      };
      const steps = P.states.map((s, i) => (t) => {
        if (i === 0 && P.title) t = K.title(t, P.title);
        if (s.title) t = K.title(t, s.title);
        if (i === 0) frames.forEach((f, k) => { f.to(t + 0.12 * k, 0.45, { o: 1, y: 0 }, "out"); t += k === frames.length - 1 ? 0.5 : 0; });
        if (s.caption === "off" && !(hasSay && P.say[K.step])) K.resay(t, "off");      // say:off in a state: the caption leaves
        else if (s.caption || (hasSay && P.say[K.step])) t = K.say(t, s.caption || "", { y: 34 + top, size: 30, fill: K.pal.accent }) - 0.3;
        if ((s.cmd || (hasCmd && P.cmds[K.step])) && P.captions !== "off") t = K.cmd(t, s.cmd || "", { danger: /^!/.test(s.cmd || "") }) - 0.2;
        else if (cmdH && i > 0 && !s.cmd && s.cmd !== undefined) K.cmdOff(t);
        let end = t;
        Gs.forEach((G, k) => { end = Math.max(end, one(G, k, multi ? s.p[k] : s, t, i)); });
        // link:A>B:label  an arrow from a commit of one panel to a commit of another (a superproject's pointer into a submodule)
        (P.links || []).filter((l) => l[5] === i).forEach((l) => { const a = pos(Gs[l[0]], l[1]), b = pos(Gs[l[2]], l[3]), r = 30 * a[2], dx = b[0] - a[0], dy = b[1] - a[1], d = Math.hypot(dx, dy) || 1;
          const bend = Math.abs(dy) < 60 ? -210 : 0, x0 = a[0] + (bend ? r * 0.7 : (dx / d) * r), y0 = a[1] + (bend ? -r * 0.75 : (dy / d) * r), x1 = b[0] - (bend ? r * 0.8 : (dx / d) * (r + 8)), y1 = b[1] - (bend ? r * 0.9 : (dy / d) * (r + 8));
          const ar = K.arrow(K.top, x0, y0, x1, y1, { d: `M${x0},${y0} Q${(x0 + x1) / 2},${(y0 + y1) / 2 + bend} ${x1},${y1}`, stroke: K.pal.accent2, sw: 5 }); end = ar.draw(end, 0.5);
          if (l[4]) { const g = svg("g", {}, K.top), w = A.sans_w(l[4], 26) + 30, lx = (x0 + x1) / 2, ly = (y0 + y1) / 2 + bend / 2; A.rect(g, lx - w / 2, ly - 22, w, 44, { r: 22, fill: INK, stroke: K.pal.accent2, sw: 2.5 }); A.text(g, lx, ly + 1, l[4], { mono: false, size: 26, weight: 700, fill: WHITE });
            K.tl.node(g, { o: 0, s: 0.7 }).to(end - 0.2, 0.3, { o: 1, s: 1 }, "back"); } });
        return end;
      });
      // every state is laid out once before fitting so that the scale never changes mid-scene
      return { steps, refit: !(P.links && P.links.length), fit: () => Gs.forEach((G, k) => { const b = boxOf(k); if (multi && rowsLayout) G.fit(b[0] + 350, b[1] + 18, b[2] - 390, b[3] - 36, 1.6); else if (multi) G.fit(b[0] + 34, b[1] + (P.boxes === "repos" ? 84 : 66), b[2] - 68 - (P.boxes === "repos" ? 20 : 0), b[3] - (P.boxes === "repos" ? 110 : 86), 1.6); else G.fit(b[0], b[1], b[2], b[3], 2.1); }),
        focus: (t, keys) => { let end = t; keys.forEach((k, i) => { for (const G of Gs) { const id = G.c[k] ? k : G.map[k] && G.c[G.map[k]] ? G.map[k] : G.notes[k] ? G.notes[k].at : null; const ch = G.chips[k];
          if (ch && ch.n.plan.o > 0) { ch.n.pulse(t + i * 0.25, 0.8, "s", 0.2); end = t + i * 0.25 + 0.8; }
          if (id) end = Math.max(end, G.focus(t + i * 0.25, id, 1.0)); } }); if (keys.length) K.tl.sound(t + 0.05, "pop", 0.5); return end; } };
    },
  };

  // (b) fast-forward versus three-way merge.   params: {mode: "ff"|"three-way"|"versus", main, feature}
  // The commits of a merge picture.  common=A,B (history both sides share; the last one is the merge base), main_only=C, feature_only=D,E,
  // merge_id=M.  A number instead of a list ("feature_only=3") takes the next letters.  Real short IDs are drawn under the commits.
  function mergeIds(P, mode) {
    const given = [P.common, P.main_only, P.feature_only, P.after].filter(Array.isArray).flat().concat(P.merge_id || "M");
    const letters = "ABCDEFGHIJKL".split("").filter((x) => !given.includes(x));
    const take = (v, dflt) => { if (v == null) v = dflt; if (Array.isArray(v)) return v.slice(0, 5); return letters.splice(0, Math.max(0, Math.min(5, +v || 0))); };
    const common = take(P.common, 2), ours = mode === "ff" ? [] : take(P.main_only, 1), theirs = take(P.feature_only, 2);
    return { common: common.length ? common : letters.splice(0, 1), ours, theirs: theirs.length ? theirs : letters.splice(0, 1), merge: P.merge_id || "M", after: P.after ? take(P.after, 1) : [] };
  }
  function ffPart(K, G, P, o) {
    const m = P.main || "main", f = P.feature || "feature";
    const say = P.captions === "off" ? (t) => t + 0.3 : K.say;
    const I = mergeIds(P, "ff"), all = I.common.concat(I.theirs), base = I.common[I.common.length - 1], tip = all[all.length - 1];
    all.forEach((id, i) => G.commit(id, i, 0, i ? [all[i - 1]] : []));
    G.o.prefer[m] = "above"; G.o.prefer[f] = "above";
    const path = I.theirs.map((id, i) => [id, i ? I.theirs[i - 1] : base]);
    const HD = P.head === "off" ? {} : { HEAD: m };                    // head=off: no HEAD chip in the picture
    return {
      setup: (t) => { t = G.showAll(t); return G.refs(t - 0.1, Object.assign({ [m]: base, [f]: tip }, HD)); },
      check: (t) => { G.focus(t, base, 0.9); path.forEach(([c, p], i) => G.heatEdge(t + 0.3 + i * 0.2, c, p, true)); G.heat(t + 0.3, base, true);
        return say(t + 0.4, `${m} is an ancestor of ${f}: nothing to combine`, o.say) + 0.3; },
      ff: (t) => { if (o.cmd && P.captions !== "off") t = K.cmd(t, `git merge ${f}`); t = G.refs(t, Object.assign({ [m]: tip, [f]: tip }, HD), { dur: 0.9 });
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
    const mcol = nc + Math.max(I.ours.length, I.theirs.length);
    G.commit(M, mcol, 0, [C, E], P.merge_id === "none" ? { text: " " } : {});                 // the merge commit stands to the right of both parents (merge_id=none: no ID is drawn)
    I.after.forEach((id, i) => G.commit(id, mcol + 1 + i, 0, [i ? I.after[i - 1] : M]));     // after=...: commits made after the merge
    const HD = P.head === "off" ? {} : { HEAD: m };                    // head=off: no HEAD chip in the picture
    G.o.prefer[m] = "above"; G.o.prefer[f] = "below"; G.o.prefer[BL] = P.base ? "below" : "above";
    const before = I.common.concat(I.ours, I.theirs);
    const pathO = I.ours.map((id, i) => [id, i ? I.ours[i - 1] : B]).reverse(), pathT = I.theirs.map((id, i) => [id, i ? I.theirs[i - 1] : B]).reverse();
    return {
      setup: (t) => { t = G.showAll(t, before); return G.refs(t - 0.1, Object.assign({ [m]: C, [f]: E }, HD)); },
      base: (t) => { if (C !== B) G.heat(t, C, true); G.heat(t, E, true);
        pathO.forEach(([c, p], i) => G.heatEdge(t + 0.25 + i * 0.2, c, p, true)); pathT.forEach(([c, p], i) => G.heatEdge(t + 0.25 + i * 0.2, c, p, true));
        const w = 0.25 + 0.2 * Math.max(pathO.length, pathT.length);
        G.heat(t + w + 0.05, B, true); G.focus(t + w + 0.1, B, 1.0); t = P.base === "off" ? t + w + 0.6 : G.note(t + w + 0.25, BL, B);     // base=off: no words under the merge base
        return say(t - 0.3, "Both histories meet at the merge base", o.say) + 0.3; },
      merge: (t) => { if (o.cmd && P.captions !== "off") t = K.cmd(t, `git merge ${f}`); G.focus(t, B, 0.7); G.focus(t + 0.12, C, 0.7); G.focus(t + 0.24, E, 0.7);
        t = G.show(t + 0.6, M, { glow: true }); t = G.refs(t - 0.1, Object.assign({ [m]: M, [f]: E }, HD));
        for (const [c, p] of pathO.concat(pathT)) G.heatEdge(t, c, p, false); for (const c of [B, C, E]) G.heat(t, c, false);
        return say(t - 0.3, "Three-way merge: a new commit with two parents", o.say) + 0.2; },
      after: (t) => { if (!I.after.length) return t; for (const id of I.after) t = G.show(t, id, { glow: true }) - 0.1; t = G.refs(t, Object.assign({ [m]: I.after[I.after.length - 1], [f]: E }, HD));
        return say(t - 0.3, "Work goes on: the next commit has the merge as its parent", o.say) + 0.2; },
    };
  }
  // A cherry-pick or a revert drawn as what it is: a three-way merge whose result has ONE parent.  as=cherry-pick: base = the parent of the picked
  // commit, ours = HEAD, theirs = the picked commit.  as=revert (a straight history; target=ID): base = the reverted commit, ours = HEAD, theirs = its parent.
  function pickPart(K, G, P) {
    const m = P.main || "main", f = P.feature || "feature", rev = P.as === "revert", say = P.captions === "off" ? (t) => t + 0.3 : K.say;
    const I = mergeIds(rev ? Object.assign({ common: 4 }, P, { main_only: 0, feature_only: 0 }) : P, "three-way"), nc = I.common.length, M = I.merge;
    const HD = P.head === "off" ? {} : { HEAD: m };
    let base, ours, theirs, shown, col;
    I.common.forEach((id, i) => G.commit(id, i, 0, i ? [I.common[i - 1]] : []));
    if (rev) {
      const k = Math.max(1, I.common.indexOf(P.target) >= 1 ? I.common.indexOf(P.target) : nc - 2);
      base = I.common[k]; theirs = I.common[k - 1]; ours = I.common[nc - 1]; shown = I.common; col = nc;
    } else {
      const B = I.common[nc - 1];
      I.ours.forEach((id, i) => G.commit(id, nc + i, 0, [i ? I.ours[i - 1] : B]));
      I.theirs.forEach((id, i) => G.commit(id, nc + i, 1, [i ? I.theirs[i - 1] : B]));
      theirs = I.theirs[I.theirs.length - 1]; base = I.theirs.length > 1 ? I.theirs[I.theirs.length - 2] : B; ours = I.ours.length ? I.ours[I.ours.length - 1] : B;
      shown = I.common.concat(I.ours, I.theirs); col = nc + I.ours.length;
    }
    G.commit(M, col, 0, [ours], P.merge_id === "none" ? { text: " " } : {});
    G.o.prefer[m] = "above"; G.o.prefer[f] = "below";
    const names = (P.roles && P.roles.length === 3 ? P.roles : ["base", "ours", "theirs"]), keys = [base, ours, theirs].map((id, i) => names[i] + "#" + id);
    const refs = (tip) => Object.assign(rev ? { [m]: tip } : { [m]: tip, [f]: theirs }, HD);
    return {
      setup: (t) => { t = G.showAll(t, shown); return G.refs(t - 0.1, refs(ours)); },
      base: (t) => { [base, ours, theirs].forEach((id, i) => { G.heat(t + i * 0.3, id, true); G.focus(t + i * 0.3, id, 0.8); G.notes[keys[i]] = { at: id }; G.chip(keys[i], "role"); });
        t = G.refs(t + 0.9, G.map);
        return say(t - 0.3, rev ? "A revert is a three-way merge: the base is the commit being undone" : "A cherry-pick is a three-way merge: the base is the parent of the picked commit", {}) + 0.3; },
      merge: (t) => { if (P.captions !== "off") t = K.cmd(t, rev ? `git revert ${base}` : `git cherry-pick ${theirs}`); G.focus(t, base, 0.7); G.focus(t + 0.12, ours, 0.7); G.focus(t + 0.24, theirs, 0.7);
        t = G.show(t + 0.6, M, { glow: true }); t = G.refs(t - 0.1, refs(M)); for (const id of [base, ours, theirs]) G.heat(t, id, false);
        return say(t - 0.3, "The result is a new commit with ONE parent: only that change is applied", {}) + 0.2; },
      after: (t) => t,
    };
  }
  Scenes.defs.merge = {
    steps: (P) => (P.mode === "ff" ? ["setup", "check", "fast-forward"] : P.mode === "three-way" ? ["setup", "merge-base", "merge"].concat(P.after ? ["after"] : []) : ["setup", "check", "fast-forward", "merge-base", "merge"]),
    build(K, P) {
      const mode = P.mode || "versus";
      if (mode === "ff" || mode === "three-way") {
        const G = new Graph(K, K.main, { dx: 230, dy: 190, r: 28 });
        const pick = mode === "three-way" && (P.as === "cherry-pick" || P.as === "revert");
        const S = mode === "ff" ? ffPart(K, G, P, { cmd: true, say: {} }) : pick ? pickPart(K, G, P) : twPart(K, G, P, { cmd: true, say: {} });
        const title = (t) => K.title(t, P.title || (mode === "ff" ? "Fast-forward merge" : pick ? (P.as === "revert" ? "A revert is a three-way merge" : "A cherry-pick is a three-way merge") : "Three-way merge"));
        const steps = mode === "ff" ? [(t) => S.setup(title(t)), S.check, S.ff] : [(t) => S.setup(title(t)), S.base, S.merge].concat(P.after ? [S.after] : []);
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

  // Letters or real IDs for a row of commits: a list is taken as it is, a number takes the next unused letters.
  function idPool(P, keys) { const given = keys.map((k) => P[k]).filter(Array.isArray).flat(); return "ABCDEFGHIJKLMNOPQRSTUVWXYZ".split("").filter((x) => !given.includes(x)); }
  function takeIds(pool, v, dflt, max) { if (v == null) v = dflt; if (Array.isArray(v)) return v.slice(0, max || 8); return pool.splice(0, Math.max(0, Math.min(max || 8, +v || 0))); }

  // (c) rebase: commits are lifted, copied onto the new base as NEW commits, the originals fade to ghosts
  //     params: {branch, onto, upstream (the three-point form: git rebase --onto <onto> <upstream> <branch>), common, main_only, feature_only, upstream_only
  //              (each a count or a list of labels / real short IDs), new_ids: [the IDs of the copies], stop: N (the rebase stops after N copies with a
  //              conflict; steps conflict and continue are added), orig_head: "on", rebase_head: "on", title}
  Scenes.defs.rebase = {
    steps: (P) => (P && P.stop != null ? ["setup", "lift", "copy", "conflict", "continue", "ghost", "move"] : ["setup", "lift", "copy", "ghost", "move"]),
    build(K, P) {
      const b = P.branch || "feature", onto = P.onto || "main", up = P.upstream || null;
      const pool = idPool(P, ["common", "main_only", "feature_only", "upstream_only"]);
      const common = takeIds(pool, P.common, 2), mine = takeIds(pool, P.main_only, 1), ups = up ? takeIds(pool, P.upstream_only, 2) : [], feat = takeIds(pool, P.feature_only, 2);
      if (!common.length) common.push(pool.shift()); if (!feat.length) feat.push(pool.shift());
      const nc = common.length, base = common[nc - 1], R1 = up ? 2 : 1, RU = 1, wide = [...common, ...mine, ...ups, ...feat].some((x) => x.length > 2);
      const G = new Graph(K, K.main, { dx: wide ? 264 : 210, dy: up ? 176 : 210, r: 26 });
      common.forEach((id, i) => G.commit(id, i, R1, i ? [common[i - 1]] : []));
      mine.forEach((id, i) => G.commit(id, nc + i, R1, [i ? mine[i - 1] : base]));
      ups.forEach((id, i) => G.commit(id, nc + i, RU, [i ? ups[i - 1] : base]));
      const fork = ups.length ? ups[ups.length - 1] : base, f0 = nc + ups.length - (ups.length ? 0 : 0);
      feat.forEach((id, i) => G.commit(id, f0 + i, 0, [i ? feat[i - 1] : fork]));
      const ontoTip = mine.length ? mine[mine.length - 1] : base, tip = feat[feat.length - 1], c0 = nc + mine.length;
      // the copies: new commits with new IDs (new_ids=...; else the letter with a prime, or no text under a real ID's copy)
      const copies = feat.map((id, i) => { const nid = (P.new_ids || [])[i]; const key = nid || id + "2";
        G.commit(key, c0 + i, R1, [i ? ((P.new_ids || [])[i - 1] || feat[i - 1] + "2") : ontoTip], nid ? {} : { text: id.length <= 2 ? id + "′" : id + "′" }); return key; });
      const lastCopy = copies[copies.length - 1];
      G.o.prefer[onto] = "below"; G.o.prefer[b] = "above"; G.o.prefer["new IDs"] = "below"; G.o.prefer["still in the reflog"] = "above"; if (up) G.o.prefer[up] = "right";
      const at = (id) => G.xy(G.c[id].col, G.c[id].row);
      const stop = P.stop == null ? null : Math.max(0, Math.min(feat.length - 1, +P.stop || 0));
      if (stop != null) G.commit("?stop", c0 + stop, R1, [stop ? copies[stop - 1] : ontoTip], { kind: "placeholder", text: "", dashed: true });
      const refs0 = () => Object.assign({ [onto]: ontoTip, [b]: tip, HEAD: b }, up ? { [up]: fork } : {});
      const fly = (t0, src, dst) => { const a = at(src), d = at(dst); return K.fly(t0, a.x * G.scale + G.tx, (a.y - 22) * G.scale + G.ty, d.x * G.scale + G.tx, d.y * G.scale + G.ty, { dur: 0.7, r: 22 * G.scale, lift: 40 }); };
      const gapT = feat.length <= 3 ? 1.0 : 0.72;
      const copy = (t, from, to) => { let e = t; for (let i = from; i < to; i++) { const t0 = t + (i - from) * gapT; fly(t0, feat[i], copies[i]); e = G.show(t0 + 0.6, copies[i], { glow: true }); } return e; };
      const S = {
        setup: (t) => { t = K.title(t, P.title || `Rebase ${b} onto ${onto}`); t = G.showAll(t, [...common, ...mine, ...ups, ...feat]); return G.refs(t - 0.1, refs0()); },
        lift: (t) => { t = K.cmd(t, up ? `git rebase --onto ${onto} ${up} ${b}` : `git rebase ${onto}`); for (const id of feat) { G.heat(t, id, true); G.c[id].n.to(t, 0.4, { y: at(id).y - 22 }, "out"); }
          feat.forEach((id, i) => G.focus(t + 0.1 + i * 0.15, id, 0.8));
          return K.say(t + 0.2, up ? `Git lifts the commits that are on ${b} but not on ${up}` : "Git lifts the commits that are only on " + b) + 0.2; },
        copy: (t) => { const e = copy(t, 0, stop == null ? feat.length : stop);
          return stop === 0 ? K.say(t, "Git replays the commits on top of " + onto + ", one at a time") + 0.2 : K.say(e - 0.6, "Each one is replayed on top of " + onto + " as a new commit") + 0.2; },
        conflict: (t) => { fly(t, feat[stop], "?stop"); t = G.show(t + 0.6, "?stop", { quiet: true }); G.mark(t - 0.1, "?stop", "conflict"); K.tl.sound(t, "pop", 1.0);
          const m = Object.assign(refs0(), { HEAD: stop ? copies[stop - 1] : ontoTip }); if (P.rebase_head === "on") m.REBASE_HEAD = feat[stop];
          t = G.refs(t, m); return K.say(t - 0.2, `${feat[stop]} does not apply cleanly: the rebase stops and waits for you`) + 0.2; },
        continue: (t) => { t = K.cmd(t, "git rebase --continue"); G.mark(t, "?stop", null); G.gone(t, "?stop"); t = G.show(t + 0.2, copies[stop], { glow: true });
          const e = copy(t - 0.1, stop + 1, feat.length); t = G.refs(Math.max(t, e) - 0.1, Object.assign(refs0(), { HEAD: lastCopy }));
          return K.say(t - 0.3, "After you resolve it, the remaining commits are replayed") + 0.2; },
        ghost: (t) => { for (const id of feat) { G.ghost(t, id); G.heat(t, id, false); G.c[id].n.to(t, 0.4, { y: at(id).y }, "inOut"); } t = G.note(t + 0.3, "new IDs", lastCopy); return K.say(t - 0.3, "Same changes, new parents, so new commit IDs") + 0.2; },
        move: (t) => { delete G.notes["new IDs"]; const m = Object.assign(refs0(), { [b]: lastCopy, HEAD: b }); if (P.orig_head === "on") m.ORIG_HEAD = tip;
          t = G.refs(t, m, { dur: 0.9 }); t = G.note(t, "still in the reflog", tip); return K.say(t - 0.3, "The label moves; the originals are no longer on any branch") + 0.2; },
      };
      return {
        steps: Scenes.defs.rebase.steps(P).map((n) => S[n]),
        refit: false,
        fit: () => { const s = up ? G.fit(90, 132, K.W - 180, K.H - 262, 1.4) : G.fit(140, 150, K.W - 280, K.H - 330, 1.4); const m = /translate\(([-\d.]+),([-\d.]+)\)/.exec(G.g.getAttribute("transform")); G.tx = +m[1]; G.ty = +m[2]; },
      };
    },
  };

  // (g) the reflog rescue: a label yanked back, the lost commits found again
  //     params: {branch, commits: count or [ids], back: how many commits the reset drops (default 2), rows: [[id, selector, text], ...] the reflog lines,
  //              hl: the line that is found (default 1), lost: "ghost" (v1) | "reflog" (dashed but not faded: only the reflog names them),
  //              note: the words under the lost tip, rescue: "reset" (v1) | "branch" (a new branch is put on the lost tip) | "none", rescue_name, title}
  Scenes.defs.reflog = {
    steps: () => ["setup", "reset", "reflog", "rescue"],
    danger: ["reset"],
    build(K, P) {
      const b = P.branch || "main";
      const ids = takeIds(idPool(P, ["commits"]), P.commits, 4, 8), n = ids.length, back = Math.max(1, Math.min(n - 1, +P.back || 2));
      const tip = ids[n - 1], target = ids[n - 1 - back], lost = ids.slice(n - back), wide = ids.some((x) => x.length > 2);
      const G = new Graph(K, K.main, { dx: wide ? 230 : 215, dy: 150, r: 26 });
      ids.forEach((id, i) => G.commit(id, i, 0, i ? [ids[i - 1]] : []));
      const NOTE = P.note || (P.lost === "reflog" ? "only the reflog names it" : "no label points here");
      G.o.prefer[b] = "above"; G.o.prefer[NOTE] = "below";
      const dflt = [[target, "HEAD@{0}", `reset: moving to HEAD~${back}`], [tip, "HEAD@{1}", "commit: add retry"], [ids[n - 2], "HEAD@{2}", "commit: tune limits"]];
      const rows = (P.rows && P.rows.length ? P.rows : dflt).slice(0, 5), hlRow = Math.max(0, Math.min(rows.length - 1, P.hl == null ? 1 : +P.hl)), found = rows[hlRow][0];
      const panel = svg("g", {}, K.main);
      const wId = Math.max(...rows.map((r) => A.mono_w(r[0], 25))), wSel = Math.max(...rows.map((r) => A.mono_w(r[1], 25))), wMsg = Math.max(...rows.map((r) => A.mono_w(r[2], 25)));
      const xSel = Math.max(50, wId + 24), xMsg = xSel + Math.max(170, wSel + 24);
      const pw = Math.max(880, Math.min(K.W - 120, 30 + xMsg + wMsg + 40)), px = (K.W - pw) / 2, py = 470 - Math.max(0, rows.length - 3) * 26, ph = 230 + (rows.length - 3) * 52;
      const fsM = Math.min(25, Math.floor((25 * (pw - xMsg - 60)) / Math.max(1, wMsg)));
      A.rect(panel, px, py, pw, ph, { r: 16, fill: "#0b0d12", stroke: "#30363d", sw: 2 }).setAttribute("filter", "url(#sh)");
      A.text(panel, px + 30, py + 34, "$ git reflog" + (P.reflog_of ? " " + P.reflog_of : ""), { size: 25, fill: K.pal.accent, anchor: "start" });
      const lines = rows.map((r, i) => { const g = svg("g", {}, panel); const hl = A.rect(g, px + 16, py + 62 + i * 52, pw - 32, 46, { r: 8, fill: K.pal.accent, o: 0 });
        A.text(g, px + 30, py + 85 + i * 52, r[0], { size: 25, fill: WHITE, anchor: "start" }); A.text(g, px + 30 + xSel, py + 85 + i * 52, r[1], { size: 25, fill: K.pal.accent2, anchor: "start", weight: 500 });
        A.text(g, px + 30 + xMsg, py + 85 + i * 52, r[2], { size: fsM, fill: "#b6bfc9", anchor: "start", weight: 500 }); return { g, hl }; });
      const pn = K.tl.node(panel, { o: 0, y: 30 });
      const ln = lines.map((l) => K.tl.node(l.g, { o: 0 }));
      const fade = (t, id, on) => (P.lost === "reflog" ? G.kept(t, id, on) : G.ghost(t, id, on));
      const mode = P.rescue || "reset", rname = P.rescue_name || "rescue", fid = G.c[found] ? found : tip;
      return {
        steps: [
          (t) => { t = K.title(t, P.title || "The reflog rescue"); t = G.showAll(t); return G.refs(t - 0.1, { [b]: tip, HEAD: b }); },
          (t) => { t = K.cmd(t, `git reset --hard HEAD~${back}`, { danger: true }); const ch = G.chips[b], hd = G.chips.HEAD;
            K.tl.add(t, 0.3, (p) => { ch.danger = p; hd.danger = p; }, "out");
            t = G.refs(t + 0.1, { [b]: target, HEAD: b }, { dur: 0.5, ease: "back", lift: 60 }); lost.forEach((id, i) => fade(t - 0.2 + i * 0.1, id));
            K.tl.add(t + 0.3, 0.5, (p) => { ch.danger = 1 - p; hd.danger = 1 - p; }, "inOut");
            t = G.note(t + 0.2, NOTE, tip); return t + 0.2; },
          (t) => { K.cmdOff(t); pn.to(t, 0.4, { o: 1, y: 0 }, "out"); ln.forEach((nd, i) => { nd.to(t + 0.4 + i * 0.22, 0.25, { o: 1 }, "out"); K.tl.sound(t + 0.42 + i * 0.22, "tick", 0.8); });
            t += 0.54 + rows.length * 0.22; K.tl.add(t, 0.35, (p) => { lines[hlRow].hl.setAttribute("opacity", (0.28 * p).toFixed(3)); }, "out"); G.focus(t + 0.15, fid, 1.1); G.heat(t + 0.15, fid, true);
            return K.say(t, "Every move of HEAD was written down: the commit is still there") + 0.4; },
          (t) => { if (mode === "none") { G.heat(t, fid, false); return t + 0.3; }
            if (mode === "branch") { t = K.cmd(t, `git branch ${rname} ${rows[hlRow][1]}`); delete G.notes[NOTE]; lost.forEach((id, i) => fade(t + i * 0.1, id, false));
              t = G.refs(t + 0.15, { [b]: target, HEAD: b, [rname]: fid }); G.heat(t, fid, false); return K.say(t - 0.3, "A new branch names the commit again. Nothing was lost.") + 0.2; }
            t = K.cmd(t, `git reset --hard ${rows[hlRow][1]}`); delete G.notes[NOTE]; lost.forEach((id, i) => fade(t + i * 0.1, id, false));
            t = G.refs(t + 0.15, { [b]: fid, HEAD: b }, { dur: 0.9 }); G.heat(t, fid, false); return K.say(t - 0.4, "The label goes back. Nothing was lost.") + 0.2; },
        ],
        fit: () => G.fit(200, 130, K.W - 400, py - 170, 1.35),
      };
    },
  };

  // (d) the three trees: working tree, index, HEAD.  A file's content flows between them.
  //     params: {file, names: [working tree, index, HEAD], subs: [...], order: "reverse", ref: "main", commits: [id, id], versions: [v1, v2, v3], chips: [wt, index, head], title,
  //              in: ["wt", "index", "head"] (the boxes that hold the file at the start; default all three), state: [1..3 per box] (the version each box starts with),
  //              absent: the words in a box that does not hold the file, badges: [wt, index, head] (a flag on a file card, "-" for none), forms: [wt, index, head]
  //              (the form the content has in that box: CRLF / LF, smudged / clean), history: "off", commits: [one id] | ["none"] (no commit yet), merge: "on" (the commit
  //              is a merge), reset: "soft" | "mixed" | "hard", safe: [steps that are not drawn as destructive]}
  //     Steps beyond the first six play only when steps=... lists them: edit2, unstage, restore-source, commit-a, forget, reset-soft, reset-mixed, reset-hard.
  Scenes.defs.trees = {
    steps: () => ["setup", "edit", "add", "commit", "restore", "reset", "edit2", "unstage", "restore-source", "commit-a", "forget", "reset-soft", "reset-mixed", "reset-hard"],
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
      const needSlot = !!P.in || (K.names || []).some((nm) => nm === "forget" || nm === "unstage");
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
        // a box that does not hold the file: a dashed, empty slot (version 0).  It is only made when the tag can need it: an element that is
        // never shown still shifts the anti-aliasing of its neighbours by one grey level, and the pictures of v1 are kept byte for byte.
        if (needSlot) { const cg = svg("g", {}, g), lab = P.absent || "not here"; A.rect(cg, -fw / 2 + 22, -36, fw - 44, 72, { r: 12, fill: "none", stroke: "#59636e", sw: 3, dash: "9 8" });
          A.text(cg, 0, 1, lab, { mono: false, size: Math.min(28, Math.floor((fw - 80) / (lab.length * 0.5))), weight: 600, fill: DIM, italic: true }); chips[0] = tl.node(cg, { x: fx + fw / 2, y: fy + 130, o: 0, s: 1 }); }
        // badges=a,b,c: a flag on the file card (skip-worktree, assume-unchanged, intent-to-add ...); forms=a,b,c: the form the content has in this box
        const flag = (P.badges || [])[i], form = (P.forms || [])[i];
        if (flag && flag !== "-") { const w = A.mono_w(flag, 22) + 30; A.rect(g, fx + 14, fy - 19, w, 38, { r: 6, fill: INK, stroke: pal.accent, sw: 2.5 }); A.text(g, fx + 14 + w / 2, fy + 1, flag, { size: 22, fill: pal.accent }); }
        // forms_<step>=a,b,c: the forms change when that step plays.  Then every form of this box is a pill of its own and one shows at a time
        // (made only when the tag asks for it, like the empty slot above).
        const formN = {};
        if (P.forms_steps) { const all = [form].concat(Object.keys(P.forms_steps).map((k) => (P.forms_steps[k] || [])[i]));
          all.filter((x, k) => x && x !== "-" && all.indexOf(x) === k).forEach((tx) => { const fg = svg("g", {}, g), w = A.mono_w(tx, 23) + 28;
            A.rect(fg, -w / 2, -21, w, 40, { r: 20, fill: INK, stroke: NEUTRAL, sw: 2.5 }); A.text(fg, 0, 0, tx, { size: 23, fill: WHITE });
            formN[tx] = tl.node(fg, { x: fx + fw / 2, y: fy + fh, o: tx === form ? 1 : 0, s: 1 }); }); }
        else if (form && form !== "-") { const w = A.mono_w(form, 23) + 28; A.rect(g, fx + fw / 2 - w / 2, fy + fh - 21, w, 40, { r: 20, fill: INK, stroke: NEUTRAL, sw: 2.5 }); A.text(g, fx + fw / 2, fy + fh, form, { size: 23, fill: WHITE }); }
        let badge2 = null;
        if (needSlot) { badge2 = svg("g", {}, g); const bw2 = A.sans_w("untracked", 22) + 34;      // a file the index does not know
          A.rect(badge2, fx + fw - bw2 - 14, fy - 19, bw2, 38, { r: 19, fill: INK, stroke: pal.accent2, sw: 2.5 });
          A.text(badge2, fx + fw - 14 - bw2 / 2, fy + 1, "untracked", { mono: false, size: 22, weight: 700, fill: pal.accent2, italic: true }); }
        return { g, x, cx: fx + fw / 2, cy: fy + 130, chips, ver: 0, formN, form: form && form !== "-" ? form : null, badge: tl.node(badge, { o: 0 }), badge2: badge2 ? tl.node(badge2, { o: 0 }) : null, n: tl.node(g, { o: 0, y: 50 }) };
      });
      const setV = (t, tr, v, o) => { o = o || {}; if (tr.ver || tr.shown0) tr.chips[tr.ver].to(t, 0.22, { o: 0, s: 0.92 }, "in"); tr.chips[v].to(t + 0.1, 0.32, { o: 1, s: 1 }, "back"); tr.chips[v].plan.s = 1; tr.ver = v; tr.shown0 = v === 0; if (!o.quiet) tl.sound(t + 0.14, "pop", 0.8); return t + 0.42; };
      const flow = (t, a, b, v, o) => { const lab = vers[v - 1]; t = K.fly(t, a.cx, a.cy, b.cx, b.cy, Object.assign({ label: lab, fill: (o && o.danger) ? RED : VC[v], dur: 0.75, lift: 110, size: Math.min(29, Math.floor(330 / (lab.length * 0.6021))) }, o || {})); return setV(t - 0.2, b, v); };
      // the little history under the HEAD box: two commits and the name that points at the newest one
      // (commits=id: one ID; commits=none: "no commit yet"; history=off: no strip at all)
      const unborn = P.commits && P.commits[0] === "none", showHist = P.history !== "off";
      const ids = unborn ? ["", (P.commits || [])[1] || ""] : P.commits && P.commits.length >= 2 ? P.commits.slice(0, 2) : P.commits && P.commits.length === 1 ? [P.commits[0], ""] : null, ref = P.ref || null;
      const hist = svg("g", {}, K.main), GAP = ids ? 200 : 180, hx = trees[2].x + (ref ? 96 : 130), hy = SY + SH + (ids ? 52 : 62), R = ids ? 21 : 27;
      const dots = [0, 1].map((i) => { const g = svg("g", {}, hist); if (i && !unborn) svg("line", { x1: -GAP + R + 4, y1: 0, x2: -R - 4, y2: 0, stroke: NEUTRAL, "stroke-width": 5 }, g);
        if (i && P.merge === "on") { svg("line", { x1: -GAP * 0.62, y1: -44, x2: -R * 0.8, y2: -R * 0.62, stroke: NEUTRAL, "stroke-width": 5, "stroke-linecap": "round" }, g); svg("circle", { cx: -GAP * 0.62 - 12, cy: -50, r: 13, fill: INK, stroke: NEUTRAL, "stroke-width": 4 }, g); }
        const c = svg("circle", { r: R, fill: INK, stroke: NEUTRAL, "stroke-width": 5 }, g);
        if (unborn && !i) { c.setAttribute("stroke-dasharray", "6 7"); c.setAttribute("stroke", DIM); A.text(g, R + 16, 1, "no commit yet", { mono: false, size: 24, weight: 600, fill: DIM, italic: true, anchor: "start" }); }
        else if (ids) A.text(g, 0, R + 20, ids[i], { size: 20, fill: DIM, weight: 500 }); else A.text(g, 0, 1, "c" + (i + 1), { size: 24, fill: WHITE });
        return tl.node(g, { x: hx + (unborn ? 0 : i * GAP), y: hy, o: 0, s: 0.3 }); });
      const hg = svg("g", {}, hist), rw = ref ? A.mono_w(ref, 22) + 26 : 100;
      if (ref) {                                                         // the branch, filled because it is current, with HEAD's small white chip beside it
        const tw = rw + 6 + 64;
        A.rect(hg, -tw / 2, -20, rw, 40, { r: 9, fill: pal.accent }); A.text(hg, -tw / 2 + rw / 2, 1, ref, { size: 22, fill: INK });
        A.rect(hg, -tw / 2 + rw + 6, -15, 64, 30, { r: 8, fill: WHITE }); A.text(hg, -tw / 2 + rw + 38, 1, "HEAD", { size: 17, fill: INK });
      } else { A.rect(hg, -50, -20, 100, 40, { r: 9, fill: pal.accent }); A.text(hg, 0, 1, "HEAD", { size: 23, fill: INK }); }
      const hyc = hy + (ids ? R + 62 : 56);
      const hn = tl.node(hg, { x: hx, y: hyc, o: 0 });
      if (!showHist) hist.setAttribute("display", "none");
      const [WT, IX, HD] = trees;
      const mover = ref ? ref : "the current branch";
      // where the file is at the start (in=wt,index: not in HEAD yet) and which version each box holds (state=2,1,1)
      const inSet = P.in ? ["wt", "index", "head"].map((k) => P.in.includes(k) || (k === "wt" && P.in.includes("worktree"))) : [true, true, true];
      const init = [0, 1, 2].map((i) => (inSet[i] ? Math.max(1, Math.min(3, +((P.state || [])[i]) || 1)) : 0));
      const plain = !P.in && !P.state, safe = (n) => (P.safe || []).includes(n);
      const next = () => Math.min(3, Math.max(WT.ver, IX.ver, HD.ver) + 1);
      const badge = (t) => { const un = WT.ver && !IX.ver && !HD.ver; WT.badge.to(t, 0.25, { o: !un && WT.ver && WT.ver !== IX.ver ? 1 : 0 }); if (WT.badge2) WT.badge2.to(t, 0.25, { o: un ? 1 : 0 }); };
      let committed = false, prevHead = null, back = false;
      const newDot = (t) => { if (unborn) { dots[0].to(t - 0.2, 0.25, { o: 0 }, "in"); dots[1].to(t - 0.1, 0.35, { o: 1, s: 1 }, "back"); } else { dots[1].to(t - 0.2, 0.35, { o: 1, s: 1 }, "back"); hn.to(t - 0.1, 0.5, { x: hx + GAP }, "inOut"); } committed = true; };
      // reset in its three modes: soft moves HEAD only, mixed also rewrites the index, hard also overwrites the files
      const reset = (mode, name) => (t) => {
        const hard = mode === "hard", red = hard && !safe(name), to = prevHead == null ? 1 : prevHead;
        t = K.cmd(t, `git reset --${mode} HEAD~1`, { danger: red });
        if (!back) { hn.to(t, 0.5, { x: hx }, "back"); dots[1].to(t + 0.2, 0.4, { o: 0.3 }, "inOut"); t = setV(t + 0.4, HD, to); back = true; } else t += 0.3;
        if (mode !== "soft" && IX.ver !== HD.ver) t = flow(t - 0.1, HD, IX, HD.ver, red ? { danger: true } : {});
        if (hard && WT.ver !== HD.ver) t = flow(t - 0.15, IX, WT, HD.ver, red ? { danger: true } : {});
        badge(t - 0.2);
        return K.say(t - 0.3, hard ? "reset --hard: HEAD moves back, then overwrites the index and the files" : mode === "mixed" ? "reset --mixed: HEAD and the index move back; your files keep the edit" : "reset --soft: only HEAD moves; the index and your files keep the newer version") + 0.2; };
      const S = {
        setup: (t) => { t = K.title(t, P.title || "The three trees"); trees.forEach((tr, i) => { tr.n.to(t + i * 0.18, 0.5, { o: 1, y: 0 }, "out"); tl.sound(t + i * 0.18 + 0.1, "pop", 0.6); }); t += 0.8;
            trees.forEach((tr, i) => setV(t + i * 0.1, tr, init[i], { quiet: true })); dots[0].to(t + 0.2, 0.3, { o: 1, s: 1 }, "back"); hn.to(t + 0.35, 0.3, { o: 1 }, "out");
            if (!plain) badge(t + 0.4);
            return K.say(t + 0.2, P.chips || !plain ? "One file, held in three places" : "Three copies of every tracked file. Right now they agree.") + 0.2; },
        edit: (t) => { t = K.say(t, "You edit the file: only the working tree changes"); setV(t - 0.3, WT, plain ? 2 : next()); WT.badge.to(t - 0.1, 0.3, { o: 1 }); return t + 0.3; },
        add: (t) => { t = K.cmd(t, "git add " + file); t = flow(t, WT, IX, plain ? 2 : WT.ver); WT.badge.to(t - 0.3, 0.2, { o: 0 }); if (WT.badge2) WT.badge2.to(t - 0.3, 0.2, { o: 0 }); return K.say(t - 0.3, "add copies the working tree into the index") + 0.2; },
        commit: (t) => { t = K.cmd(t, "git commit"); prevHead = HD.ver; t = flow(t, IX, HD, plain ? 2 : IX.ver); newDot(t);
            return K.say(t - 0.2, P.merge === "on" ? `commit records the index as a merge commit with two parents; ${mover} moves to it` : `commit turns the index into a new snapshot; ${mover} moves to it`) + 0.2; },
        restore: (t) => { const iv = IX.ver || 1, red = !safe("restore");     // the edit that is about to be lost: a new one, unless one is already waiting unstaged
            if (red && WT.ver === iv) { t = setV(t, WT, Math.min(3, iv + 1)); WT.badge.to(t - 0.3, 0.25, { o: 1 }); t += 0.2; }
            const lost = vers[Math.max(1, WT.ver) - 1], was = WT.ver;
            t = K.cmd(t, "git restore " + file, { danger: red }); t = flow(t, IX, WT, iv, red ? {} : { fill: VC[iv] }); WT.badge.to(t - 0.3, 0.2, { o: 0 });
            return K.say(t - 0.3, red ? `restore copies the index back over your edit. ${lost.charAt(0).toUpperCase() + lost.slice(1)} is gone.` : was ? "restore copies the index into the working tree: here nothing is lost" : "restore writes the file again from the index: nothing is lost") + 0.2; },
        reset: plain && !P.reset ? (t) => { t = K.cmd(t, "git reset --hard HEAD~1", { danger: true }); hn.to(t, 0.5, { x: hx }, "back"); dots[1].to(t + 0.2, 0.4, { o: 0.3 }, "inOut");
            t = setV(t + 0.4, HD, 1); t = flow(t - 0.1, HD, IX, 1, { danger: true }); t = flow(t - 0.15, IX, WT, 1, { danger: true });
            return K.say(t - 0.3, "reset --hard: HEAD moves back, then overwrites the index and the files") + 0.2; } : reset(P.reset || "hard", "reset"),
        edit2: (t) => { t = K.say(t, "A second edit after add: the index still holds the version you staged"); setV(t - 0.3, WT, next()); WT.badge.to(t - 0.1, 0.3, { o: 1 }); return t + 0.3; },
        unstage: (t) => { t = K.cmd(t, "git restore --staged " + file); t = HD.ver || !needSlot ? flow(t, HD, IX, HD.ver || 1) : setV(t, IX, 0); badge(t - 0.2);
            return K.say(t - 0.3, "restore --staged copies HEAD into the index: your file keeps the edit") + 0.2; },
        "restore-source": (t) => { const red = !safe("restore-source"); t = K.cmd(t, "git restore --source=HEAD " + file, { danger: red }); t = flow(t, HD, WT, HD.ver || 1, red ? { danger: true } : {}); badge(t - 0.2);
            return K.say(t - 0.3, "restore --source copies a commit's version over the file; the index is not touched") + 0.2; },
        "commit-a": (t) => { t = K.cmd(t, "git commit -a"); prevHead = HD.ver; t = flow(t, WT, IX, WT.ver); WT.badge.to(t - 0.3, 0.2, { o: 0 }); t = flow(t - 0.15, IX, HD, IX.ver); newDot(t);
            return K.say(t - 0.2, "commit -a stages every tracked file that changed, then commits") + 0.2; },
        forget: (t) => { t = K.cmd(t, "git rm --cached " + file); t = setV(t, IX, 0); WT.badge.to(t - 0.2, 0.2, { o: 0 }); return K.say(t - 0.2, "The index entry is gone. The file on disk and the committed version stay.") + 0.2; },
        "reset-soft": reset("soft", "reset-soft"), "reset-mixed": reset("mixed", "reset-mixed"), "reset-hard": reset("hard", "reset-hard"),
      };
      // forms_<step>: after that step's own motion the pills change ("-": no form in that box)
      const setForm = (t, tr, tx) => { tx = tx && tx !== "-" ? tx : null; if (tr.form === tx) return t;
        if (tr.form && tr.formN[tr.form]) tr.formN[tr.form].to(t, 0.2, { o: 0, s: 0.8 }, "in");
        if (tx && tr.formN[tx]) { tr.formN[tx].to(t + 0.12, 0.3, { o: 1, s: 1 }, "back"); tl.sound(t + 0.15, "pop", 0.6); }
        tr.form = tx; return t + 0.45; };
      for (const nm of Object.keys(P.forms_steps || {})) if (S[nm]) { const f0 = S[nm], list = P.forms_steps[nm];
        S[nm] = (t) => { const e = f0(t); let e2 = e; trees.forEach((tr, i) => { e2 = Math.max(e2, setForm(e - 0.4, tr, list[i])); }); return e2; }; }
      return { steps: Scenes.defs.trees.steps().map((n) => S[n]), fit: () => {} };
    },
  };

  // (e) the object model: commit -> tree -> blobs, and two snapshots that share blobs
  //     params: {commits: [id, id], trees: [id, id], files: [{name, id, new}], messages: [m1, m2]}   (one file has "new": its second blob)
  //     With cards=... the scene draws any objects instead (a tag object, nested trees, a gitlink entry, a missing blob):
  //     {cards: [{kind, id, rows: [text]}], levels: [[card index, ...] per column], links: [[from card, row, to card]], refs: [[name, card index]],
  //      missing: [ids], damaged: [ids]}  (the planner works out levels and links: a row that contains another card's ID points at it); steps level-1, level-2 ...
  function objectCards(K, P) {
    const tl = K.tl, pal = K.pal, cards = P.cards, levels = P.levels, ncol = levels.length;
    const COL = { commit: NEUTRAL, tree: pal.accent, blob: pal.accent2, tag: WHITE };
    const refsOf = (i) => (P.refs || []).filter((r) => r[1] === i);
    const hasRefs = (P.refs || []).length > 0, left = 40, gapX = 90;
    const cw = Math.min(520, (K.W - left - 50 - gapX * (ncol - 1)) / ncol), totalW = ncol * cw + (ncol - 1) * gapX, x0 = left + (K.W - left - 40 - totalW) / 2;
    const top = hasRefs ? 196 : 150, bottom = K.H - 40, box = {};
    levels.forEach((lv, c) => {
      // a card with names above it needs room for them; a card with a stamp ("not in this repository") needs room under it
      const hs = lv.map((i) => 66 + Math.max(1, cards[i].rows.length) * 38 + 16), up = lv.map((i) => (refsOf(i).length ? 70 : 0)), dn = lv.map((i) => ((P.missing || []).includes(cards[i].id) || (P.damaged || []).includes(cards[i].id) ? 22 : 0) + ((P.signed || []).some((x) => x[0] === cards[i].id) ? 50 : 0));
      const need = hs.reduce((a, b) => a + b, 0) + up.reduce((a, b) => a + b, 0) + dn.reduce((a, b) => a + b, 0), free = bottom - (hasRefs ? 126 : 150) - need;
      const gapY = Math.min(70, Math.max(18, free / Math.max(1, lv.length)));
      let y = (hasRefs ? 126 : 150) + Math.max(0, (free - gapY * (lv.length - 1)) / 2);
      lv.forEach((i, k) => { y += up[k]; box[i] = { x: x0 + c * (cw + gapX), y, w: cw, h: hs[k] }; y += hs[k] + dn[k] + gapY; });
    });
    const made = cards.map((cd, i) => {
      const b = box[i], g = svg("g", {}, K.main), col = COL[cd.kind] || NEUTRAL, gone = (P.missing || []).includes(cd.id), bad = (P.damaged || []).includes(cd.id);
      if (gone) A.rect(g, b.x, b.y, b.w, b.h, { r: 6, fill: "none", stroke: "#59636e", sw: 3, dash: "10 8" });
      else A.slab(g, b.x, b.y, b.w, b.h, { depth: 12, stroke: bad ? RED : col, fill: "#11151c" });
      A.text(g, b.x + 20, b.y + 36, cd.kind.toUpperCase(), { mono: false, size: 26, weight: 800, fill: gone ? DIM : bad ? RED : col, anchor: "start", spacing: 2 });
      A.text(g, b.x + b.w - 18, b.y + 36, cd.id, { size: 25, fill: DIM, anchor: "end", weight: 500 });
      const longest = Math.max(1, ...cd.rows.map((r) => r.length)), fs = Math.max(20, Math.min(26, Math.floor((b.w - 40) / (longest * 0.6021))));      // a long row (a gitlink entry, a signature line) shrinks to 20 units before it is cut
      const maxc = Math.floor((b.w - 40) / (fs * 0.6021));
      const hl = cd.rows.map((r, k) => { const h = A.rect(g, b.x + 10, b.y + 64 + k * 38, b.w - 20, 36, { r: 7, fill: pal.accent2, o: 0 });
        A.text(g, b.x + 20, b.y + 83 + k * 38, r.length > maxc ? Scenes.cut(r.slice(0, maxc - 1) + "…", r) : r, { size: fs, fill: gone ? DIM : "#d5dce4", anchor: "start", weight: 500 }); return h; });
      // signed=ID:1-3 (signed_text=...): a bar beside those rows and a word: what a signature covers
      const sg = (P.signed || []).find((x) => x[0] === cd.id);
      if (sg) { const a = Math.max(1, sg[1]), z = Math.min(cd.rows.length, sg[2]), word = P.signed_text || "signed";
        A.rect(g, b.x + 4, b.y + 64 + (a - 1) * 38, 7, (z - a + 1) * 38 - 2, { r: 3, fill: GREEN });
        A.rect(g, b.x + 6, b.y + b.h + 20, 7, 30, { r: 3, fill: GREEN }); A.text(g, b.x + 26, b.y + b.h + 36, word, { mono: false, size: 25, weight: 700, fill: GREEN, anchor: "start" }); }      // the legend stands under the card
      if (gone || bad) { const word = gone ? "not in this repository" : "damaged", w = A.sans_w(word, 24) + 34, cy = b.y + b.h - 6; A.rect(g, b.x + b.w / 2 - w / 2, cy - 20, w, 40, { r: 20, fill: INK, stroke: gone ? AMBER : RED, sw: 3 });
        A.text(g, b.x + b.w / 2, cy + 1, word, { mono: false, size: 24, weight: 800, fill: gone ? AMBER : RED }); }
      K.spot(cd.id, b.x + b.w / 2, b.y + b.h / 2);
      return { n: tl.node(g, { o: 0, y: 26 }), b, hl };
    });
    const arrows = (P.links || []).map(([a, r, to]) => { const A0 = box[a], B0 = box[to], same = Math.abs(A0.x - B0.x) < 1;
      const y0 = A0.y + 82 + r * 38, y1 = B0.y + 36;
      return { a, to, r, ar: same ? K.arrow(K.back, A0.x + A0.w + 14, y0, B0.x + B0.w + 14, y1, { d: `M${A0.x + A0.w + 14},${y0} h30 V${y1} h-22`, stroke: DIM }) : K.arrow(K.back, A0.x + A0.w + 14, y0, B0.x - 8, y1) }; });
    // names that point at an object: a branch or a tag, to the left of the card
    const chips = (P.refs || []).map(([name, i]) => { const b = box[i], g = svg("g", {}, K.main), isTag = /^v\d/.test(name) || /^tag:/.test(name), nm = name.replace(/^tag:/, "");
      const mine = refsOf(i), k = mine.findIndex((r) => r[0] === name), w = A.mono_w(nm, 24) + 34 + (isTag ? 14 : 0);
      const cx = b.x + 16 + mine.slice(0, k).reduce((a, r) => a + A.mono_w(r[0].replace(/^tag:/, ""), 24) + 34 + 26, 0) + w / 2, cy = b.y - 52;
      if (isTag) { svg("path", { d: `M${cx - w / 2},${cy} l20,-21 H${cx + w / 2 - 7} a7,7 0 0 1 7,7 v28 a7,7 0 0 1 -7,7 H${cx - w / 2 + 20} Z`, fill: "#232b38", stroke: WHITE, "stroke-width": 3, "stroke-linejoin": "round" }, g); A.text(g, cx + 8, cy + 1, nm, { size: 24, fill: WHITE }); }
      else { A.rect(g, cx - w / 2, cy - 21, w, 42, { r: 9, fill: INK, stroke: NEUTRAL, sw: 3 }); A.text(g, cx, cy + 1, nm, { size: 24, fill: WHITE }); }
      const ar = K.arrow(K.back, cx, cy + 24, cx, b.y - 8, { straight: true, stroke: WHITE });
      return { i, n: tl.node(g, { o: 0, y: -16 }), ar, box: [cx - w / 2 - 4, cy - 26, cx + w / 2 + 4, cy + 24] }; });
    const shown = new Set();
    const steps = levels.map((lv, c) => (t) => {
      if (c === 0) t = K.title(t, P.title || "Objects point at objects");
      arrows.filter((x) => lv.includes(x.to) && shown.has(x.a)).forEach((x, k) => { x.ar.draw(t + k * 0.12, 0.4); tl.add(t + k * 0.12, 0.9, (p) => made[x.a].hl[x.r].setAttribute("opacity", (0.3 * p).toFixed(3)), "there"); });
      t += arrows.some((x) => lv.includes(x.to) && shown.has(x.a)) ? 0.3 : 0;
      lv.forEach((i, k) => { const m = made[i]; m.n.to(t + k * 0.18, 0.42, { o: 1, y: 0 }, "out"); tl.sound(t + k * 0.18 + 0.1, "pop", 0.75); shown.add(i); K.grow(m.b.x - 6, m.b.y - 20, m.b.x + m.b.w + 20, m.b.y + m.b.h + 26); });
      t += 0.42 + 0.18 * (lv.length - 1);
      arrows.filter((x) => lv.includes(x.to) && lv.includes(x.a)).forEach((x) => x.ar.draw(t, 0.4));
      chips.filter((ch) => lv.includes(ch.i)).forEach((ch, k) => { ch.n.to(t + 0.1 + k * 0.15, 0.35, { o: 1, y: 0 }, "out"); ch.ar.draw(t + 0.3 + k * 0.15, 0.3); K.grow(ch.box[0], ch.box[1], ch.box[2], ch.box[3]); t += 0.3; });
      return t + 0.3;
    });
    return { steps, fit: () => {}, stage: [30, 130, K.W - 60, K.H - 160] };
  }
  Scenes.defs.objects = {
    steps: (P) => (P && P.cards ? P.levels.map((_, i) => "level-" + (i + 1)) : ["commit", "tree", "blobs", "second-commit", "shared", "compare"]),
    follow: (P) => !!(P && P.cards),
    build(K, P) {
      if (P.cards) return objectCards(K, P);
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
        return { g, n, x, y, w, h, rows, show: (t) => { n.to(t, 0.42, { o: 1, y: 0 }, "out"); tl.sound(t + 0.1, "pop", 0.75); K.grow(x - 6, y - 20, x + w + 20, y + h + 20); return t + 0.42; } };
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
  //     params: {teammate: "Asha" | "none" (only "you" and "origin" are drawn), branch, ids: [commits], note (under "origin"), title,
  //              start: how many commits every repository has at the beginning (default 2), incoming: how many the teammate pushes (default 1; 0 = none,
  //              so that "commit" and "push" can follow "setup" without a gap), names: [your clone, origin, the teammate's clone]}
  //     Any other story (a rejected push, a forced update, pull --rebase, tags, a fork, a third repository) is written in the graph notation with
  //     panels: "remotes: [your clone] A-B main || [origin] A-B-C main => ..." (the planner turns that into the graph scene with repository boxes).
  Scenes.defs.remotes = {
    steps: () => ["setup", "teammate-push", "fetch", "pull", "commit", "push"],
    build(K, P) {
      const tl = K.tl, pal = K.pal, solo = P.teammate === "none", mate = P.teammate || "teammate", br = P.branch || "main", rb = "origin/" + br;
      const nStart = Math.max(1, Math.min(4, P.start == null ? 2 : +P.start || 1)), nIn = Math.max(0, Math.min(3, P.incoming == null ? 1 : +P.incoming || 0)), N = nStart + nIn + 1;
      const ids = (P.ids || []).concat("ABCDEFGH".split("").slice((P.ids || []).length)).slice(0, N);
      const first = ids.slice(0, nStart), inc = ids.slice(nStart, nStart + nIn), own = ids[N - 1], c1 = first[nStart - 1], c2 = nIn ? inc[nIn - 1] : c1, c3 = own;
      const long = ids.some((x) => x.length > 2), nm = P.names || [];
      const boxes = solo ? [[nm[0] || "your clone", 70, 290, 760], [nm[1] || "origin", 898, 290, 760]] : [[nm[0] || "your clone", 40, 400, 780], [nm[1] || "origin", 474, 90, 780], [nm[2] || mate + "'s clone", 908, 400, 780]];
      const PH = 300;
      const reps = boxes.map(([name, x, y, w], i) => {
        const g = svg("g", {}, K.main);
        A.slab(g, x, y, w, PH, { depth: i === 1 ? 22 : 14, stroke: i === 1 ? pal.accent : "#59636e", fill: "#0e1218" });
        A.text(g, x + 24, y + 34, name, { mono: false, size: 28, weight: 800, fill: i === 1 ? pal.accent : WHITE, anchor: "start" });
        if (i === 1) A.text(g, x + w - 24, y + 34, P.note || "the shared server", { mono: false, size: 22, weight: 500, fill: DIM, anchor: "end" });
        const dx0 = long ? 170 : 150, G = new Graph(K, g, { dx: N > 4 ? Math.min(dx0, (w - 230) / (N - 1)) : dx0, dy: 100, r: 21, ox: x + (long ? 100 : 110), oy: y + (long ? 170 : 190), order: ["above", "below"] });
        ids.forEach((id, k) => G.commit(id, k, 0, k ? [ids[k - 1]] : []));
        G.o.prefer[rb] = "below";
        K.spot(name, x + w / 2, y + PH / 2);
        return { g, G, x, y, w, n: tl.node(g, { o: 0, y: 40 }), at: (id) => { const q = G.xy(G.c[id].col, 0); return [q.x, q.y]; } };
      });
      const [me, origin, tm] = reps;
      const send = (t, a, b, id) => { const q0 = a.at(id), q = b.at(id); return K.fly(t, q0[0], q0[1], q[0], q[1], { label: id, dur: 0.85, lift: 90 }); };
      const cap = solo ? { y: 150, size: 30 } : { y: 30, x: 1180, size: 27 };
      const who = P.teammate && !solo ? mate : "A teammate", what = nIn > 1 ? `${nIn} commits` : `commit ${c2}`, them = nIn > 1 ? "them" : "it";
      return {
        steps: [
          (t) => { t = K.title(t, P.title || "Remotes"); reps.forEach((r, i) => r.n.to(t + [0.15, 0, 0.3][i], 0.5, { o: 1, y: 0 }, "out")); t += 0.7;
            reps.forEach((r) => first.forEach((id, k) => r.G.show(t + 0.15 * k, id, { quiet: true }))); t += 0.35 + 0.15 * (nStart - 1);
            me.G.refs(t, { [br]: c1, HEAD: br, [rb]: c1 }); const e = origin.G.refs(t, { [br]: c1 }); return (tm ? tm.G.refs(t, { [br]: c1, HEAD: br }) : e) + 0.1; },
          (t) => { if (!nIn) return t;
            if (tm) { for (const id of inc) t = tm.G.show(t, id, { glow: true }) - (nIn > 1 ? 0.1 : 0); t = tm.G.refs(t - 0.1, { [br]: c2, HEAD: br }); inc.forEach((id, k) => { const e = send(t + 0.3 * k, tm, origin, id); if (k === nIn - 1) t = e; }); }
            else inc.forEach((id, k) => { const q = origin.at(id), e = K.fly(t + 0.3 * k, K.W + 60, origin.y - 70, q[0], q[1], { label: id, dur: 0.95, lift: 40 }); if (k === nIn - 1) t = e; });      // the teammate is outside the picture: the commit arrives from off-screen
            inc.forEach((id, k) => { const e = origin.G.show(t - 0.25 + 0.12 * k, id, tm ? {} : { glow: true }); if (k === nIn - 1) t = e; }); t = origin.G.refs(t - 0.1, { [br]: c2 });
            return K.say(t - 0.4, `${who} pushes ${what}. Your clone has not heard about ${them}.`, cap) + 0.2; },
          (t) => { t = K.cmd(t, "git fetch"); inc.forEach((id, k) => { const e = send(t + 0.3 * k, origin, me, id); if (k === nIn - 1) t = e; }); inc.forEach((id, k) => { const e = me.G.show(t - 0.25 + 0.12 * k, id); if (k === nIn - 1) t = e; });
            t = me.G.refs(t - 0.1, { [br]: c1, HEAD: br, [rb]: c2 });
            return K.say(t - 0.4, nIn > 1 ? `fetch downloads ${nIn} commits and moves only ${rb}` : `fetch downloads ${c2} and moves only ${rb}`, cap) + 0.2; },
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
  //     params: {feature, main, title, number ("off": no number), review: approved|missing|changes|unknown|off, checks: passed|failing|pending|unknown,
  //              check_names: [a, b, ...] (one to four rows), check_states: [a state per row; also "skipped"], review_text (the words of the review row),
  //              approvals: "2/3", layers: "on" (says which layer owns each part: Git, GitHub, GitHub Actions), base_ids: [2 commits on main],
  //              commits: count or [ids] (the commits of the branch), merge_id, late_id (the commit of step push-again), letters: "off",
  //              method: merge|squash|rebase (what lands on the base branch)}
  //     When the review or a check is not green, the merge step shows a blocked merge: no merge commit, a BLOCKED stamp.
  //     Steps that play only when steps=... lists them: push-again (a commit pushed after the review), dismissed (the approval is withdrawn), re-approve.
  Scenes.defs.pr = {
    steps: () => ["branch", "push", "review", "checks", "merge", "push-again", "dismissed", "re-approve"],
    build(K, P) {
      const tl = K.tl, pal = K.pal, f = P.feature || "feature", m = P.main || "main";
      const cn_ = (P.check_names || ["tests", "lint"]).slice(0, 4), noRv = P.review === "off";
      const rvS = P.review || "approved", ckS = P.checks || "passed";
      const ap = /^(\d+)\/(\d+)$/.exec(P.approvals || ""), apOk = ap ? +ap[1] >= +ap[2] : true;
      const ckStates = cn_.map((_, i) => (P.check_states && P.check_states[i]) || (i === 1 && !P.check_states && ckS === "failing" ? "passed" : ckS));
      const blocked = (!noRv && (rvS !== "approved" || !apOk)) || ckStates.some((x) => x !== "passed") || !!P.block;      // block=words: a rule that refuses the merge although review and checks are green
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
      // the commits: two on the base branch, the branch's own, a late one (step push-again), and what the merge method puts on the base branch
      const pool = idPool(P, ["base_ids", "commits"]).filter((x) => x !== (P.merge_id || "M") && x !== P.late_id);
      const baseIds = takeIds(pool, P.base_ids, 2, 2), feat = takeIds(pool, P.commits, 2, 4), late = (K.names || []).includes("push-again") ? P.late_id || pool.shift() : null;
      if (baseIds.length < 2) baseIds.push(...pool.splice(0, 2 - baseIds.length)); if (!feat.length) feat.push(pool.shift());
      const [A0, B0] = baseIds, M = P.merge_id || "M", method = P.method || "merge", all = late ? feat.concat(late) : feat, nf = all.length;
      const ncol = 2 + nf + (method === "rebase" ? Math.max(0, nf - 2 + 1) : 1) + (baseIds.concat(feat).some((x) => x.length > 2) ? 1 : 0), wide = baseIds.concat(all).some((x) => x.length > 2), hide = P.letters === "off" ? { text: " " } : {};
      const gg = svg("g", {}, K.main);
      const G = new Graph(K, gg, { dx: ncol <= 5 ? 170 : Math.max(wide ? 112 : 96, 700 / (ncol - 1)), dy: 170, r: 24, ox: 130, oy: 420 + DY });
      const SH = wide ? 1 : 0;                                          // real IDs: the branch starts one column later, so that its first edge clears the ID under the base commit
      G.commit(A0, 0, 0, [], hide); G.commit(B0, 1, 0, [A0], hide); all.forEach((id, i) => G.commit(id, 2 + SH + i, 1, [i ? all[i - 1] : B0], hide));
      let landed;
      if (method === "rebase") landed = all.map((id, i) => { const k = id + "2"; G.commit(k, 2 + i, 0, [i ? all[i - 1] + "2" : B0], P.letters === "off" ? hide : { text: id.length <= 2 ? id + "′" : " " }); return k; });
      else { G.commit(M, 2 + SH + nf, 0, method === "squash" ? [B0] : [B0, all[nf - 1]], hide); landed = [M]; }
      G.o.prefer[m] = "above"; G.o.prefer[f] = "below"; G.o.prefer["origin/" + f] = "below";
      // the pull request card
      const nrows = (noRv ? 0 : 1) + cn_.length + (P.block ? 1 : 0), px = 980, py = 300 + DY - Math.max(0, nrows - 3) * 30, pw = 660, ph = Math.max(400, 140 + nrows * 70), card = svg("g", {}, K.main);
      A.slab(card, px, py, pw, ph, { depth: 16, stroke: pal.accent, fill: "#0e1218" });
      const head = "Pull request" + (P.number === "off" ? "" : " #" + (P.number || "42"));
      A.text(card, px + 26, py + 40, head, { mono: false, size: 30, weight: 800, fill: WHITE, anchor: "start" });
      A.text(card, px + 26, py + 84, `${f}  ->  ${m}`, { size: Math.min(24, Math.floor((pw - 60) / ((f.length + m.length + 6) * 0.6021))), fill: pal.accent2, anchor: "start", weight: 500 });
      const cn = tl.node(card, { o: 0, y: 40 });
      K.spot("card", px + pw / 2, py + ph / 2);
      // a small pill that says which layer owns a thing (layers=on)
      const layer = (parent, xr, y, text) => { const g = svg("g", {}, parent), w = A.sans_w(text, 20) + 26; A.rect(g, xr - w, y - 17, w, 34, { r: 17, fill: INK, stroke: DIM, sw: 2 }); A.text(g, xr - w / 2, y + 1, text, { mono: false, size: 20, weight: 700, fill: "#aeb8c4" }); if (P.layers !== "on") g.setAttribute("display", "none"); return g; };
      const row = (y, label, lay, alt) => { const g = svg("g", {}, card); A.rect(g, px + 22, py + y, pw - 44, 58, { r: 10, fill: "#0b0d12", stroke: "#30363d", sw: 2 }); const ring = svg("circle", { cx: px + 56, cy: py + y + 29, r: 14, fill: "none", stroke: "#59636e", "stroke-width": 4 }, g);
        const room = pw - 44 - 88 - (P.layers === "on" ? A.sans_w(lay, 20) + 50 : 20), fs = (str) => (A.sans_w(str, 25) <= room ? 25 : Math.floor((25 * room) / A.sans_w(str, 25)));
        const txt = A.text(g, px + 88, py + y + 30, label, { mono: false, size: fs(label), weight: 600, fill: "#d5dce4", anchor: "start" }); layer(g, px + pw - 36, py + y + 29, lay);
        const txt2 = alt ? A.text(g, px + 88, py + y + 30, alt, { mono: false, size: fs(alt), weight: 600, fill: AMBER, anchor: "start" }) : null; if (txt2) txt2.setAttribute("opacity", 0);
        const tk = K.tick(g, px + 56, py + y + 29, 0.9), cr = K.cross(g, px + 56, py + y + 29, 0.8), qm = A.text(g, px + 56, py + y + 30, "?", { size: 22, fill: AMBER }); qm.setAttribute("opacity", 0);
        return { n: tl.node(g, { o: 0, x: 24 }), ring, tk, cr, qm, txt, txt2 }; };
      const RV = { approved: "Review: approved by a teammate", missing: "Review: required, not given yet", changes: "Review: changes requested", unknown: "Review: approved?" };
      const rvText = P.review_text || (ap ? `Review: ${ap[1]} of ${ap[2]} approvals` : RV[rvS] || RV.approved);
      const y0 = noRv ? 120 : 190, rv = noRv ? null : row(120, rvText, "GitHub", "Review: approval dismissed"), cks = cn_.map((nm, i) => row(y0 + i * 70, "Check: " + nm, "GitHub Actions"));
      const blk = P.block ? row(y0 + cn_.length * 70, P.block, "GitHub") : null;
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
      const ptw = A.sans_w(head, 30);
      layer(card, px + 26 + ptw + 22 + A.sans_w("GitHub", 20) + 26, py + 40, "GitHub");
      const cross5 = K.cross(stages[4].n.el, 0, 0, 1.1, RED);
      const tipF = feat[feat.length - 1];
      let cur = tipF;                                                      // the tip of the branch: moves with push-again
      const dismiss = (t, on) => { if (!rv) return t; tl.add(t, 0.3, (p) => { const q = on ? p : 1 - p; rv.txt.setAttribute("opacity", (1 - q).toFixed(3)); rv.txt2.setAttribute("opacity", q.toFixed(3)); rv.tk.setAttribute("opacity", (1 - q).toFixed(3));
          rv.ring.setAttribute("stroke", q > 0.5 ? AMBER : GREEN); rv.ring.setAttribute("stroke-dasharray", q > 0.5 ? "7 6" : "none"); }, "inOut"); tl.sound(t + 0.1, "pop", 0.7); rv.n.pulse(t, 0.4, "x", 8); return t + 0.4; };
      return {
        steps: [
          (t) => { t = K.title(t, P.title); stages.forEach((s, i) => s.n.to(t + i * 0.07, 0.3, { o: 1, s: 1 }, "back")); K.fadeIn(t, rail, { dy: 0 }); t += 0.5; G.show(t, A0, { quiet: true }); G.show(t + 0.15, B0, { quiet: true }); t = G.refs(t + 0.5, { [m]: B0, HEAD: m });
            gln.to(t, 0.3, { o: 1 }, "out");
            t = stage(t, 0); t = K.cmd(t, "git switch -c " + f); t = G.refs(t, { [m]: B0, [f]: B0, HEAD: f }); feat.forEach((id, i) => { t = G.show(t - (i ? 0.1 : 0), id, { glow: true }); }); return G.refs(t - 0.15, { [m]: B0, [f]: tipF, HEAD: f }) + 0.2; },
          (t) => { t = stage(t, 1); t = K.cmd(t, "git push -u origin " + f); t = G.refs(t, { [m]: B0, [f]: tipF, HEAD: f, ["origin/" + f]: tipF }); cn.to(t - 0.1, 0.5, { o: 1, y: 0 }, "out"); tl.sound(t, "pop", 0.8); return t + 0.6; },
          (t) => { t = stage(t, 2); K.cmdOff(t); if (!rv) return t; rv.n.to(t, 0.35, { o: 1, x: 0 }, "out"); return done(t + 0.6, rv, ap ? (apOk ? "approved" : "missing") : rvS) + 0.3; },
          (t) => { t = stage(t, 3); cks.forEach((c, i) => c.n.to(t + 0.15 * i, 0.35, { o: 1, x: 0 }, "out")); t += 0.7; cks.forEach((c, i) => { t = done(t + (i ? 0.25 : 0), c, ckStates[i]); }); return t + 0.3; },
          (t) => { if (blocked) {                                           // the button stays grey: no merge commit, main stays where it was
              t = stage(t, 4, true); tl.add(t - 0.2, 0.25, (p) => { cross5.setAttribute("stroke-dashoffset", (1 - p).toFixed(3)); stages[4].num.setAttribute("opacity", (1 - p).toFixed(3)); }, "out");
              if (blk) { blk.n.to(t, 0.35, { o: 1, x: 0 }, "out"); t = done(t + 0.5, blk, "failing") + 0.2; }
              sn.to(t - 0.1, 0.3, { o: 1 }, "out"); sn.pulse(t - 0.1, 0.4, "x", 9); return t + 0.5; }
            t = stage(t, 4); landed.forEach((id, i) => { t = G.show(t - (i ? 0.1 : 0), id, { glow: true }); }); t = G.refs(t - 0.1, { [m]: landed[landed.length - 1], [f]: cur, HEAD: f, ["origin/" + f]: cur }); sn.to(t - 0.2, 0.3, { o: 1 }, "out"); sn.pulse(t - 0.2, 0.4, "y", -10);
            if (method === "squash") t = K.say(t - 0.2, "Squash: one new commit on " + m + ". Its only parent is on " + m + ".", { y: 800, size: 28 });
            if (method === "rebase") t = K.say(t - 0.2, "Rebase: copies of the commits on " + m + ", with new IDs and no merge commit", { y: 800, size: 28 });
            return t + 0.4; },
          (t) => { if (!late) return t; t = K.cmd(t, "git push"); t = G.show(t, late, { glow: true }); cur = late; t = G.refs(t - 0.1, { [m]: B0, [f]: late, HEAD: f, ["origin/" + f]: late }); return t + 0.3; },
          (t) => dismiss(t, true) + 0.3,
          (t) => dismiss(t, false) + 0.3,
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
      // file=off, job=off, runner=off hide those names; result=skipped: no run starts (a path filter did not match), the check stays pending (skip_text=...)
      const EV = { push: ["a push", "commit"], pull_request: ["a pull request", "the merge result"], schedule: ["a schedule", "default branch"], workflow_dispatch: ["a click on Run workflow", "chosen branch"], release: ["a published release", "tagged commit"],
        merge_group: ["a merge group", "the queue's commit"] };
      const evn = P.event || "push", trig = P.trigger || (EV[evn] || EV.push)[0], subj = P.subject || (EV[evn] || EV.push)[1], failed = P.result === "failed" || P.result === "failing", skipped = P.result === "skipped", RES = failed ? RED : skipped ? AMBER : GREEN;
      const ev = svg("g", {}, K.main);
      svg("circle", { cx: 150, cy: 330, r: 34, fill: INK, stroke: NEUTRAL, "stroke-width": 6 }, ev);
      A.text(ev, 150, 400, subj, { size: Math.min(23, Math.floor(270 / (subj.length * 0.6021))), fill: DIM, weight: 500 });
      A.rect(ev, 30, 222, 240, 46, { r: 10, fill: pal.accent }); A.text(ev, 150, 246, evn, { size: Math.min(24, Math.floor(220 / (evn.length * 0.6021))), fill: INK });
      A.text(ev, 150, 180, "EVENT", { mono: false, size: 22, weight: 800, fill: DIM, spacing: 3 });
      const en = tl.node(ev, { o: 0, y: 24 });
      const wf = svg("g", {}, K.main), wx = 400, wy = 240, ww = 380, wh = 190;
      A.slab(wf, wx, wy, ww, wh, { depth: 14, stroke: pal.accent2, fill: "#11151c" });
      A.text(wf, wx + ww / 2, wy - 60, "WORKFLOW", { mono: false, size: 22, weight: 800, fill: DIM, spacing: 3 });
      if (P.file === "off" || P.job === "off") { const ls = (P.file === "off" ? [] : [".github/workflows/" + (P.file || "ci.yml")]).concat(["on: " + evn, "jobs:"], P.job === "off" ? ["  ..."] : ["  " + (P.job || "test") + ": ..."]);
        ls.forEach((s, i) => A.text(wf, wx + 20, wy + 36 + i * 38 + (P.file === "off" ? 20 : 0), s, { size: /^\.github/.test(s) ? 21 : 23, fill: /^\.github/.test(s) ? pal.accent2 : "#d5dce4", anchor: "start", weight: 500 })); }
      else [".github/workflows/" + (P.file || "ci.yml"), "on: " + evn, "jobs:", "  " + (P.job || "test") + ": ..."].forEach((s, i) => A.text(wf, wx + 20, wy + 36 + i * 38, s, { size: i ? 23 : 21, fill: i ? "#d5dce4" : pal.accent2, anchor: "start", weight: 500 }));
      const wn = tl.node(wf, { o: 0, y: 24 });
      const skg = svg("g", {}, K.top), skt = P.skip_text || "no run: the path filter did not match", skw = A.sans_w(skt, 26) + 44;
      A.rect(skg, wx + ww / 2 - skw / 2, wy + wh + 30, skw, 52, { r: 26, fill: INK, stroke: AMBER, sw: 3, dash: "8 6" }); A.text(skg, wx + ww / 2, wy + wh + 57, skt, { mono: false, size: 26, weight: 700, fill: AMBER });
      const skn = tl.node(skg, { o: 0, y: -10 });
      const run = svg("g", {}, K.main), rx = 960, ry = 130, rw = 660, rh = 560;
      A.slab(run, rx, ry + rh - 90, rw, 90, { depth: 26, stroke: "#59636e", fill: "#0d1016" });
      if (P.runner !== "off") A.text(run, rx + 30, ry + rh - 44, "runner: " + (P.runner || "ubuntu-latest"), { size: 24, fill: "#b6bfc9", anchor: "start", weight: 500 });
      for (let i = 0; i < 3; i++) svg("circle", { cx: rx + rw - 40 - i * 30, cy: ry + rh - 45, r: 7, fill: i ? "#30363d" : pal.accent }, run);
      A.text(run, rx + rw / 2, ry - 46, "RUNNER: A FRESH MACHINE", { mono: false, size: 22, weight: 800, fill: DIM, spacing: 3 });
      const rn = tl.node(run, { o: 0, y: 30 });
      const job = svg("g", {}, K.main), jx = rx + 40, jy = ry + 20, jw = rw - 80, jh = rh - 150;
      A.slab(job, jx, jy, jw, jh, { depth: 12, stroke: pal.accent, fill: "#11151c" });
      A.text(job, jx + 24, jy + 36, P.job === "off" ? "job" : "job: " + (P.job || "test"), { size: 26, fill: pal.accent, anchor: "start" });
      const jn = tl.node(job, { o: 0, y: -40 });
      const rows = stepNames.slice(0, 5).map((s, i) => { const g = svg("g", {}, job), y = jy + 70 + i * 66; A.rect(g, jx + 20, y, jw - 40, 54, { r: 9, fill: "#0b0d12", stroke: "#30363d", sw: 2 });
        const ring = svg("circle", { cx: jx + 52, cy: y + 27, r: 13, fill: "none", stroke: "#59636e", "stroke-width": 4 }, g); A.text(g, jx + 84, y + 28, s, { size: 24, fill: "#d5dce4", anchor: "start", weight: 500 });
        const tk = K.tick(g, jx + 52, y + 27, 0.85), cr = K.cross(g, jx + 52, y + 27, 0.75); const bar = A.rect(g, jx + 20, y, 0, 54, { r: 9, fill: pal.accent, o: 0.16 }); return { n: tl.node(g, { o: 0, x: 20 }), ring, tk, cr, bar, w: jw - 40 }; });
      const a1 = K.arrow(K.back, 250, 330, wx - 10, 330, { straight: true }), a2 = K.arrow(K.back, wx + ww + 18, 330, jx - 10, 330, { straight: true });
      const back = K.arrow(K.back, rx - 8, ry + rh - 45, 150, 428, { stroke: RES, d: `M${rx - 8},${ry + rh - 45} H170 Q150,${ry + rh - 45} 150,${ry + rh - 65} V428` });
      const res = svg("g", {}, K.top); svg("circle", { cx: 190, cy: 300, r: 22, fill: skipped ? INK : RES, stroke: skipped ? AMBER : "none", "stroke-width": skipped ? 5 : 0, "stroke-dasharray": skipped ? "7 6" : null }, res);
      const rt = failed ? K.cross(res, 190, 300, 0.9, INK) : K.tick(res, 190, 300, 1, skipped ? "none" : INK); const resn = tl.node(res, { o: 0 });
      return {
        steps: [
          (t) => { t = K.title(t, P.title || "A CI run, end to end"); en.to(t, 0.45, { o: 1, y: 0 }, "out"); tl.sound(t + 0.1, "pop", 0.8); return K.say(t + 0.2, "An event starts everything: here, " + trig, { y: 760 }) + 0.2; },
          (t) => { t = a1.draw(t, 0.4); wn.to(t - 0.1, 0.45, { o: 1, y: 0 }, "out"); tl.sound(t, "pop", 0.8);
            if (skipped) { skn.to(t + 0.5, 0.4, { o: 1, y: 0 }, "out"); return K.say(t + 0.1, "The workflow listens for the event, but its filter does not match: no run starts", { y: 760 }) + 0.5; }
            return K.say(t + 0.1, "GitHub finds the workflow files that listen for that event", { y: 760 }) + 0.2; },
          (t) => { if (skipped) return t; t = a2.draw(t, 0.45); rn.to(t - 0.2, 0.5, { o: 1, y: 0 }, "out"); jn.to(t + 0.25, 0.5, { o: 1, y: 0 }, "out"); tl.sound(t + 0.3, "pop", 0.8); return K.say(t + 0.3, "Each job gets a runner: a clean machine that is thrown away afterwards", { y: 760 }) + 0.3; },
          (t) => { if (skipped) return t; K.say(t, "The job's steps run in order, top to bottom", { y: 760 }); rows.forEach((r, i) => { const t0 = t + 0.3 + i * 0.62; r.n.to(t0, 0.25, { o: 1, x: 0 }, "out");
              const bad = failed && i === rows.length - 1;
              tl.add(t0 + 0.2, 0.35, (p) => r.bar.setAttribute("width", (r.w * p).toFixed(1)), "inOut"); tl.at(t0 + 0.5, (p) => r.ring.setAttribute("stroke", p ? (bad ? RED : GREEN) : "#59636e")); K.drawTick(t0 + 0.5, bad ? r.cr : r.tk); });
            return t + 0.3 + rows.length * 0.62 + 0.3; },
          (t) => { if (skipped) { resn.to(t, 0.3, { o: 1 }, "out"); resn.pulse(t, 0.5, "y", -12); tl.sound(t + 0.1, "pop", 0.7); return K.say(t + 0.1, "No run, no result: a required check keeps waiting", { y: 760 }) + 0.5; }
            t = back.draw(t, 0.6); resn.to(t - 0.1, 0.3, { o: 1 }, "out"); resn.pulse(t - 0.1, 0.5, "y", -12); K.drawTick(t, rt); return K.say(t, failed ? "The result is attached to the commit as a failed check" : "The result is attached to the commit as a check", { y: 760 }) + 0.4; },
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
      // beyond v1: up to eight lines, change=N (the line that differs; default the last), fn2 (another function on the second card), badge (a word on both
      // cards: "binary"), one value in ids, and long IDs (40 or 64 digits, an SSH fingerprint) on two lines
      if (P.lines && P.lines.length) D.lines = P.lines.slice(0, 8);
      for (const k of ["alt", "fn", "same", "diff"]) if (P[k]) D[k] = P[k];
      if (P.ids && P.ids.length >= 2) D.ids = P.ids.slice(0, 2); else if (P.ids && P.ids.length === 1) D.ids = [P.ids[0], P.ids[0]];
      const lines = D.lines, many = lines.length > 5, PITCH = many ? 35 : 44;
      const last = P.change != null ? Math.max(0, Math.min(lines.length - 1, +P.change - 1)) : lines.length - 1;
      if (!P.alt && P.fn2) D.alt = lines[last];              // nothing changes in the content (two functions, or only "one" and "same" are played)
      let LS = Math.min(many ? 25 : 28, Math.floor(590 / (Math.max(D.alt.length, ...lines.map((l) => l.length)) * 0.6021)));
      if (LS < 20) { LS = 20; const mc = Math.floor(590 / (20 * 0.6021)), cut = (x) => (x.length > mc ? Scenes.cut(x.slice(0, mc - 1) + "…", x) : x); for (let i = 0; i < lines.length; i++) lines[i] = cut(lines[i]); D.alt = cut(D.alt); }   // a very long line is cut, not shrunk further
      const idLen = Math.max(D.ids[0].length, D.ids[1].length), twoRows = idLen > 16, rowLen = twoRows ? Math.ceil(idLen / 2) : idLen;
      const noChange = !!P.fn2 && !P.alt;                                 // the same content through two functions
      if (noChange && !P.diff) D.diff = "The same content through another function: another ID";
      const IS = Math.min(44, Math.floor(570 / (rowLen * 0.6021))), IH = twoRows ? 84 + IS * 1.25 : 84;
      const CW = 640, CH = 96 + lines.length * PITCH, XS = [120, 968], Y = many || twoRows ? 126 : 150, MY = Y + CH + (many || twoRows ? 46 : 70), IY = MY + (many || twoRows ? 150 + (IH - 84) / 2 : 190);
      const side = (i) => {
        const x = XS[i], g = svg("g", {}, K.main);
        A.slab(g, x, Y, CW, CH, { depth: 16, stroke: i ? "#59636e" : NEUTRAL, fill: "#11151c" });
        A.text(g, x + 26, Y + 40, [P.left || D.left, P.right || D.right][i], { mono: false, size: 28, weight: 800, fill: WHITE, anchor: "start" });
        const hl = A.rect(g, x + 14, Y + 62 + last * PITCH, CW - 28, PITCH - 2, { r: 8, fill: pal.accent2, o: 0 });
        const txt = lines.map((s, k) => A.text(g, x + 26, Y + 84 + k * PITCH - (many ? 4 : 0), s, { size: LS, fill: "#d5dce4", anchor: "start", weight: 500 }));
        const alt = A.text(g, x + 26, Y + 84 + last * PITCH - (many ? 4 : 0), D.alt, { size: LS, fill: pal.accent2, anchor: "start" }); alt.setAttribute("opacity", 0);
        if (P.badge) { const bw = A.sans_w(P.badge, 22) + 30; A.rect(g, x + CW - bw - 20, Y + 22, bw, 36, { r: 18, fill: INK, stroke: pal.accent2, sw: 2.5 }); A.text(g, x + CW - 20 - bw / 2, Y + 41, P.badge, { mono: false, size: 22, weight: 700, fill: pal.accent2 }); }
        const cx = x + CW / 2;
        const a1 = K.arrow(K.back, cx, Y + CH + 10, cx, MY - 10, { straight: true });
        const fnName = i && P.fn2 ? P.fn2 : D.fn, fw = Math.max(300, A.mono_w(fnName + "( )", 32) + 60);
        const m = svg("g", {}, K.main); A.rect(m, cx - fw / 2, MY, fw, 78, { r: 39, fill: INK, stroke: pal.accent, sw: 4 }); A.text(m, cx, MY + 40, fnName + "( )", { size: 32, fill: pal.accent });
        const a2 = K.arrow(K.back, cx, MY + 88, cx, IY - IH / 2 - 10, { straight: true, stroke: pal.accent });
        const idg = svg("g", {}, K.main), iw = Math.max(300, (twoRows ? rowLen : D.ids[1].length) * IS * 0.6021 + 70); const box = A.rect(idg, cx - iw / 2, IY - IH / 2, iw, IH, { r: 16, fill: INK, stroke: NEUTRAL, sw: 4 });
        const idt = A.text(idg, cx, IY + 2 - (twoRows ? IS * 0.62 : 0), twoRows ? D.ids[0].slice(0, rowLen) : D.ids[0], { size: IS, fill: WHITE });
        const idt2 = twoRows ? A.text(idg, cx, IY + 2 + IS * 0.62, D.ids[0].slice(rowLen), { size: IS, fill: WHITE }) : null;
        if (twoRows) Object.defineProperty(idt, "textContent", { get() { return Object.getOwnPropertyDescriptor(Node.prototype, "textContent").get.call(idt); },
          set(v) { const h = Math.ceil(v.length / 2); Object.getOwnPropertyDescriptor(Node.prototype, "textContent").set.call(idt, v.slice(0, h)); idt2.textContent = v.slice(h); } });
        if (twoRows) idt.textContent = D.ids[0];
        return { g, cx, hl, last: txt[last], alt, a1, a2, idt, box, n: tl.node(g, { o: 0, y: 30 }), mn: tl.node(m, { o: 0, s: 0.6, x: 0, y: 0 }), idn: tl.node(idg, { o: 0, s: 1 }), shown: false, ver: 0 };
      };
      const S = [side(0), side(1)];
      const HEX = "0123456789abcdef";
      const scramble = (t, sd, to) => { const from = sd.cur || D.ids[0]; sd.cur = to;
        tl.add(t, 0.7, (p) => { let out = ""; for (let i = 0; i < to.length; i++) out += /[0-9a-f]/.test(to[i]) && p < 1 && i >= Math.floor(p * to.length) ? HEX[(i * 7 + Math.floor(p * 23) * 5 + to.charCodeAt(i)) % 16] : (p > 0 ? to[i] : from[i] || ""); sd.idt.textContent = p > 0 ? out : from; }, "lin");
        for (let i = 0; i < 6; i++) tl.sound(t + i * 0.1, "tick", 0.7); return t + 0.7; };
      const run = (t, sd, id, quiet) => { t = sd.a1.draw(t, 0.3); sd.mn.to(t - 0.1, 0.3, { o: 1, s: 1 }, "back"); sd.mn.pulse(t + 0.25, 0.4, "y", 6); t = sd.a2.draw(t + 0.35, 0.3); sd.idn.to(t - 0.1, 0.3, { o: 1 }, "out"); if (!quiet) tl.sound(t, "pop", 0.8); sd.cur = D.ids[0]; return id === D.ids[0] ? t + 0.3 : scramble(t, sd, id); };
      const showCard = (t, sd) => { sd.n.to(t, 0.45, { o: 1, y: 0 }, "out"); tl.sound(t + 0.1, "pop", 0.8); sd.shown = true; K.grow(sd.cx - CW / 2 - 10, Y - 26, sd.cx + CW / 2 + 26, IY + IH / 2 + 20); return t + 0.5; };
      const setVer = (t, sd, v) => { if (sd.ver === v || noChange) return t; sd.ver = v;
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
    // the camera of a scene that is not a commit graph: on by default in the scenes that say so (follow: true), camera=follow asks for it elsewhere
    const follow = P.camera === "follow" || ((typeof def.follow === "function" ? def.follow(P) : !!def.follow) && P.camera !== "off");
    // Labels claim room as the steps are built, and some steps need the final scale.  So the scene is built twice:
    // once on a hidden scratch element to learn how much room every state needs, then for real.
    const host = document.getElementById("scene"), scratch = document.createElement("div");
    host.id = "scene-real"; scratch.id = "scene"; scratch.style.cssText = "position:absolute;left:-9999px;top:0;visibility:hidden";
    document.body.appendChild(scratch);
    const K2 = kit(A.stage(), cfg, follow); K2.names = names; const sc2 = def.build(K2, P);
    sc2.fit && sc2.fit();
    const stepExts = [], stageExts = [];                                    // what every graph (and the stage) covers after each step: the camera follows it
    const snap = (g) => { const e = (g.view || g.ext).slice(); if (g.view) e.free = true; return e; };
    let tt = 0; for (const n of names.slice(0, cfg.fit_to || names.length)) { K2.step = n; tt = fn(sc2, n)(tt) + gap; stepExts.push((K2.graphs || []).map(snap)); stageExts.push(K2.ext.slice()); }
    const exts = (K2.graphs || []).map((g) => g.ext.slice());
    scratch.remove(); host.id = "scene";
    const K = kit(tl, cfg, follow); K.names = names; const sc = def.build(K, P);
    (K.graphs || []).forEach((g, i) => { if (exts[i]) g.ext = exts[i]; });
    sc.fit && sc.fit();
    // A scene that grows is not framed for its final size from the first frame: the camera starts on what the first step shows
    // and re-fits gently when a later step needs more room.  camera=off (or a scene with refit: false) keeps the final framing throughout.
    const refit = sc.refit !== false && P.camera !== "off" && stepExts.length > 0;
    // The stage camera.  It centres what is on screen so far inside the box the scene names (sc.stage, default: between caption and command line)
    // and stands up to 25 % closer than the layout while the picture is small; a scene that fills its layout ends at scale 1.
    const SB = sc.stage || [40, 120, K.W - 80, K.H - 230], scam = { tx: 0, ty: 0, s: 1 };
    let splan = { tx: 0, ty: 0, s: 1 };
    const sframe = (e, last) => {
      const bw = e[2] - e[0], bh = e[3] - e[1];
      if (!(bw > 0 && bh > 0)) return { tx: 0, ty: 0, s: 1 };
      const s1 = Math.max(1, Math.min(1.25, SB[2] / bw, SB[3] / bh));
      if (last && s1 < 1.03) return { tx: 0, ty: 0, s: 1 };              // the finished picture fills its layout: it is shown as it was laid out
      return { s: s1, tx: SB[0] + (SB[2] - bw * s1) / 2 - e[0] * s1, ty: SB[1] + (SB[3] - bh * s1) / 2 - e[1] * s1 };
    };
    if (K.stage) tl.after.push(() => K.stage.setAttribute("transform", `translate(${scam.tx.toFixed(1)},${scam.ty.toFixed(1)}) scale(${scam.s.toFixed(4)})`));
    const stageTo = (i, t, dur) => {
      if (!K.stage || !stageExts.length) return t;
      const k = Math.min(i, stageExts.length - 1), target = sframe(stageExts[k], k === stageExts.length - 1), f = splan;
      if (dur === 0) { Object.assign(scam, target); splan = target; return t; }
      if (Math.abs(target.tx - f.tx) < 2 && Math.abs(target.ty - f.ty) < 2 && Math.abs(target.s - f.s) < 0.004) return t;
      splan = target;
      return tl.add(t, dur, (p) => { scam.tx = lerp(f.tx, target.tx, p); scam.ty = lerp(f.ty, target.ty, p); scam.s = lerp(f.s, target.s, p); }, "inOut");
    };
    const cam = (i, t, dur) => { let end = t; if (!refit) return end; const e = stepExts[Math.min(i, stepExts.length - 1)];
      (K.graphs || []).forEach((g, k) => { if (g.box && e[k]) end = Math.max(end, g.camTo(t, e[k], dur)); }); return Math.max(end, stageTo(i, t, dur)); };
    cam(0, 0, 0);
    let t = 0;
    // point_<step>=name: after the step an arrow lands on a named spot (a commit, a label, a box of the scene)
    const where = (key) => {
      const k = String(key).toLowerCase();
      for (const g of K.graphs || []) {
        const id = Object.keys(g.c).find((x) => x.toLowerCase() === k), ch = Object.keys(g.shown).find((x) => DISPLAY(x).toLowerCase() === k);
        const q = id ? g.xy(g.c[id].col, g.c[id].row) : ch ? g.shown[ch] : null;
        if (q) { const c = g.box ? g.camPlan : { tx: 0, ty: 0, s: 1 }; return [(q.x * c.s + c.tx) * splan.s + splan.tx, (q.y * c.s + c.ty) * splan.s + splan.ty, id ? g : null, id]; }
      }
      const sp = K.spots[k]; return sp ? [sp[0] * splan.s + splan.tx, sp[1] * splan.s + splan.ty] : null;
    };
    // a step is over when its own motion AND the camera's re-fit are over: the picture that is held afterwards is the settled one
    // When the camera has to move, it gets a head start of 0.35 s, so that what the step adds arrives inside the frame.
    const play = (i, last) => { K.step = names[i]; const c = i ? cam(i, t, 0.8) : t;
      for (const old of K.points || []) if (old.plan.o > 0) old.to(t, 0.2, { o: 0 }, "in");
      if (P.titles && typeof P.titles === "object" && P.titles[names[i]] !== undefined) K.title(t, "");
      t = Math.max(fn(sc, names[i])(t + (c > t ? 0.35 : 0)), c);
      // say_<step>= in a schematic scene (flow, gates, stores ...): these have no captions of their own, so the caption takes the line under the title
      if (def.free && P.say && typeof P.say === "object" && P.say[names[i]] !== undefined && !K.said["s" + names[i] + "main"]) {
        if (P.say[names[i]] === "off") K.resay(t - 0.2, "off"); else t = Math.max(t, K.say(t - 0.2, "", { y: K.capY || 96, plate: true })); }
      if (P.point && typeof P.point === "object" && P.point[names[i]]) { const w = where(P.point[names[i]]); if (w) { if (w[2]) w[2].focus(t, w[3], 0.9); t = K.point(t, w[0], w[1]); } }
      t += last ? 0 : gap; };
    for (let i = 0; i < from; i++) play(i, false);
    // captions given while the scene is held ("[ANIMATION] say: ..."): those already on screen are replayed, the newest one is animated
    const says = cfg.says || [], said = Math.min(says.length, cfg.says_from || 0);
    K.step = null;
    for (let i = 0; i < said; i++) t = K.resay(t, says[i]) + 0.1;
    tl.start = t;
    for (let i = from; i < to; i++) play(i, i === to - 1);
    K.step = null;
    for (let i = said; i < says.length; i++) t = K.resay(t + (i > said || to > from ? 0.1 : 0), says[i]);
    if (cfg.focus && sc.focus) t = sc.focus(t, cfg.focus);
    tl.t = Math.max(t, tl.start);
    tl.info = { steps: names, from, to };
    // the layout check also reports what is on screen (every visible text, and the outline of every visible circle): the self-test reads it
    if (cfg.lint) { tl.seek(tl.t); const seen = {}; tl.info.lint = Scenes.lint(K.root, cfg.lint, seen); tl.info.texts = seen.texts; tl.info.circles = seen.circles; tl.seek(tl.start); }
  };

  // ---- a layout check for the self-test: text that is too small, cut short with "…", cut off at the edge of the scene, or lying on other text ----
  // o: {min: smallest font size on screen in px}.  -> list of findings (empty = clean)
  Scenes.lint = function (root, o, report) {
    const out = [], items = [], R = root.getBoundingClientRect(), min = (o && o.min) || 0;
    const seen = (el) => { for (let e = el; e && e !== root.parentNode; e = e.parentNode) { if (!e.getAttribute) break;
      const a = e.getAttribute("opacity"); if (a != null && +a < 0.06) return false; if (e.getAttribute("display") === "none") return false;
      if (e.style && e.style.opacity !== "" && +e.style.opacity < 0.06) return false; if (e.style && e.style.visibility === "hidden") return false; } return true; };
    for (const el of root.querySelectorAll("text")) {
      const str = el.textContent; if (!str.trim() || !seen(el)) continue;
      const r = el.getBoundingClientRect(), m = el.getScreenCTM(), px = +el.getAttribute("font-size") * Math.hypot(m.a, m.b);
      if (r.width < 1) continue;
      if (Scenes.cuts[str]) out.push(`text cut short: "${str.slice(0, 40)}" (in full: "${Scenes.cuts[str].slice(0, 70)}")`);
      if (min && px < (el.getAttribute("data-small") ? min * 0.72 : min) && !/^[·.]$/.test(str)) out.push(`small text ${px.toFixed(1)} px: "${str.slice(0, 40)}"`);
      if (r.right < R.left || r.left > R.right || r.bottom < R.top || r.top > R.bottom) continue;      // wholly outside (a history that scrolls): not on screen
      if (r.left < R.left - 1 || r.right > R.right + 1 || r.top < R.top - 1 || r.bottom > R.bottom + 1) out.push(`cut off at the edge: "${str.slice(0, 40)}"`);
      const dy = r.height * 0.18;                                       // a line's box is taller than its glyphs
      items.push([r.left + 2, r.top + dy, r.right - 2, r.bottom - dy, str, el]);
    }
    if (report) { report.texts = items.map((x) => x[4]);
      report.circles = Array.from(root.querySelectorAll("circle")).filter((c) => seen(c) && c.getAttribute("stroke") && c.getAttribute("stroke") !== "none" && +c.getAttribute("r") >= 20)
        .map((c) => `${c.getAttribute("stroke-width")}/${c.getAttribute("stroke-dasharray") || "none"}`); }
    for (let i = 0; i < items.length; i++) for (let j = i + 1; j < items.length; j++) {
      const a = items[i], b = items[j];
      if (a[0] < b[2] && a[2] > b[0] && a[1] < b[3] && a[3] > b[1]) out.push(`text on text: "${a[4].slice(0, 30)}" / "${b[4].slice(0, 30)}"`);
    }
    return out;
  };
})();
