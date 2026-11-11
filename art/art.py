# Uso: python art.py   (rodar dentro da pasta art)
# Gera ícone, logo animada da interface e imagens do instalador a partir do gato
# (art/cat-black.png = desenho base, art/cat.svg = logo vetorial que pisca, art/cat-work.gif = trabalhando).
# Na interface a logo é branca com transparência; o CSS deixa preta no tema claro.
from PIL import Image, ImageDraw, ImageFilter, ImageFont, ImageSequence, ImageChops
import os, shutil
A=os.path.dirname(os.path.abspath(__file__)); U=os.path.join(A,'..','app','ui','img')
G=(61,220,107); DK=(21,25,30)
FD='/usr/share/fonts/opentype/inter/'
def F(n,sz):
    try: return ImageFont.truetype(FD+n,sz)
    except: return ImageFont.load_default()
def alpha(im): return im.convert('RGBA').getchannel('A')
def tint(a,rgb): 
    c=Image.new('RGBA',a.size,rgb+(0,)); c.putalpha(a); return c
def fit(a,sz,pad):
    a=a.crop(a.getbbox()); s=int(sz*(1-2*pad)); r=min(s/a.width,s/a.height)
    a=a.resize((max(1,round(a.width*r)),max(1,round(a.height*r))),Image.LANCZOS)
    c=Image.new('L',(sz,sz),0); c.paste(a,((sz-a.width)//2,(sz-a.height)//2)); return c
base=alpha(Image.open(A+'/cat-black.png'))
# animações: mesmo recorte quadrado em todos os quadros, alfa suavizado
def anim(src,out,sz=420):
    im=Image.open(A+'/'+src); fr=[alpha(f.copy()) for f in ImageSequence.Iterator(im)]
    du=[f.info.get('duration',100) for f in ImageSequence.Iterator(Image.open(A+'/'+src))]
    bb=None
    for f in fr:
        b=f.getbbox(); bb=b if bb is None else (min(bb[0],b[0]),min(bb[1],b[1]),max(bb[2],b[2]),max(bb[3],b[3]))
    cx,cy=(bb[0]+bb[2])/2,(bb[1]+bb[3])/2; h=max(bb[2]-bb[0],bb[3]-bb[1])/2+10
    box=tuple(int(v) for v in (cx-h,cy-h,cx+h,cy+h))
    out_fr=[tint(f.crop(box).filter(ImageFilter.GaussianBlur(0.8)).resize((sz,sz),Image.LANCZOS),(255,255,255)) for f in fr]
    out_fr[0].save(U+'/'+out,'WEBP',save_all=True,append_images=out_fr[1:],duration=du,loop=0,lossless=True,method=6)
anim('cat-work.gif','cat-work.webp')
# logo da interface: vetor (art/cat.svg, traçado de cat-black.png) com a piscada animada dentro do próprio SVG
shutil.copy(A+'/cat.svg',U+'/cat.svg')
# ícone: gato branco num quadrado escuro arredondado (aparece bem em barra clara ou escura)
def tile(sz):
    S=sz*4; t=Image.new('RGBA',(S,S),(0,0,0,0)); ImageDraw.Draw(t).rounded_rectangle([0,0,S-1,S-1],radius=int(S*.23),fill=DK+(255,))
    t.alpha_composite(tint(fit(base,S,0.10 if sz>32 else 0.06),(255,255,255))); return t.resize((sz,sz),Image.LANCZOS)
sizes=(16,20,24,32,40,48,64,96,128,256)
imgs=[tile(s) for s in sizes]
imgs[-1].save(A+'/CleanPano.ico',sizes=[(s,s) for s in sizes],append_images=imgs[:-1])
imgs[-1].save(U+'/logo.png',optimize=True)
shutil.copy(A+'/CleanPano.ico',U+'/favicon.ico')
# instalador: arte desenhada em 8x e reduzida com filtro de qualidade.
#  welcome-hq.bmp / header-hq.bmp (4x) = o instalador reduz na hora para o tamanho exato da tela (nítido em qualquer escala do Windows)
#  welcome.bmp / header.bmp (2x) = reserva, usada só se a redução de qualidade falhar
def welcome(K):
    W,H=164*K,314*K
    bg=Image.new('RGB',(W,H)); px=bg.load()
    top,bot=(27,33,40),(7,9,12)
    for y in range(H):
        t=(y/H)**1.15; c=tuple(int(top[i]+(bot[i]-top[i])*t) for i in range(3))
        for x in range(W): px[x,y]=c
    bg=bg.convert('RGBA')
    # brilho suave atrás da logo
    g=Image.new('RGBA',(W,H),(0,0,0,0)); ImageDraw.Draw(g).ellipse([W*.5-70*K,62*K,W*.5+70*K,202*K],fill=G+(70,))
    bg=Image.alpha_composite(bg,g.filter(ImageFilter.GaussianBlur(34*K)))
    # marcas de garra bem discretas embaixo (assinatura visual do app)
    m=Image.new('L',(W,H),0); d=ImageDraw.Draw(m)
    for k,(dx,ln) in enumerate([(-26,.78),(0,1),(26,.82)]):
        x0,y0,x1,y1=W*.5+38*K+dx*K,222*K,W*.5-38*K+dx*K,300*K
        cx,cy=(x0+x1)/2,(y0+y1)/2; x0,y0,x1,y1=cx+(x0-cx)*ln,cy+(y0-cy)*ln,cx+(x1-cx)*ln,cy+(y1-cy)*ln
        d.polygon([(x0,y0),(cx+5*K,cy+3*K),(x1,y1),(cx-5*K,cy-3*K)],fill=255)
    m=m.filter(ImageFilter.GaussianBlur(.6*K))
    bg=Image.alpha_composite(bg,tint(m.point(lambda v:int(v*.07)),(255,255,255)))
    L=96*K; bg.alpha_composite(tint(fit(base,L,0.0),(255,255,255)),((W-L)//2,84*K))
    d=ImageDraw.Draw(bg)
    d.text((W/2,206*K),'CleanPano',font=F('InterDisplay-Bold.otf',25*K),fill=(255,255,255),anchor='mm')
    tg='PC CLEANER'; f=F('Inter-SemiBold.otf',int(7.5*K)); sp=2.6*K
    w=sum(d.textlength(c,font=f) for c in tg)+sp*(len(tg)-1); x=W/2-w/2
    for c in tg: d.text((x,226*K),c,font=f,fill=G,anchor='lm'); x+=d.textlength(c,font=f)+sp
    d.rectangle([0,H-3*K,W,H],fill=G)
    return bg.convert('RGB')
def header(K):
    W,H=150*K,57*K; h=Image.new('RGBA',(W,H),(255,255,255,255)); L=40*K
    h.alpha_composite(tint(fit(base,L,0.0),DK),(W-L-10*K,(H-L)//2)); return h.convert('RGB')
big=welcome(8); hb=header(8)
for K,suf in ((4,'-hq'),(2,'')):
    big.resize((164*K,314*K),Image.LANCZOS).save(A+'/welcome'+suf+'.bmp')
    hb.resize((150*K,57*K),Image.LANCZOS).save(A+'/header'+suf+'.bmp')
big.resize((328,628),Image.LANCZOS).save('/tmp/welcome_prev.png')
print('ok')
