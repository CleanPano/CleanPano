/* ============================================================
   PANO SHELL · base reutilizável da janela
   - helpers ($, arr, esc, store)
   - zoom automático: tudo cabe na janela, sem barra de rolagem
   - janela própria (WebView2): arrastar, minimizar/maximizar/fechar,
     opacidade, elementos sólidos (fora da transparência)
   Configuração em window.APP (definido no index.html):
     id (prefixo do localStorage), baseW/baseH (tamanho de desenho),
     solid (seletores que ficam 100% opacos)
   Requer: i18n.js (função t) carregado antes.
   ============================================================ */
const $=s=>document.querySelector(s);
const arr=x=>x==null?[]:Array.isArray(x)?x:[x];
const esc=s=>String(s??'').replace(/[&<>"]/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;'}[c]));
const store={get(k,d){try{const v=localStorage.getItem(APP.id+'_'+k);return v==null?d:JSON.parse(v)}catch(e){return d}},set(k,v){try{localStorage.setItem(APP.id+'_'+k,JSON.stringify(v))}catch(e){}}};

function magnet(el){
  if(!el||el._mg)return;el._mg=1;
  el.addEventListener('pointermove',e=>{const r=el.getBoundingClientRect();el.style.transform=`translate(${(e.clientX-r.left-r.width/2)*.1}px,${(e.clientY-r.top-r.height/2)*.22}px)`});
  el.addEventListener('pointerleave',()=>el.style.transform='');
}

const BASE=APP.baseW||1440,BASEH=APP.baseH||900;
function fit(){
  const z=Math.max(.5,Math.min(1.7,innerWidth/BASE,innerHeight/BASEH)),app=$('#app');
  app.style.zoom=z;app.style.width=(innerWidth/z)+'px';app.style.height=(innerHeight/z)+'px';
  const so=$('#solid');if(so)so.style.zoom=z;
  document.querySelectorAll('.dlg').forEach(d=>d.style.zoom=Math.min(z,innerHeight/(d.classList.contains('tbl')?800:400)));
  window.__zoom=z;
  if(window.syncSolid)requestAnimationFrame(syncSolid);
}
addEventListener('resize',fit);fit();

addEventListener('beforeunload',()=>navigator.sendBeacon('/api/quit'));

/* ---------- janela própria (WebView2) ---------- */
(()=>{
  const wv=window.chrome&&chrome.webview;if(!wv)return;
  const R=document.documentElement;R.classList.add('hosted');
  const H=m=>{try{wv.postMessage(m)}catch(e){}};
  const setMax=v=>{R.classList.toggle('maxed',v);const b=$('#wcMax');if(b){b.title=t(v?'wc_rest':'wc_max');b.innerHTML=v?'<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linejoin="round"><rect x="5" y="8" width="11" height="11" rx="2"/><path d="M9 8V6a1 1 0 0 1 1-1h8a1 1 0 0 1 1 1v8a1 1 0 0 1-1 1h-2"/></svg>':'<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linejoin="round"><rect x="6" y="6" width="12" height="12" rx="2"/></svg>'}};
  setMax(!!(window.cpHost&&cpHost.max));
  wv.addEventListener('message',e=>{const d=String(e.data||'');if(d.startsWith('max:'))setMax(d==='max:1')});
  document.querySelectorAll('#wc button').forEach(b=>{b.title=t(b.dataset.tt);b.onclick=()=>H(b.dataset.w)});
  $('#opq').title=t('win_op');
  document.addEventListener('mousedown',e=>{
    if(e.button!==0)return;
    const z=e.target.closest('.top,.head,.crumb');if(!z)return;
    if(e.target.closest('button,a,input,select,textarea,label,.lang,.tabs,.wc,.dlg'))return;
    e.preventDefault();
    if(e.detail>=2){H('max');return}
    H('drag');
  });
  const op=$('#winOp'),ov=$('#winOpV');
  const apply=v=>{v=Math.max(50,Math.min(100,+v||98));R.style.setProperty('--op',v/100);if(op)op.value=v;if(ov)ov.textContent=v+'%';return v};
  apply(window.cpHost&&cpHost.op?cpHost.op:98);
  if(op)op.oninput=()=>H('op:'+apply(op.value));

  /* logo, mascote e botão principal ficam fora da transparência */
  const so=document.createElement('div');so.id='solid';document.body.appendChild(so);so.style.zoom=window.__zoom||1;
  const items=[];
  (APP.solid||[]).forEach(sel=>{
    const el=document.querySelector(sel);if(!el)return;
    const ph=document.createElement(el.tagName==='BUTTON'?'span':'div');ph.className='ph';
    ph.style.display=getComputedStyle(el).display==='inline-flex'?'inline-block':'block';ph.style.flex='none';
    el.parentNode.insertBefore(ph,el);so.appendChild(el);items.push([el,ph]);
  });
  window.syncSolid=()=>{
    const z=window.__zoom||1;
    items.forEach(([el,ph])=>{
      ph.style.width=el.offsetWidth+'px';ph.style.height=el.offsetHeight+'px';
      const r=ph.getBoundingClientRect(),vis=ph.getClientRects().length>0&&r.width>0;
      el.style.visibility=vis?'':'hidden';
      if(vis){el.style.left=(r.left/z)+'px';el.style.top=(r.top/z)+'px'}
    });
  };
  const ro=new ResizeObserver(()=>requestAnimationFrame(syncSolid));items.forEach(([el])=>ro.observe(el));ro.observe($('#app'));
  setInterval(syncSolid,400);syncSolid();
  H('state');
})();

/* ---------- tema claro / escuro (botão ao lado da opacidade) ---------- */
(()=>{
  const R=document.documentElement,K=APP.id+'_theme';
  const apply=d=>{R.classList.toggle('dark',d);document.dispatchEvent(new CustomEvent('themechange',{detail:d}))};
  let d=false;try{d=localStorage.getItem(K)==='dark'}catch(e){}
  apply(d);
  window.isDark=()=>R.classList.contains('dark');
  window.addEventListener('DOMContentLoaded',()=>{});
  const b=document.getElementById('thm');
  if(b){b.title=t('theme');b.onclick=()=>{const n=!isDark();apply(n);try{localStorage.setItem(K,n?'dark':'light')}catch(e){}}}
})();
