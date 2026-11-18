
// ================================================================ INTERACTIVE WORLD: talk to anyone, emotes, physics, orbs, skateboard, pets
const NPC_NAMES=['Maya','Leo','Noa','Sam','Ari','Zoe','Ben','Tali','Omer','Lily','Max','Ella'];
npcs.forEach((n,i)=>{n.name=NPC_NAMES[i%NPC_NAMES.length]});
let pvx=0,pvy=0,_ppx=P.x,_ppy=P.y;FRAME_HOOKS.push(()=>{pvx=(P.x-_ppx)/Math.max(DT,.001);pvy=(P.y-_ppy)/Math.max(DT,.001);_ppx=P.x;_ppy=P.y});
const NPCBUB=[];function npcSay(n,text,ms=2600){let o=NPCBUB.find(b=>b.n===n);if(!o){o={n,s:sprite(textTex('',{size:40,bg:'rgba(255,255,255,.95)',color:'#222'}),6,1.3,town)};NPCBUB.push(o)}o.s.material.map=textTex(text,{size:40,bg:'rgba(255,255,255,.95)',color:'#222'});o.s.material.needsUpdate=true;o.until=Date.now()+ms}
FRAME_HOOKS.push(()=>{for(const o of NPCBUB){o.s.visible=Date.now()<o.until&&!ROOM&&!inMoon;if(o.s.visible)o.s.position.set(o.n.x/K,8.6,o.n.y/K)}});

// ---------------- 1) talk to anyone on the street
const npcSpot={id:'spot',n:'🧍 Someone',label:'Talk',px:0,py:0,cur:null,when:()=>!!npcSpot.cur,fn:()=>talkTo(npcSpot.cur)};TOWN_SPOTS.push(npcSpot);
FRAME_HOOKS.push(()=>{let best=null,bd=55;if(!ROOM&&!inMoon)for(const n of npcs){const d=Math.hypot(n.x-P.x,n.y-P.y);if(d<bd){bd=d;best=n}}npcSpot.cur=best;if(best){npcSpot.px=best.x;npcSpot.py=best.y;npcSpot.n='🧍 '+best.name}});
function talkTo(n){n.t=6;n.tx=n.x;n.ty=n.y;n.f=Math.atan2(P.x-n.x,P.y-n.y);const lk=look();const st=stageOf(S.cells);
  const greet=st.k!==('human')&&st.k!=='barely'?rnd(['…is that a '+st.n.toLowerCase()+'? Talking?','AAAH a talking '+st.n.toLowerCase()+'!','cute '+st.n.toLowerCase()+' 🥺']):S.path==='Lose'?rnd(['hey… do you smell burnt popcorn?','bro your brain is buffering','did you just walk into that lamp?','hi!! I saw you on the billboard lol']):rnd(['oh hi, genius!','hey! you\'re the one from the library!','hi! can I ask you something?','nice glasses 😎']);
  npcSay(n,greet);const el=panel('💬 '+n.name,`<p>"${esc(greet)}"</p>`);
  btns(el,[['👋 Say hi',()=>{closePanel();npcSay(n,rnd(['hi!! 👋','heyyy','sup','hello friend']));blip(900)}],
   ['❓ "Ask me anything"',()=>{const q=rnd(C.Library.concat(C.Theater));panel('❓ '+n.name+' asks…','');question($('pc'),q,ok=>{closePanel();if(ok){npcSay(n,rnd(['woah, smart!','you\'re so right','I learned something!']));if(S.path==='Gain'){gain(1);S.coins+=5}else{gain(.6);toast('🤓 Oops, answering correctly made you smarter.')}}else{npcSay(n,rnd(['…that\'s not it 😅','lol no','are you sure?']));if(S.path==='Lose')lose(.8)}update()})}],
   ['🙌 High five',()=>{closePanel();highFive(n)}],
   ['🕺 Dance-off',()=>{mgRhythm('🕺 Dance-off vs '+n.name,'Hit the beat 5 times to win the dance-off!',ok=>{closePanel();if(ok){npcSay(n,'you WIN 🏆');doEmote('dance');S.coins+=8;confetti();if(S.path==='Lose'){S.emb=Math.min(100,S.emb+8)}else S.stress=Math.max(0,S.stress-10)}else npcSay(n,'I win 😎 better luck next time');update()})}],
   [S.path==='Lose'?'🤡 Tell them a fake fact':'📚 Teach them something',()=>{closePanel();if(S.path==='Lose'){npcSay(n,rnd(['wait… cows can fly??','REALLY? the moon is a lamp??','no way the ocean is soup']));lose(1);toast('🤡 You spread a fake fact. Your brain feels lighter.')}else{const f=rnd(C.Theater);npcSay(n,'woah, I didn\'t know that!');gain(.8);S.coins+=4;toast('📚 You taught '+n.name+': '+esc(f.text.replace(/^Fun fact: /,'')))}update()}]])}
function highFive(n){const el=panel('🙌 High five!','<p>Tap when the hands meet!</p><div class="hf"><span id="hl">✋</span><span id="hr">🤚</span></div>');let t=0,done=false;btns(el,[['🙌 NOW!',()=>{if(done)return;done=true;const d=Math.abs(Math.sin(t*3));const ok=d<.22;closePanel();npcSay(n,ok?'PERFECT high five 🙌':'…you missed my hand 😐');snd(ok?'good':'bad');if(ok){S.coins+=3;if(S.path==='Gain')S.stress=Math.max(0,S.stress-5)}else if(S.path==='Lose'){S.emb=Math.min(100,S.emb+6)}update()},'go']]);
  loopUntil(el,dt=>{t+=dt;const d=Math.abs(Math.sin(t*3))*45;$('hl').style.transform=`translateX(${-d}px)`;$('hr').style.transform=`translateX(${d}px)`;return !done})}

// ---------------- 2) emotes (people around you react)
const emoBtn=document.createElement('button');emoBtn.id='emoBtn';emoBtn.textContent='😀';emoBtn.setAttribute('aria-label','Emotes');$('app').appendChild(emoBtn);
const EMOTES=[['wave','👋','Wave'],['dance','🕺','Dance'],['flex','💪','Flex'],['facepalm','🤦','Facepalm'],['laugh','😂','Laugh'],['salute','🫡','Salute']];
emoBtn.onclick=e=>{e.stopPropagation();let m=$('emoMenu');if(m){m.remove();return}m=document.createElement('div');m.id='emoMenu';EMOTES.forEach(([k,ic,n])=>{const b=document.createElement('button');b.innerHTML=ic+'<small>'+n+'</small>';b.onclick=ev=>{ev.stopPropagation();m.remove();doEmote(k)};m.appendChild(b)});$('app').appendChild(m)};
let EMOTE=null;
function doEmote(k){EMOTE={k,t0:performance.now()};blip(800);const react={wave:['👋','hi!!','hey!'],dance:['🔥🔥','GO GO GO','lol nice moves'],flex:['💪 woah','ok show-off','😳'],facepalm:['😂','same','lol what happened'],laugh:['😂😂','what\'s funny?','lol'],salute:['🫡','yes captain','🫡🫡']}[k];
  let n=0;for(const p of npcs){if(Math.hypot(p.x-P.x,p.y-P.y)<220){n++;setTimeout(()=>npcSay(p,rnd(react)),200+Math.random()*600);if(k==='dance'){p.tx=P.x+(Math.random()-.5)*90;p.ty=P.y+(Math.random()-.5)*90;p.t=6}}}
  if(k==='dance'&&n>=2){toast('🕺 A crowd is forming! ('+n+' people)');if(S.path==='Lose'){S.emb=Math.min(100,S.emb+4)}else S.stress=Math.max(0,S.stress-6);S.coins+=n;update()}}
FRAME_HOOKS.push(()=>{if(!EMOTE)return;const t=(performance.now()-EMOTE.t0)/1000;if(t>3){EMOTE=null;return}const a=ME;const k=EMOTE.k;
  if(k==='wave'){a.aR.rotation.x=-2.8;a.aR.rotation.z=Math.sin(t*12)*.4}else if(k==='dance'){a.aL.rotation.x=Math.sin(t*10)*2;a.aR.rotation.x=-Math.sin(t*10)*2;ME.g.rotation.y+=Math.sin(t*6)*.6;ME.g.position.y+=Math.abs(Math.sin(t*10))*.6}
  else if(k==='flex'){a.aL.rotation.x=a.aR.rotation.x=-1.6;a.aL.rotation.z=.8;a.aR.rotation.z=-.8}else if(k==='facepalm'){a.aR.rotation.x=-2.5;a.head.rotation.x=.35}else if(k==='laugh'){a.head.rotation.x=-.3+Math.sin(t*20)*.12;ME.g.position.y+=Math.abs(Math.sin(t*20))*.15}else if(k==='salute'){a.aR.rotation.x=-2.6;a.aR.rotation.z=-.6}});

// ---------------- 3) physics: soccer ball, goal, cones, trash cans
const PROPS=[];function addProp(kind,x,y){const g=new THREE.Group();town.add(g);let r=12;
  if(kind==='ball'){const m=mesh(new THREE.SphereGeometry(.8,16,12),MAT('#ffffff'),g,0,.8,0);mesh(new THREE.SphereGeometry(.81,6,4),new THREE.MeshStandardMaterial({color:'#111',wireframe:true}),g,0,.8,0);r=9}
  else if(kind==='cone'){mesh(new THREE.ConeGeometry(.6,1.6,12),MAT('#ff7a1a'),g,0,.8,0);mesh(boxG(1.4,.15,1.4),MAT('#ff7a1a'),g,0,.07,0);r=9}
  else{mesh(new THREE.CylinderGeometry(.8,.7,2,14),MAT('#5a6a7a'),g,0,1,0);mesh(new THREE.CylinderGeometry(.85,.85,.2,14),MAT('#3a4a5a'),g,0,2.05,0);r=11}
  const o={kind,g,x,y,ox:x,oy:y,vx:0,vy:0,r,tipped:false};PROPS.push(o);return o}
const BALL=addProp('ball',PLAZA.x+60,PLAZA.y+150);[[480,560],[640,560],[300,355],[820,355]].forEach(([x,y])=>addProp('cone',x,y));[[260,370],[720,370],[1000,560]].forEach(([x,y])=>addProp('trash',x,y));
const parkB=B.find(b=>b.park);const GOAL={x:parkB.x+parkB.w/2,y:parkB.y+12,w:60};const goalG=new THREE.Group();goalG.position.set(GOAL.x/K,0,GOAL.y/K);town.add(goalG);
for(const sx of[-1,1])mesh(boxG(.25,3,.25),MAT('#ffffff'),goalG,sx*GOAL.w/2/K,1.5,0);mesh(boxG(GOAL.w/K+.25,.25,.25),MAT('#ffffff'),goalG,0,3,0);const net=mesh(boxG(GOAL.w/K,3,.05),new THREE.MeshStandardMaterial({color:'#ddd',transparent:true,opacity:.35}),goalG,0,1.5,-1.2);net.castShadow=false;
const goalSign=sprite(textTex('⚽ GOAL — kick the ball in!',{size:40}),6,1.2,goalG);goalSign.position.y=4.8;
FRAME_HOOKS.push(()=>{if(ROOM||inMoon)return;const sp=Math.hypot(pvx,pvy);
  for(const o of PROPS){const dx=o.x-P.x,dy=o.y-P.y,d=Math.hypot(dx,dy);if(d<o.r+12&&sp>20&&PH<2){const k=o.kind==='ball'?1.6:o.kind==='cone'?1.1:.7;o.vx+=dx/d*sp*k*DT*6+pvx*.08;o.vy+=dy/d*sp*k*DT*6+pvy*.08;if(o.kind==='trash'&&!o.tipped&&sp>120){o.tipped=true;burst(o.x/K,1.5,o.y/K,['#9a9a9a','#e8d070','#c0392b','#6ab04c'],14,6,.3);toast(S.path==='Lose'?'🗑 You knocked over a trash can. For fun.':'🗑 Oops! You knocked over a trash can.');if(S.path==='Lose'){lose(.3)}else{S.coins=Math.max(0,S.coins-1)}}}
    const nx=o.x+o.vx*DT,ny=o.y+o.vy*DT;if(solid(nx,o.y)){o.vx*=-.6}else o.x=nx;if(solid(o.x,ny)){o.vy*=-.6}else o.y=ny;o.x=Math.max(10,Math.min(W-10,o.x));o.y=Math.max(10,Math.min(H-10,o.y));
    const fr=o.kind==='ball'?.985:.9;o.vx*=Math.pow(fr,DT*60);o.vy*=Math.pow(fr,DT*60);o.g.position.set(o.x/K,0,o.y/K);
    if(o.kind==='ball'){o.g.children[0].rotation.x+=o.vy*DT*.12;o.g.children[0].rotation.z-=o.vx*DT*.12;o.g.children[1].rotation.copy(o.g.children[0].rotation)}
    if(o.kind==='trash')o.g.rotation.z+=((o.tipped?1.4:0)-o.g.rotation.z)*.15;if(o.kind==='cone'&&Math.hypot(o.vx,o.vy)>60)o.g.rotation.z=.9}
  if(Math.abs(BALL.x-GOAL.x)<GOAL.w/2&&BALL.y<GOAL.y+4&&BALL.y>GOAL.y-20){S.goals=(S.goals||0)+1;burst(BALL.x/K,1,BALL.y/K,['#ffd23c','#2fbf71','#3a7bff','#ff4f9a'],30,10,.3);toast('⚽ GOOOOAL! ('+S.goals+')');snd('good');confetti();S.coins+=10;if(S.goals===5)badge('striker','Brainville Striker');for(const p of npcs)if(Math.hypot(p.x-P.x,p.y-P.y)<300)npcSay(p,rnd(['GOAAAL!','⚽🔥','what a shot!']));BALL.x=PLAZA.x+60;BALL.y=PLAZA.y+150;BALL.vx=BALL.vy=0;update()}});
setInterval(()=>{for(const o of PROPS)if(o.kind==='trash'&&o.tipped&&Math.hypot(o.x-P.x,o.y-P.y)>400){o.tipped=false;o.x=o.ox;o.y=o.oy}},20000);

// ---------------- 4) orbs to collect, with combos
const ORBS=[];let comboN=0,comboT=0;
function placeOrb(o){const p=freeSpot();o.x=p.x;o.y=p.y;o.alive=true;o.s.visible=true}
for(let i=0;i<10;i++){const o={s:sprite(emojiTex('🧠'),1.6,1.6,town)};placeOrb(o);ORBS.push(o)}
FRAME_HOOKS.push(()=>{const em=S.path==='Lose'?'🍬':'🧠';for(const o of ORBS){if(o.s.userData.e!==em){o.s.userData.e=em;o.s.material.map=emojiTex(em);o.s.material.needsUpdate=true}o.s.visible=o.alive&&!!S.path;if(!o.alive)continue;o.s.position.set(o.x/K,1.6+Math.sin(T*3+o.x)*.3,o.y/K);
  if(S.path&&!ROOM&&!inMoon&&!S.dead&&Math.hypot(o.x-P.x,o.y-P.y)<26){o.alive=false;const now=performance.now();comboN=now-comboT<5000?comboN+1:1;comboT=now;const mult=Math.min(5,comboN);burst(o.x/K,1.6,o.y/K,S.path==='Lose'?['#ff6fb0','#ffd23c']:['#ff9ac0','#ffd23c','#7dffb0'],10,5,.2);blip(600+comboN*120);
    if(S.path==='Gain')gain(.25*mult);else lose(.25*mult);if(comboN>=2)toast('🔥 COMBO ×'+comboN+(S.path==='Lose'?' (brainrot candy!)':''));setTimeout(()=>placeOrb(o),25000)}}});

// ---------------- 5) wishing fountain
TOWN_SPOTS.push({id:'spot',n:'⛲ Wishing fountain',label:'Make a wish',px:PLAZA.x,py:PLAZA.y+60,when:()=>!!S.path,fn:()=>{const cost=S.path==='Gain'?2:0;if(S.coins<cost)return toast('🪙 You need 2 coins to make a wish.');S.coins-=cost;burst(PLAZA.x/K,3,PLAZA.y/K,['#ffd23c'],6,6,.25);blip(1400);
  const W_=S.path==='Lose'?[['🌠 You wished to be dumber. The fountain agreed.',()=>lose(2)],['🌠 You wished for more BrainTok. A pigeon brings you a phone. It\'s a rock.',()=>lose(1)],['🌠 You wished for nothing. Perfect.',()=>{}],['🌠 The fountain splashes you. You forget your own name.',()=>lose(1.5)]]:[['🌠 Your wish: wisdom. +brain cells!',()=>gain(1.5)],['🌠 Your wish: calm. Stress −30.',()=>{S.stress=Math.max(0,S.stress-30)}],['🌠 Your wish: an idea! 💡',()=>idea(1)],['🌠 The fountain gives you 2 coins back. Rare!',()=>{S.coins+=4}],['🌠 Nothing happens. Wishes aren\'t science.',()=>{}]];const w=rnd(W_);w[1]();toast(w[0]);update();save()}});

// ---------------- 6) skateboard (tricks when you jump)
const board=new THREE.Group();mesh(boxG(1.4,.15,3.2),MAT('#2b2b33'),board,0,.35,0);for(const z of[-1,1])for(const x of[-.5,.5])mesh(new THREE.CylinderGeometry(.18,.18,.2,10),MAT('#ffd23c'),board,x,.18,z).rotation.z=Math.PI/2;scene.add(board);board.visible=false;
const rack=new THREE.Group();rack.position.set(PLAZA.x/K-12,0,(PLAZA.y+40)/K);town.add(rack);mesh(boxG(3,1.6,.4),MAT('#ff4f9a'),rack,0,.8,0);mesh(boxG(1.2,.15,2.8),MAT('#2b2b33'),rack,0,1.6,.3).rotation.x=-.7;
TOWN_SPOTS.push({id:'spot',n:'🛹 Skateboard rack',label:'Ride a skateboard',px:PLAZA.x-120,py:PLAZA.y+40,when:()=>!!S.path&&['human','barely'].includes(stageK()),fn:()=>{S.skate=!S.skate;toast(S.skate?'🛹 Skateboard ON! You\'re faster. Jump (⤒) to do tricks!':'🛹 Skateboard parked.');blip(700)}});
speedMult=(o=>function(){return o()*(S.skate&&!ROOM&&!inMoon&&['human','barely'].includes(stageK())?1.6:1)})(speedMult);
let trickT=0,trickPts=0;jump=(o=>function(){const was=PH;o();if(S.skate&&!ROOM&&PH<=.05&&PV>0){trickT=performance.now();const tr=rnd(['Kickflip','Ollie','360 Spin','Heelflip','Brain Grind']);trickPts++;toast('🛹 '+tr+'! ('+trickPts+' tricks)');S.coins+=1;if(trickPts===20)badge('sk8','Skate Brain')}})(jump);
FRAME_HOOKS.push(()=>{const on=S.skate&&!ROOM&&!inMoon&&['human','barely'].includes(stageK());board.visible=on;if(!on)return;board.position.set(P.x/K,PH,P.y/K);board.rotation.y=(P.face||0);const t=(performance.now()-trickT)/1000;if(t<.6){board.rotation.z=t/.6*Math.PI*2;ME.g.rotation.y+=t/.6*Math.PI*2}else board.rotation.z=0;ME.g.position.y+=.35;ME.lL.rotation.x=ME.lR.rotation.x=0});

// ---------------- 7) pets (Lose path only — the dumb side)
const PETS=[['rock','🪨','Pet Rock','It does nothing. Perfect.'],['hamster','🐹','Cursed Hamster','It runs in circles. So do you.'],['pigeon','🐦','Pigeon Gerald','Steals your snacks.'],['duck','🦆','Rubber Duck (alive?)','Squeaks when you think.']];
const petS=sprite(emojiTex('🪨'),2.2,2.2,scene);petS.visible=false;const petP={x:0,y:0};
function petShop(){const el=panel('🐾 Pet shop','<p>Pets are only for the dumb side. Each pet costs brain cells (they\'re very distracting).</p>');btns(el,PETS.map(([k,ic,n,d])=>[`${ic} ${n}${S.pet===k?' ✅':''}<small>${d}</small>`,()=>{S.pet=k;lose(1.5);petS.material.map=emojiTex(ic);petS.material.needsUpdate=true;petS.userData.k=k;petP.x=P.x;petP.y=P.y;toast('🐾 You adopted '+n+'! It follows you everywhere.');closePanel();save()}]))}
LAYOUT.mall=(o=>b=>{o(b);spot(-18,8,'Adopt a pet','🐾 Pet shop',guard('Lose',petShop))})(LAYOUT.mall);
FRAME_HOOKS.push(()=>{const on=S.path==='Lose'&&!!S.pet;petS.visible=on;if(!on)return;const k=S.pet;if(petS.userData.k!==k){petS.userData.k=k;const p=PETS.find(x=>x[0]===k);petS.material.map=emojiTex(p?p[1]:'🪨');petS.material.needsUpdate=true}
  const tx=P.x-Math.sin(P.face||0)*30,ty=P.y-Math.cos(P.face||0)*30;petP.x+=(tx-petP.x)*Math.min(1,DT*3);petP.y+=(ty-petP.y)*Math.min(1,DT*3);const hop=k==='rock'?0:Math.abs(Math.sin(T*(k==='hamster'?14:6)))*.6;petS.position.set(petP.x/K,PH+1+hop,petP.y/K);if(k==='hamster')petS.material.rotation=T*6;else petS.material.rotation=0});
setInterval(()=>{if(S.path!=='Lose'||!S.pet||ROOM)return;const m={rock:['🪨 Your pet rock did nothing. Amazing.','🪨 Your pet rock stared at you. You lost a staring contest.'],hamster:['🐹 Your hamster ran in 400 circles. You watched all of them.','🐹 The hamster bit your phone. You lost a thought.'],pigeon:['🐦 Gerald stole your sandwich.','🐦 Gerald brought you a bottle cap. Treasure.'],duck:['🦆 *squeak* You forgot what you were doing.','🦆 The duck judged your life choices.']}[S.pet]||[];if(m.length){toast(rnd(m));lose(.3)}},45000);
