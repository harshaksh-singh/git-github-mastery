// Explainer scenes, third file: the rest of the schematic scenes and the scenes of single topics.
//   decide  a decision tree or a state diagram            stores  boxes that hold things, and what moves between them
//   bars    a few numbers as bars                         blame   the lines of a file, each with the commit that last changed it
//   todo    a rebase todo list being edited               push    the anatomy of a push: refspec, two gatekeepers, the lease check
//   ladder  how far a commit has fallen: reachable, only in the reflog, unreachable, pruned
//   run     a workflow run in detail: event, ref, jobs with needs, matrix, token, cache and artifacts, an environment gate, concurrency
// Every label comes from the script; the same rules as in scenes2.js (type of 28 units or more, the stage camera follows the growth).
(function () {
  "use strict";
  const A = window.A, svg = A.svg, lerp = A.lerp, Scenes = window.Scenes, U = Scenes.util;
  const { fit, T, wrap, wrapW, width, COL, mark, pill, box, num, fadeTo, FS } = U;
  const NEUTRAL = "#c9d1d9", DIM = "#8b949e", INK = "#0b0d12", RED = "#ff5c5c", GREEN = "#3fb950", WHITE = "#f0f6fc", AMBER = "#e3b341", SOFT = "#d5dce4", LINE = "#30363d";
  const STAGE = (K) => [30, 118, K.W - 60, K.H - 150];

  // =================================================================================================
  // decide: questions, answers and leaves (a decision tree), or states and transitions (reveal: "edges").
  //   params: {nodes: [[id, text]], edges: [[from, to, label]], cols: [[ids of column 1], ...] (worked out by the planner), path: [ids] (the way taken),
  //            reveal: "levels" | "edges", title}
  Scenes.defs.decide = {
    free: true, follow: true,
    steps: (P) => (P.reveal === "edges" ? ["nodes"].concat((P.edges || []).map((_, i) => num(i))) : (P.cols || []).map((_, i) => "level-" + (i + 1)).concat(P.path && P.path.length ? ["path"] : [])),
    build(K, P) {
      const tl = K.tl, pal = K.pal, nodes = P.nodes || [], edges = P.edges || [], cols = P.cols || [nodes.map((n) => n[0])], nc = cols.length, byEdges = P.reveal === "edges";
      const X0 = 70, AW = K.W - 140, colW = AW / nc, bw = Math.min(byEdges ? 280 : 400, colW - (byEdges ? 150 : nc > 3 ? 84 : 120)), top = 140, AH = K.H - top - 40;
      const taken = [];
      const chars = Math.max(10, Math.floor((bw - 36) / 15.2)), pos = {};
      const hasOut = (id) => edges.some((e) => e[0] === id);
      const grid = P.grid || null, nrow = grid ? 1 + Math.max(...Object.values(grid).map((g) => g[1])) : 0, rowH = grid ? Math.min(230, AH / nrow) : 0;
      cols.forEach((ids, c) => {
        const items = ids.map((id) => { const text = (nodes.find((n) => n[0] === id) || [id, id])[1], lines = wrap(text, chars, 3); return { id, lines, h: 44 + lines.length * 36 }; });
        const total = items.reduce((a, b) => a + b.h, 0), gap = Math.min(90, (AH - total) / Math.max(1, items.length));
        let y = top + Math.max(0, (AH - total - gap * (items.length - 1)) / 2);
        for (const it of items) { const gy = grid && grid[it.id] ? top + (AH - nrow * rowH) / 2 + grid[it.id][1] * rowH + (rowH - it.h) / 2 : y;      // grid=...: the row is given
          pos[it.id] = { x: X0 + c * colW + (colW - bw) / 2, y: gy, w: bw, h: it.h, lines: it.lines, c }; y += it.h + gap; }
      });
      const made = {};
      for (const [id] of nodes) { const q = pos[id]; if (!q) continue; const g = svg("g", {}, K.main), leaf = !hasOut(id) && !byEdges;
        const frame = A.rect(g, q.x, q.y, q.w, q.h, { r: leaf ? q.h / 2 > 40 ? 40 : q.h / 2 : 14, fill: "#11151c", stroke: leaf ? pal.accent : NEUTRAL, sw: 3.5 });
        q.lines.forEach((l, k) => T(g, q.x + q.w / 2, q.y + 22 + 18 + k * 36, l, { size: 29, weight: leaf ? 800 : 600, fill: leaf ? pal.accent : WHITE, max: q.w - 26 }));
        K.spot(id, q.x + q.w / 2, q.y + q.h / 2);
        made[id] = { n: tl.node(g, { o: 0, s: 0.9 }), frame, q, leaf }; }
      const lines = edges.map(([a, b, label]) => { const p = pos[a], q = pos[b]; if (!p || !q) return null; const g = svg("g", {}, K.back), fwd = q.c > p.c;
        let d, lx, ly;
        let pts;                                                       // the curve as four points; the label sits on it where no other label is
        if (byEdges) {                                                 // states: a straight line from border to border; a pair of opposite transitions runs side by side
          const c1 = [p.x + p.w / 2, p.y + p.h / 2], c2 = [q.x + q.w / 2, q.y + q.h / 2], dx = c2[0] - c1[0], dy = c2[1] - c1[1], len = Math.hypot(dx, dy) || 1, nx = -dy / len, ny = dx / len;
          const twin = edges.some((e) => e[0] === b && e[1] === a), off = twin ? 18 : 0;
          const cut = (bx, sgn) => { const tx = Math.abs(dx) < 1 ? 1e9 : (bx.w / 2 + 10) / Math.abs(dx), ty = Math.abs(dy) < 1 ? 1e9 : (bx.h / 2 + 10) / Math.abs(dy), u = Math.min(tx, ty); return [sgn > 0 ? c1[0] + dx * u : c2[0] - dx * u, sgn > 0 ? c1[1] + dy * u : c2[1] - dy * u]; };
          const s0 = cut(p, 1), s1 = cut(q, -1), x0 = s0[0] + nx * off, y0 = s0[1] + ny * off, x1 = s1[0] + nx * off, y1 = s1[1] + ny * off;
          pts = [x0, y0, x0 + (x1 - x0) / 3 + nx * off, y0 + (y1 - y0) / 3 + ny * off, x0 + ((x1 - x0) * 2) / 3 + nx * off, y0 + ((y1 - y0) * 2) / 3 + ny * off, x1, y1];
        } else if (fwd) { const x0 = p.x + p.w + 6, y0 = p.y + p.h / 2 + (byEdges ? -12 : 0), x1 = q.x - 12, y1 = q.y + q.h / 2 + (byEdges ? -12 : 0), mx = (x0 + x1) / 2; pts = [x0, y0, mx, y0, mx, y1, x1, y1]; }
        else if (q.c === p.c) { const up = q.y < p.y, x0 = p.x + p.w / 2 + (up ? 40 : -40), y0 = up ? p.y - 6 : p.y + p.h + 6, y1 = up ? q.y + q.h + 12 : q.y - 12; pts = [x0, y0, x0, y0, x0, y1, x0, y1]; }
        else { const x0 = p.x - 6, y0 = p.y + p.h / 2 + 14, x1 = q.x + q.w + 12, y1 = q.y + q.h / 2 + 14, mx = (x0 + x1) / 2, sag = Math.abs(y1 - y0) < 30 ? 64 : 0; pts = [x0, y0, mx, y0 + sag, mx, y1 + sag, x1, y1]; }
        d = `M${pts[0]},${pts[1]} C${pts[2]},${pts[3]} ${pts[4]},${pts[5]} ${pts[6]},${pts[7]}`;
        const at = (u) => { const v = 1 - u; return [v * v * v * pts[0] + 3 * v * v * u * pts[2] + 3 * v * u * u * pts[4] + u * u * u * pts[6], v * v * v * pts[1] + 3 * v * v * u * pts[3] + 3 * v * u * u * pts[5] + u * u * u * pts[7]]; };
        const lmax = byEdges ? Math.max(200, colW - 40) : Math.max(150, (fwd || q.c !== p.c ? colW - bw : 300) + 40), ll = !label ? [] : width(label, FS, false) <= lmax ? [label] : wrapW(label, FS, lmax, false, 3), lw = label ? Math.max(...ll.map((l) => width(l, FS, false))) + 26 : 0, lh = 42 + (ll.length - 1) * 30;
        const hitsNode = (x, y) => Object.values(pos).some((b) => x + lw / 2 > b.x - 6 && x - lw / 2 < b.x + b.w + 6 && y + lh / 2 + 1 > b.y - 4 && y - lh / 2 - 1 < b.y + b.h + 4);
        for (const u of [0.5, 0.4, 0.6, 0.3, 0.7, 0.22, 0.78, 0.5]) { [lx, ly] = at(u); if (!taken.some((b) => Math.abs(b[0] - lx) < (b[2] + lw) / 2 && Math.abs(b[1] - ly) < (b[3] + lh) / 2 + 4) && !(byEdges && hitsNode(lx, ly))) break; }
        if (label) taken.push([lx, ly, lw, lh]);
        const path = svg("path", { d, fill: "none", stroke: DIM, "stroke-width": 4.5, "stroke-linecap": "round", pathLength: 1, "stroke-dasharray": "1 1", "stroke-dashoffset": 1 }, g);
        const tip = path.getPointAtLength ? null : null, e2 = (() => { const m = /([-\d.]+),([-\d.]+)$/.exec(d); return [+m[1], +m[2]]; })();
        const dot = svg("circle", { cx: e2[0], cy: e2[1], r: 8, fill: DIM, opacity: 0 }, g);
        const lg = svg("g", {}, K.main); let ln = null;
        if (label) { A.rect(lg, lx - lw / 2 + 2, ly - lh / 2, lw - 4, lh, { r: 21, fill: INK, stroke: LINE, sw: 2 }); ll.forEach((l, q) => A.text(lg, lx, ly + 1 + (q - (ll.length - 1) / 2) * 30, l, { mono: false, size: FS, weight: 700, fill: pal.accent2 })); ln = tl.node(lg, { o: 0, s: 0.7 }); }
        return { a, b, path, dot, ln, drawn: false, draw(t) { if (this.drawn) return t; this.drawn = true; tl.add(t, 0.4, (pp) => { path.setAttribute("stroke-dashoffset", (1 - pp).toFixed(4)); dot.setAttribute("opacity", pp > 0.9 ? 1 : 0); }, "inOut"); if (ln) ln.to(t + 0.15, 0.3, { o: 1, s: 1 }, "back"); return t + 0.4; },
          tint(t, col) { tl.at(t, (pp) => { path.setAttribute("stroke", pp ? col : DIM); dot.setAttribute("fill", pp ? col : DIM); path.setAttribute("stroke-width", pp ? 6 : 4.5); }); } }; }).filter(Boolean);
      const showNode = (t, id) => { const m = made[id]; if (!m || m.shown) return t; m.shown = true; m.n.to(t, 0.36, { o: 1, s: 1 }, "back"); tl.sound(t + 0.05, "pop", 0.65); K.grow(m.q.x - 14, m.q.y - 26, m.q.x + m.q.w + 14, m.q.y + m.q.h + 26); return t + 0.36; };
      let steps;
      if (byEdges) {
        let cur = null;
        steps = [(t) => { t = K.title(t, P.title); nodes.forEach(([id], i) => showNode(t + i * 0.12, id)); return t + 0.5 + nodes.length * 0.12; }];
        lines.forEach((ln) => steps.push((t) => { if (cur) { const c0 = cur; tl.at(t, (p) => { c0.frame.setAttribute("stroke", p ? NEUTRAL : pal.accent2); }); }
          const a = made[ln.a], b = made[ln.b]; if (a) a.n.pulse(t, 0.4, "s", 0.05); t = ln.draw(t + 0.1); if (b) { tl.at(t, (p) => { b.frame.setAttribute("stroke", p ? pal.accent2 : NEUTRAL); }); b.n.pulse(t, 0.45, "s", 0.07); cur = b; tl.sound(t + 0.05, "pop", 0.7); }
          return t + 0.5; }));
      } else {
        steps = cols.map((ids, c) => (t) => { if (c === 0) t = K.title(t, P.title);
          lines.filter((l) => ids.includes(l.b) && made[l.a] && made[l.a].shown).forEach((l, k) => l.draw(t + k * 0.1)); t += lines.some((l) => ids.includes(l.b)) ? 0.3 : 0;
          ids.forEach((id, k) => showNode(t + k * 0.14, id)); t += 0.36 + ids.length * 0.14;
          lines.filter((l) => ids.includes(l.b) && ids.includes(l.a)).forEach((l) => l.draw(t)); return t + 0.3; });
        if (P.path && P.path.length) steps.push((t) => { const on = new Set(P.path);
          for (const id in made) { const m = made[id]; if (on.has(id)) { tl.at(t + 0.2, (p) => { m.frame.setAttribute("stroke", p ? pal.accent2 : m.leaf ? pal.accent : NEUTRAL); m.frame.setAttribute("stroke-width", p ? 5.5 : 3.5); }); } else m.n.to(t, 0.4, { o: 0.36 }, "inOut"); }
          P.path.forEach((id, k) => { const l = lines.find((x) => x.a === id && x.b === P.path[k + 1]); if (l) l.tint(t + 0.2 + k * 0.3, pal.accent2); if (made[id]) made[id].n.pulse(t + 0.2 + k * 0.3, 0.4, "s", 0.06); tl.sound(t + 0.22 + k * 0.3, "tick", 0.8); });
          for (const l of lines) if (!(on.has(l.a) && on.has(l.b))) { if (l.ln) l.ln.to(t, 0.4, { o: 0.3 }, "inOut"); fadeTo(K, l.path, t, 1, 0.3, 0.4); }
          return t + 0.4 + P.path.length * 0.3; });
      }
      return { steps, fit: () => {}, stage: STAGE(K) };
    },
  };

  // =================================================================================================
  // stores: boxes that hold things; rows arrive and arrows are drawn step by step.
  //   params: {boxes: [[title, sub]], rows: [[step, box letter, text, kind]] (kind: hl | ok | bad | dim | ghost | ref), arrows: [[step, from, to, label]]
  //            (from / to: a box letter, or letter + row number such as "A2"), title}
  Scenes.defs.stores = {
    free: true, follow: true,
    steps: (P) => ["boxes"].concat(Array.from({ length: Math.max(0, ...(P.rows || []).map((r) => +r[0]), ...(P.arrows || []).map((r) => +r[0])) }, (_, i) => num(i))),
    build(K, P) {
      const tl = K.tl, pal = K.pal, boxes = P.boxes || [], n = boxes.length, rows = P.rows || [], arrows = P.arrows || [];
      const nsteps = Math.max(0, ...rows.map((r) => +r[0]), ...arrows.map((r) => +r[0]));
      const skips = arrows.some((a) => Math.abs(a[1].toUpperCase().charCodeAt(0) - a[2].toUpperCase().charCodeAt(0)) > 1);
      const isFar = (a) => Math.abs(a[1].toUpperCase().charCodeAt(0) - a[2].toUpperCase().charCodeAt(0)) > 1, nfar = arrows.filter(isFar).length;
      const letter = (x) => x.toUpperCase().charCodeAt(0) - 65, mono = P.mono === "on";
      // An arrow's label stands on the arrow, in the gap between two boxes.  A label wider than the gap is set in two lines and the gap
      // grows with it (up to gapMax), so that no label lies on the rows of a box; what is still too long is cut and reported.
      const gapMin = arrows.length ? (n > 2 ? 130 : 200) : 46, gapMax = n > 3 ? 190 : n > 2 ? 250 : 340;
      const labL = arrows.map((a) => { const label = a[3], same = letter(a[1]) === letter(a[2]), w1 = label ? width(label, FS, false) : 0;
        if (!label) return [];
        if (same || isFar(a)) return w1 <= (same ? 260 : 500) ? [label] : wrapW(label, FS, same ? 260 : 500, false, 2);
        if (w1 <= gapMin - 44) return [label];
        const words = label.split(" "); let best = null;              // two lines of about the same width, broken between two words
        for (let q = 1; q < words.length; q++) { const l = [words.slice(0, q).join(" "), words.slice(q).join(" ")], w = Math.max(width(l[0], FS, false), width(l[1], FS, false)); if (!best || w < best.w) best = { l, w }; }
        return best && best.w <= gapMax - 44 ? best.l : w1 <= gapMax - 44 ? [label] : wrapW(label, FS, gapMax - 44, false, 2); });
      const labW = (k) => Math.max(0, ...labL[k].map((l) => width(l, FS, false)));
      const gapX = arrows.length ? Math.max(gapMin, Math.min(gapMax, Math.max(0, ...arrows.map((a, k) => (letter(a[1]) === letter(a[2]) || isFar(a) ? 0 : labW(k) + 44))))) : 46;
      const X0 = 60, BW = (K.W - 120 - gapX * (n - 1)) / n, top = skips ? 150 + 54 * nfar : 150;
      const per = boxes.map((_, i) => rows.filter((r) => letter(r[1]) === i));
      // a title or a sub-line too long for its box at the smallest size takes two lines
      const two = (str) => (width(str || "", FS, false) <= BW - 48 ? [str || ""] : wrapW(str, FS, BW - 48, false, 2));
      const ttl = boxes.map((b) => two(b[0].replace(/^\*/, ""))), sbl = boxes.map((b) => (b[1] ? two(b[1]) : []));
      const tLines = Math.max(1, ...ttl.map((l) => l.length)), sLines = Math.max(0, ...sbl.map((l) => l.length));
      const HEAD = 66 + (tLines - 1) * 34 + (sLines ? 38 + (sLines - 1) * 34 : 0), avail = K.H - 60 - top - HEAD - 16, TXW = BW - 68;
      // a row too long for its box (a path, a command) is set in up to three lines, as far as the boxes have the height for it
      let ML = 3, rl, tot;
      for (;;) { rl = rows.map((r) => (ML === 1 || width(r[2], FS, mono) <= TXW ? [r[2]] : wrapW(r[2], FS, TXW, mono, ML)));
        tot = per.map((list) => list.reduce((acc, r) => acc + 74 + (rl[rows.indexOf(r)].length - 1) * 32, 0));
        if (ML === 1 || Math.max(74, ...tot) <= avail) break; ML--; }
      const squeeze = Math.min(1, avail / Math.max(74, ...tot)), BH = HEAD + Math.max(74, ...tot) * squeeze + 16;
      const bx = boxes.map(([title], i) => { const main = /^\*/.test(title), col = main ? pal.accent : WHITE; const b = box(K, K.main, X0 + i * (BW + gapX), top, BW, BH, { stroke: main ? pal.accent : "#59636e" });
        ttl[i].forEach((l, q) => T(b.g, b.x + 24, top + 40 + q * 34, l, { size: ttl[i].length > 1 ? FS : 30, weight: 800, fill: col, anchor: "start", max: BW - 48 }));
        sbl[i].forEach((l, q) => T(b.g, b.x + 24, top + 78 + (tLines - 1) * 34 + q * 34, l, { size: FS, weight: 500, fill: DIM, anchor: "start", max: BW - 48 }));
        K.spot(title.replace(/^\*/, ""), b.x + BW / 2, top + BH / 2); return b; });
      const STY = { hl: [pal.accent2, WHITE], ok: [GREEN, WHITE], bad: [RED, RED], dim: ["#3a424d", DIM], ghost: ["#59636e", DIM], ref: [pal.accent, pal.accent] };
      const made = rows.map(([step, bl, text, kind], k) => { const i = letter(bl), b = bx[i]; if (!b) return null; const j = per[i].indexOf(rows[k]), lines = rl[k];
        const y = top + HEAD + per[i].slice(0, j).reduce((acc, r) => acc + (74 + (rl[rows.indexOf(r)].length - 1) * 32) * squeeze, 0), h = (74 + (lines.length - 1) * 32) * squeeze - 10;
        const g = svg("g", {}, K.main), st = STY[kind] || [LINE, SOFT];
        A.rect(g, b.x + 16, y, BW - 32, h, { r: 10, fill: INK, stroke: st[0], sw: kind ? 3 : 2.5, dash: kind === "ghost" ? "8 7" : null });
        lines.forEach((l, q) => T(g, b.x + 34, y + h / 2 + 1 + (q - (lines.length - 1) / 2) * 32, l, { mono, size: lines.length > 1 ? FS : 29, weight: kind === "ref" || kind === "hl" ? 700 : 600, fill: st[1], anchor: "start", max: TXW, italic: kind === "ghost" }));
        return { step: +step, i, j, n: tl.node(g, { o: 0, x: -22 }), yc: y + h / 2, x0: b.x + 16, x1: b.x + BW - 16 }; }).filter(Boolean);
      const end = (ref, towardRight) => { const m = /^([A-Za-z])(\d*)$/.exec(ref) || ["", "A", ""], i = m[1].toUpperCase().charCodeAt(0) - 65, b = bx[i] || bx[0];
        const r = m[2] ? made.find((x) => x.i === i && x.j === +m[2] - 1) : null;
        return { i, x: towardRight ? (r ? r.x1 : b.x + BW) + 8 : (r ? r.x0 : b.x) - 12, y: r ? r.yc : top + 38 }; };
      const placed = [];
      const arr = arrows.map(([step, from, to, label], k) => { const fi = (/^[A-Za-z]/.exec(from) || ["A"])[0].toUpperCase().charCodeAt(0), ti = (/^[A-Za-z]/.exec(to) || ["A"])[0].toUpperCase().charCodeAt(0), right = ti >= fi;
        const a = end(from, right), b = end(to, !right), g = svg("g", {}, K.top), same = a.i === b.i;
        const far = Math.abs(a.i - b.i) > 1, oy = top - 40 - 54 * arrows.filter(isFar).findIndex((x) => x[0] === step && x[1] === from && x[2] === to), s1 = right ? 1 : -1;      // an arrow that skips a box goes over the top of it
        const ar = same ? K.arrow(K.back, a.x, a.y, a.x, b.y, { d: `M${a.x},${a.y} h34 V${b.y} h-26`, stroke: pal.accent2, sw: 4.5 })
          : far ? K.arrow(K.back, a.x, a.y, b.x, b.y, { d: `M${a.x},${a.y} h${s1 * (gapX / 2 - 12)} V${oy} H${b.x - s1 * (gapX / 2 - 4)} V${b.y} H${b.x}`, stroke: pal.accent2, sw: 4.5 })
          : K.arrow(K.back, a.x, a.y, b.x, b.y, { stroke: pal.accent2, sw: 4.5 });
        let ln = null; if (label && bx[a.i] && bx[b.i]) { const lines = labL[k], lw = labW(k), lh = 44 + (lines.length - 1) * 30, lo = bx[Math.min(a.i, b.i)], hi = bx[Math.max(a.i, b.i)];
          const lx = same ? a.x + 34 : far ? (a.x + b.x) / 2 : (lo.x + BW + hi.x) / 2 + 4;      // in the middle of the gap between the two boxes
          let ly = far ? oy : (a.y + b.y) / 2;                           // a label that would lie on an earlier one moves down along its arrow
          for (let q = 0; q < 6 && placed.some((r) => Math.abs(r[0] - lx) < (r[2] + lw) / 2 + 24 && Math.abs(r[1] - ly) < (r[3] + lh) / 2 + 4); q++) ly += 10;
          placed.push([lx, ly, lw, lh]);
          A.rect(g, lx - lw / 2 - 12, ly - lh / 2, lw + 24, lh, { r: 22, fill: INK, stroke: pal.accent2, sw: 2.5 });
          lines.forEach((l, q) => A.text(g, lx, ly + 1 + (q - (lines.length - 1) / 2) * 30, l, { mono: false, size: FS, weight: 700, fill: WHITE })); ln = tl.node(g, { o: 0, s: 0.7 }); }
        return { step: +step, ar, ln, a, b }; });
      const steps = [(t) => { t = K.title(t, P.title); bx.forEach((b, i) => b.show(t + i * 0.16)); return t + 0.5 + n * 0.16; }];
      for (let s = 1; s <= nsteps; s++) steps.push((t) => {
        made.filter((r) => r.step === s).forEach((r, k) => { r.n.to(t + k * 0.16, 0.36, { o: 1, x: 0 }, "out"); tl.sound(t + k * 0.16 + 0.05, "pop", 0.65); });
        t += 0.2 + made.filter((r) => r.step === s).length * 0.16;
        arr.filter((a) => a.step === s).forEach((a, k) => { const t0 = t + k * 0.3; a.ar.draw(t0, 0.45); K.fly(t0, a.a.x, a.a.y, a.b.x, a.b.y, { dur: 0.5, lift: a.a.i === a.b.i ? 0 : 30, r: 10 }); if (a.ln) a.ln.to(t0 + 0.25, 0.3, { o: 1, s: 1 }, "back"); });
        return t + 0.3 + arr.filter((a) => a.step === s).length * 0.3 + (arr.some((a) => a.step === s) ? 0.3 : 0); });
      return { steps, fit: () => {}, stage: STAGE(K) };
    },
  };

  // =================================================================================================
  // bars: a few numbers as bars, one per step.   params: {bars: [[label, value]], unit, max, title}
  Scenes.defs.bars = {
    free: true, follow: true,
    steps: (P) => (P.bars || []).map((_, i) => num(i)),
    build(K, P) {
      const tl = K.tl, pal = K.pal, bars = P.bars || [], n = bars.length, vals = bars.map((b) => parseFloat(b[1]) || 0), mx = +P.max || Math.max(1, ...vals);
      const BASE = K.H - 150, MAXH = BASE - 230, sp = Math.min(300, (K.W - 240) / Math.max(1, n)), bw = Math.min(170, sp * 0.56), X0 = (K.W - sp * n) / 2;
      const axis = svg("line", { x1: X0 - 20, y1: BASE, x2: X0 + sp * n + 20, y2: BASE, stroke: "#59636e", "stroke-width": 4, "stroke-linecap": "round" }, K.back), an = tl.node(axis, { o: 0 });
      const made = bars.map(([label, value], i) => { const x = X0 + i * sp + sp / 2, h = Math.max(6, (MAXH * vals[i]) / mx), g = svg("g", {}, K.main), last = i === n - 1;
        const r = A.rect(g, x - bw / 2, BASE - h, bw, h, { r: 8, fill: last ? pal.accent : "#2a323d", stroke: last ? pal.accent : NEUTRAL, sw: 3 });
        const vt = T(g, x, BASE - h - 30, value + (P.unit ? " " + P.unit : ""), { mono: true, size: 31, weight: 700, fill: WHITE, max: sp - 10 });
        wrap(label, Math.max(8, Math.floor((sp - 16) / 15.5)), 2).forEach((l, k) => T(g, x, BASE + 40 + k * 36, l, { size: FS, weight: 600, fill: SOFT, max: sp - 10 }));
        return { g, r, vt, h, x, n: tl.node(g, { o: 0 }) }; });
      const steps = made.map((b, i) => (t) => { if (i === 0) { t = K.title(t, P.title); an.to(t, 0.3, { o: 1 }, "out"); }
        b.n.to(t, 0.2, { o: 1 }, "out"); tl.add(t, 0.6, (p) => { b.r.setAttribute("height", (b.h * p).toFixed(1)); b.r.setAttribute("y", (BASE - b.h * p).toFixed(1)); b.vt.setAttribute("opacity", p > 0.85 ? 1 : 0); }, "out");
        tl.sound(t + 0.1, "pop", 0.7); K.grow(X0 - 30, BASE - MAXH - 70, b.x + sp / 2 + 10, BASE + 100); return t + 0.75; });
      return { steps, fit: () => {}, stage: STAGE(K) };
    },
  };

  // =================================================================================================
  // cards: a few statements as cards, one per step; afterwards some are ticked, crossed, locked, ringed or dimmed.
  //   params: {question: the line above, cards: [[text, sub-line]], numbered: "on", dim: [numbers: these arrive dimmed], ask: [numbers: these arrive dashed, with a
  //            question mark, until a mark resolves them], marks: [[number, ok | bad | lock | ring | dim | solid]] (step "marks"), title}
  Scenes.defs.cards = {
    free: true, follow: true,
    steps: (P) => (P.cards || []).map((_, i) => num(i)).concat(P.marks && P.marks.length ? ["marks"] : []),
    build(K, P) {
      const tl = K.tl, pal = K.pal, cards = (P.cards || []).slice(0, 8), n = cards.length, cols = n <= 3 ? n : n === 4 ? 2 : n <= 6 ? 3 : 4, nrows = Math.ceil(n / cols);
      const X0 = 80, AW = K.W - 160, gap = 34, cw = (AW - gap * (cols - 1)) / cols, chars = Math.max(12, Math.floor((cw - 56) / 15.6));
      const qLines = P.question ? wrap(P.question, 62, 2) : [], top = 146 + qLines.length * 46 + (qLines.length ? 26 : 0);
      const qg = svg("g", {}, K.main); qLines.forEach((l, k) => T(qg, K.W / 2, 164 + k * 46, l, { size: 35, weight: 800, fill: WHITE, max: K.W - 160 }));
      const qn = tl.node(qg, { o: 0, y: -14 });
      const lay = cards.map(([text, sub]) => { const tl_ = wrap(text, chars, 3), sl = sub ? wrap(sub, chars + 2, 2) : []; return { tl_, sl, h: 48 + tl_.length * 38 + (sl.length ? 10 + sl.length * 34 : 0) }; });
      const ch = Math.max(...lay.map((l) => l.h)), totalH = nrows * ch + (nrows - 1) * gap, y0 = top + Math.max(0, (K.H - 50 - top - totalH) / 2);
      const isDim = (i) => (P.dim || []).map(Number).includes(i + 1), asked = (i) => (P.ask || []).map(Number).includes(i + 1);
      const made = cards.map((c, i) => { const col = i % cols, row = Math.floor(i / cols), inRow = Math.min(cols, n - row * cols), x = X0 + (AW - (inRow * cw + (inRow - 1) * gap)) / 2 + col * (cw + gap), y = y0 + row * (ch + gap), g = svg("g", {}, K.main), L = lay[i];
        const frame = A.rect(g, x, y, cw, ch, { r: 16, fill: "#11151c", stroke: NEUTRAL, sw: 3.5, dash: asked(i) ? "10 8" : null });
        if (P.numbered === "on") { svg("circle", { cx: x + 2, cy: y + 2, r: 22, fill: pal.accent }, g); A.text(g, x + 2, y + 3, String(i + 1), { size: 26, fill: INK }); }
        const ty = y + (ch - (L.tl_.length * 38 + (L.sl.length ? 10 + L.sl.length * 34 : 0))) / 2 + 19;
        L.tl_.forEach((l, k) => T(g, x + cw / 2, ty + k * 38, l, { size: 30, weight: 700, fill: WHITE, max: cw - 36 }));
        L.sl.forEach((l, k) => T(g, x + cw / 2, ty + L.tl_.length * 38 + 10 + k * 34, l, { size: FS, weight: 500, fill: DIM, max: cw - 36 }));
        let qm = null; if (asked(i)) { qm = svg("g", {}, g); svg("circle", { cx: x + cw - 8, cy: y + 6, r: 27, fill: INK, stroke: AMBER, "stroke-width": 4, "stroke-dasharray": "7 6" }, qm); A.text(qm, x + cw - 8, y + 8, "?", { mono: false, size: 34, weight: 900, fill: AMBER }); }
        K.spot(String(i + 1), x + cw / 2, y + ch / 2);
        return { n: tl.node(g, { o: 0, y: 26 }), frame, qm, x, y, mk: null }; });
      const steps = made.map((m, i) => (t) => { if (i === 0) { t = K.title(t, P.title); if (qLines.length) { qn.to(t, 0.45, { o: 1, y: 0 }, "out"); t += 0.4; } }
        m.n.to(t, 0.42, { o: isDim(i) ? 0.45 : 1, y: 0 }, "out"); tl.sound(t + 0.08, "pop", 0.7); K.grow(X0 - 10, 130, X0 + AW + 10, m.y + ch + 30); return t + 0.55; });
      if (P.marks && P.marks.length) {
        const todo = P.marks.map(([k, kind]) => { const m = made[+k - 1]; if (!m) return null; let glyph = null;
          if (kind === "ok" || kind === "bad") glyph = mark(K, K.top, m.x + cw - 6, m.y + 6, kind, 1.1);
          else if (kind === "lock") { const g = svg("g", {}, K.top), lx = m.x + cw - 8, ly = m.y + 2; svg("circle", { cx: lx, cy: ly + 4, r: 27, fill: INK, stroke: AMBER, "stroke-width": 4 }, g);
            svg("path", { d: `M${lx - 8},${ly + 1} v-7 a8,8 0 0 1 16,0 v7`, fill: "none", stroke: AMBER, "stroke-width": 4, "stroke-linecap": "round" }, g); A.rect(g, lx - 12, ly + 1, 24, 18, { r: 4, fill: AMBER });
            const nn = tl.node(g, { o: 0, s: 0.5 }); glyph = { draw: (t) => { nn.to(t, 0.3, { o: 1, s: 1 }, "back"); tl.sound(t + 0.05, "pop", 0.7); return t + 0.3; } }; }
          return { m, kind, glyph }; }).filter(Boolean);
        steps.push((t) => { todo.forEach((x, j) => { const t0 = t + j * 0.35, col = COL(K, x.kind === "lock" ? "wait" : x.kind === "ring" ? "hl" : x.kind);
            if (x.glyph) x.glyph.draw(t0);
            if (x.kind === "dim") x.m.n.to(t0, 0.4, { o: 0.4 }, "inOut"); else { x.m.n.to(t0, 0.3, { o: 1 }, "out"); tl.at(t0, (p) => { x.m.frame.setAttribute("stroke", p && col ? col : NEUTRAL); x.m.frame.setAttribute("stroke-dasharray", p ? "none" : x.m.qm ? "10 8" : "none"); if (x.m.qm) x.m.qm.setAttribute("opacity", p ? 0 : 1); }); }
            if (x.kind === "ring") x.m.n.pulse(t0, 0.5, "s", 0.05); });
          return t + 0.5 + todo.length * 0.35; });
      }
      return { steps, fit: () => {}, stage: STAGE(K) };
    },
  };

  // =================================================================================================
  // blame: the lines of a file, each tagged with the commit that last changed it; "after" attributes them again (blame -w, -M, an ignored revision).
  //   params: {file, lines: [[id, text]], after: [ids, one per line], title}
  Scenes.defs.blame = {
    free: true, follow: true,
    steps: (P) => ["file", "blame"].concat(P.after && P.after.length ? ["after"] : []),
    build(K, P) {
      const tl = K.tl, pal = K.pal, lines = (P.lines || []).slice(0, 9), n = lines.length, after = P.after || [];
      const X = 110, W = K.W - 220, top = 150, RH = Math.min(62, (K.H - 70 - top - 72) / Math.max(1, n)), GW = 250;
      const card = box(K, K.main, X, top, W, 72 + n * RH + 14, { title: P.file || "file", stroke: "#59636e", slab: true });
      const first = Math.max(1, +P.from || 1), NX = Math.max(0, String(first + n - 1).length - 2) * FS * 0.6021;      // from=41: the first line number; three digits and more need room
      const ids = [], colOf = (id) => { if (!ids.includes(id)) ids.push(id); return [pal.accent, pal.accent2, "#c9d1d9", AMBER, "#79c0ff", "#d2a8ff"][ids.indexOf(id) % 6]; };
      lines.forEach(([id]) => colOf(id));
      const made = lines.map(([id, text], i) => { const y = top + 72 + i * RH, g = svg("g", {}, card.g);
        T(g, X + GW + 28 + NX, y + (RH - 8) / 2 + 1, String(first + i), { mono: true, size: FS, fill: "#59636e", weight: 500, anchor: "end" });
        T(g, X + GW + 52 + NX, y + (RH - 8) / 2 + 1, text, { mono: true, size: 29, fill: SOFT, weight: 500, anchor: "start", max: W - GW - 80 - NX });
        const chip = (cid, x) => { const cg = svg("g", {}, K.main), col = colOf(cid); A.rect(cg, X + 18, y + 3, GW - 36, RH - 14, { r: 8, fill: INK, stroke: col, sw: 3 }); T(cg, X + GW / 2, y + (RH - 8) / 2 + 1, cid, { mono: true, size: FS, fill: col, weight: 700, max: GW - 56 }); return tl.node(cg, { o: 0, x: -20 }); };
        const b = after[i] && after[i] !== id ? chip(after[i]) : null;
        return { a: chip(id), b, y }; });
      const steps = [(t) => { t = K.title(t, P.title); return card.show(t) + 0.2; },
        (t) => { made.forEach((m, i) => { m.a.to(t + i * 0.12, 0.3, { o: 1, x: 0 }, "out"); tl.sound(t + i * 0.12 + 0.03, "tick", 0.7); }); return t + 0.4 + n * 0.12; }];
      if (after.length) steps.push((t) => { made.forEach((m, i) => { if (m.b) { m.a.to(t + i * 0.1, 0.25, { o: 0 }, "in"); m.b.to(t + i * 0.1 + 0.15, 0.35, { o: 1, x: 0 }, "back"); tl.sound(t + i * 0.1 + 0.2, "pop", 0.6); } else m.a.to(t, 0.4, { o: 0.4 }, "inOut"); }); return t + 0.6 + n * 0.1; });
      return { steps, fit: () => {}, stage: STAGE(K) };
    },
  };

  // =================================================================================================
  // todo: the todo list of an interactive rebase, as Git writes it and as you leave it.
  //   params: {todo: [[verb, id, subject]], edit: [[verb, id, subject]] (the list after editing: new order, new verbs; a line left out is dropped),
  //            result: [ids or words: the commits the rebase will make], file, title}
  Scenes.defs.todo = {
    free: true, follow: true,
    steps: (P) => ["list"].concat(P.edit && P.edit.length ? ["edit"] : []).concat(P.result && P.result.length ? ["result"] : []),
    build(K, P) {
      const tl = K.tl, pal = K.pal, todo = (P.todo || []).slice(0, 8), edit = P.edit || [], n = todo.length, res = P.result || [];
      const X = 190, W = K.W - 380, top = 150, RH = Math.min(64, (K.H - 70 - top - 70 - (res.length ? 150 : 0)) / Math.max(1, n));
      const card = box(K, K.main, X, top, W, 70 + n * RH + 16, { title: P.file || "git-rebase-todo", stroke: pal.accent, color: pal.accent, slab: true });
      const VC = { pick: NEUTRAL, reword: AMBER, edit: AMBER, squash: pal.accent2, fixup: pal.accent2, drop: RED, exec: pal.accent, break: AMBER };
      const vcol = (v) => VC[String(v).split(" ")[0]] || NEUTRAL;      // "fixup -C" has the colour of "fixup"
      const VW = Math.max(A.mono_w("squash", 30), ...todo.concat(edit).map((r) => A.mono_w(r[0], 30))) + 26, IW = Math.max(...todo.map((r) => A.mono_w(r[1], 30))) + 30;
      const made = todo.map(([verb, id, subj], i) => { const y = top + 70 + i * RH + (RH - 8) / 2, g = svg("g", {}, K.main), k = edit.findIndex((e) => e[1] === id), nv = k < 0 ? "drop" : edit[k][0];
        const bar = A.rect(g, X + 14, -RH / 2 + 4, W - 28, RH - 8, { r: 8, fill: pal.accent2, o: 0 });
        const v1 = T(g, X + 34, 1, verb, { mono: true, size: 30, weight: 700, fill: vcol(verb), anchor: "start" });
        const v2 = T(g, X + 34, 1, nv, { mono: true, size: 30, weight: 700, fill: vcol(nv), anchor: "start" }); v2.setAttribute("opacity", 0);
        T(g, X + 34 + VW, 1, id, { mono: true, size: 30, weight: 500, fill: WHITE, anchor: "start" });
        T(g, X + 34 + VW + IW, 1, subj, { mono: false, size: 29, weight: 500, fill: SOFT, anchor: "start", max: W - 80 - VW - IW });
        const strike = svg("line", { x1: X + 34 + VW - 6, y1: 1, x2: X + W - 40, y2: 1, stroke: RED, "stroke-width": 3.5, opacity: 0 }, g);
        return { n: tl.node(g, { x: 0, y, o: 0 }), y, bar, v1, v2, strike, to: k, nv, verb }; });
      // the kept lines take their new places in order; dropped lines sink to the end
      const order = made.map((m, i) => [m.to < 0 ? 1e3 + i : m.to, i]).sort((a, b) => a[0] - b[0]).map((x) => x[1]);
      const rg = svg("g", {}, K.main), ry = top + 70 + n * RH + 16 + 84;
      if (res.length) { T(rg, X, ry, "the rebase will make", { size: FS, weight: 700, fill: DIM, anchor: "start" }); let cx = X + A.sans_w("the rebase will make", FS) + 60;
        res.forEach((r, i) => { if (i) svg("line", { x1: cx - 50, y1: ry, x2: cx - 34, y2: ry, stroke: NEUTRAL, "stroke-width": 5 }, rg); svg("circle", { cx: cx - 8, cy: ry, r: 22, fill: INK, stroke: pal.accent2, "stroke-width": 5 }, rg);
          const f = fit(r, FS, 260, true); A.text(rg, cx + 26, ry + 1, f.str, { size: f.size, fill: WHITE, anchor: "start", weight: 600 }); cx += 26 + f.w + 80; }); }
      const rn = tl.node(rg, { o: 0, y: 20 });
      const steps = [(t) => { t = K.title(t, P.title); t = card.show(t); made.forEach((m, i) => { m.n.to(t + i * 0.1, 0.3, { o: 1 }, "out"); tl.sound(t + i * 0.1 + 0.03, "tick", 0.7); }); return t + 0.3 + n * 0.1; }];
      if (edit.length) steps.push((t) => {
        made.forEach((m, i) => { if (m.nv !== m.verb) { tl.add(t + i * 0.08, 0.35, (p) => { m.v1.setAttribute("opacity", (1 - p).toFixed(3)); m.v2.setAttribute("opacity", p.toFixed(3)); m.bar.setAttribute("opacity", (0.22 * Math.sin(Math.PI * p)).toFixed(3)); }, "inOut"); tl.sound(t + i * 0.08 + 0.1, "pop", 0.55); } });
        t += 0.5 + n * 0.08;
        order.forEach((i, slot) => { const m = made[i], y = top + 70 + slot * RH + (RH - 8) / 2; if (Math.abs(y - m.y) > 1) { m.n.to(t, 0.7, { y }, "inOut"); } });
        if (order.some((i, slot) => i !== slot)) tl.sound(t + 0.05, "whoosh", 0.7);
        t += 0.8;
        made.forEach((m) => { if (m.to < 0) { m.n.to(t, 0.4, { o: 0.45 }, "inOut"); fadeTo(K, m.strike, t, 0, 1, 0.3); } });
        return t + 0.5; });
      if (res.length) steps.push((t) => { rn.to(t, 0.45, { o: 1, y: 0 }, "out"); tl.sound(t + 0.1, "pop", 0.8); K.grow(X - 10, top - 24, X + W + 24, ry + 50); return t + 0.6; });
      return { steps, fit: () => {}, stage: STAGE(K) };
    },
  };

  // =================================================================================================
  // push: the anatomy of a push.  A refspec maps a local name to a remote name; two gatekeepers judge the update; a lease compares three values.
  //   params: {src, dst, refspec, names: [your repository, the remote], local: id, remote: id (what the remote ref points at now), new: id,
  //            gates: [first gatekeeper, second gatekeeper], client: pass | stop, server: pass | stop | skip, notes: [what each gatekeeper says],
  //            lease: [expected, actual] (step "lease" is added), result: the last line, title}
  Scenes.defs.push = {
    free: true, follow: true,
    steps: (P) => ["refspec", "client", "server"].concat(P.lease && P.lease.length ? ["lease"] : []).concat(["result"]),
    build(K, P) {
      const tl = K.tl, pal = K.pal, nm = P.names || [], src = P.src || "main", dst = P.dst || src, gn = P.gates || [], notes = P.notes || [];
      const BW = 430, BH = 250, top = 170, LX = 60, RX = K.W - 60 - BW, cy = top + BH / 2 + 26;
      const lb = box(K, K.main, LX, top, BW, BH, { title: nm[0] || "your repository" }), rb = box(K, K.main, RX, top, BW, BH, { title: nm[1] || "the remote", stroke: pal.accent, color: pal.accent });
      const refRow = (b, name, id, col) => { const g = svg("g", {}, b.g); A.rect(g, b.x + 20, cy - 34, BW - 40, 68, { r: 10, fill: INK, stroke: col, sw: 3 });
        T(g, b.x + 38, cy + 1, name, { mono: true, size: 29, weight: 700, fill: WHITE, anchor: "start", max: BW - 80 - (id ? A.mono_w(id, FS) + 20 : 0) });
        const idt = id ? T(g, b.x + BW - 38, cy + 1, id, { mono: true, size: FS, weight: 500, fill: DIM, anchor: "end" }) : null; return { g, idt }; };
      refRow(lb, src, P.new || P.local, NEUTRAL); const rr = refRow(rb, dst, P.remote, pal.accent);
      const newId = P.new || P.local, idNew = newId ? T(rb.g, RX + BW - 38, cy + 1, newId, { mono: true, size: FS, weight: 700, fill: pal.accent2, anchor: "end" }) : null; if (idNew) idNew.setAttribute("opacity", 0);
      const WX0 = LX + BW + 26, WX1 = RX - 16, wire = svg("line", { x1: WX0, y1: cy, x2: WX1, y2: cy, stroke: LINE, "stroke-width": 7, "stroke-linecap": "round" }, K.back), wn = tl.node(wire, { o: 0 });
      const lit = svg("line", { x1: WX0, y1: cy, x2: WX0, y2: cy, stroke: pal.accent, "stroke-width": 7, "stroke-linecap": "round" }, K.back);
      const spec = pill(K.main, (WX0 + WX1) / 2, top - 6, P.refspec || `${src}:${dst}`, { mono: true, stroke: pal.accent2, r: 10, max: WX1 - WX0 + 200, weight: 600, color: WHITE, h: 54 }), sn = tl.node(spec.g, { o: 0, y: 14 });
      const GX = [WX0 + (WX1 - WX0) * 0.27, WX0 + (WX1 - WX0) * 0.73], GW = 150, GH = 150, verdict = [P.client || "pass", P.server || "pass"];
      // steps=refspec,result (or refspec,server,result): a gatekeeper whose step this video does not play is not drawn
      const plays = (name) => !K.names || !K.names.length || K.names.includes(name), shown = [plays("client"), plays("server")];
      const gates = [0, 1].map((i) => { const g = svg("g", {}, K.main), x = GX[i];
        const frame = svg("path", { d: `M${x - GW / 2},${cy + GH / 2} V${cy - GH / 2 + 14} a14,14 0 0 1 14,-14 H${x + GW / 2 - 14} a14,14 0 0 1 14,14 V${cy + GH / 2}`, fill: "#11151c", "fill-opacity": 0.7, stroke: NEUTRAL, "stroke-width": 6, "stroke-linecap": "round" }, g);
        wrap(gn[i] || (i ? "the server: hooks and rules" : "your Git: a fast-forward?"), 17, 2).forEach((l, k, all) => T(g, x, cy + GH / 2 + 40 + k * 34, l, { size: FS, weight: 700, fill: WHITE, max: (WX1 - WX0) / 2 - 16 }));
        const ng = svg("g", {}, g); if (notes[i]) wrap(notes[i], 20, 2).forEach((l, k) => T(ng, x, cy + GH / 2 + 118 + k * 34, l, { size: FS, weight: 600, italic: true, fill: COL(K, verdict[i]) || pal.accent2, max: (WX1 - WX0) / 2 - 10 }));
        return { n: tl.node(g, { o: 0, y: 20 }), frame, nn: tl.node(ng, { o: 0 }), mk: mark(K, K.top, x, cy - GH / 2 - 34, verdict[i]), x }; });
      const dotg = svg("g", {}, K.top), dot = svg("circle", { r: 16, fill: pal.accent2, filter: "url(#glow)" }, dotg), dn = tl.node(dotg, { x: WX0, y: cy, o: 0 });
      // the lease: what you expected the remote ref to be, what it is, and the verdict
      const lease = P.lease && P.lease.length ? P.lease : null, LY = top + BH + 196, lg = svg("g", {}, K.main), same = lease && lease[0] === lease[1];
      if (lease) { const cw = 420, x0 = K.W / 2 - cw * 1.5;
        [["expected", lease[0], NEUTRAL], ["actual", lease[1], NEUTRAL], ["verdict", same ? "equal: may overwrite" : "different: refused", same ? GREEN : RED]].forEach(([h, v, col], i) => {
          A.rect(lg, x0 + i * cw + 8, LY - 30, cw - 16, 118, { r: 12, fill: "#11151c", stroke: i === 2 ? col : "#59636e", sw: 3 });
          T(lg, x0 + i * cw + cw / 2, LY + 2, (P.lease_names || [])[i] || h, { size: FS, weight: 800, fill: DIM, max: cw - 40 }); T(lg, x0 + i * cw + cw / 2, LY + 52, v, { mono: i < 2, size: i < 2 ? 31 : FS, weight: 700, fill: i === 2 ? col : WHITE, max: cw - 36 }); }); }
      const ln = tl.node(lg, { o: 0, y: 20 });
      const stoppedAt = verdict[0] === "stop" ? 0 : verdict[1] === "stop" || (lease && !same) ? 1 : -1, ok = stoppedAt < 0;
      const resg = svg("g", {}, K.main), ry = lease ? LY + 140 : top + BH + 230; T(resg, K.W / 2, ry, P.result || (ok ? "the remote ref moves" : "the push is rejected"), { mono: !!P.result, size: 31, weight: 800, fill: ok ? GREEN : RED, max: K.W - 240 });
      const resn = tl.node(resg, { o: 0, y: 14 });
      let at = WX0;
      const go = (t, x) => { const from = at; at = x; dn.to(t, 0.5, { x }, "inOut"); tl.add(t, 0.5, (p) => lit.setAttribute("x2", lerp(from, x, p).toFixed(1)), "inOut"); tl.sound(t + 0.05, "whoosh", 0.5); return t + 0.55; };
      const judge = (t, i) => { const g = gates[i], col = COL(K, verdict[i]) || NEUTRAL; tl.at(t, (p) => g.frame.setAttribute("stroke", p ? col : NEUTRAL)); g.mk.draw(t); g.nn.to(t + 0.15, 0.3, { o: 1 }, "out");
        if (verdict[i] === "stop") { tl.at(t, (p) => { dot.setAttribute("fill", p ? RED : pal.accent2); lit.setAttribute("stroke", p ? RED : pal.accent); }); dn.pulse(t, 0.4, "x", -12); } return t + 0.6; };
      const S = {
        refspec: (t) => { t = K.title(t, P.title || "The anatomy of a push"); lb.show(t); rb.show(t + 0.15); wn.to(t + 0.3, 0.4, { o: 1 }, "out"); t += 0.7; sn.to(t, 0.4, { o: 1, y: 0 }, "out"); tl.sound(t + 0.05, "pop", 0.7);
          gates.forEach((g, i) => { if (shown[i]) g.n.to(t + 0.3 + i * 0.15, 0.4, { o: 1, y: 0 }, "out"); }); dn.to(t + 0.6, 0.3, { o: 1 }, "out"); K.grow(LX - 10, top - 60, RX + BW + 24, cy + GH / 2 + 160); return t + 1.0; },
        client: (t) => { t = go(t, GX[0]); return judge(t, 0); },
        server: (t) => { if (stoppedAt === 0) { gates[1].n.to(t, 0.35, { o: 0.32 }, "inOut"); return t + 0.35; } t = go(t, GX[1]); return judge(t, 1); },
        lease: (t) => { ln.to(t, 0.45, { o: 1, y: 0 }, "out"); tl.sound(t + 0.1, "pop", 0.8); K.grow(LX - 10, top - 60, RX + BW + 24, LY + 110); return t + 0.7; },
        result: (t) => { if (ok) { t = go(t, WX1); if (rr.idt && idNew) tl.add(t, 0.35, (p) => { rr.idt.setAttribute("opacity", (1 - p).toFixed(3)); idNew.setAttribute("opacity", p.toFixed(3)); }, "inOut"); dn.to(t + 0.1, 0.25, { o: 0 }, "in"); }
          resn.to(t + 0.2, 0.4, { o: 1, y: 0 }, "out"); tl.sound(t + 0.25, "pop", 0.9); K.grow(LX - 10, top - 60, RX + BW + 24, ry + 40); return t + 0.7; },
      };
      return { steps: Scenes.defs.push.steps(P).map((s) => S[s]), fit: () => {}, stage: STAGE(K) };
    },
  };

  // =================================================================================================
  // ladder: how far a commit has fallen, and what still brings it back at each rung.
  //   params: {rungs: [[state, what brings it back]] (default: reachable, only in the reflog, unreachable, pruned), commit: its ID, title}
  Scenes.defs.ladder = {
    free: true, follow: true,
    steps: (P) => (P.rungs && P.rungs.length ? P.rungs : [0, 1, 2, 3]).map((_, i) => num(i)),
    build(K, P) {
      const tl = K.tl, pal = K.pal;
      const rungs = P.rungs && P.rungs.length ? P.rungs : [["reachable", "a branch or a tag leads to it"], ["only in the reflog", "git reflog still lists it"], ["unreachable", "git fsck --lost-found can find it"], ["pruned", "gone from this repository"]];
      const n = rungs.length, X = 250, W = K.W - 500, top = 150, RH = Math.min(140, (K.H - 60 - top) / n - 16), CX = X + 86;
      svg("line", { x1: CX, y1: top + RH / 2, x2: CX, y2: top + (n - 1) * (RH + 16) + RH / 2, stroke: LINE, "stroke-width": 6, "stroke-dasharray": "3 12", "stroke-linecap": "round" }, K.back);
      const STY = [{ dash: null, o: 1 }, { dash: "8 7", o: 1 }, { dash: "8 7", o: 0.42 }, { dash: "2 8", o: 0.5, gone: true }];
      const made = rungs.map(([name, how], i) => { const y = top + i * (RH + 16), g = svg("g", {}, K.main), st = STY[Math.min(3, n === 4 ? i : Math.round((i * 3) / Math.max(1, n - 1)))];
        A.rect(g, X, y, W, RH, { r: 16, fill: "#11151c", stroke: "#59636e", sw: 3 });
        const c = svg("circle", { cx: CX, cy: y + RH / 2, r: 30, fill: st.gone ? "none" : INK, stroke: st.gone ? DIM : NEUTRAL, "stroke-width": 5, "stroke-dasharray": st.dash, opacity: st.o, "stroke-linecap": st.gone ? "round" : null }, g);
        T(g, X + 170, y + RH / 2 - (how ? 20 : -1), name, { size: 32, weight: 800, fill: i === n - 1 ? RED : WHITE, anchor: "start", max: W - 200 });
        if (how) T(g, X + 170, y + RH / 2 + 24, how, { size: FS, weight: 500, fill: i === n - 1 ? DIM : pal.accent2, anchor: "start", max: W - 200 });
        K.spot(name, X + W / 2, y + RH / 2);
        return { n: tl.node(g, { o: 0.0, x: -30 }), y: y + RH / 2 }; });
      const tag = P.commit ? pill(K.top, 0, 0, P.commit, { mono: true, stroke: pal.accent2, r: 8, h: 44, weight: 600, color: WHITE }) : null, tn = tag ? tl.node(tag.g, { x: X - 30 - (tag.w / 2), y: made[0].y, o: 0 }) : null;
      const steps = made.map((m, i) => (t) => { if (i === 0) t = K.title(t, P.title || "How far can a commit fall?");
        m.n.to(t, 0.4, { o: 1, x: 0 }, "out"); tl.sound(t + 0.06, "pop", 0.7); K.grow(X - (tag ? tag.w + 50 : 10), top - 20, X + W + 10, m.y + RH / 2 + 20);
        if (tn) { if (i === 0) tn.to(t + 0.2, 0.3, { o: 1 }, "out"); else tn.to(t, 0.6, { y: m.y, o: i === n - 1 ? 0.45 : 1 }, "inOut"); }
        return t + 0.7; });
      return { steps, fit: () => {}, stage: STAGE(K) };
    },
  };

  // =================================================================================================
  // run: one workflow run in detail.  Nothing is drawn that the tag does not name.
  //   params: {event, ref, sha, jobs: [[name, "need+need"]], cols: [[job names of column 1], ...] (worked out by the planner), matrix: [job, "a+b+c"],
  //            token: "contents:read+id-token:write", artifact: [from job, to job, name], cache: [job, name], env: [job, environment, reviewer],
  //            concurrency: the group (an older run of the group is cancelled), title}
  Scenes.defs.run = {
    free: true, follow: true,
    steps: (P) => ["event", "jobs"].concat(P.matrix ? ["matrix"] : [], P.token ? ["token"] : [], P.artifact || P.cache ? ["data"] : [], P.env ? ["gate"] : [], P.concurrency ? ["cancel"] : []),
    build(K, P) {
      const tl = K.tl, pal = K.pal, jobs = P.jobs || [], cols = P.cols || [jobs.map((j) => j[0])], nc = cols.length;
      const top = 150, EH = 92, JY = top + EH + (P.concurrency ? 150 : 96), JAREA = K.H - JY - 60, X0 = 70, AW = K.W - 140, colW = AW / nc, JW = Math.min(360, colW - 110), JH = 96;
      // the event, and what the run is run on
      const eg = svg("g", {}, K.main); let ex = X0;
      const ep = pill(eg, 0, 0, P.event || "push", { mono: true, fill: pal.accent, stroke: pal.accent, color: INK, r: 10, h: 54, weight: 700 }); ep.g.setAttribute("transform", `translate(${ex + ep.w / 2},${top + EH / 2})`); ex += ep.w + 26;
      for (const [k, v] of [["ref", P.ref], ["commit", P.sha]]) if (v) { T(eg, ex, top + EH / 2 + 1, k, { size: FS, weight: 700, fill: DIM, anchor: "start" }); ex += A.sans_w(k, FS) + 14; const f = T(eg, ex, top + EH / 2 + 1, v, { mono: true, size: 29, weight: 600, fill: WHITE, anchor: "start", max: 560 }); ex += f._w + 34; }
      const en = tl.node(eg, { o: 0, x: -24 });
      const pos = {};
      const legsOf = (nm) => (P.matrix && P.matrix[0] === nm ? String(P.matrix[1]).split("+").filter(Boolean).slice(0, 4) : []);
      const extra = (nm) => (legsOf(nm).length ? 22 + 52 * Math.ceil(legsOf(nm).length / 2) : 0) + (P.cache && P.cache[0] === nm ? 74 : 0) + (P.env && P.env[0] === nm ? (P.env[2] ? 92 : 54) : 0);
      cols.forEach((names, c) => { const hs = names.map((nm) => JH + extra(nm)), total = hs.reduce((a, b) => a + b, 0), gap = Math.min(64, Math.max(14, (JAREA - total) / Math.max(1, names.length)));
        let y = JY + Math.max(0, (JAREA - total - gap * (names.length - 1)) / 2);
        names.forEach((nm, k) => { pos[nm] = { x: X0 + c * colW + (colW - JW) / 2, y, c }; y += hs[k] + gap; }); });
      const made = {};
      for (const [nm] of jobs) { const q = pos[nm]; if (!q) continue; const g = svg("g", {}, K.main);
        const frame = A.rect(g, q.x, q.y, JW, JH, { r: 14, fill: "#11151c", stroke: pal.accent, sw: 3.5 });
        T(g, q.x + 22, q.y + JH / 2 + 1, nm, { mono: true, size: 30, weight: 700, fill: WHITE, anchor: "start", max: JW - 44 });
        K.spot(nm, q.x + JW / 2, q.y + JH / 2);
        made[nm] = { n: tl.node(g, { o: 0, y: 20 }), frame, q, g }; }
      const needs = []; for (const [nm, nd] of jobs) for (const d of String(nd || "").split("+").filter(Boolean)) if (pos[d] && pos[nm]) needs.push(K.arrow(K.back, pos[d].x + JW + 6, pos[d].y + JH / 2, pos[nm].x - 12, pos[nm].y + JH / 2, { stroke: NEUTRAL, sw: 4.5 }));
      // matrix: one job becomes several
      const mx = P.matrix && pos[P.matrix[0]] ? P.matrix : null, mg = svg("g", {}, K.main);
      if (mx) { const q = pos[mx[0]], legs = String(mx[1]).split("+").filter(Boolean).slice(0, 4); legs.forEach((l, i) => { const p = pill(mg, 0, 0, l, { mono: true, stroke: pal.accent2, r: 8, h: 44, size: FS, weight: 600, color: WHITE, max: JW / Math.min(2, legs.length) - 16 });
          const perRow = legs.length > 1 ? 2 : 1, col = i % perRow, row = Math.floor(i / perRow), sw = JW / perRow; p.g.setAttribute("transform", `translate(${q.x + sw * col + sw / 2},${q.y + JH + 38 + row * 52})`); }); }
      const mn = tl.node(mg, { o: 0, y: -14 });
      // the token of the run and what it may do
      const tg = svg("g", {}, K.main); if (P.token) { T(tg, K.W - X0, top + 26, "GITHUB_TOKEN", { mono: true, size: FS, weight: 700, fill: AMBER, anchor: "end" });
        T(tg, K.W - X0, top + 66, String(P.token).split("+").join("   "), { mono: true, size: FS, weight: 500, fill: SOFT, anchor: "end", max: K.W - ex - 140 }); }
      const tn = tl.node(tg, { o: 0, x: 24 });
      // data between jobs: an artifact travels from one job to another; a cache is restored and saved
      const dg = svg("g", {}, K.top); let art = null;
      if (P.artifact && pos[P.artifact[0]] && pos[P.artifact[1]]) { const a = pos[P.artifact[0]], b = pos[P.artifact[1]], y = Math.min(a.y, b.y) - 46, x0 = a.x + JW / 2, x1 = b.x + JW / 2;
        art = K.arrow(K.back, x0, a.y - 8, x1, b.y - 12, { d: `M${x0},${a.y - 8} C${x0},${y - 30} ${x1},${y - 30} ${x1},${b.y - 12}`, stroke: pal.accent2, sw: 4 });
        const p = pill(dg, (x0 + x1) / 2, y - 24, P.artifact[2] || "artifact", { mono: true, stroke: pal.accent2, r: 8, h: 44, size: FS, weight: 600, color: WHITE, max: Math.abs(x1 - x0) + 60 }); }
      if (P.cache && pos[P.cache[0]]) { const q = pos[P.cache[0]], lg = legsOf(P.cache[0]).length, cxx = q.x + 44, cyy = q.y + JH + (lg ? 22 + 52 * Math.ceil(lg / 2) : 0) + 40;
        svg("path", { d: `M${cxx - 30},${cyy - 10} a30,8 0 0 1 60,0 v22 a30,8 0 0 1 -60,0 z M${cxx - 30},${cyy - 10} a30,8 0 0 0 60,0`, fill: INK, stroke: AMBER, "stroke-width": 3.5 }, dg);
        T(dg, cxx + 46, cyy + 3, "cache: " + (P.cache[1] || ""), { mono: true, size: FS, weight: 600, fill: AMBER, anchor: "start", max: JW - 90 }); }
      const dnn = tl.node(dg, { o: 0 });
      // an environment with a reviewer: the job waits at a gate
      const gg = svg("g", {}, K.top); let gmk = null, gframe = null;
      if (P.env && pos[P.env[0]]) { const q = pos[P.env[0]], gx = q.x - 62;
        gframe = svg("path", { d: `M${gx - 30},${q.y + JH + 8} V${q.y - 8} a12,12 0 0 1 12,-12 H${gx + 18} a12,12 0 0 1 12,12 V${q.y + JH + 8}`, fill: INK, stroke: AMBER, "stroke-width": 5.5, "stroke-linecap": "round" }, gg);
        const ey = q.y + JH + (legsOf(P.env[0]).length ? 22 + 52 * Math.ceil(legsOf(P.env[0]).length / 2) : 0) + (P.cache && P.cache[0] === P.env[0] ? 74 : 0);
        T(gg, q.x + JW / 2, ey + 34, "environment: " + (P.env[1] || ""), { mono: true, size: FS, weight: 600, fill: AMBER, max: colW - 10 });
        if (P.env[2]) T(gg, q.x + JW / 2, ey + 72, "waits for " + P.env[2], { size: FS, weight: 600, fill: SOFT, italic: true, max: colW - 10 });
        gmk = mark(K, K.top, gx, q.y + JH + 38, "pass", 0.85); }
      const gn = tl.node(gg, { o: 0 });
      // concurrency: the older run of the same group is cancelled
      const cg = svg("g", {}, K.main); if (P.concurrency) { const y = top + EH + 38; A.rect(cg, X0, y - 30, AW, 64, { r: 12, fill: "#11151c", stroke: "#59636e", sw: 3, dash: "9 8" });
        T(cg, X0 + 24, y + 2, "an older run of group " + P.concurrency, { size: FS, weight: 600, fill: DIM, anchor: "start", max: AW - 260 });
        const p = pill(cg, X0 + AW - 110, y + 2, "cancelled", { stroke: RED, size: FS, h: 44, color: RED }); }
      const cn = tl.node(cg, { o: 0, y: -12 });
      const S = {
        event: (t) => { t = K.title(t, P.title); en.to(t, 0.45, { o: 1, x: 0 }, "out"); tl.sound(t + 0.1, "pop", 0.8); K.grow(X0 - 10, top - 10, Math.max(ex, 700), top + EH + 10); return t + 0.6; },
        jobs: (t) => { cols.forEach((names, c) => { needs.forEach((a) => 0); names.forEach((nm, k) => { const m = made[nm]; if (m) { m.n.to(t + c * 0.5 + k * 0.12, 0.4, { o: 1, y: 0 }, "out"); tl.sound(t + c * 0.5 + k * 0.12 + 0.05, "pop", 0.65); K.grow(m.q.x - 80, top - 10, m.q.x + JW + 20, m.q.y + JH + 30); } }); });
          needs.forEach((a, i) => a.draw(t + 0.4 + i * 0.1, 0.4)); return t + 0.6 + nc * 0.5; },
        matrix: (t) => { if (mx) { const m = made[mx[0]]; m.n.pulse(t, 0.4, "y", -8); mn.to(t + 0.2, 0.4, { o: 1, y: 0 }, "out"); tl.sound(t + 0.25, "pop", 0.8); K.grow(m.q.x - 10, m.q.y, m.q.x + JW + 10, m.q.y + JH + 120); } return t + 0.7; },
        token: (t) => { tn.to(t, 0.45, { o: 1, x: 0 }, "out"); tl.sound(t + 0.1, "pop", 0.7); K.grow(K.W - X0 - 500, top - 10, K.W - X0 + 10, top + 90); return t + 0.6; },
        data: (t) => { dnn.to(t, 0.4, { o: 1 }, "out"); if (art) art.draw(t + 0.1, 0.6); tl.sound(t + 0.15, "whoosh", 0.6); K.grow(X0, JY - 110, K.W - X0, K.H - 60); return t + 0.8; },
        gate: (t) => { gn.to(t, 0.4, { o: 1 }, "out"); tl.sound(t + 0.1, "pop", 0.8); t += 1.0; if (gmk) { gmk.draw(t); tl.at(t, (p) => gframe.setAttribute("stroke", p ? GREEN : AMBER)); } return t + 0.6; },
        cancel: (t) => { cn.to(t, 0.45, { o: 1, y: 0 }, "out"); tl.sound(t + 0.1, "pop", 0.8); return t + 0.6; },
      };
      return { steps: Scenes.defs.run.steps(P).map((s) => S[s]), fit: () => {}, stage: STAGE(K) };
    },
  };
})();
