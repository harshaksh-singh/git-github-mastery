// Twig: the course mascot.  A commit dot with eyes and a small forked twig (a branch) growing from its head.
// Original to this course; built from circles and a few paths.  Drawn as sprites once per part palette and
// laid over the video by ffmpeg, so it costs nothing per frame in Chrome.
//
// Sprite sheet layout per pose (30 fps):  frames 0..59 eyes open (one breathing loop), 60..119 eyes half shut,
// 120..179 eyes shut, 180..191 the hop that plays when the pose changes.
(function () {
  "use strict";
  const A = window.A, svg = A.svg;
  const W = 170, H = 200, CX = 85, CY = 142, R = 44;
  const POSES = {
    curious:   { look: [-4, -3], eye: [1, 1], mouth: "smile", tilt: -4, twig: 8, bob: 3 },
    thinking:  { look: [-5, -7], eye: [1, 1], mouth: "side", tilt: 6, twig: -6, bob: 2, prop: "?" },
    surprised: { look: [-2, -2], eye: [1.25, 1.3], mouth: "o", tilt: 0, twig: 0, bob: 2, prop: "!", stretch: 0.04 },
    worried:   { look: [-4, 1], eye: [1, 0.95], mouth: "wavy", tilt: -3, twig: 22, bob: 1.5, brow: 1, prop: "drop", stretch: -0.03 },
    celebrate: { look: [0, -2], eye: [1, 1], mouth: "grin", tilt: 0, twig: 0, bob: 0, jump: 20, happy: 1, prop: "spark" },
  };
  const LOOP = 60, HOP = 12;
  const Mascot = (window.Mascot = { W, H, POSES, LOOP, HOP, FRAMES: LOOP * 3 + HOP });

  Mascot.draw = function (root, poseName, frame, pal) {
    const P = POSES[poseName] || POSES.curious;
    root.innerHTML = "";
    const eyes = frame < LOOP ? 1 : frame < 2 * LOOP ? 0.45 : frame < 3 * LOOP ? 0.08 : 1;
    const hop = frame >= 3 * LOOP ? (frame - 3 * LOOP) / (HOP - 1) : null;
    const ph = hop == null ? (frame % LOOP) / LOOP : 0;
    const s2 = Math.sin(2 * Math.PI * ph);
    let dy = -P.bob * s2, sy = 1 + 0.018 * s2 + (P.stretch || 0), twigSwing = 3 * Math.sin(2 * Math.PI * ph + 1);
    if (P.jump) { const j = Math.abs(Math.sin(2 * Math.PI * ph)); dy = -P.jump * j; sy = 1 + 0.07 * j - 0.05 * (1 - j); twigSwing = 14 * Math.cos(4 * Math.PI * ph); }
    if (hop != null) { const j = Math.sin(Math.PI * hop); dy = -24 * j; sy = 1 + 0.1 * j - 0.08 * (hop < 0.15 || hop > 0.9 ? 1 : 0); twigSwing = -16 * Math.cos(Math.PI * hop); }
    const sx = 1 / Math.sqrt(sy);
    const INK = "#12151c", BODY = "#f4ecdf", SHADE = "#d9cdb9";
    // ground shadow (stays on the ground while the body bobs)
    svg("ellipse", { cx: CX, cy: CY + R + 7, rx: 38 * (1 + dy / 90), ry: 7, fill: "#000", opacity: 0.35 + dy / 120 }, root);
    const g = svg("g", { transform: `translate(${CX},${CY + R + dy}) rotate(${P.tilt}) scale(${sx.toFixed(4)},${sy.toFixed(4)}) translate(0,${-R})` }, root);
    // twig
    const tw = svg("g", { transform: `translate(2,${-R + 4}) rotate(${P.twig + twigSwing})` }, g);
    svg("path", { d: "M0,0 C-2,-14 4,-22 6,-34 M3,-18 C-6,-22 -12,-22 -16,-28", fill: "none", stroke: INK, "stroke-width": 9, "stroke-linecap": "round" }, tw);
    svg("path", { d: "M0,0 C-2,-14 4,-22 6,-34 M3,-18 C-6,-22 -12,-22 -16,-28", fill: "none", stroke: pal.accent, "stroke-width": 5, "stroke-linecap": "round" }, tw);
    svg("circle", { cx: 7, cy: -40, r: 10, fill: pal.accent, stroke: INK, "stroke-width": 3 }, tw);
    svg("circle", { cx: -19, cy: -32, r: 7, fill: pal.accent2, stroke: INK, "stroke-width": 3 }, tw);
    // feet
    svg("ellipse", { cx: -18, cy: R - 1, rx: 12, ry: 7, fill: SHADE, stroke: INK, "stroke-width": 3 }, g);
    svg("ellipse", { cx: 18, cy: R - 1, rx: 12, ry: 7, fill: SHADE, stroke: INK, "stroke-width": 3 }, g);
    // body: a commit dot
    svg("circle", { r: R, fill: BODY, stroke: INK, "stroke-width": 4 }, g);
    svg("path", { d: `M${-R + 9},10 A${R - 8},${R - 8} 0 0 0 ${R - 16},30`, fill: "none", stroke: SHADE, "stroke-width": 7, "stroke-linecap": "round", opacity: 0.8 }, g);
    svg("circle", { r: R - 7, fill: "none", stroke: pal.accent, "stroke-width": 3, opacity: 0.55 }, g);
    // face
    const [lx, ly] = P.look, ey = -8 + ly;
    for (const sgn of [-1, 1]) {
      const ex = sgn * 15 + lx;
      if (P.happy && eyes > 0.9) svg("path", { d: `M${ex - 8},${ey + 3} q8,-12 16,0`, fill: "none", stroke: INK, "stroke-width": 4.5, "stroke-linecap": "round" }, g);
      else {
        svg("ellipse", { cx: ex, cy: ey, rx: 7.5 * P.eye[0], ry: Math.max(1.2, 10.5 * P.eye[1] * eyes), fill: INK }, g);
        if (eyes > 0.9) svg("circle", { cx: ex + 2.5, cy: ey - 4, r: 2.6, fill: "#fff" }, g);
      }
      if (P.brow) svg("path", { d: `M${ex - sgn * 9},${ey - 19} l${sgn * 15},${-6}`, stroke: INK, "stroke-width": 3.5, "stroke-linecap": "round" }, g);
      svg("ellipse", { cx: sgn * 27 + lx * 0.5, cy: 9 + ly * 0.5, rx: 6.5, ry: 4, fill: pal.accent, opacity: 0.45 }, g);
    }
    const mx = lx * 0.8, my = 13 + ly * 0.6;
    const mouths = {
      smile: `M${mx - 8},${my} q8,8 16,0`, side: `M${mx - 2},${my + 2} q6,2 11,-2`, wavy: `M${mx - 10},${my + 3} q5,-6 10,0 t10,0`,
      grin: `M${mx - 11},${my - 2} q11,15 22,0 z`,
    };
    if (P.mouth === "o") svg("ellipse", { cx: mx, cy: my + 3, rx: 5, ry: 6.5, fill: INK }, g);
    else svg("path", { d: mouths[P.mouth], fill: P.mouth === "grin" ? INK : "none", stroke: INK, "stroke-width": 3.5, "stroke-linecap": "round", "stroke-linejoin": "round" }, g);
    // props float beside the head and do not squash with the body
    const px = CX + 50, py = CY - 62 + dy * 0.6 - 2 * Math.sin(2 * Math.PI * ph + 2);
    const prop = hop != null && hop < 0.35 ? null : P.prop;
    if (prop === "?" || prop === "!") {
      svg("text", { x: px, y: py, "text-anchor": "middle", "font-family": A.SANS, "font-size": 46, "font-weight": 900, fill: pal.accent, stroke: INK, "stroke-width": 7, "paint-order": "stroke", "stroke-linejoin": "round" }, root, prop);
    } else if (prop === "drop") {
      const y = CY - 50 + dy + ((ph * 26) % 26);
      svg("path", { d: `M${CX + 44},${y} q-9,14 0,19 q9,-5 0,-19 z`, fill: "#9fd3ff", stroke: INK, "stroke-width": 3, opacity: 1 - ph * 0.6 }, root);
    } else if (prop === "spark") {
      [[-58, -78, 0], [56, -86, 0.33], [66, -20, 0.66], [-64, -14, 0.5]].forEach(([x, y, o], i) => {
        const p = (ph * 2 + o) % 1, s = 0.5 + 0.8 * Math.sin(Math.PI * p), c = i % 2 ? pal.accent2 : pal.accent;
        svg("path", { d: "M0,-11 L3,-3 L11,0 L3,3 L0,11 L-3,3 L-11,0 L-3,-3 Z", fill: c, stroke: INK, "stroke-width": 2, transform: `translate(${CX + x},${CY + y - 14 * p}) scale(${s.toFixed(3)}) rotate(${(p * 90).toFixed(1)})`, opacity: Math.sin(Math.PI * p).toFixed(3) }, root);
      });
    }
  };

  // sprite page: window.__anim.seek(i / 30) draws frame i
  Mascot.page = function (cfg) {
    document.body.style.cssText = "margin:0;background:transparent;overflow:hidden";
    const root = svg("svg", { width: W, height: H, viewBox: `0 0 ${W} ${H}` }, document.body);
    window.__anim = { duration: (Mascot.FRAMES - 1) / 30, sfx: [], info: { frames: Mascot.FRAMES },
      seek: (t) => Mascot.draw(root, cfg.pose, Math.round(t * 30), cfg.palette) };
    window.__anim.seek(0);
  };
})();
