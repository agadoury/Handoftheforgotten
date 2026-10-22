// Runs the pilot (docs/pilot/index.html) in headless Chromium, with Three.js served from
// node_modules instead of the CDN, so it works offline and from any network.
//
//   cd tools/pilot && npm install            (once; or use a global Playwright)
//   node pilot.mjs shot <out_dir> [poses.json] [--align=-1] [--lights=2.4,1.15] [--prefix=pilot]
//   node pilot.mjs dump <out.json>
//
// "shot" renders the same camera poses as debug/shot.tscn (default debug/shot_poses.json), with the
// UI hidden, for side-by-side comparison. "dump" writes the pilot's tree, rock and cloud placements
// and sample terrain heights (how data/island.json and tests/fixtures/pilot_heights.json were made).
import { readFileSync, writeFileSync, mkdirSync, existsSync } from 'node:fs';
import { createRequire } from 'node:module';
import path from 'node:path';

const here = path.dirname(new URL(import.meta.url).pathname);
const root = path.resolve(here, '../..');
const localRequire = createRequire(path.join(here, 'package.json'));

function requireAnywhere(name) {
  try { return localRequire(name); } catch { /* fall through to a global install */ }
  const globalRoot = process.env.NODE_GLOBAL_MODULES || '/opt/node22/lib/node_modules/';
  return createRequire(globalRoot)(name);
}
function threeModulePath() {
  const local = path.join(here, 'node_modules/three/build/three.module.min.js');
  if (existsSync(local)) return local;
  if (process.env.THREE_MODULE && existsSync(process.env.THREE_MODULE)) return process.env.THREE_MODULE;
  throw new Error('Three.js r169 not found: run "npm install" in tools/pilot, or set THREE_MODULE');
}

const { chromium } = requireAnywhere('playwright');
const [mode, out, ...rest] = process.argv.slice(2);
const flags = Object.fromEntries(rest.filter((a) => a.startsWith('--')).map((a) => a.slice(2).split('=')));
const posesPath = rest.find((a) => !a.startsWith('--')) || path.join(root, 'debug/shot_poses.json');

let html = readFileSync(path.join(root, 'docs/pilot/index.html'), 'utf8');
const hook = `
window.__pilot = {
  trees, items, VILLAGES, clouds, heightAt, groundAt,
  setAlign: (a) => { playerAlign = a; },
  setLights: (s, h) => { sun.intensity = s; hemi.intensity = h; },
  pose: (p) => { cam.fly = null; cam.vx = cam.vz = 0; cam.tx = p.x; cam.tz = p.z; cam.ty = groundAt(p.x, p.z);
    cam.yaw = cam.dYaw = p.yaw; cam.pitch = cam.dPitch = p.pitch; cam.dist = cam.dDist = p.distance; applyCamera(); },
};
`;
const end = html.lastIndexOf('</script>');
html = html.slice(0, end) + hook + html.slice(end);
html = html.replace('<style>', '<style>body * { visibility: hidden !important; } #world { visibility: visible !important; }\n');
const threeJs = readFileSync(threeModulePath());

const browser = await chromium.launch({ args: ['--use-angle=swiftshader', '--enable-unsafe-swiftshader', '--ignore-gpu-blocklist'] });
const page = await browser.newPage({ viewport: { width: 1280, height: 720 } });
page.on('pageerror', (e) => console.error('pilot error:', e.message));
await page.route('**/*', (route) => {
  const url = route.request().url();
  if (url.startsWith('http://pilot.local/')) return route.fulfill({ body: html, contentType: 'text/html' });
  if (url.includes('three.module.min.js')) return route.fulfill({ body: threeJs, contentType: 'text/javascript' });
  return route.abort();
});
await page.goto('http://pilot.local/index.html');
await page.waitForFunction(() => !!window.__pilot, null, { timeout: 60000 });

if (mode === 'dump') {
  const data = await page.evaluate(() => {
    const P = window.__pilot;
    const r = (v, n = 4) => Math.round(v * 10 ** n) / 10 ** n;
    const heights = [];
    for (let k = 0; k < 400; k++) {
      const x = -150 + ((k * 37) % 300) + 0.37, z = -150 + ((k * 53) % 300) + 0.71;
      heights.push([r(x), r(z), r(P.heightAt(x, z), 6)]);
    }
    return {
      trees: P.trees.map((t) => [r(t.pos.x), r(t.pos.z), t.pine ? 1 : 0, r(t.s), r(t.rot)]),
      rocks: P.items.filter((i) => i.kind === 'rock').map((i) => [r(i.pos.x), r(i.pos.z), r(i.extra.size), r(i.mesh.rotation.y)]),
      clouds: P.clouds.map((g) => ({ x: r(g.position.x), y: r(g.position.y), z: r(g.position.z), speed: r(g.userData.speed),
        blobs: g.children.map((m) => [r(m.position.x), r(m.position.y), r(m.position.z), r(m.geometry.parameters.radius)]) })),
      heights,
    };
  });
  writeFileSync(out, JSON.stringify(data));
  console.log(`wrote ${out}: ${data.trees.length} trees, ${data.rocks.length} rocks, ${data.clouds.length} clouds`);
} else if (mode === 'shot') {
  mkdirSync(out, { recursive: true });
  const poses = JSON.parse(readFileSync(posesPath, 'utf8')).poses;
  if (flags.align) await page.evaluate((a) => window.__pilot.setAlign(a), Number(flags.align));
  if (flags.lights) await page.evaluate((l) => window.__pilot.setLights(l[0], l[1]), flags.lights.split(',').map(Number));
  const prefix = flags.prefix || 'pilot';
  for (const p of poses) {
    await page.evaluate((p) => window.__pilot.pose(p), p);
    await page.waitForTimeout(1500); // let the sky blend and shadows settle
    await page.evaluate((p) => window.__pilot.pose(p), p);
    await page.waitForTimeout(300);
    const file = path.join(out, `${prefix}_${p.name}.png`);
    await page.screenshot({ path: file });
    console.log('shot', file);
  }
} else {
  console.error('usage: node pilot.mjs shot <out_dir> [poses.json] [--align=-1] [--lights=2.4,1.15] [--prefix=pilot] | dump <out.json>');
  process.exit(1);
}
await browser.close();
