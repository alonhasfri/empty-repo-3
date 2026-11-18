const { chromium } = require('playwright');
require('fs').mkdirSync(require('path').join(__dirname, 'shots'), { recursive: true });
const fs = require('fs');
(async () => {
  const b = await chromium.launch({ args: ['--use-gl=swiftshader', '--enable-webgl', '--ignore-gpu-blocklist'] });
  const p = await b.newPage({ viewport: { width: 420, height: 820 }, hasTouch: true });
  await p.route('**/three.min.js', r => r.fulfill({ body: fs.readFileSync(__dirname + '/three.min.js'), contentType: 'application/javascript' }));
  const errs = []; p.on('pageerror', e => errs.push('PAGEERR ' + e.message + ' | ' + (e.stack || '').split('\n')[1]));
  const ev = (f, a) => p.evaluate(f, a); const W = ms => p.waitForTimeout(ms);
  const shot = async n => { await ev(() => { $('toasts').innerHTML = '' }); await p.screenshot({ path: require('path').join(__dirname, 'shots', 'c_' + n + '.png') }); };
  await p.goto((process.env.GAME_URL || 'file://' + require('path').resolve(__dirname, '../lose-a-brain-cell-web.html'))); await W(2600);
  await ev(() => { closePanel(); S.tutDone = { Lose: 1, Gain: 1 }; S.notes = 8191; S.done.flashySeen = 1; $('doors').classList.add('hide'); startPath('Gain'); S.cells = cellsFor(150); S.gates = { 100: 1, 115: 1, 130: 1, 145: 1 }; after(); closePanel(); });
  // every minigame of every job
  const counts = await ev(() => { const out = {}; for (const [job, list] of Object.entries(MG)) { out[job] = 0; list.forEach((f, i) => { try { f(() => {}); if (!$('panelWrap').classList.contains('hide')) out[job]++; } catch (e) { out[job] = 'ERR ' + e.message } closePanel(); }); } return out; });
  console.log('minigames opened:', JSON.stringify(counts));
  await W(4500); await ev(() => closePanel());
  for (const [n, f] of [['bag', 'mgBag'], ['type', 'mgType'], ['rhythm', null], ['whack', null], ['count', null], ['order', null]]) {
    await ev(n => { if (n === 'rhythm') mgRhythm('💓 Heartbeat', 'Tap on the beat', () => {}); else if (n === 'whack') mgWhack('🧹 Clean up!', 'Tap the trash', ['🗑', '🍌'], ['📚'], 8, () => {}); else if (n === 'count') mgCount('🔬 Microscope', '🦠', ['🫧', '⚪'], () => {}); else if (n === 'order') mgOrder('🧪 Steps', 'Order:', ['A', 'B', 'C', 'D'], () => {}); else window[n === 'bag' ? 'mgBag' : 'mgType'](() => {}); }, n);
    await W(1200); await shot('mg_' + n); await ev(() => closePanel());
  }
  // conversations differ between visits
  const firsts = await ev(async () => { const seen = new Set(); for (let i = 0; i < 12; i++) { ROOM = ROOMS.court || buildRoom(B.find(x => x.id === 'court')); const base = ORIG_CONV.courtG; const pool = [base].concat((SCN.courtG || []).map(l => buildScenario(base, l))); const c = shuffledCopy(rnd(pool)); seen.add(c.nodes.a.say.slice(0, 30) + ' | first option: ' + c.nodes.a.opts[0].t.slice(0, 20)); } ROOM = null; return [...seen] });
  console.log('court variations seen:', firsts.length); firsts.slice(0, 4).forEach(x => console.log('  ', x));
  // town event
  await ev(() => { EVENT = EVENTS[0]; EVENT.until = Date.now() + 99999; EVENT.start(); }); await W(500); await shot('event');
  console.log('event spots:', await ev(() => TOWN_SPOTS.filter(t => t.ev).length));
  await ev(() => { const sp = TOWN_SPOTS.filter(t => t.ev); sp[0].fn(); sp[1].fn(); }); await W(300);
  console.log('event cleared:', await ev(() => EVENT === null));
  // Lose: dumb gameplay
  await ev(() => { S.tutDone.Lose = 1; startPath('Lose'); S.cells = 60e9; after(); closePanel(); showAd(); }); await W(600); await shot('ad');
  await ev(() => { document.querySelector('.ad .adx').click(); }); await W(200); console.log('ad still there after 1st X:', await ev(() => !!document.querySelector('.ad')));
  await ev(() => { document.querySelector('.ad .adx') && document.querySelector('.ad .adx').click(); });
  await ev(() => { S.cells = 20e9; after(); closePanel(); $('scene').classList.add('hide'); library(); }); await W(900); await shot('scrambled');
  await ev(() => closePanel());
  await ev(() => { S.cells = 1e9; after(); }); await W(4500); await ev(() => phone()); await W(300); await shot('nothumbs'); await ev(() => closePanel());
  console.log('dumbInput lag test ok:', await ev(() => { lagUntil = Date.now() + 1000; const r = dumbInput(1, 0); lagUntil = 0; return r[0] < 0 }));
  console.log('speed Gain150/Lose20B:', await ev(() => { const a = S.path; S.path = 'Gain'; const s1 = speedMult(); S.path = a; return s1 }), await ev(() => speedMult()));
  console.log(errs.join('\n') || 'no errors');
  await b.close();
})();
