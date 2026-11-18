const { chromium } = require('playwright');
require('fs').mkdirSync(require('path').join(__dirname, 'shots'), { recursive: true });
const fs = require('fs');
(async () => {
  const b = await chromium.launch({ args: ['--use-gl=swiftshader', '--enable-webgl', '--ignore-gpu-blocklist'] });
  const p = await b.newPage({ viewport: { width: 420, height: 820 }, hasTouch: true });
  await p.route('**/three.min.js', r => r.fulfill({ body: fs.readFileSync(__dirname + '/three.min.js'), contentType: 'application/javascript' }));
  const errs = []; p.on('pageerror', e => errs.push('PAGEERR ' + e.message + ' | ' + (e.stack || '').split('\n')[1]));
  const ev = (f, a) => p.evaluate(f, a); const W = ms => p.waitForTimeout(ms);
  const shot = async n => { await p.screenshot({ path: require('path').join(__dirname, 'shots', 'i_' + n + '.png') }); };
  await p.goto((process.env.GAME_URL || 'file://' + require('path').resolve(__dirname, '../lose-a-brain-cell-web.html'))); await W(2600);
  await ev(() => { closePanel(); S.tutDone = { Lose: 1, Gain: 1 }; S.notes = 8191; S.done.flashySeen = 1; $('doors').classList.add('hide'); startPath('Gain'); S.cells = cellsFor(120); S.coins = 100; after(); closePanel(); });
  // talk to an NPC
  await ev(() => { const n = npcs[0]; n.x = P.x + 30; n.y = P.y; n.tx = n.x; n.ty = n.y; n.t = 99; }); await W(500);
  console.log('npc spot:', await ev(() => !!npcSpot.cur && npcSpot.cur.name));
  await ev(() => talkTo(npcSpot.cur)); await W(400); await shot('talk');
  await ev(() => { [...document.querySelectorAll('#pc .btn')][2].click(); }); await W(500); await shot('highfive'); await ev(() => document.querySelector('#pc .btn.go').click()); await W(300);
  // emotes
  await ev(() => { closePanel(); for (const n of npcs.slice(0, 4)) { n.x = P.x + 60 + Math.random() * 40; n.y = P.y + 40; n.t = 99; n.tx = n.x; n.ty = n.y; } }); await p.click('#emoBtn'); await W(200); await shot('emomenu');
  await ev(() => document.querySelector('#emoMenu button:nth-child(2)').click()); await W(900); await shot('dance');
  // kick the ball into the goal
  await ev(() => { BALL.x = GOAL.x; BALL.y = GOAL.y + 70; BALL.vx = 0; BALL.vy = -400; P.x = GOAL.x; P.y = GOAL.y + 130; }); await W(1500);
  console.log('goals:', await ev(() => S.goals || 0)); await shot('goal');
  // orbs
  await ev(() => { const o = ORBS[0]; P.x = o.x; P.y = o.y; }); await W(300); await ev(() => { const o = ORBS[1]; P.x = o.x; P.y = o.y; }); await W(300);
  console.log('orbs alive:', await ev(() => ORBS.filter(o => o.alive).length));
  // fountain + skateboard
  await ev(() => TOWN_SPOTS.find(t => t.n.includes('fountain')).fn()); await W(300);
  await ev(() => { TOWN_SPOTS.find(t => t.n.includes('Skateboard')).fn(); jump(); }); await W(400); await shot('skate');
  console.log('speed with skate:', await ev(() => speedMult()));
  // Lose + pet
  await ev(() => { S.tutDone.Lose = 1; startPath('Lose'); S.cells = 80e9; after(); closePanel(); enterRoom(B.find(x => x.id === 'mall')); }); await W(1500);
  await ev(() => { const s = ROOM.spots.find(x => x.label === 'Adopt a pet'); s.fn(); }); await W(300); await shot('petshop');
  await ev(() => document.querySelectorAll('#pc .btn')[1].click()); await W(300);
  await ev(() => leaveRoom(true)); await W(1200); await shot('pet');
  console.log(errs.join('\n') || 'no errors');
  await b.close();
})();
