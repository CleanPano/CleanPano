/* args das flags: string 'a|b' (motor) ou array antigo */
const hfa=a=>Array.isArray(a)?a.flatMap(x=>String(x).split(' ')):a==null||a===''?[]:String(a).split('|');
/* ============================================================
   CleanPano · lógica da interface (páginas, tarefas, painéis)
   ============================================================ */
/* ================= util ================= */
const ICON={
ram:'<rect x="2" y="7" width="20" height="10" rx="1.5"/><path d="M6 7V5M10 7V5M14 7V5M18 7V5M6 17v2M18 17v2M6 11h2M11 11h2M16 11h2"/>',
gpu:'<rect x="2" y="6" width="20" height="12" rx="2"/><circle cx="9" cy="12" r="3"/><path d="M15 10h3M15 14h3M5 18v2M19 18v2"/>',
disk:'<rect x="3" y="4" width="18" height="16" rx="2"/><circle cx="12" cy="11" r="4"/><path d="M12 11l2.5 4M7 17h.01"/>',
board:'<rect x="3" y="3" width="18" height="18" rx="2"/><rect x="7" y="7" width="5" height="5"/><path d="M15 7h2M15 10h2M7 15h10M7 18h4"/>',
monitor:'<rect x="2" y="3" width="20" height="14" rx="2"/><path d="M8 21h8M12 17v4"/>',
audio:'<path d="M11 5L6 9H2v6h4l5 4z"/><path d="M15.5 8.5a5 5 0 0 1 0 7M19 5a10 10 0 0 1 0 14"/>',
sparkles:'<path d="M12 3l1.9 5.1L19 10l-5.1 1.9L12 17l-1.9-5.1L5 10l5.1-1.9z"/><path d="M19 15l.9 2.1L22 18l-2.1.9L19 21l-.9-2.1L16 18l2.1-.9z"/>',
home:'<path d="M3 10.5L12 3l9 7.5V20a1 1 0 0 1-1 1h-5v-6H9v6H4a1 1 0 0 1-1-1z"/>',
broom:'<path d="M19 3l-7.5 7.5"/><path d="M9.5 9.5l5 5-2.5 2.5c-2 2-5.5 3-8.5 3 0-3 1-6.5 3-8.5z"/><path d="M6 15l2 2"/>',
wifi:'<path d="M5 12.55a11 11 0 0 1 14.08 0"/><path d="M1.42 9a16 16 0 0 1 21.16 0"/><path d="M8.53 16.11a6 6 0 0 1 6.95 0"/><circle cx="12" cy="20" r="1"/>',
cpu:'<rect x="4" y="4" width="16" height="16" rx="2"/><rect x="9" y="9" width="6" height="6"/><path d="M9 1v3M15 1v3M9 20v3M15 20v3M20 9h3M20 14h3M1 9h3M1 14h3"/>',
shield:'<path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z"/>',
folder:'<path d="M22 19a2 2 0 0 1-2 2H4a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h5l2 3h9a2 2 0 0 1 2 2z"/>',
refresh:'<path d="M23 4v6h-6"/><path d="M20.49 15A9 9 0 1 1 18.36 5.64L23 10"/>',
zap:'<path d="M13 2L3 14h9l-1 8 10-12h-9l1-8z"/>',
list:'<path d="M8 6h13M8 12h13M8 18h13M3 6h.01M3 12h.01M3 18h.01"/>',
external:'<path d="M18 13v6a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V8a2 2 0 0 1 2-2h6"/><path d="M15 3h6v6M10 14L21 3"/>',
scale:'<path d="M12 3v18M5 21h14M5 7h14M7 7l-3 7a3 3 0 0 0 6 0zM17 7l-3 7a3 3 0 0 0 6 0z"/>',
activity:'<path d="M22 12h-4l-3 9L9 3l-3 9H2"/>',
search:'<circle cx="11" cy="11" r="8"/><path d="M21 21l-4.35-4.35"/>',
download:'<path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4"/><path d="M7 10l5 5 5-5M12 15V3"/>',
alert:'<path d="M10.29 3.86L1.82 18a2 2 0 0 0 1.71 3h16.94a2 2 0 0 0 1.71-3L13.71 3.86a2 2 0 0 0-3.42 0z"/><path d="M12 9v4M12 17h.01"/>',
restore:'<path d="M3 12a9 9 0 1 0 3-6.7L3 8"/><path d="M3 3v5h5"/><path d="M12 7v5l3 2"/>',
globe:'<circle cx="12" cy="12" r="10"/><path d="M2 12h20M12 2a15 15 0 0 1 0 20M12 2a15 15 0 0 0 0 20"/>',
trash:'<path d="M3 6h18M8 6V4h8v2M19 6l-1 14H6L5 6"/>',
package:'<path d="M21 16V8l-9-5-9 5v8l9 5 9-5z"/><path d="M3.3 7L12 12l8.7-5M12 22V12"/>',
grid:'<rect x="3" y="3" width="7" height="7" rx="1.5"/><rect x="14" y="3" width="7" height="7" rx="1.5"/><rect x="3" y="14" width="7" height="7" rx="1.5"/><rect x="14" y="14" width="7" height="7" rx="1.5"/>',
arrow:'<path d="M7 17L17 7M8 7h9v9"/>',check:'<path d="M20 6L9 17l-5-5"/>',x:'<path d="M18 6L6 18M6 6l12 12"/>',minus:'<path d="M5 12h14"/>',
cloud:'<path d="M18 10h-1.26A8 8 0 1 0 9 20h9a5 5 0 0 0 0-10z"/>',
wrench:'<path d="M14.7 6.3a1 1 0 0 0 0 1.4l1.6 1.6a1 1 0 0 0 1.4 0l3.77-3.77a6 6 0 0 1-7.94 7.94l-6.91 6.91a2.12 2.12 0 0 1-3-3l6.91-6.91a6 6 0 0 1 7.94-7.94l-3.76 3.76z"/>'
};
const svg=(n,c='')=>`<svg class="${c}" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round">${ICON[n]||''}</svg>`;
const fmt=b=>{b=+b||0;return b>=1073741824?(b/1073741824).toFixed(2)+' GB':(b/1048576).toFixed(1)+' MB'};
const hhmm=d=>new Date(d).toLocaleTimeString(LOC(),{hour:'2-digit',minute:'2-digit'});
const fx=(m,...a)=>{try{window.FX&&window.FX[m](...a)}catch(e){}};
const setText=(el,s)=>{if(!el)return;const n=[...el.childNodes].reverse().find(x=>x.nodeType===3);if(n)n.textContent=' '+s;else el.append(' '+s)};

const S={autostart:false,busy:false,runAt:0,task:'',info:null,scan:null,scanAt:null,freed:0,startup:null,ping:null,speed:null,drivers:null,bad:null,wu:null,wuType:'Driver',page:'home',sel:{},first:null,score:null,
  steps:null,optRunning:false,hw:store.get('hw',null),opts:(()=>{const o=Object.assign({restore:true,gpu:true,dism:true,drivers:true,winget:true,close:false,usewu:false},store.get('opts',{}));if(store.get('optsv',0)<3){o.winget=true;o.gpu=true;store.set('optsv',3);store.set('opts',o)}return o})(),last:store.get('last',null)};

async function api(p,b){const r=await fetch(p,b?{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify(b)}:{cache:'no-store'});return r.json()}
const openW=w=>api('/api/open?w='+w);
async function power(m){await api('/api/power?m='+m);loadInfo()}
function markRun(el){document.querySelectorAll('.tile.run').forEach(x=>x.classList.remove('run'));if(el&&el.classList&&el.classList.contains('tile'))el.classList.add('run')}
async function run(task,vars={},el){
  if(S.busy)return false;
  S.busy=true;S.runAt=Date.now();document.body.classList.add('busy');markRun(el);
  const r=await api('/api/run',{task,vars}).catch(()=>({ok:false}));
  if(!r.ok){S.busy=false;document.body.classList.remove('busy');markRun(null)}
  return r.ok;
}
async function confirmRun(task,q,m,vars,el){if(await ask(t(q),t(m)))run(task,vars,el)}

/* ================= idioma ================= */
function buildLang(){
  $('#lflag').innerHTML=FLAG[LANG];$('#lcode').textContent=LANGS.find(l=>l[0]===LANG)[2];
  $('#lmenu').innerHTML=LANGS.map(([k,n])=>`<button class="lopt${k===LANG?' on':''}" data-l="${k}"><span class="flag">${FLAG[k]}</span>${n}${k===LANG?svg('check','lchk'):''}</button>`).join('');
  $('#lmenu').querySelectorAll('.lopt').forEach(b=>b.onclick=e=>{e.stopPropagation();setLang(b.dataset.l)});
}
function setLang(l){
  document.querySelectorAll('#wc button').forEach(b=>b.title=t(b.dataset.w==='max'&&document.documentElement.classList.contains('maxed')?'wc_rest':b.dataset.tt));
  LANG=l;try{localStorage.setItem('cp_lang',l)}catch(e){}
  document.documentElement.lang=LOC();$('#lang').classList.remove('open');syncSettings();
  buildLang();applyStatic();$('#facs').innerHTML='';
  nav();renderPage();setBusy(S.busy,S.task);
  const L=$('#log');if(L.querySelector('.empty'))L.innerHTML=`<div class="empty">${t('no_activity')}</div>`;
  fx('burstEl',$('#lbtn'));
}
function applyStatic(){
  document.querySelectorAll('[data-t]').forEach(e=>{if(e.querySelector('svg'))setText(e,t(e.dataset.t));else e.textContent=t(e.dataset.t)});
  document.querySelectorAll('[data-tt]').forEach(e=>e.title=t(e.dataset.tt));
  $('#tQ').placeholder=t('filter');$('#orb').title=t('opt_now');
}

/* ================= plano do botão ================= */
const PLAN=[['restore','restore'],['temp'],['logs'],['browsers'],['system'],['net'],['hw','@hw'],['gpu','gpu'],['drivers','drivers'],['winget','winget'],['dism','dism']];
const optOn=o=>!o||(o==='@hw'?(S.opts.gpu||S.opts.drivers):S.opts[o]);
const enabledPlan=()=>PLAN.filter(p=>optOn(p[1]));
let syncT;const syncSettings=()=>{clearTimeout(syncT);syncT=setTimeout(()=>api('/api/settings',{opts:S.opts,lang:LANG}).catch(()=>{}),400)};
const saveOpts=()=>{store.set('opts',S.opts);syncSettings()};
function renderSteps(){
  const box=$('#steps');if(!box)return;
  const st={};arr(S.steps).forEach(s=>st[s.id]=s);
  box.innerHTML=PLAN.map(([id,opt],ix)=>{
    const on=optOn(opt),s=st[id],state=s?s.state:(on?'wait':'off');
    const icon=state==='run'?svg('zap'):state==='ok'?svg('check'):state==='err'?svg('x'):state==='skip'?svg('minus'):(ix+1);
    const d=s&&s.detail?tr(s.detail):t('d_'+id);
    const right=opt&&opt[0]!=='@'&&!S.steps?`<button class="sw${on?' on':''}" data-opt="${opt}" title="${t('toggle')}"></button>`:'';
    return `<div class="st ${state}" data-id="${id}"><span class="si">${icon}</span><div><b>${t('p_'+id)}</b><span class="d">${esc(d)}</span></div>${right}</div>`;
  }).join('');
  box.querySelectorAll('.sw').forEach(b=>b.onclick=()=>{const k=b.dataset.opt;S.opts[k]=!S.opts[k];saveOpts();renderSteps()});
  $('#stMeta').textContent=t('n_tasks',enabledPlan().length);
  renderProgress();
}
function lastTxt(){if(!S.last)return t('never');const d=new Date(S.last.t),same=d.toDateString()===new Date().toDateString();return `${same?t('today'):d.toLocaleDateString(LOC(),{day:'2-digit',month:'2-digit'})} ${t('at')} ${hhmm(d)} · ${fmt(S.last.freed)}`}
function renderProgress(){
  const steps=arr(S.steps),n=steps.length,d=steps.filter(s=>['ok','skip','err'].includes(s.state)).length,cur=steps.find(s=>s.state==='run');
  $('#pBar').style.width=(n?d/n*100:0)+'%';setCleaning();
  if(S.optRunning){$('#hState').textContent=t('optimizing');$('#hNote').textContent=cur?t('p_'+cur.id):t('preparing');$('#pTxt').textContent=t('step_of',Math.min(d+1,n||1),n||enabledPlan().length)}
  else if(S.steps&&n){$('#hState').textContent=t('all_done');$('#hNote').textContent=S.last?t('freed_x',fmt(S.last.freed)):t('all_done');$('#pTxt').textContent=t('done_at',S.last?hhmm(S.last.t):hhmm(Date.now()))}
  else{$('#hState').textContent=t('ready_opt');$('#hNote').textContent=t('one_click');$('#pTxt').textContent=S.last?t('last_time',lastTxt()):t('tasks_min',enabledPlan().length,(S.opts.dism||S.opts.gpu)?'10–40':'1–10')}
  setText($('#bigGo'),S.optRunning?t('optimizing'):(S.steps?t('opt_again'):t('opt_now')));
}
async function optimize(){
  if(S.busy)return;
  if(S.page!=='home')go('home');
  S.steps=null;renderSteps();S.optRunning=true;renderProgress();
  const ok=await run('optimize',{DoRestore:!!S.opts.restore,DoDism:!!S.opts.dism,DoDrivers:!!S.opts.drivers,DoGpu:!!S.opts.gpu,DoWinget:!!S.opts.winget,CloseBrowsers:true,UseWU:!!S.opts.usewu},$('#bigGo'));
  if(!ok){S.optRunning=false;renderProgress()}
}

/* ================= páginas ================= */
function PG(){
 const T2=(id,ic,fn)=>[id,ic,t('ti_'+id),t('td_'+id),fn];
 return {
 home:{nav:t('n_home'),title:()=>`${t('greet')[Math.floor(new Date().getHours()/6)]}, ${S.info?S.info.pc:''}`,sub:()=>S.last?t('home_sub_last',lastTxt()):t(isDark()?'home_sub_dk':'home_sub_none'),
  kpis:[['kFree','k_free'],['kRam','k_ram'],['kCan','k_junk'],['kLast','k_last',1]]},
 clean:{nav:t('n_clean'),title:()=>t('n_clean'),sub:()=>t('s_clean'),primary:[t('b_analyze'),'search',el=>run('analyze',{},el)],
  kpis:[['kFree','k_free'],['kCan','k_can'],['kFreed','k_freed'],['kScan','k_scan']]},
 perf:{nav:t('n_perf'),title:()=>t('n_perf'),sub:()=>t('s_perf'),primary:[t('ti_startoff'),'zap',el=>confirmRun('startupoff','q_startoff','m_startoff',{},el)],st:true,
  kpis:[['kRam','k_ram'],['kStart','k_start'],['kUp','k_up'],(S.info&&S.info.laptop)?['kPower','k_power',1]:['kRepair','k_repair',1]],
  tiles:[T2('startoff','zap',el=>confirmRun('startupoff','q_startoff','m_startoff',{},el)),T2('repair','wrench',el=>confirmRun('repair','q_repair','m_repair',{},el))].concat((S.info&&S.info.laptop)?[T2('high','zap',()=>power('high')),T2('bal','scale',()=>power('balanced'))]:[])},
 net:{nav:t('n_net'),title:()=>t('t_net'),sub:()=>t('s_net'),primary:[t('b_speed'),'download',el=>run('speed',{},el)],
  net:true,
  kpis:[['kIp','k_ip',1],['kPing','k_ping'],['kSpeed','k_speed'],['kDns','k_dns',1]],
  tiles:[T2('ping','activity',el=>run('ping',{},el)),T2('speed','download',el=>run('speed',{},el)),T2('flush','refresh',el=>run('flushdns',{},el)),
   T2('cf','cloud',el=>run('setdns',{Mode:'cf'},el)),['g','globe',t('ti_g'),'8.8.8.8',el=>run('setdns',{Mode:'g'},el)],T2('auto','wifi',el=>run('setdns',{Mode:'auto'},el)),
   T2('reset','alert',el=>confirmRun('resetnet','q_reset','m_reset',{},el))]},
 drv:{nav:t('n_drv'),title:()=>t('t_drv'),sub:()=>t('s_drv'),primary:[t('b_drv'),'download',el=>confirmRun('webdrivers','q_webdrv','m_webdrv',{},el)],wu:true,
  kpis:[['kDrv','k_drv'],['kBad','k_bad'],['kWU','k_wu'],['kWg','winget',1]],
  tiles:[T2('webdrv','download',el=>confirmRun('webdrivers','q_webdrv','m_webdrv',{},el)),T2('drivers','list',el=>run('drivers',{},el)),T2('baddev','alert',el=>run('baddev',{},el)),T2('devmgmt','external',()=>openW('devmgmt')),
   T2('wudrv','search',el=>{S.wuType='Driver';run('wusearch',{Type:'Driver'},el)}),T2('wusys','download',el=>{S.wuType='Software';run('wusearch',{Type:'Software'},el)}),
   T2('wgl','package',el=>run('winget',{All:false},el)),['wga','refresh',t('ti_wga'),'winget upgrade --all',el=>confirmRun('winget','q_wga','m_wga',{All:true},el)]]},
 sys:{nav:t('n_sys'),title:()=>t('n_sys'),sub:()=>t('s_sys'),primary:[t('b_restore'),'restore',el=>run('restore',{},el)],hw:true,
  kpis:[['kOs','Windows',1],['kBuild','k_build'],['kUp2','k_up'],['kPcName','k_pc',1]],
  tiles:[['restore','restore',t('p_restore'),t('td_restore'),el=>run('restore',{},el)],T2('rstrui','shield',()=>openW('rstrui')),['logs','folder',t('logs_folder'),t('td_logs'),()=>openW('logs')]]}
 };
}
const KEYS=['home','clean','perf','net','drv','sys'];

function ask(title,msg,okLabel,noLabel){
  okLabel=okLabel||t('confirm');if(noLabel===undefined)noLabel=t('cancel');
  return new Promise(res=>{
    $('#mT').textContent=title;$('#mP').textContent=msg;$('#mYes').textContent=okLabel;
    const no=$('#mNo');no.textContent=noLabel;no.style.display=noLabel?'':'none';
    $('#m1').classList.add('on');
    const done=v=>{$('#m1').classList.remove('on');$('#mYes').onclick=no.onclick=null;res(v)};
    $('#mYes').onclick=()=>done(true);no.onclick=()=>done(false);
  });
}
function table(title,rows){
  rows=arr(rows);if(!rows.length)return;
  const cols=Object.keys(rows[0]);
  $('#tT').innerHTML=`${esc(title)} <span class="cnt">${rows.length}</span>`;
  const draw=q=>{q=(q||'').toLowerCase();const f=rows.filter(r=>!q||cols.some(c=>String(r[c]??'').toLowerCase().includes(q)));
    $('#tb').innerHTML=`<thead><tr>${cols.map(c=>`<th>${esc(tr(c))}</th>`).join('')}</tr></thead><tbody>${f.map(r=>`<tr>${cols.map(c=>`<td>${esc(r[c])}</td>`).join('')}</tr>`).join('')}</tbody>`};
  $('#tQ').value='';$('#tQ').oninput=e=>draw(e.target.value);draw('');$('#m2').classList.add('on');
}

function nav(){
  const P=PG(),tabs=$('#tabs');tabs.innerHTML='';
  KEYS.forEach(k=>{const b=document.createElement('button');b.className='tab'+(k==='home'?' home':'')+(S.page===k?' on':'');b.innerHTML=(k==='home'?svg('home'):'')+P[k].nav;b.onclick=()=>go(k);tabs.append(b)});
}
function go(k){S.page=k;nav();renderPage();setCleaning();$('#app').scrollTo({top:0,behavior:'smooth'})}
function renderPage(){
  const k=S.page,p=PG()[k];document.body.dataset.page=k;
  $('#crumb').textContent=p.nav.toUpperCase();$('#title').textContent=p.title();$('#sub').textContent=p.sub();
  document.title='CleanPano'+(S.info?' · '+S.info.pc:'');
  const hm=$('#hMain');
  if(p.primary){hm.style.display='';hm.innerHTML=svg(p.primary[1])+' '+p.primary[0];hm.onclick=()=>p.primary[2](hm)}else hm.style.display='none';
  $('#hero').style.display=k==='home'?'':'none';
  let h=`<div class="page"><div class="kpis">${p.kpis.map(([id,l,sm])=>`<div class="card kpi${sm?' sm':''}" id="${id}"><div class="l">${t(l)}</div><div class="v">—</div><div class="s">&nbsp;</div></div>`).join('')}</div>`;
  if(k==='clean'){
    h+=`<div class="card"><div class="ch"><h3>${svg('trash')}${t('found')}</h3><div style="display:flex;gap:18px;align-items:center"><span class="meta" id="scanMeta"></span><button class="link" id="selAll">${t('toggle_all')}</button></div></div><div id="cats"></div>
    <div class="cfoot"><button class="btn green" data-fx="#3DDC6B" data-task id="bClean">${svg('broom')}${t('clean_sel')}</button><button class="btn ghost" data-fx="#111412" data-task id="bDism">${svg('package')}${t('deep')}</button><span class="hint">${t('in_use')}</span></div></div>`;
  }else if(p.tiles){
    if(p.wu)h+=`<div class="card" style="margin-bottom:22px"><div class="ch" style="margin-bottom:6px"><h3>${svg('shield')}${t('wu_card')}</h3><span class="meta" id="wuSvc"></span></div><div class="optrow" style="margin-top:8px"><span><b style="display:block;font-weight:600">${t('wu_use')}</b><small style="display:block;font-size:12.5px;color:var(--mut);margin-top:2px">${t('wu_use_d')}</small></span><button class="sw${S.opts.usewu?' on':''}" id="swWU"></button></div></div>`;
    if(p.hw)h+=`<div class="card" style="margin-bottom:22px"><div class="ch"><h3>${svg('cpu')}Hardware</h3><div class="hwbtns"><span class="meta" id="hwMeta"></span><button class="link" id="hwCopy">${t('copy')}</button><button class="link" id="hwRef" data-task>${t('reread')}</button></div></div><div class="hwgrid" id="hwList"></div></div>`;
    h+=`<div class="card"><div class="ch"><h3>${svg('grid')}${t('tools')}</h3><span class="meta">${t('n_actions',p.tiles.length)}</span></div><div class="tiles">${p.tiles.map(([id,ic,ti,d])=>`<button class="tile" data-fx="#3DDC6B" data-id="${id}"><div class="ic">${svg(ic)}</div>${svg('arrow','arr')}<b>${ti}</b><span>${d}</span></button>`).join('')}</div></div>`;
    if(p.net)h+=`<div class="card" style="margin-top:22px"><div class="ch"><h3>${svg('globe')}${t('nc_card')}</h3><div class="hwbtns"><span class="meta" id="ncMeta"></span><button class="link" id="ncCopy">${t('nc_copy')}</button><button class="link" id="ncRef">${t('nc_ref')}</button></div></div><div id="ncBody"></div></div>`;
    if(p.st)h+=`<div class="card" style="margin-top:22px"><div class="ch"><h3>${svg('list')}${t('st_card')}</h3><button class="link" id="stUndo" data-task style="display:none"></button></div><p class="sthint">${t('st_hint')}</p><div id="stList"></div></div>`;
  }
  $('#content').innerHTML=h+'</div>';
  if(k==='clean'){
    renderCats();
    $('#selAll').onclick=()=>{const all=!Object.values(S.sel).every(Boolean);Object.keys(S.sel).forEach(n=>S.sel[n]=all);renderCats();refreshAll()};
    $('#bClean').onclick=e=>doClean(e.currentTarget);
    $('#bDism').onclick=e=>confirmRun('dism','deep_q','deep_msg',{},e.currentTarget);
    magnet($('#bClean'));
  }else if(p.tiles){
    document.querySelectorAll('.tile').forEach(el=>{
      const def=p.tiles.find(x=>x[0]===el.dataset.id);el.onclick=()=>def[4](el);
      el.addEventListener('pointermove',e=>{const r=el.getBoundingClientRect(),x=(e.clientX-r.left)/r.width,y=(e.clientY-r.top)/r.height;
        el.style.setProperty('--mx',x*100+'%');el.style.setProperty('--my',y*100+'%');
        el.style.transform=`perspective(700px) rotateX(${(.5-y)*9}deg) rotateY(${(x-.5)*11}deg) translateY(-4px)`});
      el.addEventListener('pointerleave',()=>el.style.transform='');
    });
  }
  if(k==='home')renderSteps();
  if(p.net){renderNet();$('#ncRef').onclick=()=>loadNet(true);$('#ncCopy').onclick=copyNet;loadNet()}
  if(p.st){renderStartup();$('#stUndo').onclick=e=>run('startupundo',{},e.currentTarget);if(!S.st&&!S.busy)run('startup')}
  if(p.wu){$('#swWU').onclick=e=>{S.opts.usewu=!S.opts.usewu;saveOpts();e.currentTarget.classList.toggle('on',S.opts.usewu);fx('burstEl',e.currentTarget)}}
  if(p.hw){renderHw();$('#hwRef').onclick=()=>run('hardware');$('#hwCopy').onclick=copyHw;if(!S.hw&&!S.busy)run('hardware')}
  refreshAll();
}
async function loadNet(force){
  if(S.netBusy)return;if(S.net&&!force&&Date.now()-S.netAt<20000){renderNet();return}
  S.netBusy=true;const r=$('#ncRef');if(r)r.textContent='…';
  try{S.net=await api('/api/netinfo');S.netAt=Date.now()}catch(e){}
  S.netBusy=false;if(r)r.textContent=t('nc_ref');renderNet();refreshAll();
}
function netRows(a){
  const rows=[['nc_ip',a.ip?a.ip+(a.prefix?' /'+a.prefix:''):'—'],['nc_gw',a.gw||'—'],['nc_mask',a.mask||'—'],['nc_dns',arr(a.dns).join(', ')||'—'],
   ['nc_dhcp',a.dhcp==null?'—':t(a.dhcp?'nc_auto':'nc_man')],['nc_speed',a.link||'—'],['nc_mac',a.mac||'—'],['nc_v6',a.ipv6||'—']];
  if(a.profile)rows.push(['nc_prof',T['nc_'+a.profile]?t('nc_'+a.profile):a.profile]);
  if(a.type==='wifi'){if(a.ssid)rows.splice(0,0,['nc_ssid',a.ssid]);if(a.signal!=null)rows.push(['nc_sig',a.signal+'%']);if(a.radio||a.band)rows.push(['nc_radio',[a.radio,a.band].filter(Boolean).join(' · ')])}
  return rows;
}
function renderNet(){
  const b=$('#ncBody');if(!b)return;
  if(!S.net){b.innerHTML=`<div class="empty">${t('nc_loading')}</div>`;return}
  const m=$('#ncMeta');if(m)m.textContent=t('read_at',S.net.at||'');
  const ad=arr(S.net.adapters);
  let h=`<div class="ncg top"><div><span>${t('nc_pub')}</span><b>${esc(S.net.publicIp||t('nc_off'))}</b></div><div><span>${t('nc_host')}</span><b>${esc(S.net.host||'')}</b></div></div>`;
  if(!ad.length)h+=`<div class="empty">${t('nc_none')}</div>`;
  ad.forEach(a=>{h+=`<div class="nca"><div class="nch">${svg(a.type==='wifi'?'wifi':'globe')}<div style="min-width:0"><b>${esc(a.name)}${a.primary&&ad.length>1?` <i class="stc g">${t('nc_main')}</i>`:''}</b><span>${t(a.type==='wifi'?'nc_wifi':'nc_eth')} · ${esc(a.desc||'')}</span></div></div>
   <div class="ncg">${netRows(a).map(([k,v])=>`<div><span>${t(k)}</span><b>${esc(v)}</b></div>`).join('')}</div></div>`});
  b.innerHTML=h;
}
function copyNet(){
  if(!S.net)return;let s=t('nc_pub')+': '+(S.net.publicIp||'—')+'\n'+t('nc_host')+': '+(S.net.host||'')+'\n';
  arr(S.net.adapters).forEach(a=>{s+='\n'+a.name+' ('+(a.desc||'')+')\n'+netRows(a).map(([k,v])=>'  '+t(k)+': '+v).join('\n')+'\n'});
  const b=$('#ncCopy');navigator.clipboard.writeText(s).then(()=>{b.textContent=t('copied');setTimeout(()=>b.textContent=t('nc_copy'),1800)}).catch(()=>{});
}
function renderStartup(){
  const b=$('#stList');if(!b)return;
  if(!S.st){b.innerHTML=`<div class="empty">${t('st_loading')}</div>`;return}
  const it=arr(S.st.items).filter(x=>x.kind!=='cleanpano').sort((a,c)=>(a.kind?1:0)-(c.kind?1:0)||(c.enabled?1:0)-(a.enabled?1:0)||String(a.name).localeCompare(String(c.name)));
  b.innerHTML=it.length?it.map((x,ix)=>{
    if(x.kind)return `<div class="sti win"><span class="stx"></span><div style="min-width:0"><b>${esc(x.name)}</b><span>${esc(x.publisher||'')}</span></div><i class="stc w">${t('st_win')}</i></div>`;
    const ch=x.enabled?(x.keep?[t('st_kept'),'k']:[t('st_on'),'o']):[t('st_off'),'g'];
    return `<div class="sti${x.keep?' kept':''}"><label class="stx" title="${esc(t('st_tt'))}"><input type="checkbox" data-ix="${ix}" ${x.keep?'':'checked'}><span class="box">${svg('check')}</span></label><div style="min-width:0"><b>${esc(x.name)}</b><span>${esc(x.publisher||'')}</span></div><span class="sta">${x.enabled?'':`<button class="link" data-re="${ix}" data-task>${t('st_react')}</button>`}<i class="stc ${ch[1]}">${ch[0]}</i></span></div>`}).join(''):`<div class="empty">${t('st_empty')}</div>`;
  b.querySelectorAll('input[data-ix]').forEach(cb=>cb.onchange=async()=>{
    const x=it[+cb.dataset.ix],keep=!cb.checked;cb.disabled=true;
    const r=await fetch(`/api/startupkeep?id=${encodeURIComponent(x.id)}&keep=${keep?1:0}&name=${encodeURIComponent(x.name)}`,{cache:'no-store'}).then(r=>r.json()).catch(()=>({ok:false}));
    if(r.ok){x.keep=keep;S.st.active=arr(S.st.items).filter(y=>y.enabled&&!y.kind&&!y.keep).length;renderStartup();refreshAll()}else{cb.checked=!keep;cb.disabled=false}});
  b.querySelectorAll('button[data-re]').forEach(bt=>bt.onclick=e=>run('startupset',{Id:it[+bt.dataset.re].id},e.currentTarget));
  const u=$('#stUndo');if(u){u.style.display=S.st.mine?'':'none';u.textContent=t('st_undo',S.st.mine)}
}

function renderCats(){
  const c=$('#cats');if(!c)return;
  const names=S.info?arr(S.info.cats):Object.keys(S.scan||{});
  if(!names.length){c.innerHTML=`<div class="empty">${t('loading_cats')}</div>`;return}
  const sc=S.scan||{},max=Math.max(1,...names.map(n=>+sc[n]||0));
  c.innerHTML=names.map(n=>{if(S.sel[n]===undefined)S.sel[n]=true;const v=S.scan?+sc[n]||0:null;
    return `<label class="cat"><input type="checkbox" data-n="${esc(n)}" ${S.sel[n]?'checked':''}><span class="box">${svg('check')}</span><span class="nm">${esc(tr(n))}</span><span class="bar"><i data-w="${v==null?0:(v>0?Math.max(3,v/max*100):0)}"></i></span><span class="sz">${v==null?'—':fmt(v)}</span></label>`}).join('');
  setTimeout(()=>c.querySelectorAll('.bar i').forEach(i=>i.style.width=i.dataset.w+'%'),40);
  c.querySelectorAll('input').forEach(i=>i.onchange=()=>{S.sel[i.dataset.n]=i.checked;refreshAll()});
  const m=$('#scanMeta');if(m)m.textContent=S.scanAt?t('last_scan',hhmm(S.scanAt)):'';
}
const HWC={cpu:['cpu','#E4F6EA','#16A34A'],gpu:['gpu','#FBF1D2','#A27A0B'],ram:['ram','#E0F2FE','#0369A1'],board:['board','#EEEEE8','#111412'],disk:['disk','#FDEBDD','#C2410C'],monitor:['monitor','#EDE9FE','#6D28D9'],net:['wifi','#E4F6EA','#16A34A'],audio:['audio','#FCE7F3','#BE185D']};
function renderHw(){
  const b=$('#hwList');if(!b)return;
  const it=S.hw?arr(S.hw.items):[];
  $('#hwMeta').textContent=S.hw&&S.hw.at?t('read_at',S.hw.at):'';
  if(!it.length){b.innerHTML=`<div class="empty">${t('reading')}</div>`;return}
  b.innerHTML=it.map(x=>{const c=HWC[x.cat]||['cpu','#F1F1EC','#111412'];
    return `<div class="hw" data-fx="${c[2]}"><div class="hi" style="background:${c[1]};color:${c[2]}">${svg(c[0])}</div><div style="min-width:0"><div class="t">${esc(tr(x.title))}</div><div class="n" title="${esc(tr(x.name))}">${esc(tr(x.name))}</div>${arr(x.flags).length?`<div class="hfl">${arr(x.flags).map(f=>`<b class="hf ${f.s||'ok'}">${esc(t(f.k,...hfa(f.a)))}</b>`).join('')}</div>`:''}<div class="chips">${arr(x.specs).map(s=>`<span>${esc(tr(s))}</span>`).join('')}</div></div><i class="stt${x.status==='warn'?' w':''}" title="${x.status==='warn'?t('attention'):'OK'}"></i></div>`}).join('');
}
function copyHw(){
  const it=S.hw?arr(S.hw.items):[];if(!it.length)return;
  const txt=[`${S.info?S.info.pc:''} — CleanPano`,...it.map(x=>`${tr(x.title)}: ${tr(x.name)}${arr(x.specs).length?' — '+arr(x.specs).map(tr).join(', '):''}${arr(x.flags).length?' · '+arr(x.flags).map(f=>t(f.k,...hfa(f.a))).join(', '):''}`)].join('\n');
  const b=$('#hwCopy');navigator.clipboard.writeText(txt).then(()=>{b.textContent=t('copied');setTimeout(()=>b.textContent=t('copy'),1800)}).catch(()=>{});
}

function K(id,v,s){const e=document.getElementById(id);if(!e)return;e.querySelector('.v').textContent=v;e.querySelector('.s').textContent=s||' '}
const selBytes=()=>S.scan?Object.keys(S.sel).filter(n=>S.sel[n]).reduce((a,n)=>a+(+S.scan[n]||0),0):null;
const allBytes=()=>S.scan?Object.values(S.scan).reduce((a,b)=>a+(+b||0),0):null;
const upTxt=h=>`${Math.floor(h/24)}d ${Math.floor(h%24)}h`;
function refreshAll(){
  const i=S.info;
  if(i){
    const used=i.disk.total-i.disk.free;
    K('kFree',fmt(i.disk.free),t('of_used',fmt(i.disk.total),Math.round(used/i.disk.total*100)));
    K('kRam',Math.round(i.ram.used/i.ram.total*100)+'%',t('x_of_y',fmt(i.ram.used),fmt(i.ram.total)));
    K('kPower',i.power||'—',t('active_plan'));
    K('kUp',upTxt(i.uptimeH),t('since_boot'));K('kUp2',upTxt(i.uptimeH),t('since_boot'));
    const dns=arr(i.dns);K('kDns',dns.includes('1.1.1.1')?'Cloudflare':dns.includes('8.8.8.8')?'Google':dns.length?t('dns_isp'):t('no_conn'),dns.join(', '));
    {const cur=dns.includes('1.1.1.1')||dns.includes('1.0.0.1')?'cf':dns.includes('8.8.8.8')||dns.includes('8.8.4.4')?'g':'auto';['cf','g','auto'].forEach(id=>{const el=document.querySelector(`.tile[data-id="${id}"]`);if(el)el.classList.toggle('on',id===cur)})}
    K('kAdp',i.adapter||'—',i.link||'');
    {const a=S.net&&arr(S.net.adapters)[0];K('kIp',a&&a.ip?a.ip:'—',a?(a.ssid||a.name)+(a.link?' · '+a.link:''):t('nc_loading'));}
    K('kOs',i.os,i.arch);K('kBuild',i.build,t('win_ver'));K('kPcName',i.pc,t('ram_of',fmt(i.ram.total)));
    K('kWg',i.winget?t('wg_ok'):t('wg_no'),i.winget?t('wg_ok_s'):t('wg_no_s'));
    const ws=$('#wuSvc');if(ws)ws.textContent=t('wu_svc',t('wu_'+(['Disabled','Manual','Automatic'].includes(i.wuState)?i.wuState:'Unknown')));
    $('#pcn').textContent=i.pc;$('#pcos').textContent=i.os;$('#av').textContent=String(i.pc).replace(/[^A-Za-z0-9]/g,'').slice(0,2).toUpperCase()||'PC';
    if(S.page==='home')$('#title').textContent=PG().home.title();
    document.title='CleanPano · '+i.pc;
  }
  const sb=selBytes(),ab=allBytes(),home=S.page==='home';
  K('kCan',home?(ab==null?'—':fmt(ab)):(sb==null?'—':fmt(sb)),home?t('junk_s'):t('marked_s'));
  K('kLast',S.last?lastTxt().split(' · ')[0]:t('never_cap'),S.last?t('freed_x',fmt(S.last.freed)):t('click_opt'));
  K('kFreed',fmt(S.freed),t('since_open'));
  K('kScan',S.scanAt?hhmm(S.scanAt):'—',S.scanAt?t('auto_scan'):t('not_scanned'));
  K('kStart',S.st?S.st.active:'—',t('third_party'));
  {const lr=store.get('repair',null);K('kRepair',lr?new Date(lr.t).toLocaleDateString(LOC(),{day:'2-digit',month:'2-digit'}):t('never_cap'),lr?t('rp_'+lr.r).split('.')[0]:t('never_rep'));}
  K('kPing',S.ping==null?'—':S.ping+' ms',t('ping_s'));
  K('kSpeed',S.speed==null?'—':S.speed+' Mbps',t('speed_s'));
  K('kDrv',S.drivers==null?'—':S.drivers,S.drivers==null?t('click_drv'):t('drivers_w'));
  K('kBad',S.bad==null?'—':S.bad,S.bad==null?t('not_checked'):t('err_nodrv'));
  K('kWU',S.wu==null?'—':S.wu,S.wu==null?t('not_checked'):(S.wuType==='Driver'?t('drivers_w'):t('win_updates')));
  if(home)$('#sub').textContent=PG().home.sub();
  renderHealth();
}

/* drivers conferidos há menos de 7 dias (Otimizar ou busca no Windows Update) = nota cheia */
function updFresh(){const u=store.get('updok',0);return u&&Date.now()-u<6048e5}
function health(){
  const i=S.info;if(!i)return null;
  const dp=(i.disk.total-i.disk.free)/i.disk.total*100,rp=i.ram.used/i.ram.total*100,junk=allBytes();
  const f=[['f_disk',25,dp>90?5:dp>80?12:dp>70?19:25],['f_junk',20,junk==null?14:junk>2e9?6:junk>1e9?10:junk>3e8?15:20],['f_ram',20,rp>90?6:rp>80?11:rp>70?16:20],
   ['f_dev',15,S.bad==null?15:Math.max(0,15-S.bad*5)],['f_upd',10,S.wu==null?(updFresh()?10:8):Math.max(0,10-S.wu*2)],['f_up',10,i.uptimeH>336?3:i.uptimeH>168?6:10]];
  return {score:f.reduce((a,x)=>a+x[2],0),f,dp,rp,junk};
}
function tween(el,to){const from=parseInt(el.textContent)||0,t0=performance.now();const step=n=>{const k=Math.min(1,(n-t0)/900),e=1-Math.pow(1-k,3);el.textContent=Math.round(from+(to-from)*e);if(k<1)requestAnimationFrame(step)};requestAnimationFrame(step)}
function renderHealth(){
  const h=health();if(!h)return;
  if(S.first==null&&S.scan)S.first=h.score;
  const sn=$('#sn');if(h.score!==S.score){tween(sn,h.score);S.score=h.score}
  sn.style.color=h.score>=80?(isDark()?'#ff7a33':'#16A34A'):h.score>=60?'#A27A0B':'#DC2626';
  const rv=$('#ringV');rv.style.stroke=h.score>=80?(isDark()?'#ff5900':'#3DDC6B'):h.score>=60?'#EBB931':'#E5484D';rv.style.strokeDashoffset=326.7*(1-h.score/100);
  const d=S.first==null?0:h.score-S.first,chip=$('#chip');
  if(d>0){chip.className='chip g';chip.textContent=t('up_session',d)}
  else{chip.className='chip'+(h.score>=80?' g':h.score<60?' r':'');chip.textContent=h.score>=80?t('healthy'):h.score>=60?t('improve'):t('need_att')}
  const F=$('#facs');
  if(!F.children.length)F.innerHTML=h.f.map(([n])=>`<div class="fac"><span>${t(n)}</span><span class="fbar"><i></i></span><em></em></div>`).join('');
  [...F.children].forEach((row,ix)=>{const [,m,v]=h.f[ix];setTimeout(()=>row.querySelector('i').style.width=(v/m*100)+'%',30);row.querySelector('em').textContent='+'+v});
  const i=S.info,x=[];
  if(S.freed>0)x.push(t('c_freed',fmt(S.freed)));
  if(h.junk!=null)x.push(h.junk>5e6?t('c_junk',fmt(h.junk)):t('c_nojunk'));
  x.push(t('c_disk',Math.round(h.dp),Math.round(h.rp)));
  if(i.uptimeH>168)x.push(t('c_up',Math.floor(i.uptimeH/24)));
  if(S.bad)x.push(t('c_bad',S.bad));
  if(S.wu)x.push(t('c_wu',S.wu));
  $('#chg').textContent=x.join(' ');$('#upd').textContent=t('updated',hhmm(Date.now()));
  fx('orb',h.score,S.busy);
}

function addLog(l){
  const L=$('#log');if(L.querySelector('.empty'))L.innerHTML='';
  l=String(l);const time=l.slice(0,10);let m=l.slice(10);
  const d=document.createElement('div');
  if(m.startsWith('>> ')){const name=m.slice(3);const k=Object.keys(T).find(k=>k.startsWith('task_')&&T[k][0]===name);m='>> '+(k?t(k):name)}
  else if(m.startsWith('OK  ')){const name=m.slice(4).replace(/ concluído$/,'');const k=Object.keys(T).find(k=>k.startsWith('task_')&&T[k][0]===name);m='OK  '+(k?t(k):name)+(LANG==='pt'?' concluído':LANG==='en'?' done':' completado')}
  else if(m.startsWith('-- ')){const name=m.slice(3);const k=Object.keys(T).find(k=>k.startsWith('p_')&&T[k][0]===name);m='-- '+(k?t(k):tr(name))}
  else m=tr(m);
  d.textContent=time+m;
  if(m.startsWith('>>')||m.startsWith('--'))d.className='h';
  else if(m.startsWith('OK')||/LIBERADO|FREED|CONCLUÍDA|FINISHED|TERMINADA|criado|Sucesso/.test(m))d.className='ok';
  else if(/Erro|Error|Falha|falhou|failed|PROBLEMA|Não foi|não encontrado/.test(m))d.className='er';
  L.append(d);while(L.children.length>400)L.firstChild.remove();L.scrollTop=L.scrollHeight;$('#lcnt').textContent=L.children.length;
}
function setCleaning(){const c=S.optRunning||(S.busy&&['optimize','clean','dism'].includes(S.task));document.body.classList.toggle('cleaning',!!c);document.body.classList.toggle('notHome',S.page!=='home');const st=arr(S.steps),n=st.length,d=st.filter(s=>['ok','skip','err'].includes(s.state)).length;const mt=$('#miniT');if(mt){mt.textContent=S.optRunning?t('optimizing'):(S.task?t('task_'+S.task):'');$('#miniS').textContent=S.optRunning&&n?t('step_of',Math.min(d+1,n),n):''}}
function setBusy(b,task){
  S.busy=b;S.task=task||'';document.body.classList.toggle('busy',b);setCleaning();
  $('#badge').className='badge'+(b?' busy':'');$('#btxt').textContent=b?(task?t('task_'+task):'…'):t('ready');
  if(!b)markRun(null);
  if(S.score!=null)fx('orb',S.score,b);
}
function applySteps(list){
  const prev={};arr(S.steps).forEach(s=>prev[s.id]=s.state);
  S.steps=list;
  if(S.page==='home'){renderSteps();list.forEach(s=>{if(s.state==='ok'&&prev[s.id]!=='ok'){const el=document.querySelector(`.st[data-id="${s.id}"] .si`);if(el)fx('burstEl',el)}})}
}

const DONE={
 optimize:r=>{r=r||{};const h=$('#mHead');if(h){h.classList.remove('cheer');void h.offsetWidth;h.classList.add('cheer')}if(r.hw&&arr(r.hw.items).length){S.hw=r.hw;store.set('hw',r.hw);renderHw()}S.optRunning=false;applySteps(arr(r.steps));if(arr(r.steps).some(x=>x.id==='drivers'&&x.state==='ok'))store.set('updok',Date.now());S.freed+=+r.freed||0;S.last={t:Date.now(),freed:+r.freed||0};store.set('last',S.last);renderProgress();fx('celebrate',true);loadInfo().then(()=>run('analyze'))},
 hardware:r=>{if(r&&arr(r.items).length){S.hw=r;store.set('hw',r)}renderHw();if(!S.scan)run('analyze')},
 analyze:r=>{S.scan=r||{};S.scanAt=new Date();renderCats();refreshAll()},
 clean:r=>{S.freed+=+r||0;loadInfo().then(()=>run('analyze'))},
 dism:()=>loadInfo(),startup:r=>{if(r){S.st=r;renderStartup();refreshAll()}},
 startupoff:r=>{if(r){S.st=r;renderStartup();refreshAll();ask(t('ti_startoff'),t('so_done',r.changed||0),t('ok'),'')}},
 startupset:r=>{if(r){S.st=r;renderStartup();refreshAll()}},
 startupundo:r=>{if(r){S.st=r;renderStartup();refreshAll();ask(t('ti_startoff'),t('su_done',r.changed||0),t('ok'),'')}},
 repair:r=>{const res=(r&&r.result)||'done';store.set('repair',{t:Date.now(),r:res});refreshAll();ask(t('ti_repair'),t('rp_'+res),t('ok'),'')},topproc:()=>loadInfo(),
 ping:r=>{S.ping=r;refreshAll()},speed:r=>{S.speed=r;refreshAll()},setdns:()=>{loadInfo();loadNet(true)},resetnet:()=>{loadInfo();loadNet(true)},
 drivers:r=>{const a=arr(r);S.drivers=a.length;refreshAll();table(t('k_drv'),a)},
 baddev:r=>{const a=arr(r);S.bad=a.length;refreshAll();if(a.length)table(t('ti_baddev'),a)},
 wusearch:async r=>{S.wu=+r||0;if(!S.wu)store.set('updok',Date.now());refreshAll();if(S.wu>0&&await ask(t('wu_found',S.wu),t('wu_msg'),t('install')))run('wuinstall',{Type:S.wuType})},
 wuinstall:()=>{S.wu=null;refreshAll()},
 webdrivers:r=>{if(r)ask(t('ti_webdrv'),t('web_upd',r.updated||0),t('ok'),'');loadInfo()}
};

async function doClean(el){
  const sel=Object.keys(S.sel).filter(n=>S.sel[n]);
  if(!sel.length)return ask(t('nothing'),t('check_one'),t('ok'),'');
  const sb=selBytes();
  if(!await ask(t('clean_now'),t('clean_msg',sel.length,sb!=null?t('about',fmt(sb)):''),t('clean_btn')))return;
  run('clean',{Selected:sel,CloseBrowsers:true},el);
}

async function loadInfo(){try{S.info=await api('/api/info');{const il=S.info.installLang;if(il&&il!==store.get('instlang','')&&LANGS.some(x=>x[0]===il)){store.set('instlang',il);if(il!==LANG)setLang(il)}}if(!$('#cats .cat'))renderCats();refreshAll()}catch(e){}}
let off=0;
async function poll(){
  try{
    const p=await api('/api/poll');off=0;
    arr(p.lines).forEach(addLog);
    if(p.busy&&p.key==='optimize'&&!S.optRunning){S.optRunning=true;if(S.page==='home')renderProgress()}
    if(p.steps&&arr(p.steps).length&&S.optRunning)applySteps(arr(p.steps));
    if(!(Date.now()-S.runAt<900&&!p.busy))setBusy(!!p.busy,p.key||'');
    for(const d of arr(p.done)){if(d.task!=='optimize')fx('celebrate');Promise.resolve().then(()=>DONE[d.task]&&DONE[d.task](d.result)).catch(console.error)}
  }catch(e){if(++off>4){$('#badge').className='badge off';$('#btxt').textContent=t('disconnected')}}
  setTimeout(poll,400);
}


document.querySelectorAll('[data-i]').forEach(e=>e.insertAdjacentHTML('afterbegin',svg(e.dataset.i)));
document.documentElement.lang=LOC();
buildLang();applyStatic();
$('#btxt').textContent=t('connecting');$('#log').innerHTML=`<div class="empty">${t('no_activity')}</div>`;$('#chg').textContent=t('analyzing');$('#chip').textContent=t('calculating');
$('#lbtn').onclick=e=>{e.stopPropagation();$('#lang').classList.toggle('open')};
document.addEventListener('click',()=>$('#lang').classList.remove('open'));
$('#bLogs').onclick=()=>openW('logs');
$('#hRef').onclick=()=>loadInfo();
$('#bigGo').onclick=optimize;$('#mascot').onclick=optimize;$('#mini').onclick=()=>go('home');$('#optim').onclick=optimize;
const setAuto=v=>{S.autostart=!!v;$('#swAuto').classList.toggle('on',S.autostart)};
$('#swAuto').onclick=async e=>{const want=!S.autostart;setAuto(want);fx('burstEl',e.currentTarget);
  try{const r=await api('/api/settings',{autostart:want,opts:S.opts,lang:LANG});setAuto(r.autostart);addLog(hhmm(Date.now()).padEnd(8)+'  '+t(r.autostart?'auto_on':'auto_off'))}catch(err){setAuto(!want)}};
api('/api/settings').then(r=>setAuto(r.autostart)).catch(()=>{});
syncSettings();
$('#lclr').onclick=()=>{$('#log').innerHTML=`<div class="empty">${t('no_activity')}</div>`;$('#lcnt').textContent=0};
$('#tX').onclick=()=>$('#m2').classList.remove('on');
/* reportar bug / sugestão: envia pelo Web3Forms (APP.feedbackKey); o e-mail de destino não fica no app */
{const m=$('#m4'),b=$('#fbBtn'),tx=$('#fbText'),ml=$('#fbMail'),nt=$('#fbNote'),sd=$('#fbSend');let kind='bug',busy=false;
 const ver=()=>S.info&&S.info.version?String(S.info.version).replace(/\.0$/,''):'';
 const note=(k,cls)=>{nt.textContent=k==='base'?t('fb_note',ver()||'?'):t(k);nt.className='fbnote'+(cls?' '+cls:'')};
 const paint=()=>{document.querySelectorAll('.fbtype button').forEach(x=>x.classList.toggle('on',x.dataset.k===kind));tx.placeholder=t(kind==='bug'?'fb_ph_bug':'fb_ph_idea');ml.placeholder=t('fb_mail');sd.textContent=t(busy?'fb_sending':'fb_send')};
 if(APP.feedbackKey){b.style.display='';
  b.onclick=()=>{note('base');paint();m.classList.add('on');setTimeout(()=>tx.focus(),60)};
  tx.oninput=ml.oninput=()=>{if(nt.classList.contains('bad'))note('base')};
  $('#fbX').onclick=()=>m.classList.remove('on');m.onclick=e=>{if(e.target===m&&!busy)m.classList.remove('on')};
  document.querySelectorAll('.fbtype button').forEach(x=>x.onclick=()=>{kind=x.dataset.k;paint()});
  sd.onclick=async()=>{if(busy)return;const msg=tx.value.trim(),mail=ml.value.trim();
   if(msg.length<10){note('fb_short','bad');tx.focus();return}
   if(mail&&!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(mail)){note('fb_badmail','bad');ml.focus();return}
   busy=true;paint();
   const body={access_key:APP.feedbackKey,subject:'CleanPano · '+(kind==='bug'?'Bug':'Sugestão')+(ver()?' · v'+ver():''),from_name:'CleanPano',tipo:kind==='bug'?'Bug':'Sugestão',message:msg,versao_app:ver(),windows:S.info?((S.info.os||'')+' '+(S.info.build||'')+' '+(S.info.arch||'')).trim():'',idioma:LANG};
   if(mail)body.email=mail;
   try{const r=await fetch('https://api.web3forms.com/submit',{method:'POST',headers:{'Content-Type':'application/json',Accept:'application/json'},body:JSON.stringify(body)});const j=await r.json().catch(()=>({}));
    if(r.ok&&j.success){tx.value='';ml.value='';note('fb_ok','ok');setTimeout(()=>{if(nt.classList.contains('ok'))m.classList.remove('on')},2200)}else note('fb_err','bad')}
   catch(e){note('fb_err','bad')}
   busy=false;paint()}}}
/* doação */
{const m=$('#m3'),c=$('#donCopy'),lab=()=>c.textContent=t('don_copy');$('#donBtn').onclick=$('#donTop').onclick=()=>{lab();m.classList.add('on')};$('#donX').onclick=()=>m.classList.remove('on');m.onclick=e=>{if(e.target===m)m.classList.remove('on')};
 c.onclick=()=>{const a=$('#donAddr').textContent.trim();const ok=()=>{c.textContent=t('copied');setTimeout(lab,1800)};navigator.clipboard.writeText(a).then(ok).catch(()=>{const r=document.createRange();r.selectNodeContents($('#donAddr'));const g=getSelection();g.removeAllRanges();g.addRange(r);try{document.execCommand('copy');ok()}catch(e){}})}}
document.addEventListener('keydown',e=>{if(e.key==='Escape'){$('#m2').classList.remove('on');$('#m3').classList.remove('on');$('#m4').classList.remove('on');$('#lang').classList.remove('open')}});
magnet($('#hMain'));magnet($('#bigGo'));

go('home');
loadInfo().then(()=>(S.hw&&S.hw.v>=4&&S.info&&S.info.hwKnown)?run('analyze'):run('hardware'));
poll();
setInterval(()=>{if(!S.busy)loadInfo()},30000);

document.addEventListener('themechange',()=>{try{renderPage();refreshAll();fx('theme')}catch(e){}});

/* rodapé: versão do programa (lida do .exe pelo motor) */
function showVer(){const v=S.info&&S.info.version;const e=document.getElementById('ver');if(e&&v)e.textContent='v'+String(v).replace(/\.0$/,"")}
setInterval(showVer,1500);
