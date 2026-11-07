# RISC-V 基础软件优化

源码包包含 LLVM OpenMP/libomp、OpenBLAS RVV、QEMU 及 PETSc—PCSHELL—STRUMPACK 应用的源码、构建脚本和对照测试。

```text
源码与构建脚本/
  vendor/          libomp、OpenBLAS、PETSc、STRUMPACK、METIS、GKlib
  patches/         运行库、数学库和 QEMU 补丁
  components/      构建配置及补丁对应关系
  application/     PCSHELL 适配与热传导程序
  bench/           测试前端源码
  qemu/            QEMU 9.1.0 源码及构建脚本
  scripts/         离线构建入口
Benchtest/
  scripts/         测试与统计程序
  configs/         公共 API 测试参数
  tests/           测试源码
  qemu/            QEMU 测试程序、客体源码及启动入口
  results/         RISC-V、x86 和 QEMU 的原始结果
  normalized/      跨架构对照数据与图表
```

## 环境

组件和应用使用 riscv64 Linux、LP64D、RVV 1.0；数学优化与应用测试使用 VLEN=256。准备 Clang/Clang++ 21、GCC、gfortran、Python 3.10 以上、CMake 3.21–3.x、Ninja、GNU Make、patch 和 binutils。QEMU 另需 pkg-config、GLib 2 与 zlib 开发库。建议可用磁盘不少于 12 GB、内存不少于 8 GB。

## 构建组件与应用

在 RISC-V Linux 上执行：

```bash
cd 源码与构建脚本
CC=clang CXX=clang++ FC=gfortran python3 -B scripts/build.py --component all --jobs 2
```

输出位于 `源码与构建脚本/build/`：

| 目录 | 内容 |
|---|---|
| `install/omp/<profile>/lib` | libomp |
| `install/blas/<profile>/lib` | OpenBLAS 测量库 |
| `install/support/lib` | 完整 BLAS/LAPACK 支撑库 |
| `install/backend/lib` | STRUMPACK 与依赖 |
| `install/application/bin` | PETSc 热传导程序 |
| `install/bench/bin` | 测试前端 |
| `logs/` | 构建日志 |

可分别构建，也可使用 `--out` 指定新的构建目录：

```bash
python3 -B scripts/build.py --component openmp --profile batch --jobs 2
python3 -B scripts/build.py --component openblas --profile combined --jobs 2
python3 -B scripts/build.py --component application --jobs 2
python3 -B scripts/build.py --component bench --jobs 2
```

运行库业务基线为 `general`，优化配置为 `batch`。数学库基线为 `baseline`；`row-tail` 为 GEMV 行尾分对，`short-vector` 为短 AXPY，`trsv-fused` 为三角更新融合，`combined` 组合 TRSV 融合和短 AXPY。最终业务比较 `general + baseline` 与 `batch + combined`。

六项独立 OpenMP 修复位于 `patches/community/`，共九份 patch；配置位于 `components/openmp/community.json`：

| 配置 | 内容 | 源码底稿 |
|---|---|---|
| `frame-repair` | RV64 微任务调用帧 | `community-state` |
| `rounding-repair` | 复用线程舍入继承 | `community-state` |
| `ticket-repair` | ticket try-lock 发布获取 | `community-state` |
| `task-copy` | GNU 不延迟任务数据复制 | `community-copy` |
| `taskloop-strict` | GNU taskloop 严格分块标志 | `community-taskloop` |
| `taskloop-bounds` | taskloop 有符号与倒序边界 | `community-taskloop` |

构建某项修复时使用各自的配置，例如：

```bash
python3 -B scripts/build.py --component openmp --profile task-copy --jobs 2
```

## 运行 Benchtest

从仓库根目录进入 Benchtest，先运行正确性测试，再测量性能：

```bash
cd Benchtest
python3 -B scripts/run.py --build ../源码与构建脚本/build --suite correctness --out run-correctness
python3 -B scripts/run.py --build ../源码与构建脚本/build --suite components --out run-components
python3 -B scripts/run.py --build ../源码与构建脚本/build --suite application --out run-application
```

每次使用新的输出目录。组件测试需允许 CPU0–3；应用使用 CPU0/1、两个工作线程、64×64 网格和 100 步。应用分别输出完整进程墙钟、KSP 服务时间及后 99 次复用求解时间；KSP 包含复用阶段。

输出包括实际命令、环境、原始 stdout/stderr、逐轮数据与统计。采样采用预热、同库校准和 ABBA/BAAB 交替顺序。中位耗时下降定义为 `100 × (1 − T优化/T基线)`。

## x86 对照

x86 参考环境需要支持 AVX2/FMA，在 x86_64 Linux 上执行：

```bash
cd 源码与构建脚本
CC=clang CXX=clang++ python3 -B scripts/build.py --target x86 --component all --out build-x86 --jobs 2
cd ../Benchtest
python3 -B scripts/run.py --target x86 --build ../源码与构建脚本/build-x86 --suite correctness --out run-x86-correctness
python3 -B scripts/run.py --target x86 --build ../源码与构建脚本/build-x86 --suite components --out run-x86-components
```

运行库比较该平台上的 `general` 与 `batch`；x86 数学库使用同版本官方 HASWELL 实现作公共 API 参考。RVV 候选的前后对比在 RISC-V 上进行，以同形状 x86 结果显示优化前后的相对差距。

## QEMU 构建与测试

在 RISC-V Linux 上构建普通版和优化版：

```bash
cd 源码与构建脚本
python3 -B scripts/build.py --component qemu --qemu-profile composite --jobs 2
```

输出为 `build/qemu/baseline/qemu-system-riscv64` 和 `build/qemu/optimized/qemu-system-riscv64`。可用配置为 `baseline`、`qom-filter`、`virt-mmio-batch`、`rvv-vsetvl-fastpath`、`startup`、`composite`。两版使用相同的 configure 参数，在独立源码副本上应用所选补丁。

在 x86_64 Linux 上交叉构建时增加 `--target riscv-cross`，并提供 RISC-V GNU 工具链、目标 GLib/zlib 和正确的 `PKG_CONFIG_LIBDIR`。生成的 QEMU 在 RISC-V Linux 宿主上运行。

构建完成后，在 RISC-V Linux 上运行启动对照：

```bash
cd Benchtest
python3 -B qemu/run.py \
  --baseline ../源码与构建脚本/build/qemu/baseline/qemu-system-riscv64 \
  --optimized ../源码与构建脚本/build/qemu/optimized/qemu-system-riscv64 \
  --out run-qemu
```

客体程序源码位于 `qemu/guest/source/`，构建入口为：

```bash
RISCV_GCC=gcc bash qemu/guest/build.sh
```

在 x86 交叉环境中将 `RISCV_GCC` 设为 `riscv64-linux-gnu-gcc`。裸机测试使用 `--guest-elf`、`--guest-elf-checksum` 和 `--guest-programs`；Linux 客体测试使用运行环境提供的 `--guest-kernel`、`--guest-initrd`。各参数见 `python3 -B qemu/run.py --help`。

## 已保存结果

| 路径 | 内容 |
|---|---|
| `Benchtest/results/riscv-components/` | RISC-V 组件前后对比、41项结算及原始轮次 |
| `Benchtest/results/x86-components/` | x86 公共数学 API 和运行库前后对比 |
| `Benchtest/results/x86-correctness/` | x86 正确性参照 |
| `Benchtest/results/application-native/` | 最终原生应用基线与优化结果 |
| `Benchtest/results/qemu-components/` | QEMU 普通版与优化版的正确性和性能结果 |
| `Benchtest/results/qemu-final/` | 模拟器与客体基础库的 A/B/C/D 四臂结果 |
| `Benchtest/normalized/` | 归一化跨架构数据及图表 |

原始结果记录当时的版本、环境与命令。
