
// ================================================================ THE AVERAGE FILES — a secret horror side plot
// The Perfectly Average Guy is a perfectly average eldritch being: the mean of everyone.
// It creeps in slowly (dread, not gore), the same for dumb and smart players:
// 0 normal → 1 sightings + notes → 2 the town gets "average" → 3 he follows you at night (only when you look away)
// → 4 a phone call: THE AVERAGE HOUR (escape The Mean, an endless beige room) → 5 the final conversation → 3 endings.
// Settings → Horror: Off / Spooky (no jump scares, default) / Full.
const HZ=()=>S.horror||(S.horror={stage:0,time:0,notes:[],talks:0,sight:0,first:Date.now(),setting:'spooky',outl:[]});
const hOn=()=>!!S.path&&HZ().setting!=='off';
const hFull=()=>HZ().setting==='full';
const NOTES8=[
 "Day 1. A new man stands in the plaza. Height: average. Smile: average. He said 'perfectly average day' 41 times today. I counted. It's not a big number. It's not a small number.",
 "Nobody remembers when he arrived. Everyone says 'he's always been there.' The town records say he arrived every single year.",
 "I measured him. IQ: 100. Exactly. Not 99.9. Not 100.1. Nothing in nature is that exact. Nothing.",
 "When I'm not looking, he's closer. When I look, he's just standing there. Averagely.",
 "He told me: 'Add up everyone in Brainville. Divide by everyone. That's me. Everyone becomes me, eventually.'",
 "The Mean is a place. Beige hallways. Every door opens into the same room. The clock always says 3:00.",
 "Outliers scare him. Things that are one of a kind. If he takes you to The Mean, find three of them. Don't let him make you average.",
 "He isn't evil. He's lonely. Nobody is actually average. So nobody is like him. Nobody.",
];
const NOTE_GATE=[1,1,1,2,2,3,3,1];
// where the notes hide: town spots and inside rooms
const NOTE_TOWN={0:[150,420],1:[1180,330],3:[700,250],5:[60,560]};
const NOTE_ROOM={2:'library',4:'school',6:'hospital'};// note 8 (index 7) appears at the fountain only at 10:00 game time

// ---------------- him (in the plaza)
const PAG_POS={x:PLAZA.x+95,y:PLAZA.y-25};
function averageMan(parent){const a=avatar('#d8cbb0','#e2c9a6','#8b8b8b',parent);a.head.children[0].children.forEach((m,i)=>{if(i<2)m.scale.set(1.25,1.25,1)});return a}
const PAG=averageMan(town);PAG.g.position.set(PAG_POS.x/K,0,PAG_POS.y/K);const pagTag=sprite(textTex('😐 Perfectly Average Guy',{size:42}),5.2,1.2,PAG.g);pagTag.position.y=6.7;
const hat=new THREE.Group();mesh(new THREE.CylinderGeometry(.7,.7,.3,14),MAT('#d8cbb0'),hat,0,.75,0);mesh(boxG(1.4,.08,.6),MAT('#d8cbb0'),hat,0,.62,.45);ME.head.add(hat);hat.visible=false;
const statue=new THREE.Group();statue.position.copy(PAG.g.position);town.add(statue);statue.visible=false;{const pts=[];for(let i=0;i<=20;i++){const x=(i-10)*.25;pts.push([x,Math.exp(-x*x/2)*3])}pts.forEach(([x,y])=>mesh(boxG(.26,y,.4),MAT('#c9c2b0'),statue,x,y/2+.3,0));mesh(boxG(6,.3,1.2),MAT('#9a948a'),statue,0,.15,0);const ss=sprite(textTex('📈 "There was a man here. He was perfectly average."',{size:30}),7,1,statue);ss.position.y=4.6}
FRAME_HOOKS.push(()=>{const h=HZ();const gone=h.ending==='outlier';PAG.g.visible=!gone;statue.visible=gone;hat.visible=h.ending==='friend';
  const dx=P.x-PAG_POS.x,dy=P.y-PAG_POS.y;PAG.g.rotation.y=Math.atan2(dx,dy);if(h.ending==='friend'){PAG.torM.color.set('#9fd0ff');if(Math.hypot(dx,dy)<160)PAG.aR.rotation.x=-2.6+Math.sin(T*8)*.3}else PAG.aR.rotation.x=0;
  if(h.stage>=2&&h.ending!=='friend'&&!gone){PAG.head.rotation.z=Math.sin(T*.7)*.05}});
TOWN_SPOTS.push({id:'spot',n:'😐 Perfectly Average Guy',label:'Talk',px:PAG_POS.x,py:PAG_POS.y+20,when:()=>!!S.path&&HZ().ending!=='outlier',fn:talkAverage});
function talkAverage(){const h=HZ();h.talks++;badge('average','Perfectly Average');const k=stageK();const animal=!['human','barely'].includes(k);
  if(h.ending==='friend'){npcSay({x:PAG_POS.x,y:PAG_POS.y},'🙂');return panel('🙂 Slightly Above Average Guy','<p>"Hey buddy! Slightly above average day, isn\'t it? Thanks for noticing me."</p>')}
  if(h.ending==='average'){const el=panel('😐 Perfectly Average Guy','<p>"Welcome back, average friend. Same as everyone. Isn\'t it nice?"</p>');btns(el,[['🔁 "I want to be ME again."',()=>{closePanel();h.ending=null;h.stage=5;toast('😐 "…Average decision. Fine. Talk to me when you\'re ready."');save()}]]);return}
  if(!hOn())return panel('😐 Perfectly Average Guy','<p>"Perfectly average day, isn\'t it?"</p>');
  if(h.stage>=5){if(!ROOM){const b=B.find(x=>x.id==='court');}return finaleIntro()}
  const lines=[["Perfectly average day, isn't it?","Hello. I'm perfectly average. You can tell by looking.","Nice weather. Not too nice."],
   ["Perfectly average day. You've been looking at me. An average amount.","Have you read anything interesting? …Have you read about ME?","I saw you earlier. Behind the "+rnd(['library','tree','cinema','supermarket'])+". You didn't see me."],
   ["Have you noticed? Everyone is a little more like me today.","Your brain is "+fmt(S.cells)+" cells. Mine is 86,000,000,000. Exactly. Always.","The clock was wrong today. It said 3:00. It's always 3:00 somewhere average."],
   ["Don't look away. …Just kidding. Look away. Average people look away.","At night I walk around. Only when you're not looking. That's average behavior.","It's "+new Date().toLocaleTimeString([], {hour:'2-digit',minute:'2-digit'})+" where you are. In the real world. Average time to be playing."],
   ["It's almost the Average Hour.","Answer your phone when it rings.","Everyone becomes me. Even you."]][Math.min(4,h.stage)];
  let line=rnd(lines);if(animal)line=rnd(["Even a "+stageOf(S.cells).n.toLowerCase()+" is perfectly average at being a "+stageOf(S.cells).n.toLowerCase()+".",line]);
  panel('😐 Perfectly Average Guy',`<p class="creepy">"${esc(line)}"</p>`);blip(220);save()}

// ---------------- progression
let lastStageH=HZ().stage;
FRAME_HOOKS.push(()=>{if(!hOn())return;const h=HZ();h.time+=DT;const n=h.notes.length;let st=h.stage;
  if(st===0&&(h.time>200||(h.talks>=1&&h.time>70)))st=1;if(st===1&&n>=3)st=2;if(st===2&&n>=5)st=3;if(st===3&&n>=7)st=4;if(h.escaped&&st<5)st=5;
  if(st!==h.stage){h.stage=st;onStage(st);save()}});
function onStage(st){const msg={1:'average.',2:'You found my notes. That\'s an average thing to do.',3:'I can walk now. Only when you\'re not looking. 🙂',4:'It\'s almost time. I\'ll call you.',5:'You got out. Nobody gets out. Come talk to me at the fountain.'}[st];if(msg)setTimeout(()=>textMsg('Unknown',msg),2500);if(st===4)setTimeout(averageCall,25000)}

// ---------------- notes (town + rooms + the 10:00 secret)
const noteSprites={};
function readNote(i){const h=HZ();if(!h.notes.includes(i)){h.notes.push(i);if(h.notes.length===8)badge('notes8','The Average Files')}snd('ping');
  const el=panel('📄 Note '+(i+1)+' of 8',`<div class="oldnote" id="onote"></div>`);let k=0;const txt=NOTES8[i];loopUntil(el,()=>{k+=1;$('onote').textContent=txt.slice(0,k);if(k%3===0)blip(260);return k<txt.length});save()}
Object.entries(NOTE_TOWN).forEach(([i,[x,y]])=>{i=+i;const s=sprite(emojiTex('📄'),1.5,1.5,town);s.position.set(x/K,1.2,y/K);noteSprites[i]=s;TOWN_SPOTS.push({id:'spot',n:'📄 A crumpled note',label:'Read the note',px:x,py:y,when:()=>hOn()&&HZ().stage>=NOTE_GATE[i]&&!HZ().notes.includes(i),fn:()=>readNote(i)})});
const n8=sprite(emojiTex('📄'),1.5,1.5,town);n8.position.set(PLAZA.x/K,1.6,(PLAZA.y+55)/K);
const n8spot={id:'spot',n:'📄 A note, floating in the fountain',label:'Read the note',px:PLAZA.x,py:PLAZA.y+70,when:()=>hOn()&&HZ().stage>=1&&!HZ().notes.includes(7)&&Math.floor(gameHour())===10,fn:()=>readNote(7)};TOWN_SPOTS.push(n8spot);
FRAME_HOOKS.push(()=>{const h=HZ();for(const [i,s] of Object.entries(noteSprites)){s.visible=hOn()&&h.stage>=NOTE_GATE[i]&&!h.notes.includes(+i);s.position.y=1.2+Math.sin(T*2+ +i)*.15}n8.visible=n8spot.when()});
roomNear=(o=>function(){if(!ROOM)return null;let best=null,bd=48;for(const s of ROOM.spots){if(s.hidden&&s.hidden())continue;const d=Math.hypot(P.x-s.px,P.y-s.py);if(d<bd){bd=d;best=s}}return best})(roomNear);
buildRoom=(orig=>function(b){const r=orig(b);const idx=+Object.keys(NOTE_ROOM).find(k=>NOTE_ROOM[k]===b.id);if(!isNaN(idx)){const g=grp(-6,10,.4);const paper=rm(boxG(1,.05,1.3),MAT('#efe6c8'),0,2.75,0,g);const s=spot(-6,11.6,'Read the note','📄 A note on the desk',()=>readNote(idx));s.hidden=()=>!(hOn()&&HZ().stage>=NOTE_GATE[idx]&&!HZ().notes.includes(idx));r.noteMesh={m:paper,s};table(-6,10,2.4,1.8)}
  // stage 2+: sometimes he is just… sitting in the room
  if(hOn()&&HZ().stage>=2&&b.id!=='mean'&&Math.random()<.35&&HZ().ending!=='friend'&&HZ().ending!=='outlier'){const a=averageMan(r.g);a.g.position.set(14,0,-6);a.g.rotation.y=-Math.PI/2;r.extraAvg=a;const s=spot(12,-6,'Talk','😐 A man who looks average',()=>{panel('😐 …',`<p class="creepy">"${esc(rnd(['I work here. I work everywhere.','I was sitting here before the room was built.','Don\'t mind me. I\'m just average.','Have we met? Everyone has met me.']))}"</p>`);setTimeout(()=>{a.g.visible=false;s.hidden=()=>true},400)})}
  return r})(buildRoom);
FRAME_HOOKS.push(()=>{if(ROOM&&ROOM.noteMesh)ROOM.noteMesh.m.visible=!ROOM.noteMesh.s.hidden()});
// journal app
phone=(o=>function(){o();const apps=$('apps');if(!apps||!hOn()||HZ().stage<1)return;const b=document.createElement('button');b.className='app';b.innerHTML='<span style="background:linear-gradient(135deg,#d8cbb0,#8b8170)">📓</span>Notes';b.onclick=()=>{const h=HZ();const el=panel('📓 The Average Files','<p>Notes found: '+h.notes.length+' / 8</p>',{phone:true});NOTES8.forEach((t,i)=>el.insertAdjacentHTML('beforeend',`<div class="oldnote small">${h.notes.includes(i)?esc(t):'<i>…missing…</i>'}</div>`))};apps.appendChild(b)})(phone);

// ---------------- sightings (he's in the background, then he isn't)
const GHOST=averageMan(town);GHOST.g.visible=false;let ghostUntil=0,nextSight=performance.now()+40000;
function camFwd(){const v=new THREE.Vector3();cam.getWorldDirection(v);return v}
FRAME_HOOKS.push(()=>{const h=HZ();if(!hOn()||h.stage<1||h.ending||ROOM||inMoon||S.dead){if(!FOLLOW.on)GHOST.g.visible=false;return}const now=performance.now();
  if(FOLLOW.on)return;
  if(GHOST.g.visible){const gx=GHOST.g.position.x*K,gy=GHOST.g.position.z*K;GHOST.g.rotation.y=Math.atan2(P.x-gx,P.y-gy);if(now>ghostUntil||Math.hypot(P.x-gx,P.y-gy)<150){GHOST.g.visible=false;blip(140)}return}
  if(now>nextSight){nextSight=now+(h.stage>=2?35000:60000)+Math.random()*30000;const f=camFwd();for(let i=0;i<20;i++){const d=200+Math.random()*120,a=(Math.random()-.5)*.8;const ang=Math.atan2(f.x,f.z)+a;const x=P.x+Math.sin(ang)*d,y=P.y+Math.cos(ang)*d;if(x>20&&x<W-20&&y>20&&y<H-20&&!solid(x,y)){GHOST.g.position.set(x/K,0,y/K);GHOST.g.visible=true;ghostUntil=now+2600;h.sight++;if(h.sight===1)badge('seenhim','Seen Him');for(const n of npcs)if(Math.hypot(n.x-P.x,n.y-P.y)<260&&Math.random()<.5)setTimeout(()=>npcSay(n,rnd(['who was that?','did you see that guy?','…he was looking at you'])),900);break}}}});

// ---------------- stage 2: the town gets average
let lookAllUntil=0;
setInterval(()=>{const h=HZ();if(!hOn()||h.stage<2||h.ending||ROOM)return;const r=Math.random();
  if(r<.3){lookAllUntil=Date.now()+4000;setTimeout(()=>toast('…everyone is looking at you.'),300)}
  else if(r<.5&&typeof setBillboard==='function'){setBillboard('1 0 0','PERFECTLY AVERAGE','everyone is');setTimeout(()=>setBillboard('BRAINVILLE BILLBOARD',S.viral?'"'+S.viral+'"':'Your ad here','📹 BigReactz reacts to the dumbest comments'),1500)}
  else if(r<.62)textMsg('Unknown',rnd(['average.','I saw you at the '+rnd(['library','fountain','school','diner'])+'. Average visit.','you looked at me at '+new Date().toLocaleTimeString([], {hour:'2-digit',minute:'2-digit'})+'.','you started playing on '+new Date(h.first).toLocaleDateString()+'. average.','everyone is a little more like me today 🙂']))},45000);
FRAME_HOOKS.push(()=>{if(Date.now()<lookAllUntil&&!ROOM)for(const o of NPC3){o.a.g.rotation.y=Math.atan2(P.x-o.n.x,P.y-o.n.y);o.n.t=Math.max(o.n.t,1)}
  const h=HZ();if(hOn()&&h.stage>=2&&!h.ending&&gameHour()>=20||hOn()&&h.stage>=2&&!h.ending&&gameHour()<6){if(Math.random()<.05)lampMats.forEach(m=>m.emissiveIntensity=Math.random()<.5?.1:2)}});
clockText=(o=>function(){const h=HZ();if(hOn()&&h.stage>=2&&!h.ending&&Math.random()<.04)return'🕒 03:00';return o()})(clockText);
dailyTimes=(o=>function(){o();const h=HZ();if(!hOn()||h.stage<1)return;const pc=$('pc');if(!pc)return;const ad={1:'CLASSIFIEDS: Have you seen this man? (Everyone has.)',2:'CLASSIFIEDS: Missing: one (1) personality. Last seen being average.',3:'CLASSIFIEDS: If you see him, look at him. Keep looking.',4:'CLASSIFIEDS: Answer the phone.',5:'CLASSIFIEDS: Nobody gets out. Except you?'}[Math.min(5,h.stage)];if(ad)pc.insertAdjacentHTML('beforeend','<p class="creepy" style="color:#7a6a4a">'+ad+'</p>')})(dailyTimes);

// ---------------- stage 3: at night he follows you — only while you're not looking
const FOLLOW={on:false,cool:0};
function avgFlash(){const f=document.createElement('div');f.className='avgflash';$('app').appendChild(f);setTimeout(()=>f.remove(),1600);avgCounterUntil=Date.now()+2200;snd('slam');try{navigator.vibrate&&navigator.vibrate(200)}catch(e){}
  if(hFull()){const j=document.createElement('div');j.className='avgface';j.innerHTML='<div class="e1"></div><div class="e2"></div><div class="m"></div>';$('app').appendChild(j);setTimeout(()=>j.remove(),450)}}
let avgCounterUntil=0;roll=(o=>function(){if(Date.now()<avgCounterUntil){$('cCells').textContent='🧠 86,000,000,000';$('cIQ').textContent='IQ: 100.000';return}return o()})(roll);
FRAME_HOOKS.push(()=>{const h=HZ();const night=gameHour()>=20||gameHour()<5;const can=hOn()&&h.stage>=3&&!h.ending&&night&&!ROOM&&!inMoon&&!S.dead&&$('panelWrap').classList.contains('hide');const now=performance.now();
  if(!can){if(FOLLOW.on){FOLLOW.on=false;GHOST.g.visible=false}return}
  if(!FOLLOW.on){if(now<FOLLOW.cool)return;const f=camFwd();let x=P.x-f.x*260,y=P.y-f.z*260;if(solid(x,y)){x=P.x+180;y=P.y}FOLLOW.on=true;FOLLOW.x=x;FOLLOW.y=y;GHOST.g.visible=true;return}
  const dx=P.x-FOLLOW.x,dy=P.y-FOLLOW.y,d=Math.hypot(dx,dy);const f=camFwd();const tox=(FOLLOW.x-P.x)/d,toy=(FOLLOW.y-P.y)/d;const looking=(f.x*tox+f.z*toy)>.55;
  if(!looking){const sp=95*DT;const nx=FOLLOW.x+dx/d*sp,ny=FOLLOW.y+dy/d*sp;if(!solid(nx,FOLLOW.y))FOLLOW.x=nx;if(!solid(FOLLOW.x,ny))FOLLOW.y=ny;animate(GHOST,true,T*.6)}else animate(GHOST,false,T);
  GHOST.g.position.set(FOLLOW.x/K,0,FOLLOW.y/K);GHOST.g.rotation.y=Math.atan2(dx,dy);
  if(d<28){FOLLOW.on=false;GHOST.g.visible=false;FOLLOW.cool=now+90000;avgFlash();toast('😐 "Perfectly average."');h.caught=(h.caught||0)+1}});

// ---------------- stage 4: the phone call and THE AVERAGE HOUR
function averageCall(){if(!hOn()||HZ().stage!==4||HZ().escaped)return;if(!S.path||ROOM||!$('panelWrap').classList.contains('hide')||!$('cine').classList.contains('hide')){setTimeout(averageCall,15000);return}
  const c=document.createElement('div');c.className='call';c.innerHTML='<div class="cav">😐</div><b>Unknown</b><small>is calling… (average)</small><div class="crow"><button class="cno">Decline</button><button class="cyes">Answer</button></div>';$('app').appendChild(c);
  const ring=setInterval(()=>{blip(880);setTimeout(()=>blip(660),150)},1200);
  c.querySelector('.cno').onclick=()=>{clearInterval(ring);c.remove();toast('📵 You declined. The phone rings again later. You can\'t decline average.');setTimeout(averageCall,60000)};
  c.querySelector('.cyes').onclick=()=>{clearInterval(ring);c.remove();averageHourCutscene()}}
function averageHourCutscene(){const f=$('scene');f.className='scene';f.style.background='#d9caa4';f.style.color='#3a3326';f.style.opacity=1;f.innerHTML='<div class="big" style="color:#3a3326;font-family:Inter">📞</div><p class="ah" id="ahl"></p>';
  const lines=['"Hello."','"It\'s 3:00. It\'s always 3:00."','"Welcome to the Average Hour."','"Find three things that are one of a kind… if you can."'];let i=0;const nx=()=>{if(i>=lines.length){f.classList.add('hide');f.style.color='';enterMean();return}$('ahl').textContent=lines[i++];blip(200);setTimeout(nx,1900)};nx()}
let MEAN=null;
function enterMean(){MEAN={loop:4217,outl:[],caught:0};leaveRoom(true);ROOMS.mean&&roomG.remove(ROOMS.mean.g);delete ROOMS.mean;enterRoom({id:'mean',n:'THE MEAN',p:'Any',i:40,door:{x:PLAZA.x,y:PLAZA.y+60}});badge('meanin','The Average Hour')}
const OUTLIERS=[['🌟','a golden brain'],['🐔','a rubber chicken in a tiny crown'],['📕','a book with only one copy in the world'],['🎨','a painting nobody understands'],['🦆','a duck wearing a top hat'],['🧦','one sock with no pair']];
LAYOUT.mean=b=>{const R=ROOM;R.walls.forEach(w=>{w.m.material.color.set('#d9caa4')});R.g.children.forEach(c=>{if(c.geometry&&c.geometry.parameters&&c.geometry.parameters.height===.4)c.material=MAT('#b8a77a')});
  for(let x=-16;x<=16;x+=8)for(let z=-10;z<=10;z+=10){const l=rm(boxG(4,.1,1.2),new THREE.MeshStandardMaterial({color:'#f6f6e8',emissive:'#f0f0d0',emissiveIntensity:.8}),x,8.9,z);l.castShadow=false}
  for(const [x,z] of [[-12,-6],[12,-6],[-12,6],[12,6]]){desk(x,z,0,true);chair(x,z+2.6,Math.PI,MAT('#8b8170'),false)}rm(new THREE.CylinderGeometry(.8,.8,3,12),MAT('#cfe4f0'),18,1.5,-12);
  R.clock=canvasPlane(4,1.6,(g,w,h)=>{g.fillStyle='#222';g.fillRect(0,0,w,h);g.fillStyle='#ff3b30';g.font='700 120px Inter';g.textAlign='center';g.fillText('3:00',w/2,h/2+42)},0,7,-14.6);
  R.roomNo=canvasPlane(5,1,(g,w,h)=>{},-12,7,-14.6);
  R.exit.fn=()=>meanLoop('door');R.exit.label='Open the door';R.exit.n='🚪 Door';
  [[-20.5,0,'west'],[20.5,0,'east'],[8,-13,'north']].forEach(([x,z,n])=>{rm(boxG(n==='north'?4:.3,6.4,n==='north'?.3:4),DWOOD,x+(n==='west'?-.3:n==='east'?.3:0),3.2,z+(n==='north'?-1.3:0));spot(x,z,'Open the door','🚪 A door ('+n+')',()=>meanLoop('door'))});
  R.out={s:sprite(emojiTex('🌟'),2,2,R.g),k:0};R.outSpot=spot(0,0,'Pick it up','✨ Something one of a kind',()=>takeOutlier());
  R.exitDoor=rm(boxG(4,6.6,.3),MAT('#2fbf71'),-8,3.3,-14.4);R.exitDoor.visible=false;R.exitSpot=spot(-8,-12.4,'Leave The Mean','🚪 EXIT (this one is different)',()=>escapeMean());R.exitSpot.hidden=()=>!MEAN||MEAN.outl.length<3;
  R.pag=averageMan(R.g);R.pag.g.position.set(15,0,8);R.pagPos={x:15,z:8};
  placeOutlier();setRoomNo()};
function setRoomNo(){const R=ROOM;if(!R||!R.roomNo)return;R.roomNo.material.map=canvasTex((g,w,h)=>{g.fillStyle='#f4ecd6';g.fillRect(0,0,w,h);g.fillStyle='#5a4e38';g.font='700 56px Inter';g.textAlign='center';g.fillText('ROOM '+MEAN.loop,w/2,h/2+20)},512,102);R.roomNo.material.needsUpdate=true}
function placeOutlier(){const R=ROOM;if(!R||!R.out)return;const have=MEAN.outl.map(o=>o[0]);const left=OUTLIERS.filter(o=>!have.includes(o[0]));const show=Math.random()<.65&&MEAN.outl.length<3;R.out.cur=show?rnd(left):null;R.out.s.visible=!!R.out.cur;R.outSpot.hidden=()=>!R.out.cur;
  if(show){const p=rnd([[-17,-11],[17,-11],[-17,11],[17,11],[0,-9],[-6,4],[6,4]]);R.out.s.material.map=emojiTex(R.out.cur[0]);R.out.s.material.needsUpdate=true;R.out.s.position.set(p[0],1.6,p[1]);R.outSpot.px=R.ox+p[0]*K;R.outSpot.py=R.oy+(p[1]+1.6)*K}}
function takeOutlier(){const R=ROOM;if(!R.out.cur)return;MEAN.outl.push(R.out.cur);toast('✨ You found '+R.out.cur[1]+'. It is one of a kind. ('+MEAN.outl.length+'/3)');blip(1200);R.out.cur=null;R.out.s.visible=false;if(MEAN.outl.length>=3){R.exitDoor.visible=true;toast('🚪 A green door appeared. It\'s… different.');snd('good')}}
function meanLoop(why){wipe(()=>{MEAN.loop+=why==='caught'?-MEAN.loop+4217:1+Math.floor(Math.random()*3);P.x=ROOM.ox;P.y=ROOM.oy+6*K;P.tx=null;ROOM.pagPos={x:rnd([-15,15]),z:rnd([-9,9])};placeOutlier();setRoomNo();toast(why==='caught'?'😐 He caught you. Back to the start.':rnd(['It\'s the same room.','It\'s the same room. Again.','The clock still says 3:00.','You hear an average footstep.']));blip(180)})}
FRAME_HOOKS.push(()=>{if(!ROOM||ROOM.b.id!=='mean'||!MEAN)return;roomLight.intensity=.6+Math.random()*.08;roomLight.color.set('#f2f0d8');scene.background=new THREE.Color('#2a2418');
  const R=ROOM;const pl={x:(P.x-R.ox)/K,z:(P.y-R.oy)/K};const dx=pl.x-R.pagPos.x,dz=pl.z-R.pagPos.z,d=Math.hypot(dx,dz);const f=camFwd();const looking=(f.x*(-dx/d)+f.z*(-dz/d))>.5;
  if(!looking&&$('panelWrap').classList.contains('hide')){const sp=(hFull()?7.5:6)*DT;R.pagPos.x+=dx/d*sp;R.pagPos.z+=dz/d*sp;animate(R.pag,true,T*.6)}else animate(R.pag,false,T);
  R.pag.g.position.set(R.pagPos.x,0,R.pagPos.z);R.pag.g.rotation.y=Math.atan2(dx,dz);
  if(d<2.2&&$('panelWrap').classList.contains('hide')){avgFlash();if(MEAN.outl.length){const lost=MEAN.outl.pop();toast('😐 He made your '+lost[1].replace(/^an? /,'')+' average. It\'s gone.')}MEAN.caught++;R.exitDoor.visible=MEAN.outl.length>=3;meanLoop('caught')}});
function escapeMean(){if(!MEAN||MEAN.outl.length<3)return;const h=HZ();h.escaped=true;h.outl=MEAN.outl.map(o=>o[1]);MEAN=null;badge('outofmean','Nobody Gets Out (You Did)');
  wipe(()=>{ROOM=null;standUp();appliedLook=null;P.x=PLAZA.x;P.y=PLAZA.y+80;P.tx=null;toast('⛲ You wake up by the fountain. It was a perfectly average dream… right?');setTimeout(()=>textMsg('Unknown','You got out. Nobody gets out. Come talk to me.'),3000);save()})}

// ---------------- stage 5: the final conversation and the endings
CONV.average={who:'The Perfectly Average Guy',shirt:'#d8cbb0',meter:['🎲 You (the outlier)',50],nodes:{
 a:{say:"You came back. Of course you did. Statistically, everyone does.",opts:[{t:"I'm not like everyone. Nobody is.",m:20,b:0,n:'b'},{t:"Okay… what do you want?",m:0,b:0,n:'b'},{t:"I'm perfectly average too!",m:-20,b:0,n:'b'},{t:"*holds up the one-of-a-kind things from The Mean*",m:25,b:0,n:'b'}]},
 b:{say:"Add up everyone in Brainville. Divide by everyone. That's me. I'm what you all become.",opts:[{t:"An average isn't a real person. It's just math.",m:20,b:0,n:'c'},{t:"So… you're everyone?",m:0,b:0,n:'c'},{t:"That actually sounds nice.",m:-20,b:0,n:'c'},{t:"You must be really lonely.",m:5,b:0,n:'c',friend:1}]},
 c:{say:"Join me. No more trying. No more failing. Just… average. Forever.",opts:[{t:"No. I'd rather be weird and be me.",m:25,b:0,n:null},{t:"Fine. Make me average.",m:-35,b:0,n:null},{t:"How about we just… be friends?",m:10,b:0,n:null,friend:1},{t:"*does a dance nobody has ever done before*",m:20,b:0,n:null}]}},
 end:{good:["The Perfectly Average Guy flickers. 'You're… not average.'",()=>endingGood()],bad:["'Welcome.' Everything goes beige.",()=>endingAverage()],mid:["He shrugs. 'Average answer. Come back when you're sure.'",()=>'😐 Come back when you\'re sure.']}};
remember=(o=>function(opt,t){if(opt&&opt.friend&&CV&&CV.key==='average')HZ().friendTalk=(HZ().friendTalk||0)+1;return o(opt,t)})(remember);
function finaleIntro(){if(ROOM)return;const h=HZ();h.friendTalk=0;const el=panel('😐 The Perfectly Average Guy',`<p class="creepy">"${h.ending?'Again?':'You\'re back from The Mean. Sit down. Let\'s talk. Averagely.'}"</p>`);btns(el,[['🪑 Sit down and talk',()=>{closePanel();enterRoom(B.find(x=>x.id==='cafe'));setTimeout(()=>{if(ROOM){const s=ROOM.spots.find(x=>x.main)||ROOM.spots[0];P.x=s.px;P.y=s.py;startConv('average')}},1400)}],['Not yet',()=>closePanel()]])}
function endingGood(){const h=HZ();if(h.notes.includes(7)&&(h.friendTalk||0)>=1)return endingFriend();h.ending='outlier';h.stage=6;badge('outlier','Outlier');setTimeout(()=>credits('outlier'),1500);return'📈 OUTLIER ENDING'}
function endingAverage(){const h=HZ();h.ending='average';h.stage=6;badge('meanend','Perfectly Average (Ending)');setTimeout(()=>credits('average'),1500);return'😐 PERFECTLY AVERAGE ENDING'}
function endingFriend(){const h=HZ();h.ending='friend';h.stage=6;badge('friendmean','Friend of the Mean');setTimeout(()=>credits('friend'),1500);setTimeout(()=>textMsg('Slightly Above Average Guy','thanks for noticing me 🙂 here, a hat. it\'s beige. sorry.'),9000);return'🙂 SECRET ENDING: FRIEND OF THE MEAN'}
function credits(kind){closeConv();leaveRoom(true);const f=$('scene');f.className='scene';f.style.background='#0b0a0d';f.style.opacity=1;
  const t={outlier:['📈 OUTLIER ENDING','You refused to be average. He came apart like a graph in the rain.','In the plaza there\'s a statue now. A bell curve. Nobody remembers why.'],average:['😐 PERFECTLY AVERAGE ENDING','You became perfectly average. It was… fine.','(Talk to him again if you want to be you again.)'],friend:['🙂 SECRET ENDING: FRIEND OF THE MEAN','Nobody is average. So nobody was like him. Until someone noticed.','He\'s Slightly Above Average now. He made you a hat.']}[kind];
  f.innerHTML=`<div class="credits"><h2>${t[0]}</h2><p>${t[1]}</p><p>${t[2]}</p><br><b>THE AVERAGE FILES</b><p>Starring: the Perfectly Average Guy (as himself, and everyone)</p><p>Sightings: ${HZ().sight} • Times caught: ${HZ().caught||0} • Notes: ${HZ().notes.length}/8</p><p>Outliers you saved: ${(HZ().outl||[]).join(', ')||'none'}</p><br><p>Made by the Cult of the 39 community</p><p style="opacity:.6">${kind==='friend'?'Thank you for noticing.':'There are 3 endings.'}</p><button class="btn go" id="crok" style="width:auto;margin:20px auto">Back to Brainville</button></div>`;
  $('crok').onclick=()=>f.classList.add('hide');snd('good');save()}

// ---------------- settings: horror level
settings=(o=>function(){o();const pc=$('pc');if(!pc)return;const h=HZ();const L={off:'Off',spooky:'Spooky (no jump scares)',full:'Full (jump scares)'};btns(pc,[[`👻 Secret horror: ${L[h.setting]}<small>The Perfectly Average Guy side story. Never gory.</small>`,()=>{h.setting=h.setting==='spooky'?'full':h.setting==='full'?'off':'spooky';if(h.setting==='off'){FOLLOW.on=false;GHOST.g.visible=false}settings();save()}]])})(settings);
// admin: jump through the story
ADM_TABS.push(['avg','😐 Average']);
admin=(o=>function(tab){o(tab);if(tab!=='avg')return;const box=$('adm');const h=HZ();box.innerHTML=`<div class="card">Stage ${h.stage} • notes ${h.notes.length}/8 • sightings ${h.sight} • ending: ${h.ending||'none'} • setting: ${h.setting}</div>`;
  btns(box,[['⏩ Next story stage',()=>{h.stage=Math.min(5,h.stage+1);if(h.stage>=2)h.notes=[0,1,2,3,4].slice(0,h.stage===2?3:h.stage===3?5:7);if(h.stage>=4)h.notes=[0,1,2,3,4,5,6];if(h.stage===5)h.escaped=true;onStage(h.stage);admin('avg')}],['📄 Give all 8 notes',()=>{h.notes=[0,1,2,3,4,5,6,7];admin('avg')}],['👀 Sighting now',()=>{nextSight=0;closePanel()}],['🌙 Make it night',()=>{const g=gameHour;gameHour=()=>23;setTimeout(()=>gameHour=g,60000);closePanel();toast('🌙 Night for 60 s')}],['📞 Average Hour now',()=>{closePanel();h.stage=4;h.notes=[0,1,2,3,4,5,6];averageHourCutscene()}],['🔄 Reset the story',()=>{S.horror=null;HZ();admin('avg')}]])})(admin);
