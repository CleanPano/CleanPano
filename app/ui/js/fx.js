/* partículas, halo do mascote (three.js) */
import * as THREE from '../vendor/three.module.min.js';
const DPR=Math.min(devicePixelRatio||1,2);
const hex=c=>{c=c.replace('#','');return[parseInt(c.slice(0,2),16)/255,parseInt(c.slice(2,4),16)/255,parseInt(c.slice(4,6),16)/255]};

const cv=document.getElementById('fx');
const R=new THREE.WebGLRenderer({canvas:cv,alpha:true,antialias:false});
R.setPixelRatio(DPR);R.setClearColor(0x000000,0);
const sc=new THREE.Scene();let cam;
function rs(){R.setSize(innerWidth,innerHeight,false);cam=new THREE.OrthographicCamera(0,innerWidth,0,-innerHeight,-10,10)}
rs();addEventListener('resize',rs);

const N=1200,P=new Float32Array(N*3),C=new Float32Array(N*3),Z=new Float32Array(N),A=new Float32Array(N),V=new Float32Array(N*2),L=new Float32Array(N),M=new Float32Array(N).fill(1),G=new Float32Array(N);
let head=0,alive=0;
const g=new THREE.BufferGeometry();
const at={position:new THREE.BufferAttribute(P,3),pcolor:new THREE.BufferAttribute(C,3),psize:new THREE.BufferAttribute(Z,1),palpha:new THREE.BufferAttribute(A,1)};
for(const k in at){at[k].setUsage(THREE.DynamicDrawUsage);g.setAttribute(k,at[k])}
const mat=new THREE.ShaderMaterial({uniforms:{dpr:{value:DPR}},transparent:true,depthTest:false,depthWrite:false,
 vertexShader:`attribute vec3 pcolor;attribute float psize;attribute float palpha;uniform float dpr;varying vec3 vc;varying float va;
 void main(){vc=pcolor;va=palpha;gl_PointSize=psize*dpr;gl_Position=projectionMatrix*modelViewMatrix*vec4(position,1.0);}`,
 fragmentShader:`varying vec3 vc;varying float va;
 void main(){vec2 c=gl_PointCoord-.5;float d=length(c);if(d>.5)discard;float a=smoothstep(.5,.12,d)*va;gl_FragColor=vec4(vc*a,a);}`,
 blending:THREE.CustomBlending,blendSrc:THREE.OneFactor,blendDst:THREE.OneMinusSrcAlphaFactor});
const pts=new THREE.Points(g,mat);pts.frustumCulled=false;sc.add(pts);
const zf=()=>window.__zoom||1;

function emit(x,y,vx,vy,c,s,life,grav=260){if(document.documentElement.classList.contains('dark')){if(c==='#3DDC6B')c='#ff5900';else if(c==='#111412')c='#F2F4F7'}const i=head;head=(head+1)%N;const z=zf();P[i*3]=x;P[i*3+1]=-y;P[i*3+2]=0;V[i*2]=vx*z;V[i*2+1]=-vy*z;const k=hex(c);C[i*3]=k[0];C[i*3+1]=k[1];C[i*3+2]=k[2];Z[i]=s*z;L[i]=M[i]=life;G[i]=grav*z}
function burst(x,y,cols=['#3DDC6B','#F5C542'],n=40,pw=1){for(let k=0;k<n;k++){const a=Math.random()*Math.PI*2,v=(120+Math.random()*320)*pw;emit(x,y,Math.cos(a)*v,Math.sin(a)*v-60,cols[k%cols.length],5+Math.random()*8,.6+Math.random()*.7)}}
function burstEl(el,cols){const r=el.getBoundingClientRect();burst(r.left+r.width/2,r.top+r.height/2,cols||['#3DDC6B','#F5C542'],22,.6)}
function outline(el,c='#3DDC6B',n=26){const r=el.getBoundingClientRect(),per=2*(r.width+r.height);
 for(let k=0;k<n;k++){let t=Math.random()*per,x,y,nx=0,ny=0;
  if(t<r.width){x=r.left+t;y=r.top;ny=-1}else if((t-=r.width)<r.height){x=r.right;y=r.top+t;nx=1}else if((t-=r.height)<r.width){x=r.right-t;y=r.bottom;ny=1}else{t-=r.width;x=r.left;y=r.bottom-t;nx=-1}
  const v=25+Math.random()*60;emit(x,y,nx*v+(Math.random()-.5)*20,ny*v+(Math.random()-.5)*20,Math.random()<.3?'#F5C542':c,3+Math.random()*4,.5+Math.random()*.5,40)}}

let lastS=0,hov=null;
addEventListener('pointermove',e=>{
  const el=e.target.closest?e.target.closest('[data-fx]'):null;
  if(!el){hov=null;return}
  if(el.matches('[data-task]')&&document.body.classList.contains('busy'))return;
  const t=performance.now(),c=el.dataset.fx||'#3DDC6B';
  if(t-lastS>30){lastS=t;for(let k=0;k<2;k++)emit(e.clientX,e.clientY,(Math.random()-.5)*90,-20-Math.random()*70,Math.random()<.25?'#F5C542':c,3+Math.random()*4,.45+Math.random()*.4,180)}
  if(hov!==el){hov=el;outline(el,c,el.classList.contains('tile')?34:el.classList.contains('xl')?44:18)}
});
addEventListener('pointerdown',e=>{const el=e.target.closest?e.target.closest('[data-fx]'):null;if(el)burst(e.clientX,e.clientY,[el.dataset.fx||'#3DDC6B','#3DDC6B','#F5C542'],38)});

const oc=document.getElementById('orb');
const OR=new THREE.WebGLRenderer({canvas:oc,alpha:true,antialias:true});
OR.setClearColor(0x000000,0);
function ors(){OR.setPixelRatio(DPR*Math.max(1,zf()));OR.setSize(250,250,false)}ors();addEventListener('resize',()=>setTimeout(ors,50));
const os=new THREE.Scene(),ocam=new THREE.PerspectiveCamera(35,1,.1,50);ocam.position.z=5.6;
os.add(new THREE.HemisphereLight(0xffffff,0x1a2a20,1.5));
const dl=new THREE.DirectionalLight(0xffffff,2.6);dl.position.set(2,3,4);os.add(dl);
const rim=new THREE.PointLight(0x3ddc6b,18,12);rim.position.set(-3,-2,2);os.add(rim);
const grp=new THREE.Group();os.add(grp);
const core=new THREE.Mesh(new THREE.IcosahedronGeometry(1,1),new THREE.MeshStandardMaterial({color:0x3ddc6b,flatShading:true,roughness:.3,metalness:.1,emissive:0x0b3a1a,emissiveIntensity:.6}));grp.add(core);core.visible=false;
const wire=new THREE.LineSegments(new THREE.EdgesGeometry(new THREE.IcosahedronGeometry(1.3,1)),new THREE.LineBasicMaterial({color:0xffffff,transparent:true,opacity:.18}));grp.add(wire);wire.visible=false;
const rn=200,rp=new Float32Array(rn*3);
for(let i=0;i<rn;i++){const a=i/rn*Math.PI*2,r=1.65+Math.random()*.12;rp[i*3]=Math.cos(a)*r;rp[i*3+1]=Math.sin(a)*r;rp[i*3+2]=(Math.random()-.5)*.12}
const rg=new THREE.BufferGeometry();rg.setAttribute('position',new THREE.BufferAttribute(rp,3));
const ring=new THREE.Points(rg,new THREE.PointsMaterial({color:0xebb931,size:.05}));ring.rotation.x=1.15;grp.add(ring);
let lastScore=100,target=new THREE.Color(0x3ddc6b),busy=false,pulse=0,mx=0,my=0,hoverOrb=0;
addEventListener('pointermove',e=>{mx=e.clientX/innerWidth-.5;my=e.clientY/innerHeight-.5});
oc.addEventListener('pointerenter',()=>hoverOrb=1);oc.addEventListener('pointerleave',()=>hoverOrb=0);

let last=performance.now(),ho=0;
function loop(t){
  const dt=Math.min(.05,(t-last)/1000);last=t;let n=0;
  for(let i=0;i<N;i++){
    if(L[i]>0){L[i]-=dt;A[i]=Math.max(L[i]/M[i],0);V[i*2]*=.965;V[i*2+1]=V[i*2+1]*.965-G[i]*dt;P[i*3]+=V[i*2]*dt;P[i*3+1]+=V[i*2+1]*dt;n++}
    else if(A[i])A[i]=0;
  }
  if(n||alive){for(const k in at)at[k].needsUpdate=true;R.render(sc,cam)}
  alive=n;
  if(oc.offsetParent){
    ho+=(hoverOrb-ho)*.1;
    const sp=busy?3:(.5+ho*1.5);
    core.rotation.y+=dt*sp;core.rotation.x+=dt*sp*.4;wire.rotation.y-=dt*sp*.6;wire.rotation.z+=dt*sp*.2;ring.rotation.z+=dt*(busy?2:.35+ho);
    grp.rotation.x+=(my*.7-grp.rotation.x)*.05;grp.rotation.y+=(mx*.9-grp.rotation.y)*.05;
    core.material.color.lerp(target,.05);
    pulse=Math.max(0,pulse-dt*1.4);
    core.scale.setScalar(1+ho*.08+Math.sin(pulse*Math.PI)*.25+(busy?Math.sin(t/160)*.05:0));
    OR.render(os,ocam);
  }
  requestAnimationFrame(loop);
}
requestAnimationFrame(loop);

window.FX={
  orb(score,b){busy=!!b;lastScore=score;const dk=document.documentElement.classList.contains('dark');target=new THREE.Color(score>=80?(dk?0xff5900:0x3ddc6b):score>=60?0xf5c542:0xf87171)},
  theme(){const dk=document.documentElement.classList.contains('dark');rim.color.set(dk?0xff5900:0x3ddc6b);core.material.emissive.set(dk?0x3a1400:0x0b3a1a);this.orb(lastScore,busy)},
  celebrate(big){pulse=1;const r=oc.offsetParent?oc.getBoundingClientRect():document.getElementById('sn').getBoundingClientRect();
    const x=r.left+r.width/2,y=r.top+r.height/2;burst(x,y,['#3DDC6B','#F5C542','#FFFFFF','#111412'],big?140:46,big?1.6:1)},
  burst,burstEl,outline
};

if(document.documentElement.classList.contains('dark'))window.FX.theme();
