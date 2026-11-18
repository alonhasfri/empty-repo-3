const { chromium } = require('playwright');
require('fs').mkdirSync(require('path').join(__dirname, 'shots'), { recursive: true });
const fs = require('fs');
(async () => {
  const b = await chromium.launch({ args: ['--use-gl=swiftshader', '--enable-webgl', '--ignore-gpu-blocklist'] });
  const p = await b.newPage({ viewport: { width: 420, height: 820 }, hasTouch: true });
  await p.route('**/three.min.js', r => r.fulfill({ body: fs.readFileSync(__dirname + '/three.min.js'), contentType: 'application/javascript' }));
  const errs = []; p.on('pageerror', e => errs.push('PAGEERR ' + e.message + ' | ' + (e.stack || '').split('\n')[1]));
  const ev = (f, a) => p.evaluate(f, a); const W = ms => p.waitForTimeout(ms);
  await p.goto((process.env.GAME_URL || 'file://' + require('path').resolve(__dirname, '../lose-a-brain-cell-web.html'))); await W(2700);
  // brand-new player picks LOSE: the first-10-seconds hook comes before the tutorial
  await ev(() => closePanel()); await p.click('#dLose'); await W(900); await p.screenshot({ path: require('path').join(__dirname, 'shots', 'p_hook.png') });
  const before = await ev(() => S.cells);
  for (let i = 0; i < 3; i++) { await ev(() => { const x = document.querySelector('.hookb'); x && x.click(); }); await W(250); }
  await W(400); await p.screenshot({ path: require('path').join(__dirname, 'shots', 'p_hook_done.png') });
  console.log('hook lost cells:', await ev(b => b - S.cells > 0, before), '| tutorial starts after:', await (async () => { await W(2500); return ev(() => !$('cine').classList.contains('hide') || tutRunning()); })());
  // tuning panel
  await ev(() => { TUT && (TUT.running = false); $('cine').classList.add('hide'); $('hint').classList.add('hide'); closePanel(); admin('tune'); }); await W(300); await p.screenshot({ path: require('path').join(__dirname, 'shots', 'p_tune.png') });
  await ev(() => document.querySelectorAll('.tunerow')[1].querySelectorAll('button')[1].click()); await W(200);
  console.log('loseRate after +:', await ev(() => TUNE.loseRate), 'saved:', await ev(() => S.tune && S.tune.loseRate));
  await ev(() => closePanel());
  // fountain odds (Gain)
  await ev(() => { S.tutDone.Gain = 1; S.done.hookGain = 1; startPath('Gain'); closePanel(); S.coins = 10; TOWN_SPOTS.find(t => t.n.includes('fountain')).fn(); }); await W(300); await p.screenshot({ path: require('path').join(__dirname, 'shots', 'p_odds.png') });
  await ev(() => document.querySelector('#pc .btn.go').click()); await W(300);
  console.log('coins after wish (10-2 + maybe 4):', await ev(() => S.coins));
  // triple feedback + coin pop
  await ev(() => { gain(2); S.coins += 5; }); await W(250); await p.screenshot({ path: require('path').join(__dirname, 'shots', 'p_feedback.png') });
  console.log('counter bumped:', await ev(() => $('counter').className.includes('bump')), '| coin pop shown:', await ev(() => !!document.querySelector('.coinpop')));
  console.log(errs.join('\n') || 'no errors');
  await b.close();
})();
