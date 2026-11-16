# Simulación aproximada del ritmo de la economía (no es código del juego: es documentación).
# Un "jugador medio" va a la bóveda más alta que tiene abierta, atrapa un bicho, vuelve al
# santuario, cobra y gasta: primero en la siguiente bóveda y, si no le llega, en mejoras baratas.
# Uso: python3 design/simulacion_economia.py
# Los números del juego están en src/shared/Config; si los cambias allí, cámbialos aquí también.
import random
# Simulación simple del ritmo (un jugador "medio").
CRIT=[("pez",1,"C","Playa"),("cangrejo",2,"C","Playa"),("tostada",5,"P","Playa"),("seta",15,"P","Bosque"),("cactus",40,"R","Bosque"),("roca",300,"E","Volcan"),("nube",2500,"L","Nube")]
W={"C":60,"P":25,"R":10,"E":4,"L":1}
WIN={"C":.35,"P":.25,"R":.18,"E":.12,"L":.08}
THEMES=["Playa","Bosque","Volcan","Nube"]
def run(costs, endless_growth=4, value_growth=3, replace=True, sell_s=30, seed=0, minutes=40, slots0=3, upg=dict(Santuario=(100,2.0),Botas=(40,1.7),Red=(50,1.8))):
    r=random.Random(seed)
    coins=0; t=0; maxv=1; crit=[]; lv=dict(Santuario=0,Botas=0,Red=0)
    times={}
    def cost(n):
        if n<=4: return costs[n-1]
        return costs[3]*endless_growth**(n-4)
    def pool(n):
        return [c for c in CRIT if n>4 or c[3]==THEMES[n-1]]
    def mult(n): return 1 if n<=4 else round(value_growth**(n-4))
    def income(): return sum(x for x in crit[:slots()])
    def slots(): return slots0+lv["Santuario"]
    # tutorial critter
    t+=15; crit.append(1)
    while t<minutes*60:
        n=maxv
        p=pool(n); 
        # weight
        tot=sum(W[c[2]] for c in p); x=r.uniform(0,tot)
        for c in p:
            x-=W[c[2]]
            if x<=0: break
        speed=16+lv["Botas"]
        dist=60+40+100*(n-1)+30
        trip=2*dist/speed+6
        # catch attempts
        pwin=min(.9,WIN[c[2]]+.02*lv["Red"])*1.6  # jugador apunta algo mejor que azar
        pwin=min(pwin,.95)
        tries=1
        while r.random()>pwin: tries+=1
        dt=trip+tries*4
        coins+=income()*dt; t+=dt
        val=c[1]*mult(n)
        if len(crit)<slots(): crit.append(val)
        elif replace:
            m=min(crit)
            if val>m:
                crit.remove(m); crit.append(val); coins+=m*sell_s
        # spend
        changed=True
        while changed:
            changed=False
            if coins>=cost(maxv+1):
                coins-=cost(maxv+1); maxv+=1; times[maxv]=t; changed=True; continue
            # santuario if full
            for name in ["Santuario","Botas","Red"]:
                b,g=upg[name]; c2=b*g**lv[name]
                if (name!="Santuario" or len(crit)>=slots()) and coins>=c2 and c2< cost(maxv+1)*0.35 and lv[name]<(12 if name=="Santuario" else 10):
                    coins-=c2; lv[name]+=1; changed=True; break
    return times
def avg(costs,**kw):
    acc={}
    N=200
    for s in range(N):
        for k,v in run(costs,seed=s,**kw).items(): acc.setdefault(k,[]).append(v/60)
    return {k:(round(sorted(v)[len(v)//2],1),len(v)) for k,v in sorted(acc.items())}

if __name__ == "__main__":
    print("Minuto mediano en que se abre cada bóveda (bóveda: (minuto, jugadores de 200 que llegan en 40 min))")
    print("Antes:   ", avg([0, 2500, 40000, 600000], replace=False))
    print("Ahora:   ", avg([0, 1000, 18000, 300000]))
