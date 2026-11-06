"""Paired descriptive analysis: no minimum benefit or noise-derived gain gate."""
import math
import random
import statistics


def need(ok,why):
    if not ok:raise ValueError(why)


def medmad(xs):
    need(bool(xs) and all(math.isfinite(x) and x>0 for x in xs),'positive finite samples')
    m=statistics.median(xs)
    return m,statistics.median(abs(x-m)for x in xs)


def compare(rows,calibration,metric='wall_ns'):
    """Three within-process rounds are not treated as independent processes."""
    def processes(rs):
        result={}
        for r in rs:
            if r['round']<0:continue
            key=r['slot'];result.setdefault(key,[]).append(r)
        for slot,records in result.items():
            need(len({r['round']for r in records})==len(records),'duplicate round')
            need(len({r['arm']for r in records})==1,'mixed process arm')
        return {k:dict(arm=v[0]['arm'],value=medmad([r[metric]for r in v])[0])for k,v in result.items()}
    p=processes(rows);c=processes(calibration)
    need(sorted(p)==list(range(len(p))) and len(p)>=8 and len(p)%8==0,'complete balanced blocks')
    expected='ABBABAAB'*(len(p)//8)
    need(''.join(p[i]['arm']for i in range(len(p)))==expected,'frozen order')
    arms=[[r[metric]for r in rows if r['round']>=0 and r['arm']==a]for a in 'AB']
    am,ad=medmad(arms[0]);bm,bd=medmad(arms[1]);effects=[];orders={'ABBA':[],'BAAB':[]}
    for k in range(0,len(p),2):
        pair={p[i]['arm']:p[i]['value']for i in [k,k+1]}
        need(set(pair)=={'A','B'},'paired roles')
        effect=100*(1-pair['B']/pair['A']);effects.append(effect)
        orders['ABBA'if k%8<4 else'BAAB'].append(effect)
    point=statistics.median(effects)
    rng=random.Random(20261029)
    samples=sorted(statistics.median(rng.choices(effects,k=len(effects)))for _ in range(10000))
    lo,hi=samples[249],samples[9749]
    order_effects={k:statistics.median(v)for k,v in orders.items()}
    direction=('REPEATED_GAIN'if min(order_effects.values())>0 and lo>0 else
               'POSITIVE_TREND'if min(order_effects.values())>0 else
               'REPEATED_SLOWDOWN'if max(order_effects.values())<0 and hi<0 else
               'NEGATIVE_TREND'if max(order_effects.values())<0 else'ORDER_SENSITIVE')
    ca,cd=medmad([r[metric]for r in calibration if r['round']>=0])
    calarms={a:statistics.median(v['value']for v in c.values()if v['arm']==a)for a in 'AB'}
    return dict(metric=metric,baseline_median_ns=am,candidate_median_ns=bm,
                baseline_MAD_ns=ad,candidate_MAD_ns=bd,median_reduction_percent=100*(1-bm/am),
                paired_median_reduction_percent=point,paired_bootstrap_95_percent=[lo,hi],
                order_reduction_percent=order_effects,direction=direction,
                independent_pairs=len(effects),formal_samples=sum(r['round']>=0 for r in rows),
                calibration_MAD_percent=100*cd/ca,
                calibration_arm_difference_percent=100*(1-calarms['B']/calarms['A']),
                minimum_required_gain_percent=None,noise_derived_rejection=False)
