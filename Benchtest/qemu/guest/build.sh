#!/usr/bin/env bash
# 客体程序构建入口：用与历史记录一致的编译命令，从随包源码重建全部 QEMU 客体程序。
#
# 产物写入 GUEST_BUILD_OUT（默认本目录 build/）：
#   guest/*.elf          裸机客体（-kernel 直接加载）
#   linux/*              客体 Linux 静态程序（由运行者装入自备 initramfs/磁盘）
#   host/smoke-reference x86 主机参考程序
#   guest-programs.json  每个程序的源码路径与 sha256、编译命令、产物 sha256（供 run.py 记录）
#
# 要求：Linux 宿主（原生 RISC-V，或装有 riscv64-linux-gnu-gcc 交叉工具链的 x86_64）。
# Linux 内核、initramfs 和磁盘镜像由运行环境提供。
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"
SRC="$SCRIPT_DIR/source"
OUT="${GUEST_BUILD_OUT:-$SCRIPT_DIR/build}"
CC="${RISCV_GCC:-riscv64-linux-gnu-gcc}"
HOST_CC="${HOST_GCC:-gcc}"

if [[ ! -f "$SRC/fixtures/link.ld" || ! -f "$SRC/fixtures/start.S" ]]; then
    printf 'Error: guest sources not found at %s\n' "$SRC" >&2
    exit 2
fi
command -v "$CC" >/dev/null 2>&1 || {
    printf 'Error: RISC-V cross compiler not found: %s\n' "$CC" >&2
    exit 2
}
command -v "$HOST_CC" >/dev/null 2>&1 || {
    printf 'Error: host compiler not found: %s\n' "$HOST_CC" >&2
    exit 2
}
command -v python3 >/dev/null 2>&1 || {
    printf 'Error: python3 is required to record build provenance\n' >&2
    exit 2
}
command -v sha256sum >/dev/null 2>&1 || {
    printf 'Error: sha256sum is required to verify sources and record outputs\n' >&2
    exit 2
}
sha256sum -c sources.sha256 >/dev/null || {
    printf 'Error: guest source hash mismatch; sources were modified\n' >&2
    exit 2
}

mkdir -p "$OUT/guest" "$OUT/linux" "$OUT/host"

# 客体程序编译选项。
FREESTANDING=(-O2 -static -ffreestanding -fno-builtin -fno-tree-vectorize -fno-stack-protector
              -fno-pie -no-pie -nostdlib -nostartfiles -mabi=lp64d -mcmodel=medany
              -mno-relax -ffp-contract=off -Wl,--build-id=none)
LINUX=(-O2 -static -fno-tree-vectorize -ffp-contract=off -mabi=lp64d -Wl,--build-id=none)

RECORDS=()

# record <name> <output> <command...>
record() {
    local name="$1" output="$2"; shift 2
    local command=("$@")
    RECORDS+=("$(python3 - "$name" "$output" "${command[@]}" <<'PY'
import hashlib, json, sys
name, output = sys.argv[1], sys.argv[2]
command = sys.argv[3:]
def sha(path):
    h = hashlib.sha256()
    with open(path, 'rb') as f:
        for c in iter(lambda: f.read(1 << 20), b''):
            h.update(c)
    return h.hexdigest()
json.dump({'name': name, 'command': command, 'output': output, 'sha256': sha(output)}, sys.stdout)
PY
)")
    printf 'built %-22s %s\n' "$name" "$(sha256sum "$output" | cut -c1-16)..."
}

# build_elf <name> <march> <defines...> -- <source...>
build_elf() {
    local name="$1" march="$2"; shift 2
    local defines=()
    while [[ $# -gt 0 && "$1" != "--" ]]; do defines+=("$1"); shift; done
    shift
    local out="$OUT/guest/$name.elf"
    local command=("$CC" "${FREESTANDING[@]}" "-march=$march" "${defines[@]}"
                   -T "$SRC/fixtures/link.ld" "$SRC/fixtures/start.S" "$@" -o "$out")
    "${command[@]}"
    record "$name" "$out" "${command[@]}"
}

# build_linux <name> <march> <defines...> -- <source...>
build_linux() {
    local name="$1" march="$2"; shift 2
    local defines=()
    while [[ $# -gt 0 && "$1" != "--" ]]; do defines+=("$1"); shift; done
    shift
    local out="$OUT/linux/$name"
    local command=("$CC" "${LINUX[@]}" "-march=$march" "${defines[@]}" "$@" -o "$out")
    "${command[@]}"
    record "$name" "$out" "${command[@]}"
}

SRC_Q="$SRC/qemu"
SRC_REF="$SRC/reference"
SRC_BENCH="$SRC/benchmarks/qemu"

# 裸机客体（正确性负载）
for v in 128 256 512 1024; do build_elf "mixed-$v-64" rv64gcv "-DTEST_VLEN=$v" -DTEST_ELEN=64 -- "$SRC_Q/mixed.c"; done
for e in 8 16 32; do build_elf "mixed-128-$e" rv64gcv -DTEST_VLEN=128 "-DTEST_ELEN=$e" -- "$SRC_Q/mixed.c"; done
build_elf floating-128 rv64gcv -DTEST_VLEN=128 -- "$SRC_Q/floating.c"
build_elf floating-1024 rv64gcv -DTEST_VLEN=1024 -- "$SRC_Q/floating.c"
build_elf cache rv64gcv -- "$SRC_Q/cache.c"
build_elf faults rv64gcv -- "$SRC_Q/faults.c" "$SRC_Q/faults.S"
build_elf known-vl0 rv64gcv -- "$SRC_Q/vl0_reduction.c"
build_elf scalar rv64gc -- "$SRC_Q/scalar.c"
build_elf rvv-smoke rv64gcv -- "$SRC_Q/build_smoke.c"
build_elf cross-scalar rv64gc -- "$SRC_REF/cross_kernel.c"
build_elf cross-rvv rv64gcv -DCROSS_RVV -- "$SRC_REF/cross_kernel.c"

# 裸机客体（常量/动态/流水线性能负载，RVWORK 握手）
build_elf bench-constant rv64gcv -- "$SRC_BENCH/guest.c"
build_elf bench-dynamic rv64gcv -DBENCH_DYNAMIC -- "$SRC_BENCH/guest.c"
build_elf pipeline-scalar rv64gc -DPIPELINE_DUMP -- "$SRC_BENCH/pipeline.c"
build_elf pipeline-rvv rv64gcv -DPIPELINE_RVV -DPIPELINE_DUMP -- "$SRC_BENCH/pipeline.c"
build_elf bench-pipeline-scalar rv64gc -- "$SRC_BENCH/pipeline.c"
build_elf bench-pipeline-rvv rv64gcv -DPIPELINE_RVV -- "$SRC_BENCH/pipeline.c"

# 客体 Linux 静态程序（装入运行者自备 initramfs）
build_linux pipeline-scalar rv64gc -DPIPELINE_LINUX -DPIPELINE_DUMP -- "$SRC_BENCH/pipeline.c"
build_linux pipeline-rvv rv64gcv -DPIPELINE_LINUX -DPIPELINE_DUMP -DPIPELINE_RVV -- "$SRC_BENCH/pipeline.c"

# x86 主机参考（独立正确性对照）
REF_OUT="$OUT/host/smoke-reference"
REF_COMMAND=("$HOST_CC" -O2 -Wall -Wextra -Werror "$SRC_REF/smoke_reference.c" -o "$REF_OUT")
"${REF_COMMAND[@]}"
record smoke-reference "$REF_OUT" "${REF_COMMAND[@]}"

python3 - "$OUT" "$SRC" "${RECORDS[@]}" <<'PY'
import hashlib, json, os, sys
out, src, records = sys.argv[1], sys.argv[2], sys.argv[3:]
def sha(path):
    h = hashlib.sha256()
    with open(path, 'rb') as f:
        for c in iter(lambda: f.read(1 << 20), b''):
            h.update(c)
    return h.hexdigest()
programs = [json.loads(r) for r in records]
for p in programs:
    p['sources'] = {}
    for arg in p['command']:
        if arg.endswith(('.c', '.S', '.ld')):
            rel = os.path.relpath(arg, src).replace('\\', '/')
            p['sources'][rel] = sha(arg)
manifest = {'generated_for': 'Benchtest/qemu/run.py --guest-programs',
            'toolchain': programs[0]['command'][0] if programs else None,
            'programs': programs}
path = os.path.join(out, 'guest-programs.json')
open(path, 'w', encoding='utf-8').write(json.dumps(manifest, ensure_ascii=False, indent=2) + '\n')
print('manifest written:', path, len(programs), 'programs')
PY

printf '\nGuest programs built under %s/{guest,linux,host}/.\n' "$OUT"
