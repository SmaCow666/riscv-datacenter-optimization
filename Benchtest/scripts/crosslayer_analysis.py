"""2x2 settlement: arm medians, five direct comparisons, and the layer interaction.

Estimator conventions inherited unchanged from experiments/final-acceptance/analysis.py
(sha256 47180e2ad59a08a928f750bfab95b96d8feae331a7f91a262643142fe8c9ce24) as reused by
qemu-ab and system-line: median + MAD per arm, per-block paired effect 100*(1-cand/base),
median of the block effects, paired bootstrap 10,000 draws seed 20261029 keeping sorted
indices 249 and 9749, and the two order groups reported separately. No minimum-gain gate,
no noise-derived rejection.

Four arms in one Williams block (each unordered pair adjacent exactly twice, once in each
direction):
    A B D C / B C A D / C D B A / D A C B   repeated twice -> 8 blocks, 32 slots
    A = official QEMU  + P0 (core libomp, B OpenBLAS)
    B = official QEMU  + P4 (batch libomp, D OpenBLAS)
    C = optimised QEMU + P0
    D = optimised QEMU + P4
"""
import math
import random
import statistics

ORDER = ('ABDCBCADCDBADACB') * 2
ARMS = 'ABCD'
BLOCKS = len(ORDER) // 4
SEED = 20261029

# The five direct comparisons the round must report, and what each one isolates.
COMPARISONS = (
    ('guest_under_official_qemu', 'A', 'B'),
    ('qemu_under_stock_guest', 'A', 'C'),
    ('full_stack', 'A', 'D'),
    ('qemu_under_optimised_guest', 'B', 'D'),
    ('guest_under_optimised_qemu', 'C', 'D'),
)


def need(ok, why):
    if not ok:
        raise ValueError(why)


def medmad(xs):
    need(bool(xs) and all(math.isfinite(x) and x > 0 for x in xs), 'positive finite samples')
    m = statistics.median(xs)
    return m, statistics.median(abs(x - m) for x in xs)


def bootstrap_median(values):
    rng = random.Random(SEED)
    samples = sorted(statistics.median(rng.choices(values, k=len(values))) for _ in range(10000))
    return samples[249], samples[9749]


def _table(slots, metric):
    table = {(s['block'], s['arm']): s['value'][metric] for s in slots}
    blocks = sorted({s['block'] for s in slots})
    need(blocks == list(range(BLOCKS)), 'complete balanced blocks')
    for block in blocks:
        need(''.join(sorted(a for b, a in table if b == block)) == ARMS, 'one slot per arm per block')
    return table, blocks


def _position(block, arm):
    return ORDER[4 * block:4 * block + 4].index(arm)


def _verdict(groups, lo, hi):
    low, high = min(groups.values()), max(groups.values())
    if low > 0 and lo > 0:
        return 'REPEATED_GAIN'
    if low > 0:
        return 'POSITIVE_TREND'
    if high < 0 and hi < 0:
        return 'REPEATED_SLOWDOWN'
    if high < 0:
        return 'NEGATIVE_TREND'
    if not (low > 0 or high < 0):
        return 'FLAT'
    return 'ORDER_SENSITIVE'


def arm_summary(slots, metric):
    table, blocks = _table(slots, metric)
    out = {}
    for arm in ARMS:
        values = [table[(b, arm)] for b in blocks]
        m, mad = medmad(values)
        out[arm] = dict(median=m, MAD=mad, MAD_percent=100 * mad / m, samples=values)
    return out


def compare(slots, metric, base, cand):
    table, blocks = _table(slots, metric)
    bm, bmad = medmad([table[(b, base)] for b in blocks])
    cm, cmad = medmad([table[(b, cand)] for b in blocks])
    effects, groups = [], {'baseline_first': [], 'candidate_first': []}
    for block in blocks:
        effect = 100 * (1 - table[(block, cand)] / table[(block, base)])
        effects.append(effect)
        key = 'baseline_first' if _position(block, base) < _position(block, cand) else 'candidate_first'
        groups[key].append(effect)
    need(len(groups['baseline_first']) == 4 and len(groups['candidate_first']) == 4,
         'Williams positions must split each pair four and four')
    lo, hi = bootstrap_median(effects)
    order_effects = {k: statistics.median(v) for k, v in groups.items()}
    return dict(
        metric=metric, baseline=base, candidate=cand,
        baseline_median=bm, candidate_median=cm,
        baseline_MAD=bmad, candidate_MAD=cmad,
        baseline_MAD_percent=100 * bmad / bm, candidate_MAD_percent=100 * cmad / cm,
        median_reduction_percent=100 * (1 - cm / bm),
        speedup=bm / cm,
        paired_median_reduction_percent=statistics.median(effects),
        paired_bootstrap_95_percent=[lo, hi],
        order_reduction_percent=order_effects,
        direction=_verdict(order_effects, lo, hi),
        independent_pairs=len(effects),
        pair_effects=effects,
        minimum_required_gain_percent=None,
        noise_derived_rejection=False,
    )


def unit_of(metric):
    """Durations are stored in ns and reported in ms; the one resource metric is in kB."""
    return 'ms' if metric.endswith('_ns') else 'kB'


RATIO_TOLERANCE = 1e-9


def interaction(slots, metric, draws=10000):
    """I = (T_D * T_A) / (T_C * T_B): 1 independent, <1 synergy, >1 overlap.

    Also reports the same question additively, because a ratio of times and a difference of
    milliseconds answer different questions and the round must not pick one silently:
    additive_delta = (D - C) - (B - A) is the change in the guest-layer effect when the
    emulator layer changes. For a purely multiplicative, independent structure the additive
    difference is *not* zero -- it is A * g_guest * g_qemu (two 10% gains leave 19%, not
    20%), so a positive delta alone never means the layers overlap. The ratio decides; the
    difference locates.

    The verdict is not taken on differences inside RATIO_TOLERANCE of 1: a ratio of four
    medians computed in floating point lands within ~1e-15 of 1 when the two layers really
    are independent, and that rounding must not be read as overlap.
    """
    table, blocks = _table(slots, metric)
    per_unit = 1e6 if unit_of(metric) == 'ms' else 1.0

    def aggregate(picked):
        return {arm: statistics.median([table[(b, arm)] for b in picked]) / per_unit
                for arm in ARMS}

    def ratio(m):
        return (m['D'] * m['A']) / (m['C'] * m['B'])

    def additive(m):
        return (m['D'] - m['C']) - (m['B'] - m['A'])

    medians = aggregate(blocks)
    per_block = [ratio({arm: table[(b, arm)] / per_unit for arm in ARMS}) for b in blocks]

    rng = random.Random(SEED)
    ratios, deltas = [], []
    for _ in range(draws):
        m = aggregate(rng.choices(blocks, k=len(blocks)))
        ratios.append(ratio(m))
        deltas.append(additive(m))
    ratios.sort()
    deltas.sort()
    lo, hi = ratios[249], ratios[9749]
    if hi < 1 - RATIO_TOLERANCE:
        verdict = 'SYNERGY'
    elif lo > 1 + RATIO_TOLERANCE:
        verdict = 'OVERLAP'
    else:
        verdict = 'INDEPENDENT_OR_NOT_DISTINGUISHABLE'
    return dict(
        metric=metric, definition='I = (T_D * T_A) / (T_C * T_B)',
        point=ratio(medians),
        bootstrap_95_percent=[lo, hi],
        median_of_block_ratios=statistics.median(per_block),
        per_block=per_block, verdict=verdict, seed=SEED, draws=draws,
        ratio_tolerance=RATIO_TOLERANCE,
        additive_delta=additive(medians), additive_delta_unit=unit_of(metric),
        additive_delta_bootstrap_95_percent=[deltas[249], deltas[9749]],
        arm_medians=medians, arm_median_unit=unit_of(metric),
        note='ratio and additive delta come from the same 8 blocks; neither is derived from '
             'history. additive_delta = A * g_guest * g_qemu for independent proportional '
             'gains, so it is not an overlap indicator on its own',
    )


def effect_modification(slots, metric):
    """The same layer effect measured under both levels of the other layer."""
    out = {}
    for name, one, two in (('guest_effect', ('A', 'B'), ('C', 'D')),
                           ('qemu_effect', ('A', 'C'), ('B', 'D'))):
        first, second = compare(slots, metric, *one), compare(slots, metric, *two)
        out[name] = dict(
            low_level=dict(pair=list(one), percent=first['median_reduction_percent'],
                           delta_ms=first['candidate_median'] - first['baseline_median'],
                           direction=first['direction']),
            high_level=dict(pair=list(two), percent=second['median_reduction_percent'],
                            delta_ms=second['candidate_median'] - second['baseline_median'],
                            direction=second['direction']),
            percent_gap=second['paired_median_reduction_percent']
            - first['paired_median_reduction_percent'],
            note='low/high refer to the other layer: guest effect under official/optimised QEMU, '
                 'or QEMU effect under stock/optimised guest')
    return out
