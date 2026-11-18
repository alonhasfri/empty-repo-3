
// ================================================================ INTERACTIVITY PACK + UPDATE 1.6 (browser)
const FRAME_HOOKS=[];function frameHooks(){for(const f of FRAME_HOOKS){try{f()}catch(e){console.error(e)}}}
let DT=.016,_lf=performance.now();FRAME_HOOKS.push(()=>{const n=performance.now();DT=Math.min(.05,(n-_lf)/1000);_lf=n});
let lowGravUntil=0,brainRainUntil=0;
const TOWN_SPOTS=[];
const arr=k=>S[k]||(S[k]=[]),obj=k=>S[k]||(S[k]={});
const stageK=()=>stageOf(S.cells).k;

// ---------------------------------------------------------------- shared 3D bits
const bulbS=sprite(emojiTex('💡'),2.2,2.2,scene);bulbS.visible=false;scene.add(bulbS);let bulbUntil=0;
function idea(n=1){if(S.path!=='Gain')return;S.ideas=(S.ideas||0)+n;bulbUntil=Date.now()+1300;snd('ping');if(S.ideas>=6){S.ideas=0;setTimeout(()=>{bulbUntil=Date.now()+2500;eureka()},700)}update()}
FRAME_HOOKS.push(()=>{bulbS.visible=Date.now()<bulbUntil;if(bulbS.visible){const k=1+Math.sin(T*12)*.08;bulbS.scale.set(2.2*k,2.2*k,1);bulbS.position.set(P.x/K,PH+8.2,P.y/K)}});
const particles=[];function burst(x,y,z,colors,n=18,power=9,size=.25){for(let i=0;i<n;i++){const m=mesh(new THREE.BoxGeometry(size,size,size),MAT(colors[i%colors.length]),scene,x,y,z);m.castShadow=false;particles.push({m,v:new THREE.Vector3((Math.random()-.5)*power,Math.random()*power,(Math.random()-.5)*power),t:1.4})}}
FRAME_HOOKS.push(()=>{for(let i=particles.length-1;i>=0;i--){const p=particles[i];p.t-=DT;p.v.y-=18*DT;p.m.position.addScaledVector(p.v,DT);p.m.rotation.x+=DT*5;if(p.t<=0||p.m.position.y<-1){scene.remove(p.m);particles.splice(i,1)}}});
function objective(text){let o=$('objective');if(!o){o=document.createElement('div');o.id='objective';$('app').appendChild(o)}o.textContent=text;o.classList.toggle('hide',!text)}

// ---------------------------------------------------------------- GLASSES: bought with coins at the Optician
const GPRICE=[15,30,60,100,180,300,500,800];
function glasses(){if(S.path!=='Gain'||!S.wearing)return null;return C.Glasses.find(x=>x.name===S.wearing)||null}
function gain(points){if(S.dead)return 0;let amt;
  if(S.path==='Gain'){const m=multOf(S.cells)[1];const g=glasses();amt=Math.max(1,S.cells*0.004)*m*points*S.demo*(g?g.boost:1);const cap=gainCap();if(S.cells+amt>cap){amt=Math.max(0,cap-S.cells);toast('🚧 A Skill Gate blocks your way! Go to the 🎓 University.')}}
  else amt=Math.max(1,S.cells*0.01)*points;
  S.cells+=amt;if(amt>=1){floatDelta(amt,true);snd('up')}after();return amt}
function optician(){const q=iqOf(S.cells);const owned=arr('ownedGlasses');const el=panel('👓 Optician',`<p>You have <b>🪙 ${Math.floor(S.coins)}</b>. Better glasses = more brain cells from everything. Remember: <b>flashy = dumb</b>.</p>`);
  btns(el,C.Glasses.map((g,i)=>{const has=owned.includes(g.name),wearing=S.wearing===g.name,locked=q<g.minIQ;const price=GPRICE[i]||999;
    return[`${wearing?'✅ ':''}${esc(g.name)} <small>${esc(g.desc)} • ×${g.boost} brain cells • ${has?(wearing?'wearing':'tap to wear'):locked?'🔒 IQ '+g.minIQ:'🪙 '+price}</small>`,()=>{
      if(has){S.wearing=g.name;toast('👓 You put on '+esc(g.name));optician();update();return}
      if(locked)return toast('🔒 You need IQ '+g.minIQ+' to use these.');if(S.coins<price)return toast('🪙 Not enough coins. Work a shift!');
      S.coins-=price;owned.push(g.name);S.wearing=g.name;snd('good');toast('🛍 Bought and wearing '+esc(g.name));moment('flashy');optician();update();save()}]}))}

// ---------------------------------------------------------------- IDEAS + INVENTIONS that really do things
const posHist=[];setInterval(()=>{posHist.push({x:P.x,y:P.y,room:ROOM});if(posHist.length>10)posHist.shift()},500);
function gadgets(){const el=panel('🎒 Gadgets',(S.inv||[]).length?'<p>Your secret inventions. Each one really does something.</p>':'<p>No inventions yet. Work your job → 💡 ideas fill up → <b>EUREKA</b> → pick an invention.</p>');
  btns(el,(S.inv||[]).map(k=>{const i=C.Inventions.find(x=>x.key===k);if(!i)return['?',()=>{}];const cd=Math.max(0,Math.ceil(((obj('cool')[k]||0)-Date.now())/1000));return[`${i.icon} ${esc(i.name)}${cd?' ⏳ '+cd+'s':''}<small>${esc(i.desc)}</small>`,()=>useInvention(k)]}))}
function useInvention(k){const i=C.Inventions.find(x=>x.key===k);const c=obj('cool');if((c[k]||0)>Date.now())return toast('⏳ '+i.name+' is recharging.');c[k]=Date.now()+(i.cooldown||60)*1000;closePanel();
  if(k==='duck'){S.hints=Math.min(3,(S.hints||0)+1);toast('🦆 You explained your problem to the duck. +1 Skill Gate hint ('+S.hints+'/3)')}
  else if(k==='coffee'){S.stress=0;toast('☕ Erdős mode. Stress: 0')}
  else if(k==='pigeons'){burst(P.x/K,PH+3,P.y/K,['#9a9aa6','#7d7d8a','#c4c4cc'],24,14,.5);S.stress=Math.max(0,S.stress-10);toast('🐦 PIGEONS LAUNCHED. Pointless. Beautiful. Stress −10')}
  else if(k==='rain'){brainRainUntil=Date.now()+10000;rainUntil=brainRainUntil;toast('🧠🌧 Brain Rain! +brain cells every second for 10 s')}
  else if(k==='boots'){lowGravUntil=Date.now()+30000;toast('🥾 Anti-gravity for 30 s. Jump!')}
  else if(k==='remote'){maps()}
  else if(k==='goggles'){S.goggles=3;toast('🥽 Focus! Your next 3 library or cinema answers give 1.5×')}
  else if(k==='rewind'){const h=posHist[0];if(h&&h.room===ROOM){P.x=h.x;P.y=h.y;toast('⏪ Rewound 5 seconds.')}else toast('⏪ Nothing to rewind here.')}
  else if(k==='robot'){if(!S.job){toast('🤖 The robot needs you to have a job first.');c[k]=0;return}const pay=careerPay();S.coins+=pay;careerXP(1);idea(1);toast('🤖 Robot Helper did a task: +'+pay+' coins')}
  update();save()}
setInterval(()=>{if(Date.now()<brainRainUntil&&S.path==='Gain')gain(.35)},1000);

// ---------------------------------------------------------------- CAREERS (1.6): start at the bottom, get promoted
const CAREERS={cashier:['Bagger','Cashier','Shift Lead','Store Manager'],office:['Intern','Office Worker','Manager','CEO'],teacher:["Teacher's Assistant",'Substitute Teacher','Teacher','Head Teacher'],professor:['Tutor','Lecturer','Professor','Dean'],doctor:['Hospital Volunteer','Nurse','Doctor','Chief of Medicine'],lawyer:['Court Clerk','Paralegal','Lawyer','Judge'],scientist:['Lab Assistant','Researcher','Scientist','Lead Scientist'],janitor:['Janitor','Head Janitor','Facilities Boss','Janitor Legend'],sweeper:['Street Sweeper','Senior Sweeper','Road Boss','Street Legend']};
const UNIFORM={cashier:'#e8423f',office:'#3b4a6b',teacher:'#2f9a58',professor:'#6b3f8a',doctor:'#f2f6ff',lawyer:'#20222a',scientist:'#e6fbff',janitor:'#5a7a9a',sweeper:'#f08a24'};
const XP_NEED=[0,4,10,18];
const levelIQ=(j,l)=>j.minIQ-14+l*7+(l===3?1:0);
function career(){const c=S.career;if(!c||c.id!==S.job){if(!S.job)return null;S.career={id:S.job,level:0,xp:0,shift:0,ok:0};}return S.career}
function careerTitle(){const c=career();return c?(CAREERS[c.id]||[jobName(c.id)])[c.level]:''}
function careerPay(){const j=C.Jobs.find(x=>x.id===S.job);const c=career();return j?Math.round(j.coinsPerMinute*2*(1+(c?c.level:0)*.5)):5}
function careerXP(n){const c=career();if(!c)return;c.xp+=n;const j=C.Jobs.find(x=>x.id===c.id);const next=c.level+1;if(next<4&&c.xp>=XP_NEED[next]){if(iqOf(S.cells)>=levelIQ(j,next))setTimeout(()=>promotion(),900);else if(!c.waitTold){c.waitTold=1;toast('📈 You\'ve earned a promotion! Reach IQ '+levelIQ(j,next)+' to get it.')}}}
function promotion(){const c=career();c.level++;c.waitTold=0;const title=CAREERS[c.id][c.level];closePanel();try{navigator.vibrate&&navigator.vibrate([80,60,120])}catch(e){}
  const f=$('scene');f.className='scene';f.style.background='radial-gradient(#2a3b6b,#0b0d1a)';f.style.opacity=1;
  f.innerHTML=`<div class="big o" style="color:#ffd84a">📈 PROMOTED!</div><div class="printer"><div class="slot"></div><div class="tagcard" id="tagc"><small>BRAINVILLE • STAFF</small><b id="tagt"></b><span>🧠 ${fmt(S.cells)} brain cells</span></div></div><div class="claps" id="claps"></div><p class="o1">New uniform unlocked. Pay +50%.</p><button class="btn go" style="width:auto" id="pok">Back to work</button>`;
  snd('good');let i=0;const tt=$('tagt');const it=setInterval(()=>{i++;tt.textContent=title.slice(0,i);snd('tick');if(i>=title.length)clearInterval(it)},70);
  for(let k=0;k<7;k++)$('claps').insertAdjacentHTML('beforeend',`<span style="animation-delay:${k*.08}s">🧑‍💼</span>`);
  setTimeout(()=>{for(let k=0;k<7;k++)$('claps').insertAdjacentHTML('beforeend',`<i style="animation-delay:${k*.1}s">👏</i>`);confetti()},800);
  $('pok').onclick=()=>{f.classList.add('hide')};textMsg('Your boss','Congrats on becoming '+title+'! 🎉');update();save()}
function reportCard(){const c=career();const acc=c.ok>=3?'A':c.ok===2?'B':c.ok===1?'C':'F';const vibe=rnd(['A','A−','B+','B']);const need=XP_NEED[Math.min(3,c.level+1)];
  const el=panel('📋 Shift report card',`<div class="report"><div><span>Job</span><b>${esc(careerTitle())}</b></div><div><span>Accuracy</span><b class="g">${acc}</b></div><div><span>Speed</span><b class="g">${rnd(['A','B','B+','A−'])}</b></div><div><span>Coworker vibes</span><b class="g">${vibe}</b></div></div><p>Promotion progress: <b>${c.xp}/${c.level>=3?'MAX':need} XP</b></p><div class="meter" style="height:12px"><div class="f" style="width:${c.level>=3?100:Math.min(100,c.xp/need*100)}%;background:#2fbf71"></div></div>`);c.ok=0;btns(el,[['OK',()=>closePanel(),'go']])}
function jobsPanel(el){const q=iqOf(S.cells);const c=career();
  if(c){const j=C.Jobs.find(x=>x.id===c.id);const next=c.level+1;el.insertAdjacentHTML('beforeend',`<div class="card">Your career: <b>${esc(CAREERS[c.id].join(' → '))}</b><br>Now: <b>${esc(careerTitle())}</b> • XP ${c.xp}${next<4?' • next promotion at '+XP_NEED[next]+' XP and IQ '+levelIQ(j,next):' • top of the ladder!'}</div>`)}
  el.insertAdjacentHTML('beforeend','<p style="margin-top:10px">Pick a career. You start at the bottom and get promoted by working.</p>');
  btns(el,C.Jobs.filter(j=>!j.comebackOnly||S.comeback).map(j=>{const ladder=CAREERS[j.id]||[j.name];const need=levelIQ(j,0);return[`${S.job===j.id?'✅ ':''}${esc(ladder[0])} → … → ${esc(ladder[3]||j.name)} <small>${q>=need?'Start now • works at '+esc(j.placeName):'🔒 IQ '+need}</small>`,()=>{if(q<need)return toast('🔒 You need IQ '+need+' to start this career.');if(S.job!==j.id){S.job=j.id;S.career={id:j.id,level:0,xp:0,shift:0,ok:0}}badge('job','Employed');toast('💼 You\'re now a <b>'+esc(ladder[0])+'</b>! Go to '+esc(j.placeName)+'.');tutEvent('job');closePanel();update();save()}]}))}

// ---------------------------------------------------------------- JOBS AS MINIGAMES
function work(){const b=blocked();if(b)return toast('⛔ '+b);const j=C.Jobs.find(j=>j.id===S.job);if(!j)return toast('💼 Get a job at the 📋 Job Center first.');
  const near=B.find(x=>x.id===JOB_BLD[j.id]);const inJob=ROOM&&ROOM.b.id===JOB_BLD[j.id];if(!inJob&&Math.hypot(P.x-near.door.x,P.y-near.door.y)>80)return toast('🚕 You work at '+esc(j.placeName)+'. Go there first.');
  const done=ok=>{const c=career();closePanel();if(ok){const pay=careerPay();S.coins+=pay;gain(1);idea(1);stress(4);c.ok++;c.shift++;careerXP(1);toast('✅ Task done! +'+pay+' coins');tutEvent('work');snd('good')}else{stress(8);c.shift++;toast('❌ Your boss sighs.')}
    if(c.shift>0&&c.shift%3===0)setTimeout(reportCard,600);update();save()};
  const t=j.task;if(t==='cashier')return mgScan(done);if(t==='doctor')return mgXray(done);if(t==='lawyer')return mgBoard(done);if(t==='scientist')return mgMix(done);if(t==='office')return mgEmail(done);return mgHomework(done)}
function loopUntil(el,fn){let last=performance.now();const tick=t=>{if(!el.isConnected)return;const dt=Math.min(.05,(t-last)/1000);last=t;if(fn(dt)!==false)requestAnimationFrame(tick)};requestAnimationFrame(tick)}
function mgScan(done){const items=shuffle(['🥛','🍞','🍌','🥫','🧃','🍪','🧀','🥚']).slice(0,5);const el=panel('🛒 Scan the items','<p>Tap <b>SCAN</b> when an item is on the red laser. Scan 4 of 5!</p><div class="belt" id="belt"><div class="laser"></div></div><p id="sc">Scanned: 0</p>');
  const belt=$('belt');const objs=items.map((e,i)=>{const d=document.createElement('div');d.className='bitem';d.textContent=e;belt.appendChild(d);return{d,x:-.15-i*.3,done:false}});let n=0,end=false;
  btns(el,[['📟 SCAN',()=>{const o=objs.find(o=>!o.done&&Math.abs(o.x-.5)<.07);if(o){o.done=true;o.d.classList.add('ok');n++;$('sc').textContent='Scanned: '+n;blip(1200)}else{snd('bad')}},'pink']]);
  loopUntil(el,dt=>{let all=true;for(const o of objs){o.x+=dt*.28;o.d.style.left=(o.x*100)+'%';if(o.x<1.1)all=false}if(all&&!end){end=true;setTimeout(()=>done(n>=4),300);return false}})}
function mgXray(done){const broken=Math.floor(Math.random()*3);const el=panel('🩻 Read the X-rays','<p>The patient fell off a skateboard. Tap the X-ray that shows the <b>fracture</b>.</p><div class="xrays" id="xr"></div>');
  for(let i=0;i<3;i++){const c=document.createElement('canvas');c.width=180;c.height=240;const g=c.getContext('2d');g.fillStyle='#0a1830';g.fillRect(0,0,180,240);g.fillStyle='#e8f0ff';g.globalAlpha=.9;const rr=(x,y,w,h,r)=>{g.beginPath();g.roundRect?g.roundRect(x,y,w,h,r):g.rect(x,y,w,h);g.fill()};rr(78,20,24,200,12);g.beginPath();g.arc(90,22,20,0,7);g.fill();g.beginPath();g.arc(90,218,20,0,7);g.fill();
    if(i===broken){const y=60+Math.random()*100;g.strokeStyle='#0a1830';g.lineWidth=5;g.beginPath();g.moveTo(74,y);g.lineTo(86,y+8);g.lineTo(94,y-4);g.lineTo(106,y+6);g.stroke()}
    c.className='xray';c.onclick=()=>{c.classList.add(i===broken?'ok':'bad');snd(i===broken?'good':'bad');setTimeout(()=>done(i===broken),600)};$('xr').appendChild(c)}}
function mgBoard(done){const t=rnd(C.Testimony);const el=panel('📌 Evidence board','<p>Pin the statement that <b>can\'t be true</b>.</p><div class="cork" id="cork"></div>');
  t.lines.forEach((l,i)=>{const n=document.createElement('button');n.className='note';n.style.transform=`rotate(${(i%2?3:-4)+Math.random()*2}deg)`;n.innerHTML='📌<br>'+esc(l);n.onclick=()=>{const ok=i+1===t.wrong;n.classList.add(ok?'lie':'bad');snd(ok?'good':'bad');if(ok)n.insertAdjacentHTML('beforeend','<div class="string">LIE</div>');setTimeout(()=>done(ok),800)};$('cork').appendChild(n)})}
function mgMix(done){const tg=[Math.floor(Math.random()*4),Math.floor(Math.random()*4),Math.floor(Math.random()*4)];if(tg[0]+tg[1]+tg[2]===0)tg[0]=2;let cur=[0,0,0];const col=v=>{const s=Math.max(1,v[0]+v[1]+v[2]);return`rgb(${v[0]/s*255|0},${v[1]/s*255|0},${v[2]/s*255|0})`};
  const el=panel('🧪 Mix the liquids',`<p>Make your flask match the target color. Drops: red, green, blue.</p><div class="mix"><div><div class="flask" style="background:${col(tg)}"></div>Target</div><div><div class="flask" id="mf" style="background:#ddd"></div>Yours</div></div>`);
  const upd=()=>{$('mf').style.background=cur.some(x=>x)?col(cur):'#ddd'};
  btns(el,[['🔴 + red drop',()=>{cur[0]++;upd();blip(500)}],['🟢 + green drop',()=>{cur[1]++;upd();blip(600)}],['🔵 + blue drop',()=>{cur[2]++;upd();blip(700)}],['🔄 Empty the flask',()=>{cur=[0,0,0];upd()}],['✅ Done',()=>{const s1=tg[0]+tg[1]+tg[2],s2=Math.max(1,cur[0]+cur[1]+cur[2]);const diff=Math.max(...[0,1,2].map(i=>Math.abs(tg[i]/s1-cur[i]/s2)));done(diff<.12)},'go']])}
function mgEmail(done){const E=[['URGENT: Q3 budget meeting moved to 2pm',1],['You WON a FREE yacht!!! click here',0],['Client: contract signed ✅',1],['Hot singles in your area want to talk about printers',0],['Reminder: fire drill Friday',1],['Prince needs your bank password',0],['Payroll: please confirm your hours',1],['🔥🔥 BRAIN BOOST PILLS 🔥🔥',0]];const list=shuffle(E).slice(0,5);let i=0,okc=0;
  const el=panel('📧 Sort the inbox','<p>Important or spam? 5 emails, be quick!</p><div class="card" id="em" style="font-size:16px;min-height:56px"></div><p id="emn"></p>');
  const show=()=>{if(i>=list.length)return done(okc>=4);$('em').textContent='✉️ '+list[i][0];$('emn').textContent=(i+1)+' / 5'};
  btns(el,[['📥 Important',()=>{if(list[i]&&list[i][1]===1){okc++;blip(900)}else snd('bad');i++;show()}],['🗑 Spam',()=>{if(list[i]&&list[i][1]===0){okc++;blip(900)}else snd('bad');i++;show()}]]);show()}
function mgHomework(done){const h=rnd(C.HomeworkMistakes);const el=panel('🖍 Grade the homework','<p>Circle the mistake with your red pen.</p>');
  h.lines.forEach((l,i)=>{const b=document.createElement('button');b.className='btn hw';b.textContent=l;b.onclick=()=>{const ok=i+1===h.wrong;b.classList.add(ok?'circled':'wrong');snd(ok?'good':'bad');setTimeout(()=>done(ok),700)};el.appendChild(b)})}

// ---------------------------------------------------------------- LIBRARY: find the book on the shelf / JACK B with goggles
function bookTitle(x){const w=x.text.replace(/^Fun fact:\s*/i,'').split(' ');return w.slice(0,5).join(' ').replace(/[,.:;]$/,'')+'…'}
function library(){const b=blocked();if(b)return toast('⛔ '+b);const pool=shuffle(C.Library).slice(0,6);const target=pool[0];
  const el=panel('📚 Find the book',`<p>Find the book that answers:<br><b>${esc(target.q)}</b></p><div class="spines" id="sp"></div>`);
  shuffle(pool).forEach((x,i)=>{const s=document.createElement('button');s.className='spine';s.style.background=CANDY[i%6];s.textContent=bookTitle(x);s.onclick=()=>{if(x!==target){s.classList.add('nope');snd('bad');toast('📕 Not this one. Read the titles!');return}readBook(target)};$('sp').appendChild(s)})}
function readBook(q){const el=panel('📖 '+bookTitle(q),`<p style="font-size:17px">${esc(q.text)}</p><p id="lt" style="color:#a79fbd;font-size:12px">Reading… the question appears in 5 s</p>`);
  setTimeout(()=>{if(!$('lt'))return;$('lt').remove();question(el,q,ok=>{if(ok){const g=S.goggles>0?1.5:1;if(S.goggles>0)S.goggles--;gain(3*g);if(Math.random()<.5)idea(1);toast('✅ Correct!')}else{stress(5);toast('❌ Not quite.')}tutEvent('library');closePanel()})},5000)}
function jackB(){const b=blocked();if(b)return toast('⛔ '+b);const q=rnd(C.Theater);const el=panel('🎬 Jack B Movies',`<div class="vid" style="height:180px;background:linear-gradient(160deg,#c92a2a,#1a0d12)"><span style="font-size:60px">🎬</span><div class="cap o1">${esc(q.text)}</div></div><p id="lt" style="color:#a79fbd;font-size:12px">Watching… 5 s</p>`);
  if(ROOM&&ROOM.screen){const m=ROOM.screen.material;m.map=canvasTex((g,w,h)=>{const gr=g.createLinearGradient(0,0,w,h);gr.addColorStop(0,'#c92a2a');gr.addColorStop(1,'#1a0d12');g.fillStyle=gr;g.fillRect(0,0,w,h);g.fillStyle='#fff';g.font='700 22px Fredoka';g.textAlign='center';const words=q.text.split(' ');let line='',y=h/2-30;for(const wd of words){if(g.measureText(line+wd).width>w-40){g.fillText(line,w/2,y);line='';y+=28}line+=wd+' '}g.fillText(line,w/2,y)},512,230);m.needsUpdate=true}
  setTimeout(()=>{if(!$('lt'))return;$('lt').remove();question(el,q,ok=>{if(ok){const g=S.goggles>0?1.5:1;if(S.goggles>0)S.goggles--;gain(2*g);if(Math.random()<.4)idea(1);toast('✅ Fun fact learned!')}else stress(3);tutEvent('theater');closePanel()})},5000)}

// ---------------------------------------------------------------- SKILL GATE: a real door with 3 locks
function setLocks(n,open){if(!ROOM||!ROOM.locks)return;ROOM.locks.forEach((l,i)=>{l.material.color.set(i<n?'#2fbf71':'#e5484d');l.material.emissive.set(i<n?'#1a8a4a':'#7a1010')});if(open)ROOM.gateOpenT=performance.now()}
function gate(){const b=blocked();if(b)return toast('⛔ '+b);const g=GATES.find(g=>!S.gates[g.iq]);if(!g)return panel('🚧 Skill Gates','<p>You passed every Skill Gate. 🎓</p>');
  if(S.cells<cellsFor(g.iq)-1)return panel('🚧 '+g.name,`<p>Come back at <b>IQ ${g.iq}</b> (you: ${Math.floor(iqOf(S.cells))}).</p>`);
  const qs=shuffle(C.GateQuestions.filter(q=>q.tier===g.tier)).slice(0,3);let n=0;setLocks(0);const el=panel('🚧 '+g.name,'');
  const ask=()=>{el.innerHTML=`<div class="locks">${[0,1,2].map(i=>i<n?'🔓':'🔒').join(' ')}</div><p>Lock ${n+1} of 3. <b>YOU</b> have to know this.</p>`;question(el,qs[n],ok=>{if(!ok){stress(15);setLocks(0);el.innerHTML='<div class="locks">🔒 🔒 🔒</div><p>❌ Wrong. All the locks snap shut. Study and try again.</p>';tutEvent('gate-try');return}n++;setLocks(n);blip(1400);if(n<3)return ask();S.gates[g.iq]=1;setLocks(3,true);badge('gate'+g.tier,g.name);tutEvent('gate');closePanel();gain(1);toast('🎓 GATE PASSED! The door opens.');textMsg('Your mom','I heard you passed '+g.name+'!! 😭💙');after()});
    if((S.hints||0)>0){const hb=document.createElement('button');hb.className='btn';hb.innerHTML='🦆 Use a hint ('+S.hints+' left)<small>Removes one wrong answer</small>';hb.onclick=()=>{const opts=[...el.querySelectorAll('.btn')].filter(x=>x!==hb&&!x.classList.contains('hidden'));const wrong=opts.filter((x,i)=>i+1!==qs[n].answer);if(wrong[0]){wrong[0].style.visibility='hidden';S.hints--;hb.remove()}};el.appendChild(hb)}};ask()}

// ---------------------------------------------------------------- CONVERSATIONS: memory, evidence, objection timing
const EVID={ticket:{name:'Park ticket stamped 8:00 PM',say:"The witness was at the park at 8. Here's the ticket.",x:760,y:520},cctv:{name:'Security camera photo',say:'This photo shows a totally different person.',x:900,y:350},receipt:{name:'Café receipt 7:55 PM',say:'They bought coffee at 7:55. They were not home.',x:880,y:575},article:{name:'The ORIGINAL article',say:'The real article never said that. The headline was fake.',x:420,y:360},diary:{name:"Witness's diary",say:'"Went to the park. Watched no TV." Their own words.',x:1100,y:520}};
Object.entries(EVID).forEach(([id,e])=>{const s=sprite(emojiTex('📁'),1.8,1.8,town);s.position.set(e.x/K,2,e.y/K);e.s=s;TOWN_SPOTS.push({id:'spot',n:'📁 '+e.name,label:'Pick up evidence',px:e.x,py:e.y,when:()=>!arr('evidence').includes(id),fn:()=>{arr('evidence').push(id);s.visible=false;snd('good');toast('📁 Evidence found: <b>'+e.name+'</b>. Use it in court!');save()}})});
FRAME_HOOKS.push(()=>{for(const [id,e] of Object.entries(EVID)){e.s.visible=!(S.evidence||[]).includes(id);e.s.position.y=2+Math.sin(T*3)*.3}});
function remember(o,t){if(o.b<0||o.slam){const m=arr('mem');m.push({t,key:CV.key});if(m.length>10)m.shift();(WHISPER[S.path]||[]).push('did they really say "'+t.slice(0,40)+'"? 💀')}}
function sayNode(){if(!CV)return;
  if(CV.node==='a'&&!CV.memoDone){CV.memoDone=1;const m=(S.mem||[]).filter(x=>x.key!==CV.key);if(m.length&&Math.random()<.7){const pickM=rnd(m);shot('npc');talking=CV.npc;return typeLine(CV.c.who,'Wait… aren\'t you the one who said "'+pickM.t+'"? …Anyway.',()=>{talking=null;setTimeout(sayNode,350)},320)}}
  const n=CV.c.nodes[CV.node];shot('npc');talking=CV.npc;
  typeLine(CV.c.who,n.say,()=>{talking=null;const box=$('copts');box.innerHTML='';n.opts.forEach((o,i)=>{const t=typeof o.t==='function'?o.t(S):o.t;const b=document.createElement('button');b.className='copt';b.innerHTML=`<span>${i+1}</span>${esc(t)}`;b.onclick=()=>pick(o,t);box.appendChild(b)});
    if(CV.key.startsWith('court')){const avail=(S.evidence||[]).filter(e=>!(CV.usedEv||[]).includes(e));if(avail.length){const e=avail[0];const b=document.createElement('button');b.className='copt ev';b.innerHTML='<span>📁</span>Present evidence: '+esc(EVID[e].name);b.onclick=()=>{CV.usedEv=(CV.usedEv||[]).concat(e);pick({m:25,b:1,n:n.opts[0].n,slam:1},'Look at this: '+EVID[e].name+'. '+EVID[e].say)};box.appendChild(b)}}
    box.classList.add('show')},320)}
function pick(o,t){remember(o,t);const box=$('copts');box.classList.remove('show');box.innerHTML='';shot('me');talking=ME;
  typeLine('You',t,()=>{talking=null;const cont=bonus=>{CV.meter+=o.m+bonus;setMeter();if(o.b>0)gain(o.b*.6);else if(o.b<0)lose(-o.b*.6);
      const fx=document.createElement('div');fx.className='cfx';fx.textContent=o.m+bonus>0?'▲ '+CV.c.meter[0]:o.m+bonus<0?'▼ '+CV.c.meter[0]:'';fx.style.color=o.m+bonus>0?'#7dffb0':'#ff7d9a';$('conv').appendChild(fx);setTimeout(()=>fx.remove(),1200);
      if(o.n){CV.node=o.n;setTimeout(sayNode,500)}else setTimeout(endConv,600)};
    if(o.slam)objectionTiming(bonus=>{objection();cont(bonus)});else cont(0)},220)}
function objectionTiming(cb){const w=document.createElement('div');w.className='otime';w.innerHTML='<div class="otrack"><div class="ozone"></div><div class="omark" id="omk"></div></div><button class="obtn" id="obtn">OBJECTION!</button><small>Tap when the marker is in the green!</small>';$('conv').appendChild(w);
  let x=0,dir=1,done=false;const fin=b=>{if(done)return;done=true;w.remove();toast(b>0?'⚡ PERFECT TIMING! +'+b:'😬 Bad timing…');cb(b)};$('obtn').onclick=()=>fin(x>.62&&x<.8?15:-5);
  loopUntil(w,dt=>{x+=dir*dt*1.3;if(x>1){x=1;dir=-1}if(x<0){x=0;dir=1}$('omk').style.left=(x*100)+'%';if(done)return false});setTimeout(()=>fin(-5),4000)}

// ---------------------------------------------------------------- LOSE: microwave, wall, billboard, Steal A chase, newsstand
let mwT=0;const mwS=sprite(textTex('5',{size:90,w:256,h:128}),2.4,1.2,scene);mwS.visible=false;scene.add(mwS);
function microwave(){const b=blocked();if(b)return toast('⛔ '+b);closePanel();if(!ROOM||ROOM.b.id!=='diner')return;if(mwT)return;mwT=performance.now();toast('⏲️ You stare. The burrito spins. Your brain spins with it.')}
FRAME_HOOKS.push(()=>{if(!mwT||!ROOM||ROOM.b.id!=='diner'){mwS.visible=false;return}const el=(performance.now()-mwT)/1000;const left=Math.ceil(5-el);const p=new THREE.Vector3(ROOM.ox/K,7,ROOM.oy/K-11);mwS.visible=true;mwS.position.copy(p);
  if(left!==mwS.userData.l){mwS.userData.l=left;mwS.material.map=textTex(left>0?'⏲ '+left:'DING!',{size:80,w:256,h:128,color:left>0?'#7dffb0':'#ffd23c'});mwS.material.needsUpdate=true;snd(left>0?'tick':'ping')}
  if(el>5){mwT=0;mwS.visible=false;burst(p.x,4.2,p.z,['#e8a040','#8a4a20','#f2d080','#c03020'],30,12,.35);$('app').classList.add('shakeAll');setTimeout(()=>$('app').classList.remove('shakeAll'),300);snd('slam');lose(3);toast('💥 The burrito EXPLODED. You watched the whole thing.')}});
function bonkWall(){const b=blocked();if(b)return toast('⛔ '+b);S.bonks=(S.bonks||0)+1;lose(2);bonk();ROOM.lunge=performance.now();drawCracks();drawBoard();if(S.bonks%10===0)textMsg('Your friends','LMAO you walked into the wall '+S.bonks+' times 💀')}
function drawCracks(){if(!ROOM||!ROOM.cracks)return;const n=Math.min(40,S.bonks||0);const m=ROOM.cracks.material;m.map=canvasTex((g,w,h)=>{g.clearRect(0,0,w,h);g.strokeStyle='rgba(20,10,5,.9)';g.lineWidth=4;let seed=7;const r=()=>{seed=(seed*16807)%2147483647;return seed/2147483647};for(let i=0;i<n;i++){let x=w/2+(r()-.5)*w*.8,y=h/2+(r()-.5)*h*.7;g.beginPath();g.moveTo(x,y);for(let k=0;k<5;k++){x+=(r()-.5)*70;y+=(r()-.5)*50;g.lineTo(x,y)}g.stroke()}},512,256);m.transparent=true;m.needsUpdate=true}
function drawBoard(){if(!ROOM||!ROOM.lb)return;const rows=[['WallKing_99',412],['BonkMaster',260],['xX_Concrete_Xx',133],['YOU',S.bonks||0],['pigeon',4]].sort((a,b)=>b[1]-a[1]);const m=ROOM.lb.material;m.map=canvasTex((g,w,h)=>{g.fillStyle='#14121c';g.fillRect(0,0,w,h);g.fillStyle='#ffd23c';g.font='700 40px Fredoka';g.textAlign='center';g.fillText('🧱 BONK LEADERBOARD',w/2,52);g.font='700 32px Fredoka';rows.forEach((r,i)=>{g.fillStyle=r[0]==='YOU'?'#7dffb0':'#fff';g.textAlign='left';g.fillText((i+1)+'. '+r[0],40,110+i*48);g.textAlign='right';g.fillText(r[1],w-40,110+i*48)})},512,360);m.needsUpdate=true}
FRAME_HOOKS.push(()=>{if(ROOM&&ROOM.lunge){const t=(performance.now()-ROOM.lunge)/1000;if(t<.5){const k=t<.2?t/.2:1-(t-.2)/.3;ME.g.position.z-=k*1.6}else ROOM.lunge=0}});
// the billboard in town
const billboard=new THREE.Group();billboard.position.set(300/K,0,525/K);town.add(billboard);for(const sx of[-3.5,3.5])mesh(new THREE.CylinderGeometry(.2,.2,8,8),MAT('#555'),billboard,sx,4,0);
const bbFace=new THREE.Mesh(new THREE.PlaneGeometry(10,5),new THREE.MeshBasicMaterial({}));bbFace.position.set(0,9,.2);billboard.add(bbFace);mesh(boxG(10.4,5.4,.3),MAT('#222'),billboard,0,9,0);
function setBillboard(top,mid,bot){bbFace.material.map=canvasTex((g,w,h)=>{const gr=g.createLinearGradient(0,0,w,h);gr.addColorStop(0,'#ff3c78');gr.addColorStop(1,'#7a2cff');g.fillStyle=gr;g.fillRect(0,0,w,h);g.textAlign='center';g.fillStyle='#ffd23c';g.font='700 34px Fredoka';g.fillText(top,w/2,50);g.fillStyle='#fff';g.font='700 40px Fredoka';g.fillText(mid.slice(0,26),w/2,h/2+16);g.font='600 24px Fredoka';g.fillText(bot,w/2,h-26)},512,256);bbFace.material.needsUpdate=true}
setBillboard('BRAINVILLE BILLBOARD',S.viral?'"'+S.viral+'"':'Your ad here','📹 BigReactz reacts to the dumbest comments');
function viralBillboard(text){S.viral=text;setBillboard('📹 BIGREACTZ REACTS TO:','"'+text+'"','😂 '+(1+Math.random()*4).toFixed(1)+'M views • Brainville is laughing');textMsg('Your friends','bro you\'re on the BILLBOARD 💀💀 "'+text+'"')}
// Steal A: a real chase
let CHASE=null;const guard3=avatar('#1d2a4a','#e8b98f','#111',scene);guard3.g.visible=false;const guardTag=sprite(textTex('🚨 GUARD',{size:52}),4,1,guard3.g);guardTag.position.y=6.6;
const loot=new THREE.Group();scene.add(loot);loot.visible=false;mesh(boxG(1.6,1.2,1),MAT('#c0c0c8'),loot,0,.8,0);const lootTag=sprite(textTex('🎯 GRAB IT',{size:52}),4,1,loot);lootTag.position.y=3;
function stealA(){const b=blocked();if(b)return toast('⛔ '+b);const el=panel('🎮 Steal A','<p>Pick a game. Steal A games are a real chase!</p>',{phone:true});const t=rnd(C.StealTricky);
  const opts=shuffle([['Steal A '+rnd(C.StealWords),1],['Steal A '+rnd(C.StealWords)+' 2',1],[t.make,0],[t.fix,0]]);
  btns(el,opts.map(([n,d])=>['🎮 '+esc(n),()=>{tutEvent('steal');if(d){closePanel();startChase(n.replace(/^Steal A /,''))}else{gain(1);toast('🧠 That one was actually educational. Oops.');stealA()}}]))}
function startChase(what){leaveRoom(true);if(inMoon)return toast('No stealing on the Moon.');let x,y,tries=0;do{const a=Math.random()*6.28;x=P.x+Math.cos(a)*260;y=P.y+Math.sin(a)*200;tries++}while((solid(x,y)||x<30||x>W-30||y<30||y>H-30)&&tries<40);
  CHASE={what,x,y,phase:'grab',t0:Date.now()};loot.visible=true;loot.position.set(x/K,0,y/K);lootTag.material.map=textTex('🎯 '+what.toUpperCase(),{size:52});lootTag.material.needsUpdate=true;objective('🎯 Grab the '+what+'!');snd('ping')}
FRAME_HOOKS.push(()=>{if(!CHASE)return;loot.rotation.y+=DT*2;
  if(CHASE.phase==='grab'){if(Math.hypot(P.x-CHASE.x,P.y-CHASE.y)<40){CHASE.phase='run';loot.visible=false;let gx=P.x+180,gy=P.y;if(solid(gx,gy)){gx=P.x-180}CHASE.gx=gx;CHASE.gy=gy;guard3.g.visible=true;objective('🏃 RUN to the ⛲ fountain! The guard is coming!');snd('slam')}if(Date.now()-CHASE.t0>45000)endChase(false,'⌛ Too slow. Someone else stole it.')}
  else{const dx=P.x-CHASE.gx,dy=P.y-CHASE.gy,d=Math.hypot(dx,dy);const sp=135*DT;const nx=CHASE.gx+dx/d*sp,ny=CHASE.gy+dy/d*sp;if(!solid(nx,CHASE.gy))CHASE.gx=nx;if(!solid(CHASE.gx,ny))CHASE.gy=ny;guard3.g.position.set(CHASE.gx/K,0,CHASE.gy/K);guard3.g.rotation.y=Math.atan2(dx,dy);animate(guard3,true,T*1.3);
    if(d<26)endChase(false,'🚨 BUSTED! The guard caught you.');else if(Math.hypot(P.x-PLAZA.x,P.y-PLAZA.y)<110)endChase(true)}});
function endChase(win,msg){guard3.g.visible=false;loot.visible=false;objective('');const w=CHASE.what;CHASE=null;if(win){lose(4);toast('🏆 You stole the '+esc(w)+'! Copycat-game brain: −cells');confetti()}else{toast(msg);if(msg.includes('BUSTED')){S.emb=Math.min(100,S.emb+15);if(S.emb>=50)hide()}}update()}
// the newsstand
const stand=new THREE.Group();stand.position.set(440/K,0,380/K);town.add(stand);mesh(boxG(4,3,2.4),MAT('#2f6b4a'),stand,0,1.5,0);mesh(boxG(4.6,.3,3),MAT('#e5484d'),stand,0,4.2,.2);for(let i=0;i<5;i++)mesh(boxG(.7,.9,.05),MAT(CANDY[i]),stand,-1.5+i*.75,2.2,1.22);for(const sx of[-2,2])mesh(boxG(.15,1.2,.15),darkMat,stand,sx,3.6,1.3);
const standSign=sprite(textTex('📰 NEWS'),3.4,.85,stand);standSign.position.y=5.4;
TOWN_SPOTS.push({id:'spot',n:'📰 Newsstand',label:'Use the newsstand',px:440,py:400,when:()=>true,fn:()=>S.path==='Lose'?newsCatch():dailyTimes()});
function newsCatch(){const b=blocked();if(b)return toast('⛔ '+b);let caught=0,smart=0,left=20;const el=panel('📰 Catch the headlines','<p>Headlines are flying! Tap the <b>clickbait</b> ones. Real news makes you smarter (bad!).</p><div class="sky" id="nsky"></div><p id="nst">20 s</p>');
  btns(el,[["📰 Read today's Brainville Times",()=>dailyTimes()]]);const sky=$('nsky');let spawn=0;
  loopUntil(el,dt=>{left-=dt;$('nst').textContent=Math.ceil(left)+' s • caught '+caught;spawn-=dt;if(spawn<=0&&left>1.5){spawn=.8;const h=rnd(C.Headlines);const d=document.createElement('button');d.className='fly';d.textContent=(h.bait?'😱 ':'')+h.text;d.style.top=(5+Math.random()*75)+'%';d.style.left='100%';d.dataset.v=String(55+Math.random()*50);d.onclick=()=>{if(h.bait){caught++;lose(1);d.classList.add('got')}else{smart++;gain(1);d.classList.add('bad');toast('🤓 That was real news. Oops.')}setTimeout(()=>d.remove(),250)};sky.appendChild(d)}
    for(const d of [...sky.children]){const x=parseFloat(d.style.left)-dt*parseFloat(d.dataset.v)/3;d.style.left=x+'%';if(x<-90)d.remove()}
    if(left<=0){toast('📰 Caught '+caught+' clickbait headline(s)!');tutEvent('clickbait');closePanel();return false}})}
function dailyTimes(){const d=obj('daily');const today=new Date().toDateString();if(d.date!==today){d.date=today;d.cells=S.cells;d.badges=Object.keys(S.badges||{}).length}
  const diff=S.cells-d.cells;const big=Math.abs(diff)>=1e6;const headline=S.path==='Lose'?(big&&diff<0?'LOCAL PLAYER LOSES '+fmt(-diff)+' BRAIN CELLS BEFORE LUNCH':'LOCAL PLAYER STILL HAS BRAIN CELLS, EXPERTS WORRIED'):(big&&diff>0?'LOCAL GENIUS GAINS '+fmt(diff)+' BRAIN CELLS IN ONE DAY':'LOCAL PLAYER THINKING VERY HARD');
  panel('📰 The Brainville Times',`<div class="paperp"><div class="h">THE BRAINVILLE TIMES</div><small>${today}</small><div class="l">${esc(headline)}</div><p>🧠 ${fmt(S.cells)} brain cells • ${esc(iqText(S.cells,S.path))}${S.job?' • 💼 '+esc(careerTitle()):''}</p><p>🏅 ${Object.keys(S.badges||{}).length} badges${Object.keys(S.badges||{}).length>d.badges?' (new today!)':''}${S.viral?'<br>📹 Trending: "'+esc(S.viral)+'"':''}${S.bonks?'<br>🧱 Wall bonks: '+S.bonks:''}</p><p><i>Weather: ${S.path==='Lose'?'🌧 cloudy with a chance of brainrot':'☀️ clear thinking'}</i></p></div>`)}

// ---------------------------------------------------------------- ANIMALS: real 3D bodies + powers (1.6)
const ANIM={};
function partsOf(k){const g=new THREE.Group();scene.add(g);g.visible=false;const m=(geo,c,x,y,z)=>mesh(geo,MAT(c),g,x,y,z);const o={g,wings:[],legs:[],tent:[],segs:[]};
  if(k==='dog'){m(boxG(1.4,1.1,2.6),'#a8743f',0,1.5,0);m(boxG(1.1,1,1.1),'#a8743f',0,2.3,1.5);m(boxG(.6,.45,.6),'#c9935a',0,2.1,2.15);m(boxG(.22,.18,.1),'#111',0,2.25,2.45);for(const sx of[-.4,.4]){m(boxG(.3,.6,.2),'#6b4520',sx,3,1.4);m(boxG(.12,.12,.05),'#111',sx*.6,2.5,2.06)}for(const sx of[-.5,.5])for(const sz of[-.9,.9])o.legs.push(m(boxG(.35,1,.35),'#8a5a2a',sx,.5,sz));o.tail=m(boxG(.2,.2,1),'#a8743f',0,2,-1.6)}
  if(k==='octopus'){m(new THREE.SphereGeometry(1.2,16,12),'#b04fd8',0,2.6,0);for(const sx of[-.45,.45]){m(new THREE.SphereGeometry(.25,8,6),'#fff',sx,2.8,1);m(new THREE.SphereGeometry(.12,8,6),'#111',sx,2.8,1.2)}for(let i=0;i<8;i++){const a=i/8*6.28;const t=new THREE.Group();t.position.set(Math.cos(a)*.7,1.6,Math.sin(a)*.7);t.rotation.y=-a;g.add(t);mesh(new THREE.CylinderGeometry(.18,.06,1.8,6),MAT('#9a3fc4'),t,.6,-.6,0).rotation.z=-1;o.tent.push(t)}}
  if(k==='mouse'){const b=m(new THREE.SphereGeometry(.8,12,10),'#b9b9c2',0,.8,0);b.scale.set(1,.8,1.4);m(new THREE.SphereGeometry(.5,12,10),'#b9b9c2',0,1.1,1.1);for(const sx of[-.35,.35])m(new THREE.CylinderGeometry(.3,.3,.06,12),'#f2a0b5',sx,1.6,1).rotation.x=Math.PI/2;m(new THREE.SphereGeometry(.09,6,6),'#f2a0b5',0,1.05,1.6);o.tail=m(new THREE.CylinderGeometry(.05,.03,1.8,6),'#f2a0b5',0,.7,-1.6);o.tail.rotation.x=1.3}
  if(k==='bee'||k==='fly'){const bc=k==='bee'?'#ffc928':'#2b2b30';const b=m(new THREE.SphereGeometry(.8,14,10),bc,0,1.6,0);b.scale.set(1,.9,1.4);if(k==='bee')for(const z of[-.35,.25])m(boxG(1.62,1.45,.25),'#1a1a1a',0,1.6,z);m(new THREE.SphereGeometry(.5,12,10),k==='bee'?'#1a1a1a':'#2b2b30',0,1.8,1.1);for(const sx of[-.3,.3])m(new THREE.SphereGeometry(k==='fly'?.32:.14,10,8),k==='fly'?'#c0261d':'#fff',sx,1.95,1.35);
    for(const sx of[-1,1]){const w=new THREE.Group();w.position.set(sx*.4,2.2,0);g.add(w);const wm=mesh(boxG(1.4,.04,.9),new THREE.MeshStandardMaterial({color:'#e6f4ff',transparent:true,opacity:.6}),w,sx*.7,0,0);wm.castShadow=false;w.userData.sx=sx;o.wings.push(w)}}
  if(k==='worm'){for(let i=0;i<7;i++)o.segs.push(m(new THREE.SphereGeometry(.42-i*.02,10,8),i%2?'#e8829a':'#f29ab0',0,.42,1.2-i*.55));m(new THREE.SphereGeometry(.07,6,6),'#111',-.15,.6,1.5);m(new THREE.SphereGeometry(.07,6,6),'#111',.15,.6,1.5)}
  if(k==='dead')m(new THREE.DodecahedronGeometry(1.4),'#8d8d92',0,1.2,0);
  return o}
['dog','octopus','mouse','bee','fly','worm','dead'].forEach(k=>ANIM[k]=partsOf(k));
const ANIM_SCALE={dog:1.1,octopus:1,mouse:.9,bee:.9,fly:.75,worm:1,dead:1};
let TF=null; // transformation shrink animation
FRAME_HOOKS.push(()=>{const k=stageK();const human=k==='human'||k==='barely';const hiding=Date.now()<hidingUntil;
  for(const [key,o] of Object.entries(ANIM)){o.g.visible=!human&&!hiding&&key===k}
  if(!human&&ANIM[k]){animalS.visible=false;const o=ANIM[k];let s=ANIM_SCALE[k]||1;if(TF){const t=Math.min(1,(performance.now()-TF.t0)/1600);s*=1.8-0.8*t;if(t>=1&&performance.now()-TF.t0>4200){TF=null;dist=TF_OLD.dist;pitch=TF_OLD.pitch}}
    o.g.scale.setScalar(s);const fl=(k==='bee'||k==='fly')?1.2+Math.sin(T*10)*.25:0;o.g.position.set(P.x/K,PH+fl,P.y/K);o.g.rotation.y=P.face||0;
    o.wings.forEach(w=>w.rotation.z=w.userData.sx*Math.sin(T*40)*.6);o.legs.forEach((l,i)=>l.rotation.x=moving?Math.sin(T*12+(i%2?Math.PI:0))*.6:0);if(o.tail)o.tail.rotation.y=Math.sin(T*(k==='dog'?14:4))*.5;
    o.tent.forEach((t,i)=>t.rotation.z=Math.sin(T*4+i)*.25);o.segs.forEach((sg,i)=>sg.position.x=Math.sin(T*6-i*.8)*(moving?.35:.12))}});
let TF_OLD={dist:18,pitch:.55};
const giants=[];
function transform(st){if(S.dead&&st.k!=='dead')return;closePanel();TF={t0:performance.now()};TF_OLD={dist,pitch};dist=7;pitch=.18;snd('boing');try{navigator.vibrate&&navigator.vibrate(150)}catch(e){}
  const f=$('scene');f.className='scene';f.style.background='transparent';f.style.pointerEvents='none';f.style.opacity=1;f.innerHTML=`<div class="big o">You are now: ${st.e} ${esc(st.n)}</div><p class="o1" style="font-size:16px">"bro is a ${esc(st.n.toLowerCase())} now 💀"</p>`;
  giants.forEach(g=>scene.remove(g.g));giants.length=0;if(!ROOM&&!inMoon){[['#ffb3c7',-5,6],['#9ad1ff',5,6],['#ffe08a',0,9]].forEach(([c,dx,dz])=>{const a=avatar(c,'#f2c79a','#2b3a67',scene);a.g.position.set(P.x/K+dx,0,P.y/K+dz);a.g.lookAt(P.x/K,0,P.y/K);giants.push(a)})}
  const tips={dog:'🐶 Power: BARK (button bottom-right) scares pigeons and people.',bee:'🐝 Power: FLY. Tap ⤒ again in the air to keep flying over rooftops.',fly:'🪰 Power: walk into a wall to CLIMB it.',mouse:'🐭 Power: fit through MOUSE HOLES in rooms (Library, Diner, Mall).',worm:'🪱 Power: DIG tunnels to other buildings.',octopus:'🐙 Power: ink cloud (button) to hide from embarrassment.'};
  setTimeout(()=>{f.classList.add('hide');f.style.pointerEvents='';if(tips[st.k])toast(tips[st.k])},4000);setTimeout(()=>{giants.forEach(g=>scene.remove(g.g));giants.length=0},4300);update()}
// power button
const actBtn=document.createElement('button');actBtn.id='actBtn';actBtn.className='hide';$('app').appendChild(actBtn);
const POWERS={dog:['🐶','Bark',()=>{blip(180);setTimeout(()=>blip(160),120);toast('🐶 WOOF!');for(const n of npcs){if(Math.hypot(n.x-P.x,n.y-P.y)<260){n.tx=n.x+(n.x-P.x)*2;n.ty=n.y+(n.y-P.y)*2;n.t=3}}const pk=BLD.find(o=>o.pigeons);if(pk&&Math.hypot(P.x-(pk.b.x+pk.b.w/2),P.y-(pk.b.y+pk.b.h/2))<260){pk.scare=performance.now();toast('🐦 The pigeons flew away!')}}],
  bee:['🐝','Fly up',()=>{PV=22}],worm:['🪱','Dig',()=>digTunnel()],octopus:['🐙','Ink',()=>{burst(P.x/K,PH+2,P.y/K,['#111','#222','#333'],30,6,.6);S.emb=Math.max(0,S.emb-20);toast('🐙 *INK CLOUD* Nobody saw anything. Embarrassment −20');update()}]};
FRAME_HOOKS.push(()=>{const p=POWERS[stageK()];const show=!!p&&$('panelWrap').classList.contains('hide')&&!document.body.classList.contains('photo');actBtn.classList.toggle('hide',!show);if(show&&actBtn.dataset.k!==stageK()){actBtn.dataset.k=stageK();actBtn.innerHTML=p[0]+'<small>'+p[1]+'</small>';actBtn.onclick=e=>{e.stopPropagation();p[2]()}}
  const pk=BLD.find(o=>o.pigeons);if(pk&&pk.scare){const t=(performance.now()-pk.scare)/1000;pk.pigeons.forEach((p,i)=>{p.position.y=t<4?.35+t*t*2:.35});if(t>6)pk.scare=0}});
function digTunnel(){const opts=B.filter(b=>b.p&&(!ROOM||b!==ROOM.b));const to=rnd(opts);burst(P.x/K,.5,P.y/K,['#6b4a2a','#8a5a32','#4a3420'],30,8,.4);blip(120);
  const f=$('wipe');f.style.background='#5a3a20';wipe(()=>{leaveRoom(true);P.x=to.door.x;P.y=to.door.y+30;P.tx=null;f.style.background='';toast('🪱 You dug a tunnel to the '+esc(to.n.charAt(0)+to.n.slice(1).toLowerCase())+'!')})}
// bees fly over rooftops, flies climb walls
function bldAt(x,y){for(const b of B)if(!b.park&&x>b.x-6&&x<b.x+b.w+6&&y>b.y-6&&y<b.y+b.h+4)return b;return null}
function groundH(){if(ROOM||inMoon)return 0;const k=stageK();if(k!=='bee'&&k!=='fly')return 0;const b=bldAt(P.x,P.y);if(!b)return 0;const h=HEIGHT[b.id]||10;return PH>=h-.6?h:0}
function animalPass(x,y){if(ROOM||inMoon)return false;const k=stageK();if(k!=='bee'&&k!=='fly')return false;const b=bldAt(x,y);if(!b)return false;const h=HEIGHT[b.id]||10;if(PH>=h-.6)return true;if(k==='fly'){PH=Math.min(h,PH+.45);PV=0;climbing=performance.now()}return false}
let climbing=0;
// mouse holes in some rooms + the secret Mouse Lounge
LAYOUT.mousehole=b=>{sign('🐭 MICE ONLY',0,-14.8);for(let i=0;i<5;i++){const c=rm(new THREE.CylinderGeometry(1.4,1.4,1.2,3),MAT('#ffd23c'),-12+i*6,.6,-6);c.rotation.y=i}rm(boxG(5,1,3),MAT('#c0392b'),10,.5,6);rm(boxG(5,.3,3.2),MAT('#f4f4f2'),10,1.1,6);rm(new THREE.CylinderGeometry(1.5,1.2,2,16),METAL,-10,1,6);
  spot(0,-3.5,'Eat the cheese','🧀 Giant cheese',()=>{badge('mouselounge','Secret Mouse Lounge');if(S.path==='Lose')lose(1);toast('🧀 Delicious. Your tiny brain is happy.')},true)};
function addHole(r,b,lx){const h=rm(new THREE.CylinderGeometry(1,1,.2,16,1,false,0,Math.PI),MAT('#140c08'),lx,0,-14.6,r.g);h.rotation.x=Math.PI/2;h.rotation.z=0;h.position.y=0;spot(lx,-12.6,'Squeeze into the mouse hole','🕳 Tiny hole',()=>{if(stageK()!=='mouse')return toast('🕳 Only something mouse-sized fits in there…');const back=ROOM.back;leaveRoom(true);enterRoom({id:'mousehole',n:'MOUSE HOLE LOUNGE',p:'Any',i:31,door:{x:back.x,y:back.y-30}})})}
// rubber chicken hidden in every room
function addChicken(r,b){if(obj('chickens')[b.id])return;const corners=[[-19,-12],[19,-12],[-19,12],[19,12],[-17,0],[17,0]];const [x,z]=corners[b.i%corners.length];const g=grp(x,z,b.i);rm(new THREE.SphereGeometry(.45,10,8),MAT('#ffe23c'),0,.45,0,g).scale.set(1,.9,1.3);rm(new THREE.SphereGeometry(.28,10,8),MAT('#ffe23c'),0,.95,.4,g);rm(boxG(.12,.18,.3),MAT('#e5484d'),0,1.25,.4,g);rm(boxG(.12,.1,.2),MAT('#ff8a1d'),0,.9,.7,g);
  const s=spot(x,z+1.4,'Squeak','🐔 Rubber chicken',()=>{obj('chickens')[b.id]=1;g.visible=false;r.spots=r.spots.filter(q=>q!==s);blip(1500);setTimeout(()=>blip(1700),90);const n=Object.keys(S.chickens).length;toast('🐔 *SQUEAK* Rubber chicken '+n+'/15 found!');if(n>=15)badge('chickens','Fooled You (Chicken Collector)');save()})}
buildRoom=(orig=>function(b){const r=orig(b);addChicken(r,b);if(['library','diner','mall'].includes(b.id))addHole(r,b,b.id==='mall'?4:-6);if(b.id==='wall'){r.cracks=new THREE.Mesh(new THREE.PlaneGeometry(40,8),new THREE.MeshBasicMaterial({transparent:true,depthWrite:false}));r.cracks.position.set(0,4.5,-10.2);r.g.add(r.cracks);r.lb=canvasPlane(7,5,(g,w,h)=>{},-21.6,5,4,Math.PI/2,r.g);drawCracks();drawBoard()}if(b.id==='diner'){}return r})(buildRoom);
LAYOUT.wall=b=>{sign('🧱 WALL ALLEY',0,-14.8);for(let r=0;r<10;r++)for(let c=0;c<12;c++){const br=rm(boxG(3.4,.85,1.4),MAT(['#a0522d','#8b4a2b','#b35f37'][(r+c)%3]),-18+c*3.6+(r%2)*1.8,.45+r*.9,-11);br.castShadow=false}col(0,-11,44,1.6);rm(boxG(2.6,3,2.4),MAT('#4a6a3a'),15,1.5,8);
  spot(0,-8.6,'Walk into the wall','🧱 The Wall',guard('Lose',bonkWall),true);spot(-18,4,'Check the leaderboard','🏆 Bonk leaderboard',()=>toast('🏆 You have '+(S.bonks||0)+' bonks.'))};
// school with more space + Lose-path class actions
LAYOUT.school=b=>{sign('🏫 SCHOOL',0,-14.8);ROOM.board=whiteboard(0,-14.6,S.path==='Lose'?'2 + 2 = fish':'Today: fractions');const xs=[-13.5,-4.5,4.5,13.5];const kids=['#ff8fa3','#8fd3ff','#ffd27a','#a8f0b0','#d0b0ff','#ffb38a'];let k=0;
  for(let r=0;r<2;r++)for(const x of xs){desk(x,-4+r*7,Math.PI,false);if(k<6&&!(r===1&&(x===-4.5||x===4.5)))npcAt(x,-2.2+r*7,Math.PI,kids[k++%6],'Student')}desk(0,-10.5,0,true);
  spot(0,-7.5,S.path==='Lose'?'Take the pop quiz':'Teach the class','✏️ Classroom',()=>startConv(S.path==='Lose'?'classroomL':'classroomG'),true);spot(5,-12,'Write on the board','🧑‍🏫 Whiteboard',writeBoard);spot(-10,-10.5,'Work','💼 Teacher\'s desk',guard('Gain',work));
  if(S.path==='Lose'){spot(-4.5,6,'Sleep in class','😴 Your desk',()=>doAct(()=>{lose(1.5);toast('😴 Zzz… you drooled on the desk.')}));spot(4.5,6,'Throw a paper airplane','✈️ Paper',()=>doAct(()=>{lose(1);S.emb=Math.min(100,S.emb+5);burst(ME.g.position.x,4,ME.g.position.z,['#ffffff'],1,10,.6);toast('✈️ It hit the teacher. Detention vibes.');update()}))}};
// university: the gate is a real door with locks
LAYOUT.university=b=>{sign('🎓 UNIVERSITY',0,-14.8);whiteboard(-6,-14.6,'E = mc²   a² + b² = c²');for(let r=0;r<2;r++)for(let c=-1;c<=1;c++)desk(-6+c*8,-3+r*8,Math.PI,false);podium(-6,-10);
  rm(boxG(1,10,1.4),MAT('#f0be28'),12,5,-13.6);rm(boxG(1,10,1.4),MAT('#f0be28'),20,5,-13.6);rm(boxG(9,1,1.4),MAT('#f0be28'),16,10,-13.6);ROOM.gateDoor=rm(boxG(7,9,.6),MAT('#5a4a3a'),16,4.5,-13.6);ROOM.locks=[0,1,2].map(i=>{const m=new THREE.Mesh(new THREE.SphereGeometry(.45,12,10),new THREE.MeshStandardMaterial({color:'#e5484d',emissive:'#7a1010'}));m.position.set(14+i*2,6.5,-13.1);ROOM.g.add(m);return m});
  canvasPlane(5.6,1.2,(g,w,h)=>{g.fillStyle='#000';g.fillRect(0,0,w,h);g.fillStyle='#f0be28';g.font='700 64px Fredoka';g.textAlign='center';g.fillText('🚧 SKILL GATE',w/2,h/2+22)},16,11.4,-12.8);
  if(!GATES.some(g=>!S.gates[g.iq])){ROOM.gateDoor.position.y=13.5;setTimeout(()=>setLocks(3),0)}
  spot(16,-10.5,'Face the Skill Gate','🚧 Skill Gate',guard('Gain',gate),true)};
FRAME_HOOKS.push(()=>{if(ROOM&&ROOM.gateDoor&&ROOM.gateOpenT){const t=Math.min(1,(performance.now()-ROOM.gateOpenT)/1500);ROOM.gateDoor.position.y=4.5+t*9;if(t>=1){ROOM.gateOpenT=0;setTimeout(()=>{if(ROOM&&ROOM.gateDoor&&GATES.some(g=>!S.gates[g.iq])){ROOM.gateDoor.position.y=4.5;setLocks(0)}},4000)}}});
// optician
LAYOUT.house3=b=>{sign('👓 OPTICIAN',0,-14.8);counter(0,-11,14,0,MAT('#dfe8ff'));for(let i=0;i<6;i++){const gl=rm(boxG(1.2,.25,.1),MAT(['#a050ff','#ffd700','#00ffb4','#3a2a20','#b4b4be','#c8d2dc'][i]),-6+i*2.4,3.7,-10.6)}rm(boxG(4,7,.2),new THREE.MeshStandardMaterial({color:'#dfefff',metalness:.8,roughness:.05}),-18,4,-14.6);npcAt(0,-13,0,'#e9f2ff','Optician');plant(18,-12);chair(10,4,0);
  spot(0,-8.4,'Browse glasses','👓 Optician',guard('Gain',optician),true)};

// ---------------------------------------------------------------- TOWN: morphing buildings, day & night, NPC texts
let prevLook=null,morphT=0;FRAME_HOOKS.push(()=>{const lk=appliedLook;if(lk&&lk!=='moon'&&!ROOM&&lk!==prevLook){if(prevLook&&prevLook!=='moon')morphT=performance.now();prevLook=lk}
  if(morphT){const t=(performance.now()-morphT)/1000;BLD.forEach((o,i)=>{const lt=Math.max(0,Math.min(1,(t-i*.05)/.7));const s=lt<1?0.35+0.65*(1-Math.pow(1-lt,3))+Math.sin(lt*Math.PI)*.15:1;o.g.scale.y=s});if(t>2){morphT=0;BLD.forEach(o=>o.g.scale.y=1)}}});
const DAY_LEN=720; // real seconds per in-game day (12 minutes)
function gameHour(){return((Date.now()/1000/DAY_LEN*24)+7)%24}
const NIGHT=new THREE.Color('#0b1030'),_sky=new THREE.Color();
FRAME_HOOKS.push(()=>{if(ROOM||inMoon||!appliedLook||!SKY[appliedLook])return;const h=gameHour();const day=Math.max(0,Math.min(1,Math.sin((h-6)/12*Math.PI)*1.4+.2));const sk=SKY[appliedLook];
  _sky.set(sk[0]).lerp(NIGHT,(1-day)*.85);scene.background=_sky;if(scene.fog)scene.fog.color.copy(_sky);sun.intensity=sk[2]*(.12+.88*day);hemi.intensity=sk[3]*(.35+.65*day);
  lampMats.forEach(m=>m.emissiveIntensity=day<.4?2:(appliedLook==='fancy'||appliedLook==='future'?1.4:.5));glassMat.emissive.set(day<.35?'#6a5a20':appliedLook==='fancy'?'#6a4a20':appliedLook==='future'?'#1f6a78':'#000000')});
function clockText(){const h=gameHour();const hh=Math.floor(h),mm=Math.floor((h-hh)*60/10)*10;return(hh<6||hh>=20?'🌙 ':'☀️ ')+String(hh).padStart(2,'0')+':'+String(mm).padStart(2,'0')}
function textMsg(from,msg){const t=arr('texts');t.unshift({from,msg,at:clockText()});if(t.length>30)t.pop();S.unread=(S.unread||0)+1;toast('📱 <b>'+esc(from)+'</b>: '+esc(msg));blip(1000);setTimeout(()=>blip(1300),100);updBadge();save()}
function updBadge(){$('phoneBtn').dataset.n=S.unread?String(S.unread):''}
function messages(){S.unread=0;updBadge();const el=panel('💬 Messages',(S.texts||[]).length?'':'<p>No messages yet. Do stuff. People will talk.</p>',{phone:true});(S.texts||[]).forEach(t=>el.insertAdjacentHTML('beforeend',`<div class="sms"><b>${esc(t.from)}</b><small>${esc(t.at)}</small><br>${esc(t.msg)}</div>`))}
phone=(orig=>function(){orig();const apps=$('apps');if(!apps)return;const add=(ic,n,g,fn)=>{const b=document.createElement('button');b.className='app';b.innerHTML=`<span style="background:linear-gradient(135deg,${g})">${ic}</span>${n}${n==='Messages'&&S.unread?' 🔴':''}`;b.onclick=()=>{snd('boing');fn()};apps.appendChild(b)};add('💬','Messages','#46d278,#1e965a',messages);add('📰','Times','#ececec,#9a9a9a',dailyTimes);if(S.path==='Gain')add('👓','Glasses','#9b5cff,#5a2ca8',()=>{toast('👓 Visit the Optician (east of the Courthouse) to buy glasses.')})})(phone);
setInterval(()=>{if(!S.path||Math.random()<.5)return;const L=S.path==='Lose'?[['Your friends','are you ok? you stared at a microwave for 5 minutes'],['Grandma','Did you read the book I sent you? 📚'],['BrainTok','🔥 new video from @noodlelord just dropped'],['Unknown','u won a free brain!!! (scam)']]:[['Your teacher','Proud of your progress! Keep reading.'],['Your mom','Did you eat? Big brains need food 🍝'],['Albert Zweistein','Time is relative. Your homework is not.'],['Your boss','Great work today 👍']];const [f,m]=rnd(L);textMsg(f,m)},150000);
badge=(orig=>function(k,name){const had=S.badges&&S.badges[k];orig(k,name);if(!had&&Math.random()<.6)setTimeout(()=>textMsg(rnd(['Your friends','Your mom','Your teacher']),'omg you got "'+name+'"!! 🏅'),1500)})(badge);
comments=(orig=>orig)(comments);

// ---------------------------------------------------------------- SCHOOL BELL + TRUANT OFFICER (Lose path, 1.6)
let lastHour=gameHour(),SCHOOL=null;const officer=avatar('#1e3a8a','#e8b98f','#111',scene);officer.g.visible=false;const offTag=sprite(textTex('👮 TRUANT OFFICER',{size:46}),5,1.2,officer.g);offTag.position.y=6.6;
setInterval(()=>{const h=gameHour();if(S.path==='Lose'&&!S.dead&&lastHour<8&&h>=8&&h<9){const k=stageK();if(k==='human'||k==='barely'){SCHOOL={start:Date.now(),state:'go'};snd('slam');setTimeout(()=>snd('ping'),300);toast('🔔 SCHOOL BELL! Get to the 🏫 School before 9:30 or the truant officer comes for you.');objective('🏫 Go to school! (be there by 9:30)')}}lastHour=h;
  if(!SCHOOL)return;if(SCHOOL.state==='go'){if(ROOM&&ROOM.b.id==='school'){SCHOOL.state='in';objective('😴 You\'re in class. Act dumb: sleep, throw paper, fail the quiz.');toast('✅ You made it to class. Now act dumb.');setTimeout(()=>{if(SCHOOL&&SCHOOL.state==='in'){SCHOOL=null;objective('');toast('🔔 Class is over.')}},60000)}else if(h>=9.5){SCHOOL.state='chase';SCHOOL.ox=P.x+220;SCHOOL.oy=P.y;SCHOOL.until=Date.now()+30000;if(ROOM){SCHOOL.state='go'}else{officer.g.visible=true;objective('👮 The truant officer is coming! Run (or just go to school)!');snd('slam')}}}},500);
FRAME_HOOKS.push(()=>{if(!SCHOOL||SCHOOL.state!=='chase')return;if(ROOM&&ROOM.b.id==='school'){officer.g.visible=false;SCHOOL.state='in';objective('😴 Fine, you\'re in class. Act dumb.');return}if(ROOM){return}
  const dx=P.x-SCHOOL.ox,dy=P.y-SCHOOL.oy,d=Math.hypot(dx,dy);const sp=150*DT;const nx=SCHOOL.ox+dx/d*sp,ny=SCHOOL.oy+dy/d*sp;if(!solid(nx,SCHOOL.oy))SCHOOL.ox=nx;if(!solid(SCHOOL.ox,ny))SCHOOL.oy=ny;officer.g.position.set(SCHOOL.ox/K,0,SCHOOL.oy/K);officer.g.rotation.y=Math.atan2(dx,dy);animate(officer,true,T*1.2);
  if(d<26){officer.g.visible=false;SCHOOL={start:Date.now(),state:'in'};S.emb=Math.min(100,S.emb+10);toast('👮 CAUGHT! The officer drags you to class. Embarrassment +10');enterRoom(B.find(b=>b.id==='school'));objective('😴 Detention. Act dumb in class.');update()}
  else if(Date.now()>SCHOOL.until){officer.g.visible=false;SCHOOL=null;objective('');toast('😮‍💨 You escaped the truant officer. Legend.')}});
// animals can't go to school
enterRoom=(orig=>function(b){if(b&&b.id==='school'&&S.path==='Lose'&&!['human','barely'].includes(stageK())){toast('🚫 No animals in school. You\'re officially too dumb for school now.');return}return orig(b)})(enterRoom);

// ---------------------------------------------------------------- unstuck + settings additions
function unstuck(){closePanel();if(ROOM){P.x=ROOM.ox;P.y=ROOM.oy+(RSIZE.d/2-5)*K}else if(inMoon){P.x=MOON.cx;P.y=MOON.cy+210}else{P.x=PLAZA.x;P.y=PLAZA.y+110}P.tx=null;standUp();toast('🆘 Unstuck!')}
settings=(orig=>function(){orig();const pc=$('pc');if(pc)btns(pc,[['🆘 I\'m stuck<small>Moves you to a safe spot.</small>',unstuck]])})(settings);
updBadge();
