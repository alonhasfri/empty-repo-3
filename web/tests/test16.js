const { chromium } = require('playwright');
require('fs').mkdirSync(require('path').join(__dirname, 'shots'), { recursive: true });
const fs = require('fs');
(async () => {
  const b = await chromium.launch({ args: ['--use-gl=swiftshader', '--enable-webgl', '--ignore-gpu-blocklist'] });
  const p = await b.newPage({ viewport: { width: 420, height: 820 }, hasTouch: true });
  await p.route('**/three.min.js', r => r.fulfill({ body: fs.readFileSync(__dirname + '/three.min.js'), contentType: 'application/javascript' }));
  const errs = []; p.on('pageerror', e => errs.push('PAGEERR ' + e.message + ' | ' + (e.stack || '').split('\n')[1]));
  const ev = (f, a) => p.evaluate(f, a); const W = ms => p.waitForTimeout(ms);
  const shot = async n => { await p.screenshot({ path: require('path').join(__dirname, 'shots', 'h_' + n + '.png') }); };
  await p.goto((process.env.GAME_URL || 'file://' + require('path').resolve(__dirname, '../lose-a-brain-cell-web.html'))); await W(2600);
  await ev(() => { closePanel(); S.tutDone = { Lose: 1, Gain: 1 }; S.notes = 8191; S.done.flashySeen = 1; $('doors').classList.add('hide'); startPath('Lose'); S.cells = 80e9; after(); closePanel(); EVENT = { until: 1e15 }; });
  // talk to him at stage 0 near the fountain
  await ev(() => { P.x = PAG_POS.x; P.y = PAG_POS.y + 40; }); await W(500); await shot('stage0');
  await ev(() => talkAverage()); await W(300); await shot('talk0'); await ev(() => closePanel());
  // stage 1: sighting + a note
  await ev(() => { HZ().time = 999; }); await W(300); console.log('stage after time:', await ev(() => HZ().stage));
  await ev(() => { nextSight = 0; P.x = 560; P.y = 560; }); await W(700); await shot('sighting'); console.log('ghost visible:', await ev(() => GHOST.g.visible));
  await ev(() => readNote(0)); await W(2500); await shot('note');
  await ev(() => closePanel());
  // stage 2/3 via notes
  await ev(() => { HZ().notes = [0, 1, 2, 3, 4]; }); await W(300); console.log('stage w/5 notes:', await ev(() => HZ().stage));
  // follower at night
  await ev(() => { window._gh = gameHour; gameHour = () => 23; FOLLOW.cool = 0; }); await W(600);
  console.log('follower on:', await ev(() => FOLLOW.on));
  await ev(() => { FOLLOW.x = P.x + 20; FOLLOW.y = P.y; }); await W(200); await shot('caught');
  await ev(() => { gameHour = window._gh; });
  // stage 4: the call
  await ev(() => { HZ().notes = [0, 1, 2, 3, 4, 5, 6]; }); await W(400); console.log('stage w/7 notes:', await ev(() => HZ().stage));
  await ev(() => { closePanel(); averageCall(); }); await W(500); await shot('call');
  await ev(() => document.querySelector('.call .cyes').click()); await W(8500); await shot('mean');
  console.log('in mean:', await ev(() => ROOM && ROOM.b.id));
  // grab 3 outliers through loops
  for (let i = 0; i < 12 && (await ev(() => MEAN.outl.length)) < 3; i++) {
    await ev(() => { const R = ROOM; if (R.out.cur) { takeOutlier() } else meanLoop('door'); R.pagPos = { x: -18, z: -12 }; }); await W(1300);
  }
  await shot('mean_exit'); console.log('outliers:', await ev(() => MEAN.outl.length));
  await ev(() => escapeMean()); await W(1500); console.log('escaped stage:', await ev(() => HZ().stage));
  // finale -> friend ending (needs note 8 + friend talk)
  await ev(() => { HZ().notes.push(7); closePanel(); finaleIntro(); document.querySelector('#pc .btn').click(); }); await W(2000);
  for (let k = 0; k < 3; k++) { await p.waitForSelector('.copt', { timeout: 20000 }); await W(300); await ev(() => { const o = [...document.querySelectorAll('.copt')]; const f = o.find(x => /lonely|friends/.test(x.textContent)) || o.find(x => /weird|dance|not like|holds up|just math/.test(x.textContent)) || o[0]; f.click(); }); await W(2600); const ot = await p.$('#obtn'); if (ot) await ot.click(); }
  await W(9000); await shot('credits'); console.log('ending:', await ev(() => HZ().ending));
  await ev(() => $('scene').classList.add('hide')); await ev(() => { P.x = PAG_POS.x; P.y = PAG_POS.y + 60; }); await W(800); await shot('friend');
  await ev(() => { closePanel(); settings(); }); await W(300); await shot('settings');
  console.log(errs.join('\n') || 'no errors');
  await b.close();
})();
