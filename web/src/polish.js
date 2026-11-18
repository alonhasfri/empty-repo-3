
// ================================================================ POLISH PACK (from the "Every Trick To GOOD AI Roblox Games" tips)
// Tip 18: real sound kit • Tip 19: triple feedback • Tip 22: something fun in the first 10 seconds
// Tip 23: every number in one tuning table (editable in Admin → 🎚 Tuning) • Tip 25: show the odds

// ---------------- Tip 18: a proper little sound kit (synthesized, no files needed)
function tone(f,dur,type,vol,slideTo,delay){try{AC=AC||new (window.AudioContext||window.webkitAudioContext)();const t=AC.currentTime+(delay||0);const o=AC.createOscillator(),g=AC.createGain();o.type=type||'sine';o.frequency.setValueAtTime(f,t);if(slideTo)o.frequency.exponentialRampToValueAtTime(slideTo,t+dur);g.gain.setValueAtTime(0.0001,t);g.gain.exponentialRampToValueAtTime(vol||.08,t+.012);g.gain.exponentialRampToValueAtTime(.0001,t+dur);o.connect(g);g.connect(AC.destination);o.start(t);o.stop(t+dur+.02)}catch(e){}}
function noise(dur,vol,delay){try{AC=AC||new (window.AudioContext||window.webkitAudioContext)();const t=AC.currentTime+(delay||0);const n=AC.sampleRate*dur;const buf=AC.createBuffer(1,n,AC.sampleRate);const d=buf.getChannelData(0);for(let i=0;i<n;i++)d[i]=(Math.random()*2-1)*(1-i/n);const s=AC.createBufferSource();s.buffer=buf;const g=AC.createGain();g.gain.value=vol||.06;const f=AC.createBiquadFilter();f.type='lowpass';f.frequency.value=1200;s.connect(f);f.connect(g);g.connect(AC.destination);s.start(t)}catch(e){}}
function snd(type){if(!S.music)return;switch(type){
  case'tick':tone(1800,.03,'square',.025);break;
  case'click':tone(900,.05,'triangle',.05,600);break;
  case'ping':tone(988,.12,'sine',.07);tone(1319,.18,'sine',.06,null,.08);break;
  case'coin':tone(1047,.08,'square',.05);tone(1568,.16,'square',.05,null,.07);break;
  case'up':tone(523,.09,'triangle',.07);tone(659,.09,'triangle',.07,null,.07);tone(784,.16,'triangle',.07,null,.14);break;
  case'down':tone(392,.12,'sawtooth',.05,330);tone(330,.18,'sawtooth',.05,220,.1);break;
  case'good':[523,659,784,1047].forEach((f,i)=>tone(f,.16,'triangle',.07,null,i*.08));break;
  case'bad':tone(180,.32,'sawtooth',.07,110);break;
  case'boing':tone(260,.25,'sine',.09,90);break;
  case'slam':noise(.35,.12);tone(90,.4,'square',.08,45);break;
  case'whoosh':noise(.45,.07);break;
  default:tone(440,.08,'sine',.05)}}
document.addEventListener('click',e=>{const b=e.target.closest&&e.target.closest('button');if(b&&!b.closest('.ncard'))snd('click')},true);

// ---------------- Tip 19: every brain change = sound + number + motion
let _lastFx=0;
floatDelta=(o=>function(amount,up){o(amount,up);const c=$('counter');c.classList.remove('bumpU','bumpD');void c.offsetWidth;c.classList.add(up?'bumpU':'bumpD');
  const now=performance.now();if(now-_lastFx>160&&typeof burst==='function'&&!ROOM){_lastFx=now;burst(P.x/K,PH+4,P.y/K,up?['#7dffb0','#ffd23c','#9ad1ff']:['#ff7d9a','#ff4f9a','#b47dff'],8,5,.18)}
  if(!up&&amount>S.cells*.2+1){try{navigator.vibrate&&navigator.vibrate(40)}catch(e){}}})(floatDelta);
let _lastCoins=null;FRAME_HOOKS.push(()=>{const c=Math.floor(S.coins||0);if(_lastCoins!==null&&c>_lastCoins){snd('coin');const d=document.createElement('div');d.className='delta o1 coinpop';d.textContent='+'+(c-_lastCoins)+' 🪙';$('app').appendChild(d);setTimeout(()=>d.remove(),1300)}_lastCoins=c});

// ---------------- Tip 23: every number in one place (and editable)
ADM_TABS.push(['tune','🎚 Tuning']);
admin=(o=>function(tab){o(tab);if(tab!=='tune')return;const box=$('adm');box.innerHTML='<p>Every balance number in one place. Changes save in this browser. Some apply after a reload.</p>';
  Object.keys(TUNE_DEFAULT).forEach(k=>{const row=document.createElement('div');row.className='tunerow';const v=TUNE[k];const step=v<1?(v<.01?.001:.01):v<10?.1:5;
    row.innerHTML=`<div><b>${k}</b><small>${esc(TUNE_INFO[k])}</small></div><button class="word">−</button><span>${+v.toFixed(4)}</span><button class="word">+</button>`;
    const [m,p]=row.querySelectorAll('button');const set=nv=>{TUNE[k]=Math.max(0,+nv.toFixed(4));(S.tune=S.tune||{})[k]=TUNE[k];save();admin('tune')};m.onclick=()=>set(TUNE[k]-step);p.onclick=()=>set(TUNE[k]+step);box.appendChild(row)});
  btns(box,[['↩️ Reset to defaults',()=>{S.tune={};Object.assign(TUNE,TUNE_DEFAULT);save();admin('tune')}]])})(admin);

// ---------------- Tip 25: show the odds before anything random that costs you something
setTimeout(()=>{const fsp=TOWN_SPOTS.find(t=>t.n&&t.n.includes('fountain'));if(!fsp)return;const orig=fsp.fn;fsp.fn=()=>{const lose=S.path==='Lose';
  const odds=lose?[['Dumber (big)',25],['Dumber (small)',25],['Nothing',25],['Forget your name (dumber)',25]]:[['+Brain cells',20],['−30 stress',20],['+1 idea',20],['2 coins back',20],['Nothing',20]];
  const el=panel('⛲ Wishing fountain',`<p>${lose?'Free on the Lose path.':'Costs 🪙 2.'} Every wish is random. <b>Here are the exact odds:</b></p><div class="odds">${odds.map(([n,p])=>`<div><span>${n}</span><b>${p}%</b></div>`).join('')}</div>`);btns(el,[['🌠 Make a wish',()=>{closePanel();orig()},'go']])}},0);

// ---------------- Tip 22: something fun in the first 10 seconds (before the tutorial)
function firstHook(path,then){const lose=path==='Lose';const wrap=document.createElement('div');wrap.className='hook';wrap.innerHTML=`<div class="hookt o">${lose?'😱 QUICK! Pop the clickbait!':'🧠 QUICK! Grab the brain cells!'}</div><div class="hookc" id="hookc">0 / 3</div>`;$('app').appendChild(wrap);
  let n=0;const items=lose?['😱 SHOCKING','🔥 YOU WON\'T BELIEVE','🤯 GONE WRONG']:['🧠','🧠','🧠'];
  items.forEach((t,i)=>{const b=document.createElement('button');b.className='hookb'+(lose?' bait':' orb');b.textContent=t;b.style.left=(12+i*28+Math.random()*6)+'%';b.style.top=(32+Math.random()*30)+'%';b.style.animationDelay=(i*.15)+'s';
    b.onclick=()=>{b.remove();n++;$('hookc').textContent=n+' / 3';if(lose)lose_(1.2);else gain(1.2);if(n>=3){$('hookc').textContent=lose?'🫠 Your brain feels lighter. Nice.':'✨ Your brain grew. Nice.';snd('good');confetti();setTimeout(()=>{wrap.remove();then()},1300)}};wrap.appendChild(b)});
  setTimeout(()=>{if(wrap.isConnected){wrap.remove();then()}},12000)}
const lose_=p=>lose(p);
runTutorial=(o=>function(path,replay){if(!replay&&!S.done['hook'+path]){S.done['hook'+path]=1;save();return firstHook(path,()=>o(path,replay))}return o(path,replay)})(runTutorial);
