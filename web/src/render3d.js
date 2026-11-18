// ---------------------------------------------------------------- 3D world (three.js): Roblox-style blocky town
const cv=$('cv');
const R=new THREE.WebGLRenderer({canvas:cv,antialias:true,powerPreference:'high-performance'});
R.setPixelRatio(Math.min(1.75,window.devicePixelRatio||1));
R.shadowMap.enabled=true;R.shadowMap.type=THREE.PCFSoftShadowMap;R.outputEncoding=THREE.sRGBEncoding;
const scene=new THREE.Scene();
const cam=new THREE.PerspectiveCamera(62,1,.1,700);
const hemi=new THREE.HemisphereLight(0xffffff,0x6a7a55,.8);scene.add(hemi);
const sun=new THREE.DirectionalLight(0xffffff,1);sun.castShadow=true;sun.shadow.mapSize.set(1024,1024);
Object.assign(sun.shadow.camera,{left:-45,right:45,top:45,bottom:-45,near:1,far:220});sun.shadow.bias=-.0006;scene.add(sun,sun.target);
let VW=0,VH=0;
function resize(){VW=cv.clientWidth;VH=cv.clientHeight;R.setSize(VW,VH,false);cam.aspect=VW/Math.max(1,VH);cam.updateProjectionMatrix()}
addEventListener('resize',resize);resize();
const K=10; // map pixels per stud
const town=new THREE.Group(),moonG=new THREE.Group();scene.add(town,moonG);moonG.visible=false;
const MAT=c=>new THREE.MeshStandardMaterial({color:c,roughness:.85});
function mesh(geo,mat,parent,x=0,y=0,z=0){const m=new THREE.Mesh(geo,mat);m.position.set(x,y,z);m.castShadow=true;m.receiveShadow=true;(parent||town).add(m);return m}
const boxG=(w,h,d)=>new THREE.BoxGeometry(w,h,d);
function canvasTex(draw,w=512,h=128){const c=document.createElement('canvas');c.width=w;c.height=h;draw(c.getContext('2d'),w,h);const t=new THREE.CanvasTexture(c);t.encoding=THREE.sRGBEncoding;t.anisotropy=4;return t}
function rrect(g,x,y,w,h,r){g.beginPath();g.moveTo(x+r,y);g.arcTo(x+w,y,x+w,y+h,r);g.arcTo(x+w,y+h,x,y+h,r);g.arcTo(x,y+h,x,y,r);g.arcTo(x,y,x+w,y,r);g.closePath()}
function textTex(text,o={}){return canvasTex((g,w,h)=>{if(o.bg!==null){g.fillStyle=o.bg||'rgba(22,18,32,.92)';rrect(g,4,4,w-8,h-8,o.r??18);g.fill();if(o.border){g.lineWidth=6;g.strokeStyle=o.border;g.stroke()}}
  let size=o.size||64;const f=s=>`700 ${s}px "${o.font||'Fredoka'}", Fredoka, sans-serif`;g.font=f(size);while(g.measureText(text).width>w-36&&size>14){size-=3;g.font=f(size)}
  g.textAlign='center';g.textBaseline='middle';if(o.stroke){g.lineWidth=Math.max(4,size/7);g.strokeStyle=o.stroke;g.lineJoin='round';g.strokeText(text,w/2,h/2+2)}g.fillStyle=o.color||'#fff';g.fillText(text,w/2,h/2+2)},o.w||512,o.h||128)}
function sprite(tex,w,h,parent){const s=new THREE.Sprite(new THREE.SpriteMaterial({map:tex,transparent:true,depthWrite:false}));s.scale.set(w,h,1);(parent||town).add(s);return s}
const emojiTex=e=>canvasTex((g,w,h)=>{g.font='200px serif';g.textAlign='center';g.textBaseline='middle';g.fillText(e,w/2,h/2+10)},256,256);

// ---------------- ground, roads, plaza
const groundMat=MAT('#86d96f'),roadMat=MAT('#ead9be'),walkMat=MAT('#f5ebd7'),dashMat=MAT('#f3efd0'),plazaMat=MAT('#f5ebd7'),stoneMat=MAT('#c9c9c4'),waterMat=new THREE.MeshStandardMaterial({color:'#5aaae6',roughness:.15,metalness:.1,transparent:true,opacity:.92}),statueMat=MAT('#ff96be');
const ground=mesh(new THREE.PlaneGeometry(600,600),groundMat,town,W/2/K,0,H/2/K);ground.rotation.x=-Math.PI/2;ground.castShadow=false;
function flat(x1,y1,x2,y2,mat,h=.04){const m=mesh(boxG((x2-x1)/K,.08,(y2-y1)/K),mat,town,(x1+x2)/2/K,h,(y1+y2)/2/K);m.castShadow=false;return m}
flat(-400,290,W+400,350,roadMat);flat(-400,540,W+400,580,roadMat);flat(PLAZA.x-30,520,PLAZA.x+30,H+300,roadMat);
flat(-400,282,W+400,290,walkMat,.06);flat(-400,350,W+400,358,walkMat,.06);
const dashes=[];for(let x=-380;x<W+380;x+=60)dashes.push(flat(x,318,x+30,321,dashMat,.09));
const plaza=mesh(new THREE.CylinderGeometry((PLAZA.r+30)/K,(PLAZA.r+30)/K,.16,40),plazaMat,town,PLAZA.x/K,.08,PLAZA.y/K);plaza.castShadow=false;
mesh(new THREE.CylinderGeometry(4.4,4.6,1.1,32),stoneMat,town,PLAZA.x/K,.55,PLAZA.y/K);
mesh(new THREE.CylinderGeometry(3.8,3.8,.2,32),waterMat,town,PLAZA.x/K,1.05,PLAZA.y/K).castShadow=false;
mesh(new THREE.CylinderGeometry(.45,.6,3.2,12),stoneMat,town,PLAZA.x/K,2.4,PLAZA.y/K);
const statue=mesh(new THREE.SphereGeometry(1,20,16),statueMat,town,PLAZA.x/K,4.6,PLAZA.y/K);
const drops=[];for(let i=0;i<10;i++){const d=mesh(new THREE.SphereGeometry(.16,8,6),waterMat,town);d.castShadow=false;drops.push(d)}

// ---------------- buildings
const HEIGHT={mall:14,diner:9,supermarket:11,university:18,office:30,lab:13,jobs:10,house1:9,house2:9,park:0,court:15,wall:8,cinema:12,library:12,hospital:16,cafe:9,school:13,house3:9};
const glassMat=new THREE.MeshStandardMaterial({color:'#bfe8ff',roughness:.1,metalness:.3,emissive:'#000000'});
const darkMat=MAT('#3a2a22'),leafMat=MAT('#6fd062'),trunkMat=MAT('#7a5233'),neonMat=new THREE.MeshStandardMaterial({color:'#5adce6',emissive:'#2ab8c8',emissiveIntensity:.9});
const flowerMats=CANDY.map(c=>MAT(c)),potMat=MAT('#5a3f2a'),topiaryMat=MAT('#3f7a3f');
const BLD=[];
for(const b of B){
  const g=new THREE.Group();g.position.set((b.x+b.w/2)/K,0,(b.y+b.h/2)/K);town.add(g);const o={b,g,extras:{}};BLD.push(o);
  if(b.park){
    const lawn=mesh(boxG(b.w/K,.1,b.h/K),MAT('#7cc96a'),g,0,.05,0);lawn.castShadow=false;o.lawn=lawn;
    for(let i=0;i<4;i++)tree3d(g,-5.5+i*3.6,-3+(i%2)*3,1);
    const bench=mesh(boxG(3,.3,1),MAT('#8a5a35'),g,0,.9,3.5);mesh(boxG(3,1,.2),MAT('#8a5a35'),g,0,1.4,4);
    o.pigeons=[];for(let i=0;i<4;i++){const p=mesh(new THREE.SphereGeometry(.32,10,8),MAT('#9a9aa6'),g,-1.5+i,.35,2.2);p.scale.set(1,.85,1.3);o.pigeons.push(p)}
    o.sign=sprite(textTex('PARK'),5,1.25,g);o.sign.position.set(0,2.8,b.h/K/2);continue}
  const w=b.w/K,d=b.h/K,h=HEIGHT[b.id]||10;
  o.wallMat=MAT('#ffffff');o.roofMat=MAT('#ff6e96');o.accMat=MAT('#ff6e96');
  o.body=mesh(boxG(w,h,d),o.wallMat,g,0,h/2,0);
  if(b.id.startsWith('house')){const roof=mesh(new THREE.ConeGeometry(Math.max(w,d)*.78,4,4),o.roofMat,g,0,h+2,0);roof.rotation.y=Math.PI/4;o.roof=roof}
  else{o.roof=mesh(boxG(w+.6,.6,d+.6),o.roofMat,g,0,h+.3,0);mesh(boxG(w-1.2,.5,d-1.2),o.roofMat,g,0,h+.6,0)}
  // windows on the front (+z) face
  const rows=Math.max(1,Math.floor((h-5)/3.2)),cols=Math.max(2,Math.floor(w/3));
  for(let r=0;r<rows;r++)for(let c=0;c<cols;c++){const wx=-w/2+(c+.5)*(w/cols);const wy=4.6+r*3.2;if(Math.abs(wx)<1.6&&r===0)continue;const win=mesh(boxG(Math.min(1.8,w/cols-.8),1.6,.15),glassMat,g,wx,wy,d/2+.05);win.castShadow=false;mesh(boxG(Math.min(1.8,w/cols-.8)+.3,.2,.3),o.wallMat===null?darkMat:MAT('#ffffff'),g,wx,wy-.9,d/2+.1).castShadow=false}
  if(b.p){mesh(boxG(1.8,3,.2),darkMat,g,0,1.5,d/2+.06);o.awning=mesh(boxG(3.6,.3,1.4),o.accMat,g,0,3.4,d/2+.7)}
  o.sign=new THREE.Mesh(new THREE.PlaneGeometry(Math.min(w*.9,14),Math.min(w*.9,14)/4),new THREE.MeshBasicMaterial({transparent:true}));o.sign.position.set(0,Math.min(h-1.6,6.6),d/2+.12);g.add(o.sign);
  o.extras.money=sprite(textTex('$',{w:128,h:128,size:96,bg:'#22c55e',border:'#000',r:28}),1.6,1.6,g);o.extras.money.position.set(w/2-1,h+2.2,d/2-1);
  if(b.p){o.extras.flowers=new THREE.Group();g.add(o.extras.flowers);for(const sx of[-1,1]){const bush=mesh(new THREE.SphereGeometry(.8,10,8),leafMat,o.extras.flowers,sx*(w/2+.9),.6,d/2);for(let k=0;k<4;k++)mesh(new THREE.SphereGeometry(.22,6,6),flowerMats[(k+b.i)%6],o.extras.flowers,sx*(w/2+.9)+Math.cos(k*1.6)*.5,1.1,d/2+Math.sin(k*1.6)*.5)}
    o.extras.planters=new THREE.Group();g.add(o.extras.planters);for(const sx of[-1,1]){mesh(boxG(1,1,1),potMat,o.extras.planters,sx*(w/2+.9),.5,d/2);mesh(new THREE.SphereGeometry(.75,10,8),topiaryMat,o.extras.planters,sx*(w/2+.9),1.6,d/2);mesh(new THREE.CylinderGeometry(.08,.08,4.5,6),darkMat,o.extras.planters,sx*(w/2+2),2.25,d/2+.6);o.extras.lamp=mesh(new THREE.SphereGeometry(.3,8,8),new THREE.MeshStandardMaterial({color:'#ffe1a0',emissive:'#ffcf80',emissiveIntensity:1}),o.extras.planters,sx*(w/2+2),4.6,d/2+.6)}}
  o.extras.neon=mesh(boxG(w+.2,.18,.18),neonMat,g,0,h-.2,d/2+.1);o.extras.neon.castShadow=false;
}
function tree3d(parent,x,z,s=1){mesh(new THREE.CylinderGeometry(.3*s,.4*s,2.6*s,8),trunkMat,parent,x,1.3*s,z);mesh(new THREE.SphereGeometry(1.7*s,12,10),leafMat,parent,x,3.6*s,z);mesh(new THREE.SphereGeometry(1.2*s,10,8),leafMat,parent,x+.9*s,3*s,z+.3)}
[[150,330],[400,520],[700,330],[1180,330],[1180,560],[480,250],[700,250],[1220,250]].forEach(([x,y])=>tree3d(town,x/K,y/K,1.1));
// street lamps
const lampMats=[];[[500,300],[640,300],[480,560],[660,560],[300,300],[860,300]].forEach(([x,y])=>{mesh(new THREE.CylinderGeometry(.1,.14,5,8),MAT('#444'),town,x/K,2.5,y/K);const lm=new THREE.MeshStandardMaterial({color:'#fff2cc',emissive:'#ffe9a8',emissiveIntensity:.6});lampMats.push(lm);mesh(new THREE.SphereGeometry(.35,10,8),lm,town,x/K,5.1,y/K).castShadow=false});
// cash-grab stands next to the plaza
const STANDS=[];[[PLAZA.x-130,PLAZA.y+40,'×999 BOOST','#ff32c8'],[PLAZA.x+130,PLAZA.y+40,'BUY BRAIN','#22c55e']].forEach(([x,y,t,c])=>{const g=new THREE.Group();g.position.set(x/K,0,y/K);town.add(g);const m=MAT(c);mesh(boxG(4,2.2,2),m,g,0,1.1,0);const stripes=[];for(let k=0;k<5;k++){const sm=MAT(k%2?'#ffffff':c);stripes.push(sm);mesh(boxG(.9,.3,2.6),sm,g,-1.8+k*.9,3.2,.2)}for(const sx of[-1.9,1.9])mesh(boxG(.15,1.2,.15),darkMat,g,sx,2.6,1.2);const s=new THREE.Mesh(new THREE.PlaneGeometry(3.6,.9),new THREE.MeshBasicMaterial({transparent:true}));s.position.set(0,1.4,1.02);g.add(s);const money=sprite(textTex('$',{w:128,h:128,size:96,bg:'#22c55e',border:'#000',r:28}),1.4,1.4,g);money.position.y=4.6;STANDS.push({g,m,stripes,s,t,c,money})});
// launch pad (IQ 160+)
const padG=new THREE.Group();padG.position.set(PAD.x/K,0,PAD.y/K);town.add(padG);mesh(boxG(6,.4,6),MAT('#9a9a9a'),padG,0,.2,0);
mesh(new THREE.CylinderGeometry(1,1,7,16),MAT('#f2f2f5'),padG,0,4,0);mesh(new THREE.ConeGeometry(1,2,16),MAT('#dc2828'),padG,0,8.5,0);for(let k=0;k<4;k++){const f=mesh(boxG(.15,1.6,1.2),MAT('#dc2828'),padG,0,1.2,0);f.rotation.y=k*Math.PI/2;f.position.set(Math.sin(k*Math.PI/2)*1.1,1.2,Math.cos(k*Math.PI/2)*1.1)}
const padSign=sprite(textTex('🚀 LAUNCH PAD'),5,1.25,padG);padSign.position.y=11;
// target highlight for the tutorial
const ring=mesh(new THREE.TorusGeometry(2.2,.18,8,32),new THREE.MeshBasicMaterial({color:'#ffe63c'}),town);ring.rotation.x=Math.PI/2;ring.castShadow=false;
const arrowS=sprite(emojiTex('👇'),2.6,2.6,town);

// ---------------- blocky avatars
function avatar(torso,skin='#f2c79a',legs='#2b3a67',parent){const g=new THREE.Group();(parent||town).add(g);const skinM=MAT(skin),torM=MAT(torso),legM=MAT(legs);
  const head=mesh(boxG(1.2,1.2,1.2),skinM,g,0,4.7,0);const face=new THREE.Group();head.add(face);
  mesh(boxG(.16,.26,.05),MAT('#111'),face,-.22,.12,.61);mesh(boxG(.16,.26,.05),MAT('#111'),face,.22,.12,.61);mesh(boxG(.5,.08,.05),MAT('#111'),face,0,-.25,.61);
  mesh(boxG(2,2,1),torM,g,0,3.1,0);
  const mk=(x,y,mat,w)=>{const p=new THREE.Group();p.position.set(x,y,0);g.add(p);mesh(boxG(w,2,w),mat,p,0,-1,0);return p};
  const aL=mk(-1.45,4.05,skinM,.9),aR=mk(1.45,4.05,skinM,.9),lL=mk(-.5,2.1,legM,.95),lR=mk(.5,2.1,legM,.95);
  return{g,head,aL,aR,lL,lR,torM}}
function animate(a,moving,t){const s=moving?Math.sin(t*10)*.7:0;a.aL.rotation.x=s;a.aR.rotation.x=-s;a.lL.rotation.x=-s;a.lR.rotation.x=s}
const ME=avatar('#ffd23c');ME.g.scale.setScalar(1);
const myGlasses=mesh(boxG(1.0,.25,.1),MAT('#a050ff'),ME.head,0,.15,.66);
const animalS=sprite(emojiTex('🐶'),3,3,town);animalS.visible=false;
const tagS=sprite(textTex('YOU'),4,1,town);tagS.visible=false;
const bushS=sprite(emojiTex('🌳'),6,6,town);bushS.visible=false;
const NPC3=npcs.map(n=>({n,a:avatar(n.c,'#f2c79a',['#3a3a55','#5a3a2a','#2b3a67'][Math.floor(Math.random()*3)]),strike:null}));
NPC3.forEach(o=>{o.strike=sprite(textTex('🪧 NO MORE BRAINROT',{size:48}),4.5,1.1,o.a.g);o.strike.position.y=7;o.strike.visible=false});

// ---------------- the Moon
(function(){const M=moonG;const gx=MOON.cx/K,gz=MOON.cy/K;
  const gm=mesh(new THREE.CylinderGeometry(70,70,1,64),MAT('#bdbdc2'),M,gx,-.5,gz+4);gm.castShadow=false;
  [[-14,8,5],[20,14,7],[-4,24,4],[16,-8,3.5],[-24,-6,6]].forEach(([x,z,r])=>{const c=mesh(new THREE.CylinderGeometry(r,r*.8,.3,24),MAT('#9b9ba2'),M,gx+x,.05,gz+z);c.castShadow=false});
  const dome=mesh(new THREE.SphereGeometry(10,32,16,0,Math.PI*2,0,Math.PI/2),new THREE.MeshStandardMaterial({color:'#aadcff',transparent:true,opacity:.35,roughness:.1}),M,gx,0,gz);dome.castShadow=false;
  mesh(new THREE.CylinderGeometry(10,10,.3,32),MAT('#ebeef5'),M,gx,.15,gz);
  const s=sprite(textTex('🔬 SPACE LAB',{color:'#dcf0ff'}),6,1.5,M);s.position.set(gx,11.5,gz);
  for(let i=0;i<3;i++){const p=mesh(new THREE.SphereGeometry(.4,10,8),MAT('#9a9aa6'),M,gx-1+i,.5,gz+3);mesh(new THREE.SphereGeometry(.42,10,8),new THREE.MeshStandardMaterial({color:'#dff',transparent:true,opacity:.4}),M,gx-1+i,.85,gz+2.75)}
  const rx=gx+26,rz=gz+4;mesh(new THREE.CylinderGeometry(1,1,7,16),MAT('#f2f2f5'),M,rx,3.5,rz);mesh(new THREE.ConeGeometry(1,2,16),MAT('#dc2828'),M,rx,8,rz);const rs=sprite(textTex('🌍 ROCKET HOME'),5,1.25,M);rs.position.set(rx,10.5,rz);
  const earth=mesh(new THREE.SphereGeometry(16,32,24),new THREE.MeshStandardMaterial({color:'#3f78dc',emissive:'#10285a',emissiveIntensity:.6}),M,gx-60,40,gz-140);earth.castShadow=false;
  const sp=[];for(let i=0;i<900;i++){const v=new THREE.Vector3().randomDirection?new THREE.Vector3().randomDirection():new THREE.Vector3(Math.random()-.5,Math.random()-.5,Math.random()-.5).normalize();sp.push(v.x*300+gx,Math.abs(v.y)*300,v.z*300+gz)}
  const geo=new THREE.BufferGeometry();geo.setAttribute('position',new THREE.Float32BufferAttribute(sp,3));M.add(new THREE.Points(geo,new THREE.PointsMaterial({color:'#ffffff',size:1.2})))})();

// ---------------- look (town style timeline) applied to the 3D materials
const SKY={cozycash:['#8fd8ff','#fff3e0',1.05,.85],cozy:['#9fdcff','#fff6ea',1,.85],cashgrab:['#45b4ff','#ffffff',1.15,.8],nonsense:['#b7b7ba','#dddddd',.55,.95],realistic:['#9cc6ea','#fffaf0',.95,.7],fancy:['#efb07a','#ffd2a0',1,.6],future:['#4a3a7a','#ffb2c8',.75,.55],moon:['#03030b','#ffffff',1.2,.25]};
let appliedLook=null;
function applyLook(lk){appliedLook=lk;const L=LOOKS[lk];const sk=SKY[lk];
  scene.background=new THREE.Color(sk[0]);scene.fog=lk==='moon'?null:new THREE.Fog(sk[0],lk==='nonsense'?40:90,lk==='nonsense'?120:230);
  sun.color.set(sk[1]);sun.intensity=sk[2];hemi.intensity=sk[3];hemi.color.set(lk==='future'?'#9fb4ff':'#ffffff');
  town.visible=lk!=='moon';moonG.visible=lk==='moon';if(lk==='moon')return;
  groundMat.color.set(L.grass);roadMat.color.set(L.road);dashes.forEach(d=>d.visible=['realistic','fancy','future','cashgrab'].includes(lk));
  plazaMat.color.set(lk==='nonsense'?'#9e9da0':lk.startsWith('cozy')?'#f5ebd7':'#d6d2c8');stoneMat.color.set(lk==='nonsense'?'#8f8e91':lk==='fancy'||lk==='future'?'#ece6da':'#c9c9c4');
  waterMat.color.set(lk==='nonsense'?'#a0a0a3':'#5aaae6');statueMat.color.set(lk.startsWith('cozy')?'#ff96be':lk==='cashgrab'?'#ff32c8':lk==='nonsense'?'#9e9da0':'#e3c7c0');
  leafMat.color.set(lk==='nonsense'?'#b0afb2':lk.startsWith('cozy')?'#6fd062':lk==='fancy'||lk==='future'?'#3f7a3f':'#4f9a3f');
  glassMat.color.set(lk==='future'?'#9ff3ff':lk==='nonsense'?'#b5b5b8':lk==='fancy'?'#ffd99a':'#bfe8ff');glassMat.emissive.set(lk==='fancy'?'#6a4a20':lk==='future'?'#1f6a78':'#000000');
  lampMats.forEach(m=>{m.emissiveIntensity=lk==='fancy'||lk==='future'?1.4:.5;m.emissive.set(lk==='future'?'#7ff0ff':'#ffe9a8')});
  for(const o of BLD){const b=o.b;o.g.rotation.z=L.wobble?Math.sin(b.i*7)*.05:0;o.g.rotation.x=L.wobble?Math.cos(b.i*5)*.03:0;
    if(o.lawn){o.lawn.material.color.set(lk==='nonsense'?'#a8a7aa':'#7cc96a');o.sign.material.map=textTex(degrade(b.n),{font:L.font,color:L.sign,stroke:L.fire?'#000':null});o.sign.material.needsUpdate=true;continue}
    const wall=L.wall(b.i),roof=L.roof(b.i);o.wallMat.color.set(wall);o.roofMat.color.set(roof);o.accMat.color.set(lk==='nonsense'?'#a3a2a5':(L.neon?'#5adce6':CANDY[b.i%6]));
    o.wallMat.roughness=lk==='fancy'||lk==='future'?.45:lk==='nonsense'?.6:.85;o.wallMat.metalness=lk==='future'?.15:0;
    if(b.n){o.sign.material.map=textTex((L.fire?'🔥 ':'')+degrade(b.n)+(L.fire?' 🔥':''),{font:L.font,color:L.sign,stroke:L.fire?'#000':null,bg:lk==='fancy'?'#2b241c':lk==='future'?'#0c1b2a':lk==='nonsense'?'#8f8e91':'rgba(22,18,32,.92)',border:lk==='fancy'?'#c9a45a':lk==='future'?'#5adce6':null});o.sign.material.needsUpdate=true;o.sign.visible=true}else o.sign.visible=false;
    o.extras.money.visible=!!L.money&&b.i%2===0;if(o.extras.flowers)o.extras.flowers.visible=!!L.flowers;if(o.extras.planters)o.extras.planters.visible=!!L.planters;o.extras.neon.visible=!!L.neon}
  for(const st of STANDS){st.g.visible=!!L.stands;const real=lk==='realistic'||lk==='cozy';st.m.color.set(lk==='nonsense'?'#9d9ca0':real?'#9a7a52':st.c);st.stripes.forEach((m,k)=>m.color.set(k%2?'#ffffff':(lk==='nonsense'?'#aaa':real?'#cc4433':st.c)));st.s.material.map=textTex(real?(lk==='cozy'?'Lemonade':'Snacks'):degrade(st.t),{size:56});st.s.material.needsUpdate=true;st.money.visible=!!L.money}
}
if(document.fonts&&document.fonts.ready)document.fonts.ready.then(()=>{appliedLook=null});

// ---------------- input: joystick, jump, camera drag, tap-to-walk, keyboard
const keys={};addEventListener('keydown',e=>{const k=e.key.toLowerCase();keys[k]=1;if((k==='e'||k==='enter')&&!$('enterBtn').classList.contains('hide')&&$('panelWrap').classList.contains('hide'))$('enterBtn').click();if(k===' ')jump()});addEventListener('keyup',e=>keys[e.key.toLowerCase()]=0);
let yaw=0,pitch=.42,dist=17,joy=null,drag=null;
const touch=matchMedia('(pointer:coarse)').matches;if(touch)document.body.classList.add('touch');
cv.addEventListener('pointerdown',e=>{cv.setPointerCapture(e.pointerId);
  if(touch&&e.clientX<VW*.45&&e.clientY>VH*.45&&!joy){joy={id:e.pointerId,x:e.clientX,y:e.clientY,dx:0,dy:0};const base=$('joy');base.style.left=(e.clientX-55)+'px';base.style.top=(e.clientY-55)+'px';base.classList.remove('hide');$('knob').style.transform='translate(0,0)';return}
  drag={id:e.pointerId,x:e.clientX,y:e.clientY,moved:0}});
cv.addEventListener('pointermove',e=>{if(joy&&e.pointerId===joy.id){let dx=e.clientX-joy.x,dy=e.clientY-joy.y;const l=Math.hypot(dx,dy);if(l>45){dx*=45/l;dy*=45/l}joy.dx=dx/45;joy.dy=dy/45;$('knob').style.transform=`translate(${dx}px,${dy}px)`;return}
  if(drag&&e.pointerId===drag.id){const dx=e.clientX-drag.x,dy=e.clientY-drag.y;drag.moved+=Math.abs(dx)+Math.abs(dy);drag.x=e.clientX;drag.y=e.clientY;if(drag.moved>8){yaw-=dx*.008;pitch=Math.max(.15,Math.min(1.2,pitch+dy*.005))}}});
function endPtr(e){if(joy&&e.pointerId===joy.id){joy=null;$('joy').classList.add('hide');return}
  if(drag&&e.pointerId===drag.id){if(drag.moved<=8){const r=cv.getBoundingClientRect();const v=new THREE.Vector2((e.clientX-r.left)/r.width*2-1,-(e.clientY-r.top)/r.height*2+1);const rc=new THREE.Raycaster();rc.setFromCamera(v,cam);const hit=new THREE.Vector3();if(rc.ray.intersectPlane(new THREE.Plane(new THREE.Vector3(0,1,0),0),hit)){P.tx=hit.x*K;P.ty=hit.z*K;snd('tick')}}drag=null}}
cv.addEventListener('pointerup',endPtr);cv.addEventListener('pointercancel',endPtr);
cv.addEventListener('wheel',e=>{dist=Math.max(8,Math.min(34,dist+e.deltaY*.02));e.preventDefault()},{passive:false});
$('jumpBtn').addEventListener('pointerdown',e=>{e.preventDefault();jump()});
let PH=0,PV=0;function jump(){if(PH<=.01&&$('panelWrap').classList.contains('hide')){PV=inMoon?16:24;snd('boing')}}

// ---------------- simulation
function solid(x,y){if(inMoon)return false;for(const b of B)if(!b.park&&x>b.x-6&&x<b.x+b.w+6&&y>b.y-6&&y<b.y+b.h+4)return true;const dx=x-PLAZA.x,dy=y-PLAZA.y;return dx*dx+dy*dy<(46)**2}
let hidingUntil=0,T=0,nearObj=null,moving=false;
function step(dt){
  const busy=!$('panelWrap').classList.contains('hide')||!$('cine').classList.contains('hide')||!$('scene').classList.contains('hide')||!$('doors').classList.contains('hide');
  const st=stageOf(S.cells);let sp=170*(st.k==='worm'?.45:st.k==='fly'||st.k==='bee'?1.3:1);
  if(frozen()||Date.now()<hidingUntil||busy)sp=0;
  let ix=0,iz=0;if(keys.w||keys.arrowup)iz--;if(keys.s||keys.arrowdown)iz++;if(keys.a||keys.arrowleft)ix--;if(keys.d||keys.arrowright)ix++;
  if(joy){ix=joy.dx;iz=joy.dy}
  let vx=0,vy=0;
  if(Math.hypot(ix,iz)>.12){P.tx=null;const fx=-Math.sin(yaw),fz=-Math.cos(yaw),rx=Math.cos(yaw),rz=-Math.sin(yaw);vx=rx*ix+fx*(-iz);vy=rz*ix+fz*(-iz)}
  else if(P.tx!=null){const dx=P.tx-P.x,dy=P.ty-P.y,d=Math.hypot(dx,dy);if(d<4)P.tx=null;else{vx=dx/d;vy=dy/d}}
  const l=Math.hypot(vx,vy);moving=l>.05&&sp>0;if(l>1){vx/=l;vy/=l}
  const nx=P.x+vx*sp*dt,ny=P.y+vy*sp*dt;
  if(!solid(nx,P.y))P.x=Math.max(10,Math.min(W-10,nx));else P.tx=null;
  if(!solid(P.x,ny))P.y=Math.max(10,Math.min(H-10,ny));else P.tx=null;
  if(moving)P.face=Math.atan2(vx,vy);S.x=P.x;S.y=P.y;
  PV-=(inMoon?14:80)*dt;PH=Math.max(0,PH+PV*dt);if(PH===0)PV=Math.max(0,PV);
  for(const n of npcs){n.t-=dt;if(n.t<=0){n.tx=150+Math.random()*900;n.ty=290+Math.random()*270;n.t=4+Math.random()*6}const dx=n.tx-n.x,dy=n.ty-n.y,d=Math.hypot(dx,dy);n.mv=d>3;if(d>3){const mx=n.x+dx/d*50*dt,my=n.y+dy/d*50*dt;if(!solid(mx,my)){n.x=mx;n.y=my;n.f=Math.atan2(dx,dy)}else n.t=0}}
  let near=null;if(!busy&&!S.dead&&S.path){if(inMoon){if(Math.hypot(P.x-MOON.cx,P.y-(MOON.cy+110))<60)near={id:'spacelab',n:'SPACE LAB',px:MOON.cx,py:MOON.cy+100};if(Math.hypot(P.x-(MOON.cx+260),P.y-(MOON.cy+40))<60)near={id:'rocketHome',n:'ROCKET HOME',px:MOON.cx+260,py:MOON.cy+40}}
    else{for(const b of B)if(b.p&&Math.hypot(P.x-b.door.x,P.y-b.door.y)<50)near=b;if(iqOf(S.cells)>=160&&S.path==='Gain'&&Math.hypot(P.x-PAD.x,P.y-(PAD.y+40))<50)near={id:'pad',n:'LAUNCH PAD',px:PAD.x,py:PAD.y+30}}}
  nearObj=near;const eb=$('enterBtn');
  if(near){eb.classList.remove('hide');const action=near.id==='pad'?'Launch':near.id==='rocketHome'?'Fly home':'Enter';const obj=near.id==='pad'?'🚀 Rocket':near.n.charAt(0)+near.n.slice(1).toLowerCase();
    if(eb.dataset.k!==near.id){eb.dataset.k=near.id;eb.innerHTML=`<span class="key">${touch?'👆':'E'}</span><span class="pt"><small>${esc(obj)}</small><b>${action}</b></span>`;eb.onclick=()=>enter(near)}}
  else{eb.classList.add('hide');eb.dataset.k=''}
}
function draw(){
  const lk=inMoon?'moon':look();if(lk!==appliedLook)applyLook(lk);
  const px=P.x/K,pz=P.y/K;
  // player
  const st=stageOf(S.cells);const human=st.k==='human'||st.k==='barely';const hiding=Date.now()<hidingUntil;
  ME.g.visible=human&&!hiding;ME.g.position.set(px,PH,pz);ME.g.rotation.y=P.face||0;animate(ME,moving&&PH===0,T);
  ME.torM.color.set(S.path==='Lose'?'#ff4f9a':S.path==='Gain'?'#3a7bff':'#ffd23c');
  const gl=S.path==='Gain'&&iqOf(S.cells)>=70;myGlasses.visible=gl;if(gl)myGlasses.material.color.set(iqOf(S.cells)>=145?'#c8d2dc':iqOf(S.cells)>=100?'#3a2a20':'#a050ff');
  const hs=S.path==='Gain'&&S.cells>OVER?Math.min(3,1+Math.log10(S.cells/OVER)*2):1;ME.head.scale.setScalar(hs);ME.head.position.y=4.7+(hs-1)*.6;
  animalS.visible=!human&&!hiding&&st.k!=='dead'||st.k==='dead';
  if(animalS.visible){if(animalS.userData.e!==st.e){animalS.userData.e=st.e;animalS.material.map=emojiTex(st.e);animalS.material.needsUpdate=true}const s=1.4+3.2*st.s;animalS.scale.set(s,s,1);const bob=(st.k==='fly'||st.k==='bee')?2.5+Math.sin(T*10)*.4:0;animalS.position.set(px,PH+s/2+bob,pz)}
  tagS.visible=!human&&st.k!=='dead'&&!hiding;if(tagS.visible){if(tagS.userData.n!==st.n){tagS.userData.n=st.n;tagS.material.map=textTex('YOU ('+st.n+')',{size:52});tagS.material.needsUpdate=true}tagS.position.set(px,PH+(1.4+3.2*st.s)+3.4,pz)}
  bushS.visible=hiding;bushS.position.set(px,3,pz);
  // npcs
  NPC3.forEach(o=>{o.a.g.position.set(o.n.x/K,0,o.n.y/K);if(o.n.f!=null)o.a.g.rotation.y=o.n.f;animate(o.a,o.n.mv,T+o.n.c.length);o.strike.visible=Date.now()<npcStrike});
  // fountain
  drops.forEach((d,i)=>{const a=i/drops.length*Math.PI*2+T*.6,t=(T*1.4+i*.37)%1;d.position.set(PLAZA.x/K+Math.cos(a)*(.6+2.6*t),3.2+4*t*(1-t)*2.2-1.4*t,PLAZA.y/K+Math.sin(a)*(.6+2.6*t))});
  // pigeons peck
  BLD.forEach(o=>o.pigeons&&o.pigeons.forEach((p,i)=>p.rotation.x=Math.sin(T*6+i)*.3));
  // launch pad + tutorial target
  padG.visible=!inMoon&&S.path==='Gain'&&iqOf(S.cells)>=160;
  const hb=hintBuilding();const tb=hb&&B.find(b=>b.id===hb);ring.visible=!!tb&&!inMoon;arrowS.visible=ring.visible;
  if(tb){ring.position.set(tb.door.x/K,.25,tb.door.y/K+1.2);ring.scale.setScalar(1+Math.sin(T*6)*.12);arrowS.position.set(tb.door.x/K,(HEIGHT[tb.id]||10)+4+Math.sin(T*6)*.8,tb.door.y/K)}
  // camera
  if(Date.now()<spinUntil)yaw+=.05;
  const tx=px,ty=PH+3.2,tz=pz;const cdist=dist;cam.position.set(tx+Math.sin(yaw)*Math.cos(pitch)*cdist,ty+Math.sin(pitch)*cdist,tz+Math.cos(yaw)*Math.cos(pitch)*cdist);cam.lookAt(tx,ty,tz);
  sun.position.set(px+(appliedLook==='fancy'||appliedLook==='future'?-40:-25),appliedLook==='fancy'||appliedLook==='future'?22:50,pz+20);sun.target.position.set(px,0,pz);
  R.render(scene,cam);
  // prompt follows the door on screen
  const eb=$('enterBtn');if(nearObj&&!eb.classList.contains('hide')){const n=nearObj;const wx=(n.door?n.door.x:n.px)/K,wz=(n.door?n.door.y:n.py)/K;const v=new THREE.Vector3(wx,4.2,wz+.5).project(cam);const sx=(v.x+1)/2*VW,sy=(1-v.y)/2*VH;eb.style.left=Math.max(80,Math.min(VW-80,sx))+'px';eb.style.top=Math.max(110,Math.min(VH-170,sy))+'px'}
  // animal vision + weather overlays
  const vis=$('vision');vis.className=st.k==='fly'?'v-fly':st.k==='worm'?'v-worm':st.k==='bee'?'v-bee':'';cv.style.filter=st.k==='dog'?'saturate(.35) sepia(.35) hue-rotate(-10deg)':'';
  if((Date.now()<rainUntil||Date.now()<duckUntil)&&Math.random()<.35){const d=document.createElement('div');d.className='drop';d.textContent=Date.now()<duckUntil&&(Date.now()>=rainUntil||Math.random()<.5)?'🦆':'🧠';d.style.left=Math.random()*100+'%';$('app').appendChild(d);setTimeout(()=>d.remove(),2200)}
}
let lastT=performance.now();function loop(t){const dt=Math.min(.05,(t-lastT)/1000);lastT=t;T+=dt;step(dt);draw();requestAnimationFrame(loop)}requestAnimationFrame(loop);

