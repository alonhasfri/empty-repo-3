// Tip 24: save edge cases — progress survives reloads, settings changes and a corrupted save
require('fs').mkdirSync(require('path').join(__dirname, 'shots'), { recursive: true });
const { chromium } = require('playwright');
const fs = require('fs');
(async () => {
  const b = await chromium.launch({ args: ['--use-gl=swiftshader', '--enable-webgl', '--ignore-gpu-blocklist'] });
  const ctx = await b.newContext({ viewport: { width: 420, height: 820 } });
  await ctx.route('**/three.min.js', r => r.fulfill({ body: fs.readFileSync(__dirname + '/three.min.js'), contentType: 'application/javascript' }));
  const p = await ctx.newPage();
  const errs = []; p.on('pageerror', e => errs.push('PAGEERR ' + e.message));
  const url = (process.env.GAME_URL || 'file://' + require('path').resolve(__dirname, '../lose-a-brain-cell-web.html'));
  const ok = (name, cond) => console.log((cond ? 'PASS ' : 'FAIL ') + name);
  await p.goto(url); await p.waitForTimeout(2600);
  await p.evaluate(() => { closePanel(); S.tutDone = { Gain: 1 }; S.done.hookGain = 1; startPath('Gain'); S.cells = 99e9; S.coins = 1234; S.job = 'doctor'; S.ownedGlasses = ['Reading Glasses']; S.wearing = 'Reading Glasses'; save(); _bk = 0; save(); });
  await p.reload(); await p.waitForTimeout(2600);
  let s = await p.evaluate(() => ({ c: S.cells, coins: S.coins, job: S.job, g: S.wearing }));
  ok('progress survives a reload', s.c === 99e9 && s.coins === 1234 && s.job === 'doctor' && s.g === 'Reading Glasses');
  // changing settings must not touch progress
  await p.evaluate(() => { closePanel(); settings(); [...document.querySelectorAll('#pc .btn')].find(x => x.textContent.includes('Sound')).click(); [...document.querySelectorAll('#pc .btn')].find(x => x.textContent.includes('Secret horror')).click(); [...document.querySelectorAll('#pc .btn')].find(x => x.textContent.includes('Demo speed')).click(); closePanel(); admin('tune'); document.querySelectorAll('.tunerow')[0].querySelectorAll('button')[1].click(); closePanel(); save(); });
  await p.reload(); await p.waitForTimeout(2600);
  s = await p.evaluate(() => ({ c: S.cells, coins: S.coins, job: S.job, music: S.music, horror: S.horror && S.horror.setting, tune: S.tune }));
  ok('settings changes keep progress (cells, coins, job)', s.c === 99e9 && s.coins === 1234 && s.job === 'doctor');
  ok('settings themselves are remembered', s.music === false && s.horror === 'full' && !!s.tune);
  // corrupt the main save: the backup should be used instead of wiping everything
  await p.evaluate(() => localStorage.setItem('lbc_save', '{broken json!!'));
  await p.reload(); await p.waitForTimeout(2600);
  s = await p.evaluate(() => ({ c: S.cells, coins: S.coins }));
  ok('a corrupted save falls back to the backup', s.c === 99e9 && s.coins === 1234);
  console.log(errs.join('\n') || 'no errors');
  await b.close();
})();
