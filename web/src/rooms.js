
// ================================================================ UPDATE 1.5: REAL PLACES
// Walk-in 3D rooms with real furniture, interactive furniture, and conversation scenes.
const roomG=new THREE.Group();scene.add(roomG);roomG.visible=false;
const roomLight=new THREE.PointLight('#fff4e0',.9,60);roomLight.position.set(0,14,0);roomG.add(roomLight);
let ROOM=null; // {b,ox,oy,hw,hd,g,cols,spots,walls,npcs}
const ROOMS={};
const RSIZE={w:44,d:30,h:9}; // studs
function R_(lx,lz){return{x:ROOM.ox+lx*K,y:ROOM.oy+lz*K}}
function col(lx,lz,w,d){const r=ROOM;r.cols.push({x:r.ox+(lx-w/2)*K,y:r.oy+(lz-d/2)*K,w:w*K,h:d*K})}
function spot(lx,lz,label,obj,fn,main){const p=R_(lx,lz);const s={id:'spot',n:obj,px:p.x,py:p.y,label,fn,main};ROOM.spots.push(s);return s}
const rm=(geo,mat,x,y,z,parent)=>mesh(geo,mat,parent||ROOM.g,x,y,z);
const WOOD=MAT('#9a6a42'),DWOOD=MAT('#6a4528'),METAL=new THREE.MeshStandardMaterial({color:'#aab0b8',roughness:.35,metalness:.6}),WHITE=MAT('#f4f4f2'),BLACK=MAT('#222226'),FABR=MAT('#c0483f'),SCREEN=new THREE.MeshStandardMaterial({color:'#1e90ff',emissive:'#1e90ff',emissiveIntensity:.8});
// ---------------- furniture builders (local studs; rot = facing)
function grp(x,z,rot){const g=new THREE.Group();g.position.set(x,0,z);g.rotation.y=rot||0;ROOM.g.add(g);return g}
function table(x,z,w=5,d=3,mat=WOOD){const g=grp(x,z);rm(boxG(w,.3,d),mat,0,2.6,0,g);for(const sx of[-1,1])for(const sz of[-1,1])rm(boxG(.3,2.6,.3),mat,sx*(w/2-.3),1.3,sz*(d/2-.3),g);col(x,z,w,d);return g}
function chair(x,z,rot=0,mat=FABR,sit=true){const g=grp(x,z,rot);rm(boxG(1.8,.3,1.8),mat,0,1.6,0,g);rm(boxG(1.8,2,.3),mat,0,2.7,-.8,g);for(const sx of[-1,1])for(const sz of[-1,1])rm(boxG(.2,1.6,.2),DWOOD,sx*.75,.8,sz*.75,g);if(sit)spot(x,z+Math.cos(rot)*1.6,'Sit','🪑 Chair',()=>sitDown(x,z,rot));return g}
function shelf(x,z,w=8,rot=0){const g=grp(x,z,rot);rm(boxG(w,7,1.2),DWOOD,0,3.5,0,g);const cols=['#c0392b','#2e86de','#27ae60','#f1c40f','#8e44ad','#e67e22'];for(let r=0;r<3;r++)for(let i=0;i<w/0.7-1;i++){const b=rm(boxG(.5,1.4+((i*7)%5)*.1,.9),MAT(cols[(i+r*2)%6]),-w/2+.6+i*.7,1.2+r*2.2,.2,g);b.castShadow=false}if(rot===0)col(x,z,w,1.4);else col(x,z,1.4,w);return g}
function desk(x,z,rot=0,pc=true){const g=grp(x,z,rot);rm(boxG(5,.3,2.4),WOOD,0,2.6,0,g);rm(boxG(5,2.6,.2),WOOD,0,1.3,-1.1,g);if(pc){rm(boxG(2,1.3,.15),BLACK,0,3.6,-.6,g);rm(boxG(1.8,1.1,.05),SCREEN,0,3.6,-.52,g);rm(boxG(1.6,.1,.6),BLACK,0,2.8,.2,g)}col(x,z,5,2.6);return g}
function bed(x,z,rot=0){const g=grp(x,z,rot);rm(boxG(3.4,1.4,6.5),WHITE,0,.9,0,g);rm(boxG(3.6,.4,6.7),METAL,0,.3,0,g);rm(boxG(2.6,.6,1.2),MAT('#dfe8ff'),0,1.9,-2.4,g);rm(boxG(3.5,.3,3.8),MAT('#7fb2ff'),0,1.7,1,g);col(x,z,3.6,6.6);return g}
function counter(x,z,w=10,rot=0,top=WHITE){const g=grp(x,z,rot);rm(boxG(w,3,2.2),DWOOD,0,1.5,0,g);rm(boxG(w+.2,.25,2.5),top,0,3.1,0,g);col(x,z,rot?2.4:w,rot?w:2.4);return g}
function plant(x,z){const g=grp(x,z);rm(new THREE.CylinderGeometry(.7,.55,1.4,10),MAT('#b5653a'),0,.7,0,g);rm(new THREE.SphereGeometry(1.2,10,8),leafMat,0,2.2,0,g);col(x,z,1.4,1.4)}
function rug(x,z,w,d,c){const r=rm(boxG(w,.06,d),MAT(c),x,.04,z);r.castShadow=false}
function canvasPlane(w,h,draw,x,y,z,rotY=0,parent){const t=canvasTex(draw,512,Math.round(512*h/w));const m=new THREE.Mesh(new THREE.PlaneGeometry(w,h),new THREE.MeshBasicMaterial({map:t}));m.position.set(x,y,z);m.rotation.y=rotY;(parent||ROOM.g).add(m);return m}
function whiteboard(x,z,text){rm(boxG(9,4.4,.3),METAL,x,4.6,z);const p=canvasPlane(8.6,4,(g,w,h)=>{g.fillStyle='#fdfdfb';g.fillRect(0,0,w,h);g.fillStyle='#1d4ed8';g.font='700 46px "Comic Neue", sans-serif';g.textAlign='center';g.fillText(text,w/2,h/2+16)},x,4.6,z+.17);return p}
function arcade(x,z,title,rot=0){const g=grp(x,z,rot);const c=CANDY[(x*7|0)%6];rm(boxG(2.6,6,2.2),MAT(c),0,3,0,g);const s=canvasPlane(2,1.6,(g2,w,h)=>{g2.fillStyle='#000';g2.fillRect(0,0,w,h);g2.fillStyle='#0f0';g2.font='700 60px Fredoka';g2.textAlign='center';g2.fillText(title,w/2,h/2+20)},0,4.2,1.12,0,g);rm(boxG(2.4,.4,1),BLACK,0,2.9,1.3,g);col(x,z,2.8,2.4);return{g,s}}
function micro(x,z){const g=grp(x,z);rm(boxG(2.4,1.5,1.6),MAT('#e9e9ea'),0,4,0,g);rm(boxG(1.5,1.1,.05),MAT('#2b2b33'),-.3,4,.81,g);const panel=rm(boxG(.4,.25,.05),new THREE.MeshStandardMaterial({color:'#33cc55',emissive:'#33cc55'}),.75,4.3,.82,g);return g}
function fridge(x,z,rot=0){const g=grp(x,z,rot);rm(boxG(3,7,2.6),WHITE,0,3.5,0,g);const hinge=new THREE.Group();hinge.position.set(-1.5,0,1.32);g.add(hinge);const door=rm(boxG(3,6.8,.2),MAT('#e8e8e8'),1.5,3.5,0,hinge);rm(boxG(.15,1.6,.15),METAL,2.7,4,.2,hinge);col(x,z,3,2.8);return hinge}
function screenWall(x,z,text){rm(boxG(20,9.4,.3),BLACK,x,6,z);return canvasPlane(19,8.6,(g,w,h)=>{const gr=g.createLinearGradient(0,0,w,h);gr.addColorStop(0,'#c92a2a');gr.addColorStop(1,'#1a0d12');g.fillStyle=gr;g.fillRect(0,0,w,h);g.fillStyle='#fff';g.font='700 34px Fredoka';g.textAlign='center';g.fillText(text,w/2,h/2)},x,6,z+.17)}
function seats(x,z,n){for(let i=0;i<n;i++){const g=grp(x-(n-1)*1.3+i*2.6,z,Math.PI);rm(boxG(2.2,1.4,2),FABR,0,.9,0,g);rm(boxG(2.2,2.2,.4),FABR,0,1.9,.9,g)}col(x,z,n*2.6,2.4)}
function bench(x,z,w=6,rot=0){const g=grp(x,z,rot);rm(boxG(w,.4,1.6),WOOD,0,1.5,0,g);rm(boxG(w,1.6,.3),WOOD,0,2.5,-.7,g);for(const sx of[-1,1])rm(boxG(.3,1.5,1.4),DWOOD,sx*(w/2-.4),.75,0,g);col(x,z,w,1.8)}
function podium(x,z,c='#2b3a67'){rm(boxG(3,4,2),MAT(c),x,2,z);col(x,z,3,2)}
function labBench(x,z){table(x,z,7,3,MAT('#3c4654'));const cols=['#3fd7ff','#7cff6b','#ff6bd5'];for(let i=0;i<3;i++){rm(new THREE.CylinderGeometry(.3,.45,1.1,10),new THREE.MeshStandardMaterial({color:cols[i],transparent:true,opacity:.7,emissive:cols[i],emissiveIntensity:.3}),x-2+i*2,3.3,z)}}
function shelfProducts(x,z,w=10){const g=grp(x,z);rm(boxG(w,5,1.6),METAL,0,2.5,0,g);for(let r=0;r<3;r++)for(let i=0;i<w/1.1-1;i++)rm(boxG(.8,1,.9),MAT(CANDY[(i+r)%6]),-w/2+.8+i*1.1,1+r*1.6,.5,g);col(x,z,w,1.8)}
function couch(x,z,rot=0,c='#5b6fb3'){const g=grp(x,z,rot);rm(boxG(6,1.4,2.6),MAT(c),0,1,0,g);rm(boxG(6,2,.6),MAT(c),0,2.4,-1,g);for(const sx of[-1,1])rm(boxG(.6,1.8,2.6),MAT(c),sx*3,1.5,0,g);col(x,z,6.6,2.8);spot(x,z+Math.cos(rot)*2.2,'Sit','🛋 Couch',()=>sitDown(x,z,rot))}
function judgeBench(x,z){rm(boxG(10,5,3),DWOOD,x,2.5,z);rm(boxG(10.4,.3,3.4),WOOD,x,5.1,z);col(x,z,10,3);rm(boxG(.8,.4,.4),DWOOD,x+3,5.5,z+.6)}
function npcAt(x,z,rot,shirt,name){const a=avatar(shirt,'#e8b98f','#2b2b3a',ROOM.g);a.g.position.set(x,0,z);a.g.rotation.y=rot;const tag=sprite(textTex(name,{size:46}),4.4,1.1,a.g);tag.position.y=6.6;col(x,z,2,2);ROOM.npcs.push(a);return a}
function sign(text,x,z){canvasPlane(10,1.6,(g,w,h)=>{g.fillStyle='#1d1a26';g.fillRect(0,0,w,h);g.fillStyle='#ffd23c';g.font='700 56px Fredoka';g.textAlign='center';g.fillText(text,w/2,h/2+20)},x,7.6,z)}

// ---------------- room layouts (only buildings that have a use)
const PATHOK=(p)=>p==='Any'||!p||S.path===p;
function guard(p,fn){return()=>{if(!PATHOK(p)){toast(p==='Gain'?'🧠 This is a smart place. Not for the Lose path.':'🫠 This is a dumb place. Not for the Gain path.');return}fn()}}
const LAYOUT={
 library:b=>{sign('📚 LIBRARY',0,-14.8);shelf(-14,-13.6,10);shelf(0,-13.6,8);shelf(14,-13.6,10);shelf(-20.4,0,10,Math.PI/2);table(0,0,8,4);chair(-2.5,-3,0);chair(2.5,-3,0);chair(-2.5,3,Math.PI);chair(2.5,3,Math.PI);rug(0,0,16,10,'#7a2e3a');plant(18,10);
   npcAt(14,4,-Math.PI/2,'#6b4f8a','Librarian');spot(0,-11.6,'Read a book','📚 Bookshelf',guard('Gain',library),true);spot(12,4,'Talk','🤫 Librarian',()=>toast('🤫 Librarian: "Shhh. Read something. Silently."'))},
 cinema:b=>{sign('🎬 JACK B CINEMA',0,-14.8);const scr=screenWall(0,-14.6,'🎬 JACK B MOVIES: fun facts');ROOM.screen=scr;seats(0,-2,6);seats(0,4,6);seats(0,10,6);counter(-16,10,8,Math.PI/2,MAT('#ffd23c'));spot(0,-9,'Watch Jack B','🎬 Screen',guard('Gain',jackB),true);
   rm(boxG(12,1,6),MAT('#3a2a3a'),14,.5,-8);npcAt(14,-8,Math.PI/2*0+Math.PI,'#d24c4c','Ms. Mic (host)');spot(14,-4,'Join the Debate Show','🎤 Debate stage',()=>startConv('debate'))},
 university:b=>{sign('🎓 UNIVERSITY',0,-14.8);whiteboard(0,-14.6,'E = mc²   a² + b² = c²');for(let r=0;r<3;r++)for(let c=-1;c<=1;c++)desk(c*10,-5+r*7,Math.PI,false);podium(0,-10);rm(boxG(6,9,1),MAT('#f0be28'),17,4.5,-13.6);canvasPlane(5.6,1.4,(g,w,h)=>{g.fillStyle='#000';g.fillRect(0,0,w,h);g.fillStyle='#f0be28';g.font='700 70px Fredoka';g.textAlign='center';g.fillText('🚧 SKILL GATE',w/2,h/2+24)},17,8,-13)
   spot(17,-10.5,'Face the Skill Gate','🚧 Skill Gate',guard('Gain',gate),true)},
 jobs:b=>{sign('📋 JOB CENTER',0,-14.8);desk(-8,-8,0);desk(8,-8,0);chair(-8,-5,Math.PI);chair(8,-5,Math.PI);npcAt(-8,-11,0,'#2f9a58','Job Counselor');rm(boxG(10,5,.3),MAT('#c9a46a'),14,4,-14.6);for(let i=0;i<6;i++)rm(boxG(1.4,1.8,.1),MAT(['#fff','#ffe08a','#bfe8ff'][i%3]),10.6+i*1.4,4+(i%2)*.8,-14.4);plant(-18,12);bench(10,10,8,Math.PI);
   spot(-8,-3,'Find a job','📋 Job Counselor',guard('Gain',()=>{const el=panel('📋 Job Center','');jobsPanel(el)}),true)},
 office:b=>{sign('🏢 OFFICE TOWER',0,-14.8);for(let r=0;r<2;r++)for(let c=-1;c<=1;c++){desk(c*12,-8+r*9,0);chair(c*12,-5+r*9,Math.PI)}plant(19,-12);plant(-19,-12);rm(boxG(2,3.6,2),MAT('#aaccee'),17,1.8,8);
   spot(0,-2.2,'Work','💼 Your desk',guard('Gain',work),true);npcAt(-16,8,Math.PI/2,'#444','Editor (Brainville Times)');spot(-13,8,'Give an interview','📰 The Brainville Times',()=>startConv(S.path==='Lose'?'journalistL':'journalistG'))},
 school:b=>{sign('🏫 SCHOOL',0,-14.8);ROOM.board=whiteboard(0,-14.6,S.path==='Lose'?'2 + 2 = fish':'Today: fractions');for(let r=0;r<3;r++)for(let c=-2;c<=2;c++)desk(c*7.5,-4+r*6,Math.PI,false);desk(0,-10.5,0,true);
   const kids=['#ff8fa3','#8fd3ff','#ffd27a','#a8f0b0','#d0b0ff','#ffb38a'];for(let i=0;i<6;i++)npcAt(-15+(i%5)*7.5+(i>4?3.75:0),-1.5+Math.floor(i/5)*6+.3,Math.PI,kids[i],'Student');
   spot(0,-7.5,S.path==='Lose'?'Take the pop quiz':'Teach the class','✏️ Classroom',()=>startConv(S.path==='Lose'?'classroomL':'classroomG'),true);spot(5,-12,'Write on the board','🧑‍🏫 Whiteboard',writeBoard);spot(-10,-10.5,'Work','💼 Teacher\'s desk',guard('Gain',work))},
 hospital:b=>{sign('🏥 HOSPITAL',0,-14.8);bed(-16,-8);bed(-9,-8);bed(16,-8);desk(4,-11,0);couch(12,8,Math.PI,'#7fb2a0');chair(8,4.5,0);npcAt(4,-13.4,0,'#e9f2ff','Dr. Wrinkle-Free');npcAt(16,4,Math.PI,'#a0c8b8','Dr. Calm (therapist)');
   spot(4,-8.2,S.path==='Lose'?'Get checked':'See a patient','🩺 Doctor',()=>startConv(S.path==='Lose'?'doctorL':'doctorG'),true);spot(12,4.8,'Talk to the therapist','🛋 Dr. Calm',()=>startConv('therapist'))},
 court:b=>{sign('⚖️ COURTHOUSE',0,-14.8);judgeBench(0,-11);npcAt(0,-12.6,0,'#1d1d24','Judge Gavel');table(-8,-2,7,3);table(8,-2,7,3);chair(-8,1,Math.PI);chair(8,1,Math.PI,FABR,false);bench(-10,8,10,Math.PI);bench(10,8,10,Math.PI);rm(boxG(3,5,1.6),MAT('#7a5a3a'),15,2.5,-8);
   spot(-8,3,S.path==='Lose'?'Answer the lawsuit':'Take the case','⚖️ Your table',()=>startConv(S.path==='Lose'?'courtL':'courtG'),true);spot(0,4,'Give an election speech','🗳 Podium',()=>startConv('election'));podium(0,6,'#2b3a67')},
 lab:b=>{sign('🔬 SCIENCE LAB',0,-14.8);labBench(-10,-9);labBench(10,-9);labBench(-10,1);rm(boxG(4,2,4),MAT('#c8e6ff'),10,1,2);const mouse=rm(new THREE.SphereGeometry(.45,10,8),MAT('#c9c9cf'),10,2.4,2);ROOM.mouse=mouse;plant(18,12);
   spot(-10,-6,'Work','💼 Lab bench',guard('Gain',work),true);spot(-10,4,'Major Projects','🔬 Projects',guard('Gain',projects));spot(10,5.4,'Mouse maze experiment','🐭 Maze',()=>startConv('experiment'))},
 cafe:b=>{sign("☕ BEETHOVEN'S CAFÉ",0,-14.8);counter(0,-11,16);rm(new THREE.CylinderGeometry(.9,.9,2.2,14),METAL,-5,4.3,-11);for(let i=0;i<3;i++){table(-12+i*12,2,3.4,3.4);chair(-12+i*12,5,Math.PI);chair(-12+i*12,-1,0)}rm(boxG(5,3.6,2.4),BLACK,16,1.8,10);npcAt(0,-13.2,0,'#6b4226','Barista');
   spot(-5,-8.4,'Beethoven\'s coffee','☕ Espresso machine',guard('Gain',coffee),true);spot(12,9,'Power nap','😴 Comfy corner',guard('Gain',nap))},
 diner:b=>{sign('⏲ MICROWAVE DINER',0,-14.8);counter(0,-11,18,0,MAT('#ff8fa3'));micro(-6,-11);micro(0,-11);ROOM.fridge=fridge(12,-12.6);for(let i=0;i<3;i++){table(-12+i*10,3,4,4,MAT('#e9e9ea'));chair(-12+i*10,6.4,Math.PI,MAT('#e63c50'))}rug(0,3,36,10,'#222');
   spot(-3,-8.4,'Stare at the microwave','⏲ Microwave',guard('Lose',()=>{const el=panel('⏲ Microwave','');microwave(el)}),true);spot(12,-9.4,'Open the fridge','🧊 Fridge',openFridge)},
 mall:b=>{sign('🛍 BRAINROT MALL',0,-14.8);const games=['SKIBIDI','BRAIN.EXE','JUMP!!','CLICK ME'];games.forEach((t,i)=>arcade(-15+i*5,-12,t));shelfProducts(12,-12,12);counter(12,4,10,0,MAT('#ff5ab4'));rm(new THREE.SphereGeometry(1.2,12,10),MAT('#ffd23c'),8,3.9,4);
   spot(-10,-9,'Play the arcade','🕹 Arcade',guard('Lose',()=>doAct(()=>{lose(2);toast('🕹️ 47 flashing lights later…')})),true);spot(12,7,'Buy a Skibidi Plushie','🧸 Counter',guard('Lose',()=>doAct(()=>{lose(1.5);toast('🧸 You hug it. It does not hug back.')})))},
 supermarket:b=>{sign('🛒 SUPERMARKET',0,-14.8);for(let i=0;i<3;i++)shelfProducts(-8+i*8,-4+0,6);shelfProducts(-12,-13,16);counter(12,8,8,0,MAT('#3a7bff'));rm(boxG(1.4,1,1),BLACK,12,3.7,8);
   spot(12,10.6,S.path==='Lose'?'Shake the cereal box':'Work the register','🛒 Register',()=>{if(S.path==='Lose')doAct(()=>{lose(1);toast('🥣 *shake shake* There is no prize.')});else work()},true)},
 wall:b=>{sign('🧱 WALL ALLEY',0,-14.8);for(let r=0;r<10;r++)for(let c=0;c<12;c++){const br=rm(boxG(3.4,.85,1.4),MAT(['#a0522d','#8b4a2b','#b35f37'][(r+c)%3]),-18+c*3.6+(r%2)*1.8,.45+r*.9,-11);br.castShadow=false}col(0,-11,44,1.6);rm(boxG(2.6,3,2.4),MAT('#4a6a3a'),15,1.5,8);
   spot(0,-8.6,'Walk into the wall','🧱 The Wall',guard('Lose',()=>doAct(()=>{lose(2);bonk();P.y-=0})),true)},
};
function writeBoard(){if(!ROOM||!ROOM.board)return;const lines=S.path==='Lose'?['2 + 2 = fish','the sun is a big lamp','skibidi = science','cats are just loud bread']:['¾ = 0.75','H₂O = water','√144 = 12','E = mc²'];const t=rnd(lines);const m=ROOM.board.material;m.map=canvasTex((g,w,h)=>{g.fillStyle='#fdfdfb';g.fillRect(0,0,w,h);g.fillStyle=S.path==='Lose'?'#d12':'#1d4ed8';g.font='700 46px "Comic Neue", sans-serif';g.textAlign='center';g.fillText(t,w/2,h/2+16)},512,238);m.needsUpdate=true;toast('🧑‍🏫 You wrote: '+esc(t));if(S.path==='Lose')lose(.5);else gain(.3)}
function openFridge(){const h=ROOM&&ROOM.fridge;if(!h)return;const open=h.rotation.y===0;h.rotation.y=open?-1.9:0;snd('boing');if(open)toast('🧊 The fridge only has microwave meals. Of course.')}

// ---------------- build / enter / leave
function buildRoom(b){const i=b.i;const ox=6000+i*700,oy=300;const g=new THREE.Group();g.position.set(ox/K,0,oy/K);roomG.add(g);
  const r={b,ox,oy,g,cols:[],spots:[],walls:[],npcs:[]};ROOM=r;const W2=RSIZE.w/2,D2=RSIZE.d/2,Hh=RSIZE.h;
  const L=LOOKS[look()];const wallC=mix(L.wall(i),'#ffffff',.25);
  const floorMat=MAT(b.id==='cinema'?'#3a1e2a':b.id==='wall'?'#6b6b70':b.id==='hospital'||b.id==='lab'?'#e6edf2':'#b88a5a');
  const fl=rm(boxG(RSIZE.w,.4,RSIZE.d),floorMat,0,-.2,0);fl.castShadow=false;
  if(!['cinema','wall','hospital','lab'].includes(b.id))for(let x=-W2+2;x<W2;x+=4){const l=rm(boxG(.06,.02,RSIZE.d),DWOOD,x,.01,0);l.castShadow=false}
  const wm=()=>new THREE.MeshStandardMaterial({color:wallC,roughness:.9,transparent:true,opacity:1});
  [[0,-D2,RSIZE.w,.6,new THREE.Vector3(0,0,1)],[0,D2,RSIZE.w,.6,new THREE.Vector3(0,0,-1)],[-W2,0,.6,RSIZE.d,new THREE.Vector3(1,0,0)],[W2,0,.6,RSIZE.d,new THREE.Vector3(-1,0,0)]].forEach(([x,z,w,d,n])=>{const m=rm(boxG(w,Hh,d),wm(),x,Hh/2,z);m.castShadow=false;r.walls.push({m,x,z,n});rm(boxG(w+.02,.6,d+.02),MAT(mix(wallC,'#000000',.2)),x,.3,z).castShadow=false});
  // exit door on the south wall
  rm(boxG(4,6.4,.3),DWOOD,0,3.2,D2-.4);rm(boxG(.3,.3,.3),METAL,1.4,3.2,D2-.6);
  r.exit=spot(0,D2-2.6,'Leave','🚪 Door',()=>leaveRoom());
  r.cols.push({x:ox-W2*K-50,y:oy-D2*K-50,w:RSIZE.w*K+100,h:50},{x:ox-W2*K-50,y:oy+D2*K,w:RSIZE.w*K+100,h:50},{x:ox-W2*K-50,y:oy-D2*K,w:50,h:RSIZE.d*K},{x:ox+W2*K,y:oy-D2*K,w:50,h:RSIZE.d*K});
  (LAYOUT[b.id]||(()=>{}))(b);ROOMS[b.id]=r;return r}
function wipe(cb){const w=$('wipe');w.classList.remove('hide','out');w.classList.add('in');snd('tick');setTimeout(()=>{cb();w.classList.remove('in');w.classList.add('out');setTimeout(()=>w.classList.add('hide'),520)},520)}
function enterRoom(b){if(!PATHOK(b.p)&&b.p!=='Any'){}
  wipe(()=>{let r=ROOMS[b.id];if(r&&r.look!==look()){roomG.remove(r.g);r=null}ROOM=r||buildRoom(b);ROOM.look=look();ROOM.g.add(roomLight);roomLight.position.set(0,14,0);ROOM.back={x:b.door.x,y:b.door.y+30};P.x=ROOM.ox;P.y=ROOM.oy+(RSIZE.d/2-5)*K;P.tx=null;yaw=0;S.lastPlace=b.n;
    toast('📍 '+b.n.charAt(0)+b.n.slice(1).toLowerCase()+(b.p!=='Any'&&S.path!==b.p?' (not for your path)':''));
    if(TUT&&TUT.running){const s=SEQ[TUT.path][TUT.step];if(s&&s.tg===b.id){}}})}
function leaveRoom(instant){if(!ROOM)return;const back=ROOM.back;const go=()=>{ROOM=null;standUp();appliedLook=null;if(back){P.x=back.x;P.y=back.y}P.tx=null};if(instant)go();else wipe(go)}
function roomSolid(x,y){for(const c of ROOM.cols)if(x>c.x-8&&x<c.x+c.w+8&&y>c.y-8&&y<c.y+c.h+8)return true;return false}
function roomNear(){let best=null,bd=48;for(const s of ROOM.spots){const d=Math.hypot(P.x-s.px,P.y-s.py);if(d<bd){bd=d;best=s}}return best}
// ---------------- sitting
let SIT=null;function sitDown(x,z,rot){SIT={x,z,rot};P.x=ROOM.ox+x*K;P.y=ROOM.oy+z*K;P.face=rot;toast('🪑 You sit down. Move to stand up.')}
function standUp(){SIT=null}

// ================================================================ CONVERSATION SCENES
// Two people at a table. The camera cuts to whoever talks. You pick what to say (bottom-left).
const CONV={
 therapist:{who:'Dr. Calm',shirt:'#a0c8b8',meter:['🫶 Trust',50],nodes:{
  a:{say:"Welcome. Take a seat. So… how's your brain lately?",opts:[{t:"Honestly? A bit stressed. Gates, jobs, everything.",m:15,b:1,n:'b'},{t:"bro my brain is just loading 🔄",m:-5,b:-1,n:'b'},{t:"I'd rather not talk about it.",m:-10,b:0,n:'b'}]},
  b:{say:"Hm. When you feel overwhelmed, what do you usually do?",opts:[{t:"Take a break. Coffee, a nap, a walk.",m:15,b:1,n:'c'},{t:"Scroll BrainTok for 6 hours.",m:-10,b:-2,n:'c'},{t:"Panic, mostly.",m:5,b:0,n:'c'}]},
  c:{say:"Here's a trick: name one thing you did well today.",opts:[{t:"I learned something new.",m:20,b:1,n:null},{t:"I didn't walk into the wall. Today.",m:10,b:0,n:null},{t:"I clicked every clickbait 😎",m:-10,b:-2,n:null}]}},
  end:{good:["You leave feeling lighter.",()=>{S.stress=Math.max(0,S.stress-45);S.emb=Math.max(0,S.emb-30);return'😌 Stress −45, embarrassment −30'}],bad:["Dr. Calm writes something in a notebook. Very long.",()=>'📝 "Patient is… a lot."'],mid:["That was a good start.",()=>{S.stress=Math.max(0,S.stress-15);return'😌 Stress −15'}]}},
 doctorG:{who:'Skater kid (patient)',shirt:'#ff8fa3',meter:['🩺 Patient trust',50],nodes:{
  a:{say:"Doc, I fell off my skateboard. My arm is swollen and bent. 😭",opts:[{t:"Let's get an X-ray. It might be a fracture.",m:20,b:2,n:'b'},{t:"Just walk it off.",m:-25,b:-1,n:'b'},{t:"Have you tried turning it off and on again?",m:-15,b:-1,n:'b'}]},
  b:{say:"The X-ray shows a crack in the bone. What now?",opts:[{t:"A cast for about 6 weeks, then a check-up.",m:25,b:2,n:'c'},{t:"A plaster. Like a cartoon.",m:-15,b:-1,n:'c'},{t:"Ice cream. For morale.",m:5,b:0,n:'c'}]},
  c:{say:"Will I be able to skate again?",opts:[{t:"Yes! Once it heals. Wear a helmet and pads.",m:20,b:1,n:null},{t:"Never. Become a librarian.",m:-20,b:0,n:null},{t:"Only backwards.",m:-5,b:-1,n:null}]}},
  end:{good:["The patient gives you a thumbs up with the good arm.",()=>{S.coins+=30;return'🪙 +30 coins, the hospital is impressed'}],bad:["The patient asks for a second opinion. From a pigeon.",()=>{stress(10);return'😰 Stress +10'}],mid:["The patient is OK. You could've been clearer.",()=>{S.coins+=10;return'🪙 +10 coins'}]}},
 doctorL:{who:'Dr. Wrinkle-Free',shirt:'#e9f2ff',meter:['🩺 Doctor patience',60],nodes:{
  a:{say:"So. What brings you in today?",opts:[{t:"My brain feels… quieter. It's great.",m:-5,b:-1,n:'b'},{t:"I think I'm getting smarter. Make it stop.",m:-10,b:-2,n:'b'},{t:"I read a book by accident.",m:5,b:1,n:'b'}]},
  b:{say:"Hmm. Follow my finger with your eyes. Left… right…",opts:[{t:"*follows a pigeon instead*",m:-10,b:-2,n:'c'},{t:"*follows perfectly*",m:10,b:1,n:'c'},{t:"Which finger? You have ten.",m:-5,b:-1,n:'c'}]},
  c:{say:"My diagnosis: acute brainrot. I prescribe one (1) book a day.",opts:[{t:"Can I get that as a 15-second video?",m:-15,b:-2,n:null},{t:"Fine. One book.",m:15,b:2,n:null},{t:"Is brainrot contagious? Asking for my friends.",m:-5,b:-1,n:null}]}},
  end:{good:["The doctor is relieved. You are not (it's bad for your run).",()=>'📚 The doctor believes in you. Ew.'],bad:["The doctor sighs so hard the X-ray machine turns on.",()=>{lose(2);return'🫠 Extra brainrot for the road'}],mid:["You leave with a sticker.",()=>'🩹 You got a sticker.']}},
 courtL:{who:'Judge Gavel',shirt:'#1d1d24',meter:['⚖️ Judge patience',60],nodes:{
  a:{say:"Order! The Brainville Times is suing you for spreading a fake headline. How do you plead?",opts:[{t:"Guilty. I shared it without reading it.",m:15,b:1,n:'b'},{t:"Not guilty. The headline had 🔥 emojis, so it's true.",m:-15,b:-2,n:'b'},{t:"What's a headline?",m:-10,b:-1,n:'b'}]},
  b:{say:"Did you check any other source before sharing it?",opts:[{t:"No, and I should have.",m:15,b:1,n:'c'},{t:"I checked the comments. They said 'real'.",m:-15,b:-2,n:'c'},{t:"OBJECTION! …wait, I'm the one being sued.",m:-5,b:-1,n:'c',slam:1}]},
  c:{say:"Any final words before I decide?",opts:[{t:"I'll read before I share.",m:15,b:1,n:null},{t:"Like and subscribe.",m:-20,b:-2,n:null},{t:"Can I get my sentence as a meme?",m:-10,b:-1,n:null}]}},
  end:{good:["Case dismissed. The judge tells you to read more. (Ugh.)",()=>'⚖️ Case dismissed'],bad:["GUILTY. You must hold a sign in the plaza: 'I BELIEVED A FAKE HEADLINE'.",()=>{S.emb=Math.min(100,S.emb+35);if(S.emb>=50)hide();return'🪧 Embarrassment +35'}],mid:["Small fine: you must read one (1) terms of service.",()=>'📜 Community reading service']}},
 courtG:{who:'Judge Gavel',shirt:'#1d1d24',meter:['⚖️ Jury',50],nodes:{
  a:{say:"Counselor, the witness says: 'I was home all evening. I watched TV until 9. I was at the park at 8.'",opts:[{t:"OBJECTION! They can't be home AND at the park at 8.",m:30,b:2,n:'b',slam:1},{t:"Sounds fine to me.",m:-20,b:-1,n:'b'},{t:"Can the witness do a backflip?",m:-10,b:-1,n:'b'}]},
  b:{say:"The other lawyer says your client 'looks guilty'. Your response?",opts:[{t:"Looking guilty isn't evidence. Show proof.",m:25,b:2,n:'c'},{t:"Fair point, they do.",m:-25,b:-1,n:'c'},{t:"YOU look guilty.",m:-5,b:0,n:'c'}]},
  c:{say:"Closing statement, counselor.",opts:[{t:"The story doesn't add up. The jury must find my client not guilty.",m:25,b:2,n:null},{t:"Uhh… thank you for coming to my TED talk.",m:-10,b:0,n:null},{t:"*slams table* NO FURTHER QUESTIONS",m:5,b:0,n:null,slam:1}]}},
  end:{good:["NOT GUILTY! Your client hugs you. The judge nods.",()=>{S.coins+=40;gain(2);return'🪙 +40 coins, 🧠 brain cells'}],bad:["You lost the case. Your client is very confused.",()=>{stress(15);return'😰 Stress +15'}],mid:["Hung jury. Try again another day.",()=>{S.coins+=10;return'🪙 +10'}]}},
 debate:{who:'Ms. Mic (host)',shirt:'#d24c4c',meter:['📊 Audience',50],nodes:{
  a:{say:"Welcome to THE DEBATE SHOW! Topic: should kids read more? Opening statement!",opts:[{t:"Yes. Reading grows your vocabulary and focus.",m:20,b:2,n:'b'},{t:"No. Videos are just books that move.",m:-10,b:-2,n:'b'},{t:"*airhorn noises*",m:5,b:-1,n:'b'}]},
  b:{say:"Your opponent says 'books are boring'. Rebuttal?",opts:[{t:"Boring to start, but they let you imagine anything.",m:20,b:2,n:'c'},{t:"Agreed. Next topic.",m:-15,b:-1,n:'c'},{t:"Your FACE is boring.",m:-5,b:-1,n:'c'}]},
  c:{say:"Final 10 seconds! Make them count!",opts:[{t:"Read 20 minutes a day. Your future self will thank you.",m:20,b:1,n:null},{t:"Follow me on BrainTok.",m:-10,b:-2,n:null},{t:"*dabs*",m:0,b:-1,n:null}]}},
  end:{good:["The audience gives you a standing ovation! 👏",()=>{confetti();return'🏆 You won the Debate Show'}],bad:["The audience throws (foam) tomatoes. 🍅",()=>{if(S.path==='Lose')S.emb=Math.min(100,S.emb+20);return'🍅 SPLAT'}],mid:["A draw. The host is disappointed in both of you.",()=>'🤝 Draw']}},
 journalistL:{who:'Editor (Brainville Times)',shirt:'#444',meter:['📰 Clicks',40],nodes:{
  a:{say:"We need a headline about the new park. Make people click!",opts:[{t:"'You WON'T BELIEVE what's in the PARK 😱😱'",m:20,b:-2,n:'b'},{t:"'New park opens on Main Street'",m:-15,b:1,n:'b'},{t:"'PARK? MORE LIKE BARK 🐶'",m:10,b:-1,n:'b'}]},
  b:{say:"Good. Now the article. Facts or vibes?",opts:[{t:"Vibes. Only vibes.",m:15,b:-2,n:'c'},{t:"Facts, with quotes from real people.",m:-10,b:2,n:'c'},{t:"Just the word 'park' 400 times.",m:5,b:-1,n:'c'}]},
  c:{say:"Last thing: a thumbnail.",opts:[{t:"Me pointing at a pigeon with a red arrow and a shocked face",m:20,b:-2,n:null},{t:"A nice photo of the park",m:-15,b:1,n:null},{t:"Just a red circle. On nothing.",m:10,b:-1,n:null}]}},
  end:{good:["Your article goes MEGA viral. Dumb players everywhere read it.",()=>{lose(3);return'🔥 2 million clicks. Zero facts.'}],bad:["Your article is accurate. Nobody clicks. Tragic.",()=>'📉 4 clicks (one was your mom)'],mid:["It's… fine. Some clicks.",()=>{lose(1);return'📰 Published'}]}},
 journalistG:{who:'Editor (Brainville Times)',shirt:'#444',meter:['🔎 Accuracy',50],nodes:{
  a:{say:"Fact-check this headline: 'Great Wall of China easily visible from space!'",opts:[{t:"False. Astronauts say you can't see it with the naked eye.",m:25,b:2,n:'b'},{t:"True, it's huge.",m:-20,b:-1,n:'b'},{t:"Let me ask BrainTok.",m:-15,b:-1,n:'b'}]},
  b:{say:"Next: 'Study shows chocolate makes you a genius.' Your note?",opts:[{t:"Check who paid for the study and how many people were in it.",m:25,b:2,n:'c'},{t:"Publish it, I love chocolate.",m:-15,b:-1,n:'c'},{t:"Only dark chocolate.",m:-5,b:0,n:'c'}]},
  c:{say:"Last one. A quote with no source. Run it?",opts:[{t:"No. Find the original source first.",m:25,b:2,n:null},{t:"Yes, it sounds smart.",m:-20,b:-1,n:null},{t:"Attribute it to Albert Zweistein.",m:-5,b:0,n:null}]}},
  end:{good:["The Brainville Times prints a correction, thanks to you.",()=>{S.coins+=30;gain(1.5);return'🪙 +30, 🧠 brain cells'}],bad:["The fake news got printed. Oops.",()=>{stress(10);return'😰 Stress +10'}],mid:["Mostly right. Good work.",()=>{S.coins+=10;return'🪙 +10'}]}},
 election:{who:'Voters of Brainville',shirt:'#5577aa',meter:['🗳 Votes',40],nodes:{
  a:{say:"Citizens gather at the podium. 'Why should we vote for you?'",opts:[{t:S=>S.path==='Lose'?"FREE BRAINTOK FOR EVERYONE":"More libraries and free tutoring.",m:20,b:0,n:'b'},{t:"Because I said so.",m:-15,b:-1,n:'b'},{t:"I promise a pigeon in every home.",m:10,b:0,n:'b'}]},
  b:{say:"A voter asks: 'What will you do about the potholes?'",opts:[{t:"Fix the worst ones first and publish a plan.",m:20,b:1,n:'c'},{t:"Turn them into tiny swimming pools.",m:5,b:-1,n:'c'},{t:"What's a pothole?",m:-15,b:-1,n:'c'}]},
  c:{say:"Final words before the vote!",opts:[{t:"Vote for me. I'll listen to you.",m:20,b:1,n:null},{t:"VOTE OR ELSE (please)",m:-5,b:-1,n:null},{t:"*throws confetti at the crowd*",m:15,b:0,n:null}]}},
  end:{good:["YOU WON THE ELECTION! For 20 minutes, your path gets a boost.",()=>{confetti();if(S.path==='Gain')gain(3);else lose(3);return'🏛 Mayor of Brainville (temporary)'}],bad:["You got 3 votes. One was a pigeon.",()=>'🐦 3 votes'],mid:["You lost, but it was close!",()=>'🗳 Close race']}},
 classroomL:{who:'Teacher',shirt:'#3a7bff',meter:['😤 Teacher patience',60],nodes:{
  a:{say:"Pop quiz! What is the capital of France?",opts:[{t:"F.",m:-15,b:-2,n:'b'},{t:"Paris.",m:15,b:2,n:'b'},{t:"France is a fake country.",m:-10,b:-2,n:'b'}]},
  b:{say:"…OK. How many legs does a spider have?",opts:[{t:"Spiders are just ants that gave up.",m:-10,b:-2,n:'c'},{t:"Eight.",m:15,b:2,n:'c'},{t:"*throws paper airplane*",m:-15,b:-1,n:'c'}]},
  c:{say:"Last question. What is 7 × 8?",opts:[{t:"78",m:-10,b:-2,n:null},{t:"56",m:15,b:2,n:null},{t:"*falls asleep*",m:-15,b:-2,n:null}]}},
  end:{good:["The teacher is proud. You feel… smarter. Gross.",()=>'📝 A+. Oh no.'],bad:["The teacher gives up and puts on a movie.",()=>{lose(2);return'📺 Movie day. Brain off.'}],mid:["C−. Perfectly average.",()=>'📝 C−']}},
 classroomG:{who:'The class',shirt:'#ffb38a',meter:['🙋 Class attention',50],nodes:{
  a:{say:"Students: 'Why do we need fractions?!'",opts:[{t:"Pizza. If you share a pizza with 4 friends, that's quarters.",m:25,b:1,n:'b'},{t:"Because the test says so.",m:-10,b:0,n:'b'},{t:"You don't. Class dismissed.",m:-20,b:-1,n:'b'}]},
  b:{say:"A student says: 'Is ½ bigger than ⅓?'",opts:[{t:"Yes. Cut a pizza in 2 vs 3: halves are bigger slices.",m:25,b:1,n:'c'},{t:"No, 3 is bigger than 2.",m:-20,b:-2,n:'c'},{t:"Ask your parents.",m:-10,b:0,n:'c'}]},
  c:{say:"Students: 'Can we have a fun fact?'",opts:[{t:"Octopuses have three hearts!",m:20,b:1,n:null},{t:"Homework is a fun fact.",m:-15,b:0,n:null},{t:"Wombat poop is cube-shaped.",m:25,b:1,n:null}]}},
  end:{good:["The whole class claps. One kid says you're the best teacher ever.",()=>{S.coins+=35;S.ideas++;return'🪙 +35, 💡 idea +1'}],bad:["A paper airplane hits you in the head.",()=>{stress(12);return'✈️ Stress +12'}],mid:["Half the class was listening. Not bad.",()=>{S.coins+=15;return'🪙 +15'}]}},
 experiment:{who:'Lab assistant',shirt:'#e6fbff',meter:['🐭 Mouse progress',40],nodes:{
  a:{say:"The mouse needs to learn the maze. How should we start?",opts:[{t:"Put a treat at the end and let it explore.",m:25,b:1,n:'b'},{t:"Yell directions at it.",m:-15,b:-1,n:'b'},{t:"Show it a BrainTok tutorial.",m:-10,b:-2,n:'b'}]},
  b:{say:"Should we change the maze every time?",opts:[{t:"No. Keep it the same so we can measure learning.",m:25,b:2,n:'c'},{t:"Yes! Chaos!",m:-15,b:-1,n:'c'},{t:"Let the mouse design it.",m:0,b:0,n:'c'}]},
  c:{say:"How do we know it learned?",opts:[{t:"Time it every run. If it gets faster, it learned.",m:25,b:2,n:null},{t:"Ask the mouse.",m:-10,b:-1,n:null},{t:"Vibes.",m:-15,b:-2,n:null}]}},
  end:{good:["The mouse runs the maze in 9 seconds! Science! 🎉",()=>{gain(2);S.ideas++;return'🐭 Experiment success, 💡 idea +1'}],bad:["The mouse is now in charge of the lab.",()=>'🐭 New lab director'],mid:["The mouse found the treat. Eventually.",()=>{gain(.5);return'🐭 Partial success'}]}},
};
let CV=null; // active conversation
let convCam=null;
function startConv(key){const c=CONV[key];if(!c||!ROOM)return;const b=blocked();if(b&&!(key==='therapist'&&frozen()))return toast('⛔ '+b);
  S.convSeen=S.convSeen||{};const seen=!!S.convSeen[key];
  // seat the two people facing each other at the spot
  const sp=roomNear()||ROOM.spots[0];const lx=(sp.px-ROOM.ox)/K,lz=(sp.py-ROOM.oy)/K;
  const meP={x:lx,z:lz+1.2},npP={x:lx,z:lz-4.2};
  const npc=avatar(c.shirt,'#e8b98f','#2b2b3a',ROOM.g);npc.g.position.set(npP.x,0,npP.z);npc.g.rotation.y=0;
  const tbl=new THREE.Group();ROOM.g.add(tbl);mesh(boxG(4,.3,2.2),WOOD,tbl,lx,2.6,lz-1.5);for(const sx of[-1,1])mesh(boxG(.3,2.6,.3),DWOOD,tbl,lx+sx*1.7,1.3,lz-1.5);
  P.x=ROOM.ox+meP.x*K;P.y=ROOM.oy+meP.z*K;P.face=Math.PI;P.tx=null;
  CV={key,c,node:c.start||'a',meter:c.meter[1],npc,tbl,seen,me:meP,np:npP};
  const el=$('conv');el.classList.remove('hide');el.innerHTML=`<div class="lb t"></div><div class="lb b"></div><div class="cmeter"><span>${c.meter[0]}</span><div class="cbar"><div class="cfill" id="cfill"></div></div></div><div class="csub"><div class="cname" id="cname"></div><div class="ctext" id="ctext"></div></div><div class="copts" id="copts"></div>${seen?'<button class="cskip" id="cskip">⏩ Fast text</button>':''}`;
  requestAnimationFrame(()=>el.classList.add('on'));if(seen)$('cskip').onclick=()=>{CV.fast=!CV.fast};
  setMeter();shot('wide');setTimeout(()=>sayNode(),900);snd('slam')}
function setMeter(){const f=$('cfill');if(f){f.style.width=Math.max(0,Math.min(100,CV.meter))+'%';f.style.background=CV.meter>=60?'#2fbf71':CV.meter<=25?'#e5484d':'#ffd23c'}}
function shot(kind){if(!CV||!ROOM)return;const o=new THREE.Vector3(ROOM.ox/K,0,ROOM.oy/K);const me=o.clone().add(new THREE.Vector3(CV.me.x,0,CV.me.z)),np=o.clone().add(new THREE.Vector3(CV.np.x,0,CV.np.z));
  if(kind==='wide')convCam={pos:new THREE.Vector3(me.x+9,9,(me.z+np.z)/2+4),look:new THREE.Vector3(me.x,3.5,(me.z+np.z)/2)};
  else if(kind==='npc')convCam={pos:new THREE.Vector3(me.x+1.6,5.6,me.z+2.6),look:new THREE.Vector3(np.x,4.6,np.z)}; // over your shoulder, at them
  else convCam={pos:new THREE.Vector3(np.x-1.6,5.6,np.z-2.6),look:new THREE.Vector3(me.x,4.6,me.z)}} // over their shoulder, at you
function typeLine(name,text,cb,pitch){$('cname').textContent=name;const t=$('ctext');let i=0;const sp=CV.fast?400:(UI_TEXT_SPEED());clearInterval(CV.ti);
  CV.ti=setInterval(()=>{i+=CV.fast?text.length:1;t.textContent=text.slice(0,i);if(i%3===0)blip(pitch);if(i>=text.length){clearInterval(CV.ti);cb&&setTimeout(cb,CV.fast?150:500)}},1000/sp)}
const UI_TEXT_SPEED=()=>38;
function blip(p){if(!S.music)return;try{AC=AC||new (window.AudioContext||window.webkitAudioContext)();const o=AC.createOscillator(),g=AC.createGain();o.type='square';o.frequency.value=p*(0.9+Math.random()*.25);o.connect(g);g.connect(AC.destination);const t=AC.currentTime;g.gain.setValueAtTime(.025,t);g.gain.exponentialRampToValueAtTime(.0001,t+.05);o.start(t);o.stop(t+.05)}catch(e){}}
function sayNode(){if(!CV)return;const n=CV.c.nodes[CV.node];shot('npc');talking=CV.npc;
  typeLine(CV.c.who,n.say,()=>{talking=null;const box=$('copts');box.innerHTML='';n.opts.forEach((o,i)=>{const t=typeof o.t==='function'?o.t(S):o.t;const b=document.createElement('button');b.className='copt';b.innerHTML=`<span>${i+1}</span>${esc(t)}`;b.onclick=()=>pick(o,t);box.appendChild(b)});box.classList.add('show')},320)}
function pick(o,t){const box=$('copts');box.classList.remove('show');box.innerHTML='';shot('me');talking=ME;
  typeLine('You',t,()=>{talking=null;if(o.slam)objection();CV.meter+=o.m;setMeter();if(o.b>0)gain(o.b*.6);else if(o.b<0)lose(-o.b*.6);
    const fx=document.createElement('div');fx.className='cfx';fx.textContent=o.m>0?'▲ '+CV.c.meter[0]:o.m<0?'▼ '+CV.c.meter[0]:'';fx.style.color=o.m>0?'#7dffb0':'#ff7d9a';$('conv').appendChild(fx);setTimeout(()=>fx.remove(),1200);
    if(o.n){CV.node=o.n;setTimeout(sayNode,500)}else setTimeout(endConv,600)},220)}
function objection(){const d=document.createElement('div');d.className='objection';d.textContent='OBJECTION!';$('conv').appendChild(d);snd('slam');try{navigator.vibrate&&navigator.vibrate(120)}catch(e){}$('app').classList.add('shakeAll');setTimeout(()=>$('app').classList.remove('shakeAll'),350);setTimeout(()=>d.remove(),1100)}
function endConv(){const c=CV.c;const res=CV.meter>=65?c.end.good:CV.meter<=25?c.end.bad:c.end.mid;shot('wide');
  typeLine(c.who,res[0],()=>{const msg=res[1]();S.convSeen[CV.key]=1;badge('talk','Small Talk');
    const box=$('copts');box.innerHTML='';const b=document.createElement('button');b.className='copt';b.innerHTML='<span>✓</span>'+esc(msg)+' — Leave';b.onclick=closeConv;box.appendChild(b);box.classList.add('show');update();save()},320)}
function closeConv(){if(!CV)return;clearInterval(CV.ti);ROOM&&ROOM.g.remove(CV.npc.g);ROOM&&ROOM.g.remove(CV.tbl);CV=null;convCam=null;talking=null;const el=$('conv');el.classList.remove('on');setTimeout(()=>{el.classList.add('hide');el.innerHTML=''},400)}
let talking=null;

// ================================================================ 1.5 extras: whispers, recap, loading screen, photo mode, rolling counter
const WHISPER={Lose:['did they just walk into a wall?','bro is speedrunning brainrot','I can hear the microwave from here','is that… a dunce cap?','they clicked it. they clicked the link.'],Gain:['is that the kid from the library?','they read for FUN?','I heard they passed the Gate','new glasses?? 👀','they corrected the teacher lol']};
const bubbleS=sprite(textTex('...',{size:40}),6,1.3,town);bubbleS.visible=false;let bubbleUntil=0,bubbleNpc=null;
setInterval(()=>{if(!S.path||ROOM||inMoon)return;let best=null,bd=260;for(const o of NPC3){const d=Math.hypot(o.n.x-P.x,o.n.y-P.y);if(d<bd){bd=d;best=o}}if(!best)return;bubbleNpc=best;bubbleS.material.map=textTex('💬 '+rnd(WHISPER[S.path]),{size:38,bg:'rgba(255,255,255,.95)',color:'#222'});bubbleS.material.needsUpdate=true;bubbleUntil=Date.now()+3500},9000);
let shownCells=S.cells;
function roll(){const diff=S.cells-shownCells;if(Math.abs(diff)<1){shownCells=S.cells}else shownCells+=diff*.18;const el=$('cCells');const txt='🧠 '+fmt(shownCells);if(el.textContent!==txt)el.textContent=txt}
function photoMode(on){document.body.classList.toggle('photo',on);if(on){closePanel();toast('📸 Photo mode: drag to aim, take a screenshot. Tap ✕ to exit.')}}
