"""Paired descriptive analysis: median + MAD, paired bootstrap, two-order directions.

Same estimator as the system-line acceptance (experiments/final-acceptance/analysis.py,
sha256 47180e2ad59a08a928f750bfab95b96d8feae331a7f91a262643142fe8c9ce24), extended so the
same-arm calibration block is optional. No minimum-benefit gate and no noise-derived rejection.

One "process" is one slot of the frozen order. Three formal rounds are reduced to the slot
median before pairing, so three rounds never count as three independent processes.
"""
import math
import random
import statistics


def need(ok, why):
    if not ok:
        raise ValueError(why)


def medmad(xs):
    need(bool(xs) and all(math.isfinite(x) and x > 0 for x in xs), 'positive finite samples')
    m = statistics.median(xs)
    return m, statistics.median(abs(x - m) for x in xs)


def order_direction(order_effects):
    positive = min(order_effects.values()) > 0
    negative = max(order_effects.values()) < 0
    return 'POSITIVE' if positive else 'NEGATIVE' if negative else 'MIXED'


def compare(rows, calibration, metric):
    """rows: dicts with slot, arm, round (-1 warmup, >=0 formal), metric. calibration: same or None."""
    def processes(rs):
        result = {}
        for r in rs:
            if r['round'] < 0:
                continue
            key = r['slot']
            result.setdefault(key, []).append(r)
        for slot, records in result.items():
            need(len({r['round'] for r in records}) == len(records), 'duplicate round')
            need(len({r['arm'] for r in records}) == 1, 'mixed process arm')
        return {k: dict(arm=v[0]['arm'], value=medmad([r[metric] for r in v])[0])
                for k, v in result.items()}

    p = processes(rows)
    need(sorted(p) == list(range(len(p))) and len(p) >= 8 and len(p) % 8 == 0, 'complete balanced blocks')
    expected = 'ABBABAAB' * (len(p) // 8)
    need(''.join(p[i]['arm'] for i in range(len(p))) == expected, 'frozen order')
    arms = [[r[metric] for r in rows if r['round'] >= 0 and r['arm'] == a] for a in 'AB']
    am, ad = medmad(arms[0])
    bm, bd = medmad(arms[1])
    effects = []
    orders = {'ABBA': [], 'BAAB': []}
    for k in range(0, len(p), 2):
        pair = {p[i]['arm']: p[i]['value'] for i in [k, k + 1]}
        need(set(pair) == {'A', 'B'}, 'paired roles')
        effect = 100 * (1 - pair['B'] / pair['A'])
        effects.append(effect)
        orders['ABBA' if k % 8 < 4 else 'BAAB'].append(effect)
    point = statistics.median(effects)
    rng = random.Random(20261029)
    samples = sorted(statistics.median(rng.choices(effects, k=len(effects))) for _ in range(10000))
    lo, hi = samples[249], samples[9749]
    order_effects = {k: statistics.median(v) for k, v in orders.items()}
    any_positive = max(order_effects.values()) > 0
    any_negative = min(order_effects.values()) < 0
    if min(order_effects.values()) > 0 and lo > 0:
        direction = 'REPEATED_GAIN'
    elif min(order_effects.values()) > 0:
        direction = 'POSITIVE_TREND'
    elif max(order_effects.values()) < 0 and hi < 0:
        direction = 'REPEATED_SLOWDOWN'
    elif max(order_effects.values()) < 0:
        direction = 'NEGATIVE_TREND'
    elif not any_positive and not any_negative:
        direction = 'FLAT'
    else:
        direction = 'ORDER_SENSITIVE'
    out = dict(
        metric=metric,
        baseline_median=am, candidate_median=bm,
        baseline_MAD=ad, candidate_MAD=bd,
        baseline_MAD_percent=100 * ad / am, candidate_MAD_percent=100 * bd / bm,
        median_reduction_percent=100 * (1 - bm / am),
        speedup=am / bm,
        paired_median_reduction_percent=point,
        paired_bootstrap_95_percent=[lo, hi],
        order_reduction_percent=order_effects,
        direction=direction,
        independent_pairs=len(effects),
        formal_samples=sum(r['round'] >= 0 for r in rows),
        minimum_required_gain_percent=None,
        noise_derived_rejection=False,
    )
    if calibration:
        c = processes(calibration)
        need(sorted(c) == list(range(len(c))) and len(c) >= 8, 'complete calibration block')
        ca, cd = medmad([r[metric] for r in calibration if r['round'] >= 0])
        calarms = {a: statistics.median(v['value'] for v in c.values() if v['arm'] == a) for a in 'AB'}
        out.update(calibration_MAD_percent=100 * cd / ca,
                   calibration_arm_difference_percent=100 * (1 - calarms['B'] / calarms['A']))
    return out
