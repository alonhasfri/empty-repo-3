const { chromium } = require('playwright');
require('fs').mkdirSync(require('path').join(__dirname, 'shots'), { recursive: true });
const fs = require('fs');
(async () => {
  const b = await chromium.launch({ args: ['--use-gl=swiftshader', '--enable-webgl', '--ignore-gpu-blocklist'] });
  const p = await b.newPage({ viewport: { width: 420, height: 820 }, hasTouch: true });
  await p.route('**/three.min.js', r => r.fulfill({ body: fs.readFileSync(__dirname + '/three.min.js'), contentType: 'application/javascript' }));
  const errs = [];
  p.on('pageerror', e => errs.push('PAGEERR ' + e.message + ' | ' + (e.stack || '').split('\n').slice(1, 3).join(' ')));
  p.on('console', m => { if (m.type() === 'error') errs.push('CONSOLE ' + m.text()); });
  const ev = (f, a) => p.evaluate(f, a);
  const W = ms => p.waitForTimeout(ms);
  const shot = async n => { await ev(() => { $('toasts').innerHTML = '' }); await p.screenshot({ path: require('path').join(__dirname, 'shots', 's_' + n + '.png') }); };
  await p.goto((process.env.GAME_URL || 'file://' + require('path').resolve(__dirname, '../lose-a-brain-cell-web.html'))); await W(2600);
  await ev(() => { closePanel(); S.tutDone = { Lose: 1, Gain: 1 }; S.notes = 8191; S.done.flashySeen = 1; $('doors').classList.add('hide'); startPath('Gain'); S.cells = 86e9 + 1.8 * 8e9; S.coins = 500; S.gates = { 100: 1, 115: 1 }; after(); closePanel(); });
  // optician
  await ev(() => enterRoom(B.find(x => x.id === 'house3'))); await W(1400);
  await ev(() => { const s = ROOM.spots.find(x => x.main); s.fn(); }); await W(300); await shot('optician');
  await ev(() => { const bs = [...document.querySelectorAll('#pc .btn')]; bs[3].click(); }); await W(400);
  console.log('wearing', await ev(() => S.wearing + ' coins ' + S.coins));
  await ev(() => closePanel());
  // career
  await ev(() => { leaveRoom(true); enterRoom(B.find(x => x.id === 'jobs')); }); await W(1400);
  await ev(() => { const s = ROOM.spots.find(x => x.main); s.fn(); }); await W(300); await shot('jobs');
  await ev(() => { const bs = [...document.querySelectorAll('#pc .btn')]; bs.find(b => b.textContent.includes('Nurse') || b.textContent.includes('Volunteer')).click(); }); await W(300);
  console.log('career', await ev(() => JSON.stringify(S.career) + ' ' + careerTitle()));
  // doctor minigame (x-ray)
  await ev(() => { leaveRoom(true); enterRoom(B.find(x => x.id === 'hospital')); }); await W(1400);
  await ev(() => work()); await W(300); await shot('xray');
  await ev(() => { const x = document.querySelector('.xray'); if (x) x.click(); else closePanel(); }); await W(900);
  // other minigames directly
  for (const [name, fn] of [['scan', 'mgScan'], ['board', 'mgBoard'], ['mix', 'mgMix'], ['email', 'mgEmail'], ['hw', 'mgHomework']]) {
    await ev(fn => window[fn](ok => { window.__ok = ok; closePanel() }), fn); await W(700); await shot('mg_' + name); await ev(() => closePanel());
  }
  // promotion
  await ev(() => { S.career.xp = 3; careerXP(1); }); await W(1800); await shot('promotion'); await ev(() => $('scene').classList.add('hide'));
  await ev(() => { S.career.shift = 2; S.career.ok = 2; reportCard(); }); await W(300); await shot('report'); await ev(() => closePanel());
  // library find the book
  await ev(() => { leaveRoom(true); enterRoom(B.find(x => x.id === 'library')); }); await W(1400); await ev(() => library()); await W(300); await shot('library');
  await ev(() => closePanel());
  // university gate with locks
  await ev(() => { S.cells = cellsFor(130) + 1; leaveRoom(true); enterRoom(B.find(x => x.id === 'university')); }); await W(1400); await shot('university');
  await ev(() => gate()); await W(300); await shot('gate'); await ev(() => closePanel());
  // evidence + court with timing
  await ev(() => { leaveRoom(true); arr('evidence').push('ticket'); enterRoom(B.find(x => x.id === 'court')); }); await W(1400);
  await ev(() => { const s = ROOM.spots.find(x => x.main); P.x = s.px; P.y = s.py; s.fn(); }); await p.waitForSelector('.copt', { timeout: 20000 }); await W(400);
  await shot('court_opts');
  await ev(() => { const e = document.querySelector('.copt.ev'); (e || document.querySelector('.copt')).click(); }); await W(2500); await shot('objection_timing');
  await ev(() => { const o = document.getElementById('obtn'); o && o.click(); }); await W(500);
  await ev(() => { closeConv(); leaveRoom(true); });
  // gadgets
  await ev(() => { S.inv = C.Inventions.map(i => i.key); useInvention('pigeons'); useInvention('boots'); }); await W(400); await shot('pigeons');
  // night
  await ev(() => { window.__h = gameHour; gameHour = () => 22; }); await W(600); await shot('night'); await ev(() => { gameHour = window.__h });
  // LOSE path
  await ev(() => { S.tutDone.Lose = 1; startPath('Lose'); S.cells = 75e9; after(); closePanel(); }); await W(500);
  await ev(() => enterRoom(B.find(x => x.id === 'diner'))); await W(1400); await ev(() => microwave()); await W(5600); await shot('microwave_boom');
  await ev(() => { leaveRoom(true); enterRoom(B.find(x => x.id === 'wall')); }); await W(1400);
  await ev(() => { for (let i = 0; i < 6; i++) bonkWall(); }); await W(500); await shot('wall');
  await ev(() => { leaveRoom(true); viralBillboard('first!! bonkadoo'); P.x = 300; P.y = 600; }); await W(800); await shot('billboard');
  await ev(() => { startChase('Toaster'); }); await W(300); await ev(() => { P.x = CHASE.x; P.y = CHASE.y + 10; }); await W(500); await shot('chase');
  await ev(() => { if (CHASE) endChase(true); });
  await ev(() => newsCatch()); await W(2500); await shot('newsstand'); await ev(() => closePanel());
  await ev(() => dailyTimes()); await W(300); await shot('times'); await ev(() => closePanel());
  await ev(() => messages()); await W(300); await shot('messages'); await ev(() => closePanel());
  // school chase
  await ev(() => { SCHOOL = { start: Date.now(), state: 'chase', ox: P.x + 200, oy: P.y, until: Date.now() + 30000 }; officer.g.visible = true; }); await W(800); await shot('truant');
  await ev(() => { SCHOOL = null; officer.g.visible = false; objective(''); });
  // animals
  for (const [k, c] of [['dog', 1e9], ['octopus', 3e8], ['mouse', 5e7], ['bee', 5e5], ['fly', 1e5], ['worm', 200]]) {
    await ev(c => { S.cells = c; after(); }, c); await W(4500); await shot('animal_' + k);
  }
  await ev(() => { S.cells = 5e7; after(); enterRoom(B.find(x => x.id === 'library')); }); await W(5000);
  await ev(() => { const s = ROOM.spots.find(x => x.label && x.label.includes('mouse hole')); if (s) s.fn(); }); await W(1500); await shot('mouse_lounge');
  await ev(() => { leaveRoom(true); S.cells = 200; after(); }); await W(4500); await ev(() => digTunnel()); await W(1500); await shot('dig');
  await ev(() => unstuck());
  console.log(errs.join('\n') || 'no errors');
  await b.close();
})();
