'use strict';
// Disables a better-sqlite3 native binary that crashes on this machine
// (Windows access violation 0xC0000005), so 9router falls back to
// node:sqlite / sql.js instead of crash-looping. Safe to run on every launch.
const fs = require('fs');
const path = require('path');
const { spawnSync } = require('child_process');

const root = path.resolve(__dirname, '..');
const runtimes = [
  path.join(root, 'data', 'runtime'),
  path.join(root, 'home', 'AppData', 'Roaming', '9router', 'runtime'),
  path.join(root, 'home', '.9router', 'runtime'),
];
const TAG = 'disabled-by-9router-portable';
// 9router only checks the file's magic bytes before deciding to reinstall,
// so we leave a harmless stub with a valid-looking header in place.
const STUB = process.platform === 'win32' ? Buffer.from('MZ' + TAG)
  : process.platform === 'darwin' ? Buffer.concat([Buffer.from([0xcf, 0xfa, 0xed, 0xfe]), Buffer.from(TAG)])
  : Buffer.concat([Buffer.from([0x7f, 0x45, 0x4c, 0x46]), Buffer.from(TAG)]);

function binaries(bs) {
  const out = [path.join(bs, 'build', 'Release', 'better_sqlite3.node')];
  const pre = path.join(bs, 'prebuilds');
  if (fs.existsSync(pre)) {
    for (const f of fs.readdirSync(pre)) {
      if (f.endsWith('.node') && f.includes(process.platform) && f.includes(process.arch)) out.push(path.join(pre, f));
    }
  }
  return out.filter((f) => fs.existsSync(f));
}
const isStub = (f) => { try { return fs.readFileSync(f).includes(TAG); } catch { return false; } };

for (const rt of runtimes) {
  const bs = path.join(rt, 'node_modules', 'better-sqlite3');
  if (!fs.existsSync(bs)) continue;
  const bins = binaries(bs);
  if (bins.length === 0 || bins.every(isStub)) continue;

  const test = "const D=require(process.argv[1]);const d=new D(':memory:');d.prepare('select 1').get();d.close()";
  const r = spawnSync(process.execPath, ['-e', test, bs], { timeout: 20000, stdio: 'ignore' });
  if (r.status === 0) continue;

  console.log(`[guard] better-sqlite3 failed to load here (exit ${r.status ?? r.signal}); disabling it in ${rt}`);
  for (const f of bins) {
    if (isStub(f)) continue;
    try { fs.rmSync(f + '.off', { force: true }); fs.renameSync(f, f + '.off'); fs.writeFileSync(f, STUB); }
    catch (e) { console.log(`[guard] could not disable ${f}: ${e.message}`); }
  }
}
