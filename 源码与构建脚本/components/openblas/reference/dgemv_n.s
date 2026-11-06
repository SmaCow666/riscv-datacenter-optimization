	.attribute	4, 16
	.attribute	5, "rv64i2p1_m2p0_a2p1_f2p2_d2p2_c2p0_v1p0_zicsr2p0_zmmul1p0_zaamo1p0_zalrsc1p0_zca1p0_zcd1p0_zve32f1p0_zve32x1p0_zve64d1p0_zve64f1p0_zve64x1p0_zvl128b1p0_zvl256b1p0_zvl32b1p0_zvl64b1p0"
	.file	"gemv_n_vector.c"
	.file	1 "/home/uiniu/CodeData/riscv-ai-platform" "output/clang21-audit-r1/prefix/usr/lib/llvm-21/lib/clang/21/include/__stddef_size_t.h"
	.text
	.globl	dgemv_n                         # -- Begin function dgemv_n
	.p2align	1
	.type	dgemv_n,@function
dgemv_n:                                # @dgemv_n
.Lfunc_begin0:
	.cfi_startproc
# %bb.0:
	#DEBUG_VALUE: dgemv_n:m <- $x10
	#DEBUG_VALUE: dgemv_n:n <- $x11
	#DEBUG_VALUE: dgemv_n:dummy1 <- $x12
	#DEBUG_VALUE: dgemv_n:alpha <- $f10_d
	#DEBUG_VALUE: dgemv_n:a <- $x13
	#DEBUG_VALUE: dgemv_n:lda <- $x14
	#DEBUG_VALUE: dgemv_n:x <- $x15
	#DEBUG_VALUE: dgemv_n:inc_x <- $x16
	#DEBUG_VALUE: dgemv_n:y <- $x17
	#DEBUG_VALUE: dgemv_n:inc_y <- [DW_OP_plus_uconst 32] [$x2+0]
	#DEBUG_VALUE: dgemv_n:buffer <- [DW_OP_plus_uconst 40] [$x2+0]
	.file	2 "/home/uiniu/CodeData/riscv-ai-platform" "experiments/openblas-rvv/results/2026-10-26_r192-schedule-counter-r1/llvm-tuning/build-r2/gemv_n_vector.c"
	.loc	2 60 11 prologue_end            # experiments/openblas-rvv/results/2026-10-26_r192-schedule-counter-r1/llvm-tuning/build-r2/gemv_n_vector.c:60:11
	bltz	a1, .LBB0_32
.Ltmp0:
# %bb.1:
	#DEBUG_VALUE: dgemv_n:buffer <- [DW_OP_plus_uconst 40] [$x2+0]
	#DEBUG_VALUE: dgemv_n:inc_y <- [DW_OP_plus_uconst 32] [$x2+0]
	#DEBUG_VALUE: dgemv_n:y <- $x17
	#DEBUG_VALUE: dgemv_n:inc_x <- $x16
	#DEBUG_VALUE: dgemv_n:x <- $x15
	#DEBUG_VALUE: dgemv_n:lda <- $x14
	#DEBUG_VALUE: dgemv_n:a <- $x13
	#DEBUG_VALUE: dgemv_n:alpha <- $f10_d
	#DEBUG_VALUE: dgemv_n:dummy1 <- $x12
	#DEBUG_VALUE: dgemv_n:n <- $x11
	#DEBUG_VALUE: dgemv_n:m <- $x10
	addi	sp, sp, -32
	.cfi_def_cfa_offset 32
	sd	s0, 24(sp)                      # 8-byte Folded Spill
	sd	s1, 16(sp)                      # 8-byte Folded Spill
	sd	s2, 8(sp)                       # 8-byte Folded Spill
	sd	s3, 0(sp)                       # 8-byte Folded Spill
	.cfi_offset s0, -8
	.cfi_offset s1, -16
	.cfi_offset s2, -24
	.cfi_offset s3, -32
	ld	t0, 32(sp)
	li	a2, 1
.Ltmp1:
	.loc	2 66 15                         # experiments/openblas-rvv/results/2026-10-26_r192-schedule-counter-r1/llvm-tuning/build-r2/gemv_n_vector.c:66:15
	bne	t0, a2, .LBB0_21
.Ltmp2:
# %bb.2:
	#DEBUG_VALUE: dgemv_n:y <- $x17
	#DEBUG_VALUE: dgemv_n:inc_x <- $x16
	#DEBUG_VALUE: dgemv_n:x <- $x15
	#DEBUG_VALUE: dgemv_n:lda <- $x14
	#DEBUG_VALUE: dgemv_n:a <- $x13
	#DEBUG_VALUE: dgemv_n:alpha <- $f10_d
	#DEBUG_VALUE: dgemv_n:n <- $x11
	#DEBUG_VALUE: dgemv_n:m <- $x10
	.loc	2 0 15 is_stmt 0                # experiments/openblas-rvv/results/2026-10-26_r192-schedule-counter-r1/llvm-tuning/build-r2/gemv_n_vector.c:0:15
	li	a2, 4
.Ltmp3:
	.loc	2 68 30 is_stmt 1               # experiments/openblas-rvv/results/2026-10-26_r192-schedule-counter-r1/llvm-tuning/build-r2/gemv_n_vector.c:68:30
	vsetvli	t5, zero, e64, m8, ta, ma
.Ltmp4:
	#DEBUG_VALUE: epr <- $x30
	#DEBUG_VALUE: dgemv_n:j <- 0
	.loc	2 0 30 is_stmt 0                # experiments/openblas-rvv/results/2026-10-26_r192-schedule-counter-r1/llvm-tuning/build-r2/gemv_n_vector.c:0:30
	li	t0, 0
.Ltmp5:
	.loc	2 80 9 is_stmt 1                # experiments/openblas-rvv/results/2026-10-26_r192-schedule-counter-r1/llvm-tuning/build-r2/gemv_n_vector.c:80:9
	bgeu	a1, a2, .LBB0_4
	j	.LBB0_14
.Ltmp6:
.LBB0_3:                                #   in Loop: Header=BB0_4 Depth=1
	#DEBUG_VALUE: epr <- $x30
	#DEBUG_VALUE: dgemv_n:y <- $x17
	#DEBUG_VALUE: dgemv_n:inc_x <- $x16
	#DEBUG_VALUE: dgemv_n:x <- $x15
	#DEBUG_VALUE: dgemv_n:lda <- $x14
	#DEBUG_VALUE: dgemv_n:a <- $x13
	#DEBUG_VALUE: dgemv_n:alpha <- $f10_d
	#DEBUG_VALUE: dgemv_n:n <- $x11
	#DEBUG_VALUE: dgemv_n:m <- $x10
	#DEBUG_VALUE: dgemv_n:j <- $x5
	.loc	2 80 23                         # experiments/openblas-rvv/results/2026-10-26_r192-schedule-counter-r1/llvm-tuning/build-r2/gemv_n_vector.c:80:23
	addi	a2, t0, 4
.Ltmp7:
	.loc	2 80 9 is_stmt 0                # experiments/openblas-rvv/results/2026-10-26_r192-schedule-counter-r1/llvm-tuning/build-r2/gemv_n_vector.c:80:9
	blt	a1, a2, .LBB0_14
.Ltmp8:
.LBB0_4:                                # =>This Loop Header: Depth=1
                                        #     Child Loop BB0_6 Depth 2
	#DEBUG_VALUE: epr <- $x30
	#DEBUG_VALUE: dgemv_n:y <- $x17
	#DEBUG_VALUE: dgemv_n:inc_x <- $x16
	#DEBUG_VALUE: dgemv_n:x <- $x15
	#DEBUG_VALUE: dgemv_n:lda <- $x14
	#DEBUG_VALUE: dgemv_n:a <- $x13
	#DEBUG_VALUE: dgemv_n:alpha <- $f10_d
	#DEBUG_VALUE: dgemv_n:n <- $x11
	#DEBUG_VALUE: dgemv_n:m <- $x10
	.loc	2 81 38 is_stmt 1               # experiments/openblas-rvv/results/2026-10-26_r192-schedule-counter-r1/llvm-tuning/build-r2/gemv_n_vector.c:81:38
	mul	t1, t0, a4
	.loc	2 82 33                         # experiments/openblas-rvv/results/2026-10-26_r192-schedule-counter-r1/llvm-tuning/build-r2/gemv_n_vector.c:82:33
	addi	s0, t0, 1
	.loc	2 83 33                         # experiments/openblas-rvv/results/2026-10-26_r192-schedule-counter-r1/llvm-tuning/build-r2/gemv_n_vector.c:83:33
	addi	t3, t0, 2
	.loc	2 84 33                         # experiments/openblas-rvv/results/2026-10-26_r192-schedule-counter-r1/llvm-tuning/build-r2/gemv_n_vector.c:84:33
	addi	t2, t0, 3
	.loc	2 85 42                         # experiments/openblas-rvv/results/2026-10-26_r192-schedule-counter-r1/llvm-tuning/build-r2/gemv_n_vector.c:85:42
	mul	s1, t0, a6
	mv	t0, a2
.Ltmp9:
	#DEBUG_VALUE: dgemv_n:j <- undef
	.loc	2 81 28                         # experiments/openblas-rvv/results/2026-10-26_r192-schedule-counter-r1/llvm-tuning/build-r2/gemv_n_vector.c:81:28
	slli	t1, t1, 3
	.loc	2 82 38                         # experiments/openblas-rvv/results/2026-10-26_r192-schedule-counter-r1/llvm-tuning/build-r2/gemv_n_vector.c:82:38
	mul	s2, s0, a4
	.loc	2 83 38                         # experiments/openblas-rvv/results/2026-10-26_r192-schedule-counter-r1/llvm-tuning/build-r2/gemv_n_vector.c:83:38
	mul	t4, t3, a4
	.loc	2 84 38                         # experiments/openblas-rvv/results/2026-10-26_r192-schedule-counter-r1/llvm-tuning/build-r2/gemv_n_vector.c:84:38
	mul	t6, t2, a4
	.loc	2 85 32                         # experiments/openblas-rvv/results/2026-10-26_r192-schedule-counter-r1/llvm-tuning/build-r2/gemv_n_vector.c:85:32
	slli	s3, s1, 3
	.loc	2 86 42                         # experiments/openblas-rvv/results/2026-10-26_r192-schedule-counter-r1/llvm-tuning/build-r2/gemv_n_vector.c:86:42
	mul	s0, s0, a6
	.loc	2 87 42                         # experiments/openblas-rvv/results/2026-10-26_r192-schedule-counter-r1/llvm-tuning/build-r2/gemv_n_vector.c:87:42
	mul	a2, t3, a6
	.loc	2 88 42                         # experiments/openblas-rvv/results/2026-10-26_r192-schedule-counter-r1/llvm-tuning/build-r2/gemv_n_vector.c:88:42
	mul	s1, t2, a6
	.loc	2 81 28                         # experiments/openblas-rvv/results/2026-10-26_r192-schedule-counter-r1/llvm-tuning/build-r2/gemv_n_vector.c:81:28
	add	t3, a3, t1
.Ltmp10:
	#DEBUG_VALUE: ap0 <- $x28
	.loc	2 82 28                         # experiments/openblas-rvv/results/2026-10-26_r192-schedule-counter-r1/llvm-tuning/build-r2/gemv_n_vector.c:82:28
	slli	s2, s2, 3
	.loc	2 83 28                         # experiments/openblas-rvv/results/2026-10-26_r192-schedule-counter-r1/llvm-tuning/build-r2/gemv_n_vector.c:83:28
	slli	t2, t4, 3
	.loc	2 84 28                         # experiments/openblas-rvv/results/2026-10-26_r192-schedule-counter-r1/llvm-tuning/build-r2/gemv_n_vector.c:84:28
	slli	t1, t6, 3
	.loc	2 85 32                         # experiments/openblas-rvv/results/2026-10-26_r192-schedule-counter-r1/llvm-tuning/build-r2/gemv_n_vector.c:85:32
	add	s3, s3, a5
	.loc	2 86 32                         # experiments/openblas-rvv/results/2026-10-26_r192-schedule-counter-r1/llvm-tuning/build-r2/gemv_n_vector.c:86:32
	slli	s0, s0, 3
	.loc	2 87 32                         # experiments/openblas-rvv/results/2026-10-26_r192-schedule-counter-r1/llvm-tuning/build-r2/gemv_n_vector.c:87:32
	slli	a2, a2, 3
	.loc	2 88 32                         # experiments/openblas-rvv/results/2026-10-26_r192-schedule-counter-r1/llvm-tuning/build-r2/gemv_n_vector.c:88:32
	slli	s1, s1, 3
	.loc	2 82 28                         # experiments/openblas-rvv/results/2026-10-26_r192-schedule-counter-r1/llvm-tuning/build-r2/gemv_n_vector.c:82:28
	add	t4, a3, s2
.Ltmp11:
	#DEBUG_VALUE: ap1 <- $x29
	.loc	2 83 28                         # experiments/openblas-rvv/results/2026-10-26_r192-schedule-counter-r1/llvm-tuning/build-r2/gemv_n_vector.c:83:28
	add	t2, t2, a3
.Ltmp12:
	#DEBUG_VALUE: ap2 <- $x7
	.loc	2 84 28                         # experiments/openblas-rvv/results/2026-10-26_r192-schedule-counter-r1/llvm-tuning/build-r2/gemv_n_vector.c:84:28
	add	t1, t1, a3
.Ltmp13:
	#DEBUG_VALUE: ap3 <- $x6
	.loc	2 86 32                         # experiments/openblas-rvv/results/2026-10-26_r192-schedule-counter-r1/llvm-tuning/build-r2/gemv_n_vector.c:86:32
	add	s0, s0, a5
	.loc	2 87 32                         # experiments/openblas-rvv/results/2026-10-26_r192-schedule-counter-r1/llvm-tuning/build-r2/gemv_n_vector.c:87:32
	add	a2, a2, a5
	.loc	2 88 32                         # experiments/openblas-rvv/results/2026-10-26_r192-schedule-counter-r1/llvm-tuning/build-r2/gemv_n_vector.c:88:32
	add	s1, s1, a5
	.loc	2 85 32                         # experiments/openblas-rvv/results/2026-10-26_r192-schedule-counter-r1/llvm-tuning/build-r2/gemv_n_vector.c:85:32
	fld	fa5, 0(s3)
	.loc	2 86 32                         # experiments/openblas-rvv/results/2026-10-26_r192-schedule-counter-r1/llvm-tuning/build-r2/gemv_n_vector.c:86:32
	fld	fa4, 0(s0)
	.loc	2 87 32                         # experiments/openblas-rvv/results/2026-10-26_r192-schedule-counter-r1/llvm-tuning/build-r2/gemv_n_vector.c:87:32
	fld	fa1, 0(a2)
	.loc	2 88 32                         # experiments/openblas-rvv/results/2026-10-26_r192-schedule-counter-r1/llvm-tuning/build-r2/gemv_n_vector.c:88:32
	fld	ft0, 0(s1)
	.loc	2 85 30                         # experiments/openblas-rvv/results/2026-10-26_r192-schedule-counter-r1/llvm-tuning/build-r2/gemv_n_vector.c:85:30
	fmul.d	fa3, fa0, fa5
.Ltmp14:
	#DEBUG_VALUE: t0 <- $f13_d
	.loc	2 86 30                         # experiments/openblas-rvv/results/2026-10-26_r192-schedule-counter-r1/llvm-tuning/build-r2/gemv_n_vector.c:86:30
	fmul.d	fa2, fa0, fa4
.Ltmp15:
	#DEBUG_VALUE: t1 <- $f12_d
	.loc	2 87 30                         # experiments/openblas-rvv/results/2026-10-26_r192-schedule-counter-r1/llvm-tuning/build-r2/gemv_n_vector.c:87:30
	fmul.d	fa4, fa0, fa1
.Ltmp16:
	#DEBUG_VALUE: t2 <- $f14_d
	.loc	2 88 30                         # experiments/openblas-rvv/results/2026-10-26_r192-schedule-counter-r1/llvm-tuning/build-r2/gemv_n_vector.c:88:30
	fmul.d	fa5, fa0, ft0
.Ltmp17:
	#DEBUG_VALUE: t3 <- $f15_d
	#DEBUG_VALUE: dgemv_n:i <- 0
	.loc	2 0 30 is_stmt 0                # experiments/openblas-rvv/results/2026-10-26_r192-schedule-counter-r1/llvm-tuning/build-r2/gemv_n_vector.c:0:30
	li	s1, 0
.Ltmp18:
	.loc	2 90 13 is_stmt 1               # experiments/openblas-rvv/results/2026-10-26_r192-schedule-counter-r1/llvm-tuning/build-r2/gemv_n_vector.c:90:13
	blt	a0, t5, .LBB0_7
.Ltmp19:
# %bb.5:                                #   in Loop: Header=BB0_4 Depth=1
	#DEBUG_VALUE: dgemv_n:i <- 0
	#DEBUG_VALUE: t3 <- $f15_d
	#DEBUG_VALUE: t2 <- $f14_d
	#DEBUG_VALUE: t1 <- $f12_d
	#DEBUG_VALUE: t0 <- $f13_d
	#DEBUG_VALUE: ap3 <- $x6
	#DEBUG_VALUE: ap2 <- $x7
	#DEBUG_VALUE: ap1 <- $x29
	#DEBUG_VALUE: ap0 <- $x28
	#DEBUG_VALUE: epr <- $x30
	#DEBUG_VALUE: dgemv_n:y <- $x17
	#DEBUG_VALUE: dgemv_n:inc_x <- $x16
	#DEBUG_VALUE: dgemv_n:x <- $x15
	#DEBUG_VALUE: dgemv_n:lda <- $x14
	#DEBUG_VALUE: dgemv_n:a <- $x13
	#DEBUG_VALUE: dgemv_n:alpha <- $f10_d
	#DEBUG_VALUE: dgemv_n:n <- $x11
	#DEBUG_VALUE: dgemv_n:m <- $x10
	.loc	2 0 13 is_stmt 0                # experiments/openblas-rvv/results/2026-10-26_r192-schedule-counter-r1/llvm-tuning/build-r2/gemv_n_vector.c:0:13
	li	a2, 0
	vsetvli	s0, zero, e64, m8, ta, ma
.Ltmp20:
.LBB0_6:                                #   Parent Loop BB0_4 Depth=1
                                        # =>  This Inner Loop Header: Depth=2
	#DEBUG_VALUE: t3 <- $f15_d
	#DEBUG_VALUE: t2 <- $f14_d
	#DEBUG_VALUE: t1 <- $f12_d
	#DEBUG_VALUE: t0 <- $f13_d
	#DEBUG_VALUE: ap3 <- $x6
	#DEBUG_VALUE: ap2 <- $x7
	#DEBUG_VALUE: ap1 <- $x29
	#DEBUG_VALUE: ap0 <- $x28
	#DEBUG_VALUE: epr <- $x30
	#DEBUG_VALUE: dgemv_n:y <- $x17
	#DEBUG_VALUE: dgemv_n:inc_x <- $x16
	#DEBUG_VALUE: dgemv_n:x <- $x15
	#DEBUG_VALUE: dgemv_n:lda <- $x14
	#DEBUG_VALUE: dgemv_n:a <- $x13
	#DEBUG_VALUE: dgemv_n:alpha <- $f10_d
	#DEBUG_VALUE: dgemv_n:n <- $x11
	#DEBUG_VALUE: dgemv_n:m <- $x10
	#DEBUG_VALUE: dgemv_n:i <- $x12
	.loc	2 91 27 is_stmt 1               # experiments/openblas-rvv/results/2026-10-26_r192-schedule-counter-r1/llvm-tuning/build-r2/gemv_n_vector.c:91:27
	slli	s0, a2, 3
	add	t6, a7, s0
.Ltmp21:
	#DEBUG_VALUE: dgemv_n:y_ptr <- $x31
	.loc	2 93 60                         # experiments/openblas-rvv/results/2026-10-26_r192-schedule-counter-r1/llvm-tuning/build-r2/gemv_n_vector.c:93:60
	add	a2, t2, s0
.Ltmp22:
	.loc	2 93 45 is_stmt 0               # experiments/openblas-rvv/results/2026-10-26_r192-schedule-counter-r1/llvm-tuning/build-r2/gemv_n_vector.c:93:45
	vle64.v	v0, (a2)
	.loc	2 94 60 is_stmt 1               # experiments/openblas-rvv/results/2026-10-26_r192-schedule-counter-r1/llvm-tuning/build-r2/gemv_n_vector.c:94:60
	add	a2, t4, s0
	.loc	2 92 22                         # experiments/openblas-rvv/results/2026-10-26_r192-schedule-counter-r1/llvm-tuning/build-r2/gemv_n_vector.c:92:22
	vle64.v	v24, (t6)
.Ltmp23:
	#DEBUG_VALUE: dgemv_n:vy <- undef
	.loc	2 94 45                         # experiments/openblas-rvv/results/2026-10-26_r192-schedule-counter-r1/llvm-tuning/build-r2/gemv_n_vector.c:94:45
	vle64.v	v16, (a2)
	.loc	2 95 60                         # experiments/openblas-rvv/results/2026-10-26_r192-schedule-counter-r1/llvm-tuning/build-r2/gemv_n_vector.c:95:60
	add	a2, t3, s0
	.loc	2 96 60                         # experiments/openblas-rvv/results/2026-10-26_r192-schedule-counter-r1/llvm-tuning/build-r2/gemv_n_vector.c:96:60
	add	s0, s0, t1
	.loc	2 95 45                         # experiments/openblas-rvv/results/2026-10-26_r192-schedule-counter-r1/llvm-tuning/build-r2/gemv_n_vector.c:95:45
	vle64.v	v8, (a2)
	.loc	2 93 22                         # experiments/openblas-rvv/results/2026-10-26_r192-schedule-counter-r1/llvm-tuning/build-r2/gemv_n_vector.c:93:22
	vfmadd.vf	v8, fa3, v24
	.loc	2 96 45                         # experiments/openblas-rvv/results/2026-10-26_r192-schedule-counter-r1/llvm-tuning/build-r2/gemv_n_vector.c:96:45
	vle64.v	v24, (s0)
	.loc	2 94 22                         # experiments/openblas-rvv/results/2026-10-26_r192-schedule-counter-r1/llvm-tuning/build-r2/gemv_n_vector.c:94:22
	vfmadd.vf	v16, fa2, v8
	.loc	2 95 22                         # experiments/openblas-rvv/results/2026-10-26_r192-schedule-counter-r1/llvm-tuning/build-r2/gemv_n_vector.c:95:22
	vfmadd.vf	v0, fa4, v16
	.loc	2 91 27                         # experiments/openblas-rvv/results/2026-10-26_r192-schedule-counter-r1/llvm-tuning/build-r2/gemv_n_vector.c:91:27
	add	s1, s1, t5
	.loc	2 96 22                         # experiments/openblas-rvv/results/2026-10-26_r192-schedule-counter-r1/llvm-tuning/build-r2/gemv_n_vector.c:96:22
	vfmadd.vf	v24, fa5, v0
.Ltmp24:
	.loc	2 90 33                         # experiments/openblas-rvv/results/2026-10-26_r192-schedule-counter-r1/llvm-tuning/build-r2/gemv_n_vector.c:90:33
	add	s0, t5, s1
.Ltmp25:
	.loc	2 97 17                         # experiments/openblas-rvv/results/2026-10-26_r192-schedule-counter-r1/llvm-tuning/build-r2/gemv_n_vector.c:97:17
	vse64.v	v24, (t6)
.Ltmp26:
	#DEBUG_VALUE: dgemv_n:i <- [DW_OP_LLVM_arg 0, DW_OP_LLVM_arg 1, DW_OP_div, DW_OP_LLVM_arg 1, DW_OP_mul, DW_OP_LLVM_arg 1, DW_OP_plus, DW_OP_stack_value] $x9, $x30
	.loc	2 0 17 is_stmt 0                # experiments/openblas-rvv/results/2026-10-26_r192-schedule-counter-r1/llvm-tuning/build-r2/gemv_n_vector.c:0:17
	mv	a2, s1
.Ltmp27:
	.loc	2 90 13 is_stmt 1               # experiments/openblas-rvv/results/2026-10-26_r192-schedule-counter-r1/llvm-tuning/build-r2/gemv_n_vector.c:90:13
	bge	a0, s0, .LBB0_6
.Ltmp28:
.LBB0_7:                                #   in Loop: Header=BB0_4 Depth=1
	#DEBUG_VALUE: t3 <- $f15_d
	#DEBUG_VALUE: t2 <- $f14_d
	#DEBUG_VALUE: t1 <- $f12_d
	#DEBUG_VALUE: t0 <- $f13_d
	#DEBUG_VALUE: ap3 <- $x6
	#DEBUG_VALUE: ap2 <- $x7
	#DEBUG_VALUE: ap1 <- $x29
	#DEBUG_VALUE: ap0 <- $x28
	#DEBUG_VALUE: epr <- $x30
	#DEBUG_VALUE: dgemv_n:y <- $x17
	#DEBUG_VALUE: dgemv_n:inc_x <- $x16
	#DEBUG_VALUE: dgemv_n:x <- $x15
	#DEBUG_VALUE: dgemv_n:lda <- $x14
	#DEBUG_VALUE: dgemv_n:a <- $x13
	#DEBUG_VALUE: dgemv_n:alpha <- $f10_d
	#DEBUG_VALUE: dgemv_n:n <- $x11
	#DEBUG_VALUE: dgemv_n:m <- $x10
	.loc	2 99 19                         # experiments/openblas-rvv/results/2026-10-26_r192-schedule-counter-r1/llvm-tuning/build-r2/gemv_n_vector.c:99:19
	bge	s1, a0, .LBB0_3
.Ltmp29:
# %bb.8:                                #   in Loop: Header=BB0_4 Depth=1
	#DEBUG_VALUE: t3 <- $f15_d
	#DEBUG_VALUE: t2 <- $f14_d
	#DEBUG_VALUE: t1 <- $f12_d
	#DEBUG_VALUE: t0 <- $f13_d
	#DEBUG_VALUE: ap3 <- $x6
	#DEBUG_VALUE: ap2 <- $x7
	#DEBUG_VALUE: ap1 <- $x29
	#DEBUG_VALUE: ap0 <- $x28
	#DEBUG_VALUE: epr <- $x30
	#DEBUG_VALUE: dgemv_n:y <- $x17
	#DEBUG_VALUE: dgemv_n:inc_x <- $x16
	#DEBUG_VALUE: dgemv_n:x <- $x15
	#DEBUG_VALUE: dgemv_n:lda <- $x14
	#DEBUG_VALUE: dgemv_n:a <- $x13
	#DEBUG_VALUE: dgemv_n:alpha <- $f10_d
	#DEBUG_VALUE: dgemv_n:n <- $x11
	#DEBUG_VALUE: dgemv_n:m <- $x10
	.loc	2 100 22                        # experiments/openblas-rvv/results/2026-10-26_r192-schedule-counter-r1/llvm-tuning/build-r2/gemv_n_vector.c:100:22
	sub	a2, a0, s1
	.loc	2 101 27                        # experiments/openblas-rvv/results/2026-10-26_r192-schedule-counter-r1/llvm-tuning/build-r2/gemv_n_vector.c:101:27
	slli	s1, s1, 3
	.loc	2 100 22                        # experiments/openblas-rvv/results/2026-10-26_r192-schedule-counter-r1/llvm-tuning/build-r2/gemv_n_vector.c:100:22
	vsetvli	zero, a2, e64, m8, ta, ma
.Ltmp30:
	#DEBUG_VALUE: dgemv_n:vl <- undef
	.loc	2 101 27                        # experiments/openblas-rvv/results/2026-10-26_r192-schedule-counter-r1/llvm-tuning/build-r2/gemv_n_vector.c:101:27
	add	a2, a7, s1
.Ltmp31:
	#DEBUG_VALUE: dgemv_n:y_ptr <- $x12
	.loc	2 105 37                        # experiments/openblas-rvv/results/2026-10-26_r192-schedule-counter-r1/llvm-tuning/build-r2/gemv_n_vector.c:105:37
	add	t3, t3, s1
.Ltmp32:
	.loc	2 106 38                        # experiments/openblas-rvv/results/2026-10-26_r192-schedule-counter-r1/llvm-tuning/build-r2/gemv_n_vector.c:106:38
	add	t4, t4, s1
.Ltmp33:
	.loc	2 104 22                        # experiments/openblas-rvv/results/2026-10-26_r192-schedule-counter-r1/llvm-tuning/build-r2/gemv_n_vector.c:104:22
	vle64.v	v16, (a2)
.Ltmp34:
	#DEBUG_VALUE: dgemv_n:vy <- undef
	.loc	2 105 22                        # experiments/openblas-rvv/results/2026-10-26_r192-schedule-counter-r1/llvm-tuning/build-r2/gemv_n_vector.c:105:22
	vle64.v	v8, (t3)
.Ltmp35:
	#DEBUG_VALUE: dgemv_n:va <- undef
	.loc	2 106 23                        # experiments/openblas-rvv/results/2026-10-26_r192-schedule-counter-r1/llvm-tuning/build-r2/gemv_n_vector.c:106:23
	vle64.v	v24, (t4)
.Ltmp36:
	#DEBUG_VALUE: dgemv_n:va2 <- undef
	.loc	2 111 37                        # experiments/openblas-rvv/results/2026-10-26_r192-schedule-counter-r1/llvm-tuning/build-r2/gemv_n_vector.c:111:37
	add	t2, t2, s1
.Ltmp37:
	.loc	2 107 22                        # experiments/openblas-rvv/results/2026-10-26_r192-schedule-counter-r1/llvm-tuning/build-r2/gemv_n_vector.c:107:22
	vfmadd.vf	v8, fa3, v16
	.loc	2 108 22                        # experiments/openblas-rvv/results/2026-10-26_r192-schedule-counter-r1/llvm-tuning/build-r2/gemv_n_vector.c:108:22
	vfmacc.vf	v8, fa2, v24
	.loc	2 109 17                        # experiments/openblas-rvv/results/2026-10-26_r192-schedule-counter-r1/llvm-tuning/build-r2/gemv_n_vector.c:109:17
	vse64.v	v8, (a2)
	.loc	2 110 22                        # experiments/openblas-rvv/results/2026-10-26_r192-schedule-counter-r1/llvm-tuning/build-r2/gemv_n_vector.c:110:22
	vle64.v	v8, (a2)
	.loc	2 111 22                        # experiments/openblas-rvv/results/2026-10-26_r192-schedule-counter-r1/llvm-tuning/build-r2/gemv_n_vector.c:111:22
	vle64.v	v16, (t2)
	.loc	2 112 38                        # experiments/openblas-rvv/results/2026-10-26_r192-schedule-counter-r1/llvm-tuning/build-r2/gemv_n_vector.c:112:38
	add	t1, t1, s1
.Ltmp38:
	.loc	2 112 23 is_stmt 0              # experiments/openblas-rvv/results/2026-10-26_r192-schedule-counter-r1/llvm-tuning/build-r2/gemv_n_vector.c:112:23
	vle64.v	v24, (t1)
	.loc	2 113 22 is_stmt 1              # experiments/openblas-rvv/results/2026-10-26_r192-schedule-counter-r1/llvm-tuning/build-r2/gemv_n_vector.c:113:22
	vfmadd.vf	v16, fa4, v8
	.loc	2 114 22                        # experiments/openblas-rvv/results/2026-10-26_r192-schedule-counter-r1/llvm-tuning/build-r2/gemv_n_vector.c:114:22
	vfmacc.vf	v16, fa5, v24
	.loc	2 115 17                        # experiments/openblas-rvv/results/2026-10-26_r192-schedule-counter-r1/llvm-tuning/build-r2/gemv_n_vector.c:115:17
	vse64.v	v16, (a2)
	j	.LBB0_3
.Ltmp39:
.LBB0_9:                                #   in Loop: Header=BB0_14 Depth=1
	#DEBUG_VALUE: dgemv_n:j <- $x5
	#DEBUG_VALUE: epr <- $x30
	#DEBUG_VALUE: dgemv_n:y <- $x17
	#DEBUG_VALUE: dgemv_n:inc_x <- $x16
	#DEBUG_VALUE: dgemv_n:x <- $x15
	#DEBUG_VALUE: dgemv_n:lda <- $x14
	#DEBUG_VALUE: dgemv_n:a <- $x13
	#DEBUG_VALUE: dgemv_n:alpha <- $f10_d
	#DEBUG_VALUE: dgemv_n:n <- $x11
	#DEBUG_VALUE: dgemv_n:m <- $x10
	.loc	2 121 38                        # experiments/openblas-rvv/results/2026-10-26_r192-schedule-counter-r1/llvm-tuning/build-r2/gemv_n_vector.c:121:38
	mul	t1, t0, a6
	.loc	2 122 34                        # experiments/openblas-rvv/results/2026-10-26_r192-schedule-counter-r1/llvm-tuning/build-r2/gemv_n_vector.c:122:34
	addi	s0, t0, 1
	.loc	2 123 33                        # experiments/openblas-rvv/results/2026-10-26_r192-schedule-counter-r1/llvm-tuning/build-r2/gemv_n_vector.c:123:33
	mul	s1, t0, a4
	mv	t0, a2
.Ltmp40:
	#DEBUG_VALUE: dgemv_n:j <- undef
	.loc	2 121 28                        # experiments/openblas-rvv/results/2026-10-26_r192-schedule-counter-r1/llvm-tuning/build-r2/gemv_n_vector.c:121:28
	slli	t1, t1, 3
	.loc	2 122 39                        # experiments/openblas-rvv/results/2026-10-26_r192-schedule-counter-r1/llvm-tuning/build-r2/gemv_n_vector.c:122:39
	mul	a2, s0, a6
	.loc	2 123 23                        # experiments/openblas-rvv/results/2026-10-26_r192-schedule-counter-r1/llvm-tuning/build-r2/gemv_n_vector.c:123:23
	slli	s1, s1, 3
	.loc	2 124 34                        # experiments/openblas-rvv/results/2026-10-26_r192-schedule-counter-r1/llvm-tuning/build-r2/gemv_n_vector.c:124:34
	mul	s0, s0, a4
	.loc	2 121 28                        # experiments/openblas-rvv/results/2026-10-26_r192-schedule-counter-r1/llvm-tuning/build-r2/gemv_n_vector.c:121:28
	add	t1, t1, a5
	.loc	2 122 29                        # experiments/openblas-rvv/results/2026-10-26_r192-schedule-counter-r1/llvm-tuning/build-r2/gemv_n_vector.c:122:29
	slli	a2, a2, 3
	add	a2, a2, a5
	.loc	2 121 28                        # experiments/openblas-rvv/results/2026-10-26_r192-schedule-counter-r1/llvm-tuning/build-r2/gemv_n_vector.c:121:28
	fld	fa5, 0(t1)
	.loc	2 122 29                        # experiments/openblas-rvv/results/2026-10-26_r192-schedule-counter-r1/llvm-tuning/build-r2/gemv_n_vector.c:122:29
	fld	fa3, 0(a2)
	.loc	2 123 23                        # experiments/openblas-rvv/results/2026-10-26_r192-schedule-counter-r1/llvm-tuning/build-r2/gemv_n_vector.c:123:23
	add	t1, a3, s1
.Ltmp41:
	#DEBUG_VALUE: dgemv_n:a_ptr <- $x6
	.loc	2 124 24                        # experiments/openblas-rvv/results/2026-10-26_r192-schedule-counter-r1/llvm-tuning/build-r2/gemv_n_vector.c:124:24
	slli	t2, s0, 3
	.loc	2 121 26                        # experiments/openblas-rvv/results/2026-10-26_r192-schedule-counter-r1/llvm-tuning/build-r2/gemv_n_vector.c:121:26
	fmul.d	fa4, fa0, fa5
.Ltmp42:
	#DEBUG_VALUE: dgemv_n:temp <- $f14_d
	.loc	2 122 27                        # experiments/openblas-rvv/results/2026-10-26_r192-schedule-counter-r1/llvm-tuning/build-r2/gemv_n_vector.c:122:27
	fmul.d	fa5, fa0, fa3
.Ltmp43:
	#DEBUG_VALUE: dgemv_n:temp2 <- $f15_d
	.loc	2 124 24                        # experiments/openblas-rvv/results/2026-10-26_r192-schedule-counter-r1/llvm-tuning/build-r2/gemv_n_vector.c:124:24
	add	t2, t2, a3
.Ltmp44:
	#DEBUG_VALUE: dgemv_n:i <- 0
	#DEBUG_VALUE: dgemv_n:a2_ptr <- $x7
	.loc	2 0 24 is_stmt 0                # experiments/openblas-rvv/results/2026-10-26_r192-schedule-counter-r1/llvm-tuning/build-r2/gemv_n_vector.c:0:24
	li	a2, 0
	blt	a0, t5, .LBB0_12
.Ltmp45:
# %bb.10:                               #   in Loop: Header=BB0_14 Depth=1
	#DEBUG_VALUE: dgemv_n:a2_ptr <- $x7
	#DEBUG_VALUE: dgemv_n:temp2 <- $f15_d
	#DEBUG_VALUE: dgemv_n:temp <- $f14_d
	#DEBUG_VALUE: dgemv_n:a_ptr <- $x6
	#DEBUG_VALUE: dgemv_n:i <- 0
	#DEBUG_VALUE: epr <- $x30
	#DEBUG_VALUE: dgemv_n:y <- $x17
	#DEBUG_VALUE: dgemv_n:inc_x <- $x16
	#DEBUG_VALUE: dgemv_n:x <- $x15
	#DEBUG_VALUE: dgemv_n:lda <- $x14
	#DEBUG_VALUE: dgemv_n:a <- $x13
	#DEBUG_VALUE: dgemv_n:alpha <- $f10_d
	#DEBUG_VALUE: dgemv_n:n <- $x11
	#DEBUG_VALUE: dgemv_n:m <- $x10
	li	s1, 0
	vsetvli	s0, zero, e64, m8, ta, ma
.Ltmp46:
.LBB0_11:                               #   Parent Loop BB0_14 Depth=1
                                        # =>  This Inner Loop Header: Depth=2
	#DEBUG_VALUE: dgemv_n:a2_ptr <- $x7
	#DEBUG_VALUE: dgemv_n:temp2 <- $f15_d
	#DEBUG_VALUE: dgemv_n:temp <- $f14_d
	#DEBUG_VALUE: dgemv_n:a_ptr <- $x6
	#DEBUG_VALUE: epr <- $x30
	#DEBUG_VALUE: dgemv_n:y <- $x17
	#DEBUG_VALUE: dgemv_n:inc_x <- $x16
	#DEBUG_VALUE: dgemv_n:x <- $x15
	#DEBUG_VALUE: dgemv_n:lda <- $x14
	#DEBUG_VALUE: dgemv_n:a <- $x13
	#DEBUG_VALUE: dgemv_n:alpha <- $f10_d
	#DEBUG_VALUE: dgemv_n:n <- $x11
	#DEBUG_VALUE: dgemv_n:m <- $x10
	#DEBUG_VALUE: dgemv_n:i <- $x9
	.loc	2 126 27 is_stmt 1              # experiments/openblas-rvv/results/2026-10-26_r192-schedule-counter-r1/llvm-tuning/build-r2/gemv_n_vector.c:126:27
	slli	s1, s1, 3
.Ltmp47:
	add	s0, a7, s1
.Ltmp48:
	#DEBUG_VALUE: dgemv_n:y_ptr <- $x8
	.loc	2 128 39                        # experiments/openblas-rvv/results/2026-10-26_r192-schedule-counter-r1/llvm-tuning/build-r2/gemv_n_vector.c:128:39
	add	t3, t1, s1
	.loc	2 129 41                        # experiments/openblas-rvv/results/2026-10-26_r192-schedule-counter-r1/llvm-tuning/build-r2/gemv_n_vector.c:129:41
	add	s1, s1, t2
	.loc	2 127 22                        # experiments/openblas-rvv/results/2026-10-26_r192-schedule-counter-r1/llvm-tuning/build-r2/gemv_n_vector.c:127:22
	vle64.v	v16, (s0)
.Ltmp49:
	#DEBUG_VALUE: dgemv_n:vy <- undef
	.loc	2 128 22                        # experiments/openblas-rvv/results/2026-10-26_r192-schedule-counter-r1/llvm-tuning/build-r2/gemv_n_vector.c:128:22
	vle64.v	v8, (t3)
.Ltmp50:
	#DEBUG_VALUE: dgemv_n:va <- undef
	.loc	2 129 23                        # experiments/openblas-rvv/results/2026-10-26_r192-schedule-counter-r1/llvm-tuning/build-r2/gemv_n_vector.c:129:23
	vle64.v	v24, (s1)
.Ltmp51:
	#DEBUG_VALUE: dgemv_n:va2 <- undef
	.loc	2 126 27                        # experiments/openblas-rvv/results/2026-10-26_r192-schedule-counter-r1/llvm-tuning/build-r2/gemv_n_vector.c:126:27
	add	a2, a2, t5
	.loc	2 130 22                        # experiments/openblas-rvv/results/2026-10-26_r192-schedule-counter-r1/llvm-tuning/build-r2/gemv_n_vector.c:130:22
	vfmadd.vf	v8, fa4, v16
	.loc	2 131 22                        # experiments/openblas-rvv/results/2026-10-26_r192-schedule-counter-r1/llvm-tuning/build-r2/gemv_n_vector.c:131:22
	vfmacc.vf	v8, fa5, v24
.Ltmp52:
	.loc	2 125 33                        # experiments/openblas-rvv/results/2026-10-26_r192-schedule-counter-r1/llvm-tuning/build-r2/gemv_n_vector.c:125:33
	add	t3, t5, a2
.Ltmp53:
	.loc	2 132 17                        # experiments/openblas-rvv/results/2026-10-26_r192-schedule-counter-r1/llvm-tuning/build-r2/gemv_n_vector.c:132:17
	vse64.v	v8, (s0)
.Ltmp54:
	#DEBUG_VALUE: dgemv_n:i <- [DW_OP_LLVM_arg 0, DW_OP_LLVM_arg 1, DW_OP_div, DW_OP_LLVM_arg 1, DW_OP_mul, DW_OP_LLVM_arg 1, DW_OP_plus, DW_OP_stack_value] $x12, $x30
	.loc	2 0 17 is_stmt 0                # experiments/openblas-rvv/results/2026-10-26_r192-schedule-counter-r1/llvm-tuning/build-r2/gemv_n_vector.c:0:17
	mv	s1, a2
	bge	a0, t3, .LBB0_11
.Ltmp55:
.LBB0_12:                               #   in Loop: Header=BB0_14 Depth=1
	#DEBUG_VALUE: dgemv_n:a2_ptr <- $x7
	#DEBUG_VALUE: dgemv_n:temp2 <- $f15_d
	#DEBUG_VALUE: dgemv_n:temp <- $f14_d
	#DEBUG_VALUE: dgemv_n:a_ptr <- $x6
	#DEBUG_VALUE: epr <- $x30
	#DEBUG_VALUE: dgemv_n:y <- $x17
	#DEBUG_VALUE: dgemv_n:inc_x <- $x16
	#DEBUG_VALUE: dgemv_n:x <- $x15
	#DEBUG_VALUE: dgemv_n:lda <- $x14
	#DEBUG_VALUE: dgemv_n:a <- $x13
	#DEBUG_VALUE: dgemv_n:alpha <- $f10_d
	#DEBUG_VALUE: dgemv_n:n <- $x11
	#DEBUG_VALUE: dgemv_n:m <- $x10
	bge	a2, a0, .LBB0_14
.Ltmp56:
# %bb.13:                               #   in Loop: Header=BB0_14 Depth=1
	#DEBUG_VALUE: dgemv_n:a2_ptr <- $x7
	#DEBUG_VALUE: dgemv_n:temp2 <- $f15_d
	#DEBUG_VALUE: dgemv_n:temp <- $f14_d
	#DEBUG_VALUE: dgemv_n:a_ptr <- $x6
	#DEBUG_VALUE: epr <- $x30
	#DEBUG_VALUE: dgemv_n:y <- $x17
	#DEBUG_VALUE: dgemv_n:inc_x <- $x16
	#DEBUG_VALUE: dgemv_n:x <- $x15
	#DEBUG_VALUE: dgemv_n:lda <- $x14
	#DEBUG_VALUE: dgemv_n:a <- $x13
	#DEBUG_VALUE: dgemv_n:alpha <- $f10_d
	#DEBUG_VALUE: dgemv_n:n <- $x11
	#DEBUG_VALUE: dgemv_n:m <- $x10
	.loc	2 135 22 is_stmt 1              # experiments/openblas-rvv/results/2026-10-26_r192-schedule-counter-r1/llvm-tuning/build-r2/gemv_n_vector.c:135:22
	sub	s1, a0, a2
	.loc	2 136 27                        # experiments/openblas-rvv/results/2026-10-26_r192-schedule-counter-r1/llvm-tuning/build-r2/gemv_n_vector.c:136:27
	slli	a2, a2, 3
	.loc	2 135 22                        # experiments/openblas-rvv/results/2026-10-26_r192-schedule-counter-r1/llvm-tuning/build-r2/gemv_n_vector.c:135:22
	vsetvli	zero, s1, e64, m8, ta, ma
.Ltmp57:
	#DEBUG_VALUE: dgemv_n:vl <- undef
	.loc	2 136 27                        # experiments/openblas-rvv/results/2026-10-26_r192-schedule-counter-r1/llvm-tuning/build-r2/gemv_n_vector.c:136:27
	add	s1, a7, a2
.Ltmp58:
	#DEBUG_VALUE: dgemv_n:y_ptr <- $x9
	.loc	2 138 39                        # experiments/openblas-rvv/results/2026-10-26_r192-schedule-counter-r1/llvm-tuning/build-r2/gemv_n_vector.c:138:39
	add	t1, t1, a2
.Ltmp59:
	.loc	2 137 22                        # experiments/openblas-rvv/results/2026-10-26_r192-schedule-counter-r1/llvm-tuning/build-r2/gemv_n_vector.c:137:22
	vle64.v	v8, (s1)
.Ltmp60:
	#DEBUG_VALUE: dgemv_n:vy <- undef
	.loc	2 138 22                        # experiments/openblas-rvv/results/2026-10-26_r192-schedule-counter-r1/llvm-tuning/build-r2/gemv_n_vector.c:138:22
	vle64.v	v16, (t1)
.Ltmp61:
	#DEBUG_VALUE: dgemv_n:va <- undef
	.loc	2 139 41                        # experiments/openblas-rvv/results/2026-10-26_r192-schedule-counter-r1/llvm-tuning/build-r2/gemv_n_vector.c:139:41
	add	a2, a2, t2
	.loc	2 139 23 is_stmt 0              # experiments/openblas-rvv/results/2026-10-26_r192-schedule-counter-r1/llvm-tuning/build-r2/gemv_n_vector.c:139:23
	vle64.v	v24, (a2)
.Ltmp62:
	#DEBUG_VALUE: dgemv_n:va2 <- undef
	.loc	2 140 22 is_stmt 1              # experiments/openblas-rvv/results/2026-10-26_r192-schedule-counter-r1/llvm-tuning/build-r2/gemv_n_vector.c:140:22
	vfmadd.vf	v16, fa4, v8
	.loc	2 141 22                        # experiments/openblas-rvv/results/2026-10-26_r192-schedule-counter-r1/llvm-tuning/build-r2/gemv_n_vector.c:141:22
	vfmacc.vf	v16, fa5, v24
	.loc	2 142 17                        # experiments/openblas-rvv/results/2026-10-26_r192-schedule-counter-r1/llvm-tuning/build-r2/gemv_n_vector.c:142:17
	vse64.v	v16, (s1)
.Ltmp63:
.LBB0_14:                               # =>This Loop Header: Depth=1
                                        #     Child Loop BB0_11 Depth 2
	#DEBUG_VALUE: epr <- $x30
	#DEBUG_VALUE: dgemv_n:y <- $x17
	#DEBUG_VALUE: dgemv_n:inc_x <- $x16
	#DEBUG_VALUE: dgemv_n:x <- $x15
	#DEBUG_VALUE: dgemv_n:lda <- $x14
	#DEBUG_VALUE: dgemv_n:a <- $x13
	#DEBUG_VALUE: dgemv_n:alpha <- $f10_d
	#DEBUG_VALUE: dgemv_n:n <- $x11
	#DEBUG_VALUE: dgemv_n:m <- $x10
	#DEBUG_VALUE: dgemv_n:j <- $x5
	.loc	2 120 18                        # experiments/openblas-rvv/results/2026-10-26_r192-schedule-counter-r1/llvm-tuning/build-r2/gemv_n_vector.c:120:18
	addi	a2, t0, 2
.Ltmp64:
	.loc	2 120 9 is_stmt 0               # experiments/openblas-rvv/results/2026-10-26_r192-schedule-counter-r1/llvm-tuning/build-r2/gemv_n_vector.c:120:9
	bge	a1, a2, .LBB0_9
.Ltmp65:
# %bb.15:
	#DEBUG_VALUE: dgemv_n:j <- $x5
	#DEBUG_VALUE: epr <- $x30
	#DEBUG_VALUE: dgemv_n:y <- $x17
	#DEBUG_VALUE: dgemv_n:inc_x <- $x16
	#DEBUG_VALUE: dgemv_n:x <- $x15
	#DEBUG_VALUE: dgemv_n:lda <- $x14
	#DEBUG_VALUE: dgemv_n:a <- $x13
	#DEBUG_VALUE: dgemv_n:alpha <- $f10_d
	#DEBUG_VALUE: dgemv_n:n <- $x11
	#DEBUG_VALUE: dgemv_n:m <- $x10
	.loc	2 146 15 is_stmt 1              # experiments/openblas-rvv/results/2026-10-26_r192-schedule-counter-r1/llvm-tuning/build-r2/gemv_n_vector.c:146:15
	bge	t0, a1, .LBB0_31
.Ltmp66:
# %bb.16:
	#DEBUG_VALUE: dgemv_n:j <- $x5
	#DEBUG_VALUE: epr <- $x30
	#DEBUG_VALUE: dgemv_n:y <- $x17
	#DEBUG_VALUE: dgemv_n:inc_x <- $x16
	#DEBUG_VALUE: dgemv_n:x <- $x15
	#DEBUG_VALUE: dgemv_n:lda <- $x14
	#DEBUG_VALUE: dgemv_n:a <- $x13
	#DEBUG_VALUE: dgemv_n:alpha <- $f10_d
	#DEBUG_VALUE: dgemv_n:n <- $x11
	#DEBUG_VALUE: dgemv_n:m <- $x10
	.loc	2 147 32                        # experiments/openblas-rvv/results/2026-10-26_r192-schedule-counter-r1/llvm-tuning/build-r2/gemv_n_vector.c:147:32
	mul	a1, t0, a6
.Ltmp67:
	.loc	2 147 28 is_stmt 0              # experiments/openblas-rvv/results/2026-10-26_r192-schedule-counter-r1/llvm-tuning/build-r2/gemv_n_vector.c:147:28
	slli	a1, a1, 3
	add	a1, a1, a5
	fld	fa5, 0(a1)
	.loc	2 148 27 is_stmt 1              # experiments/openblas-rvv/results/2026-10-26_r192-schedule-counter-r1/llvm-tuning/build-r2/gemv_n_vector.c:148:27
	mul	a1, t0, a4
	.loc	2 148 23 is_stmt 0              # experiments/openblas-rvv/results/2026-10-26_r192-schedule-counter-r1/llvm-tuning/build-r2/gemv_n_vector.c:148:23
	slli	a1, a1, 3
	.loc	2 147 26 is_stmt 1              # experiments/openblas-rvv/results/2026-10-26_r192-schedule-counter-r1/llvm-tuning/build-r2/gemv_n_vector.c:147:26
	fmul.d	fa5, fa0, fa5
.Ltmp68:
	#DEBUG_VALUE: dgemv_n:temp <- $f15_d
	.loc	2 148 23                        # experiments/openblas-rvv/results/2026-10-26_r192-schedule-counter-r1/llvm-tuning/build-r2/gemv_n_vector.c:148:23
	add	a3, a3, a1
.Ltmp69:
	#DEBUG_VALUE: dgemv_n:i <- 0
	#DEBUG_VALUE: dgemv_n:a_ptr <- $x13
	.loc	2 0 23 is_stmt 0                # experiments/openblas-rvv/results/2026-10-26_r192-schedule-counter-r1/llvm-tuning/build-r2/gemv_n_vector.c:0:23
	li	a1, 0
.Ltmp70:
	.loc	2 149 13 is_stmt 1              # experiments/openblas-rvv/results/2026-10-26_r192-schedule-counter-r1/llvm-tuning/build-r2/gemv_n_vector.c:149:13
	blt	a0, t5, .LBB0_19
.Ltmp71:
# %bb.17:
	#DEBUG_VALUE: dgemv_n:j <- $x5
	#DEBUG_VALUE: dgemv_n:i <- 0
	#DEBUG_VALUE: epr <- $x30
	#DEBUG_VALUE: dgemv_n:temp <- $f15_d
	#DEBUG_VALUE: dgemv_n:a_ptr <- $x13
	#DEBUG_VALUE: dgemv_n:y <- $x17
	#DEBUG_VALUE: dgemv_n:inc_x <- $x16
	#DEBUG_VALUE: dgemv_n:x <- $x15
	#DEBUG_VALUE: dgemv_n:lda <- $x14
	#DEBUG_VALUE: dgemv_n:alpha <- $f10_d
	#DEBUG_VALUE: dgemv_n:m <- $x10
	.loc	2 0 13 is_stmt 0                # experiments/openblas-rvv/results/2026-10-26_r192-schedule-counter-r1/llvm-tuning/build-r2/gemv_n_vector.c:0:13
	li	a2, 0
	vsetvli	a4, zero, e64, m8, ta, ma
.Ltmp72:
.LBB0_18:                               # =>This Inner Loop Header: Depth=1
	#DEBUG_VALUE: dgemv_n:j <- $x5
	#DEBUG_VALUE: epr <- $x30
	#DEBUG_VALUE: dgemv_n:temp <- $f15_d
	#DEBUG_VALUE: dgemv_n:a_ptr <- $x13
	#DEBUG_VALUE: dgemv_n:y <- $x17
	#DEBUG_VALUE: dgemv_n:inc_x <- $x16
	#DEBUG_VALUE: dgemv_n:alpha <- $f10_d
	#DEBUG_VALUE: dgemv_n:m <- $x10
	#DEBUG_VALUE: dgemv_n:i <- $x12
	.loc	2 150 27 is_stmt 1              # experiments/openblas-rvv/results/2026-10-26_r192-schedule-counter-r1/llvm-tuning/build-r2/gemv_n_vector.c:150:27
	slli	a2, a2, 3
.Ltmp73:
	add	a4, a7, a2
.Ltmp74:
	#DEBUG_VALUE: dgemv_n:y_ptr <- $x14
	.loc	2 152 39                        # experiments/openblas-rvv/results/2026-10-26_r192-schedule-counter-r1/llvm-tuning/build-r2/gemv_n_vector.c:152:39
	add	a2, a2, a3
	.loc	2 151 22                        # experiments/openblas-rvv/results/2026-10-26_r192-schedule-counter-r1/llvm-tuning/build-r2/gemv_n_vector.c:151:22
	vle64.v	v8, (a4)
.Ltmp75:
	#DEBUG_VALUE: dgemv_n:vy <- undef
	.loc	2 152 22                        # experiments/openblas-rvv/results/2026-10-26_r192-schedule-counter-r1/llvm-tuning/build-r2/gemv_n_vector.c:152:22
	vle64.v	v16, (a2)
.Ltmp76:
	#DEBUG_VALUE: dgemv_n:va <- undef
	.loc	2 150 27                        # experiments/openblas-rvv/results/2026-10-26_r192-schedule-counter-r1/llvm-tuning/build-r2/gemv_n_vector.c:150:27
	add	a1, a1, t5
	.loc	2 153 22                        # experiments/openblas-rvv/results/2026-10-26_r192-schedule-counter-r1/llvm-tuning/build-r2/gemv_n_vector.c:153:22
	vfmadd.vf	v16, fa5, v8
.Ltmp77:
	.loc	2 149 33                        # experiments/openblas-rvv/results/2026-10-26_r192-schedule-counter-r1/llvm-tuning/build-r2/gemv_n_vector.c:149:33
	add	a5, t5, a1
.Ltmp78:
	.loc	2 154 17                        # experiments/openblas-rvv/results/2026-10-26_r192-schedule-counter-r1/llvm-tuning/build-r2/gemv_n_vector.c:154:17
	vse64.v	v16, (a4)
.Ltmp79:
	#DEBUG_VALUE: dgemv_n:i <- [DW_OP_LLVM_arg 0, DW_OP_LLVM_arg 1, DW_OP_div, DW_OP_LLVM_arg 1, DW_OP_mul, DW_OP_LLVM_arg 1, DW_OP_plus, DW_OP_stack_value] $x11, $x30
	.loc	2 0 17 is_stmt 0                # experiments/openblas-rvv/results/2026-10-26_r192-schedule-counter-r1/llvm-tuning/build-r2/gemv_n_vector.c:0:17
	mv	a2, a1
.Ltmp80:
	.loc	2 149 13 is_stmt 1              # experiments/openblas-rvv/results/2026-10-26_r192-schedule-counter-r1/llvm-tuning/build-r2/gemv_n_vector.c:149:13
	bge	a0, a5, .LBB0_18
.Ltmp81:
.LBB0_19:
	#DEBUG_VALUE: dgemv_n:j <- $x5
	#DEBUG_VALUE: epr <- $x30
	#DEBUG_VALUE: dgemv_n:temp <- $f15_d
	#DEBUG_VALUE: dgemv_n:a_ptr <- $x13
	#DEBUG_VALUE: dgemv_n:y <- $x17
	#DEBUG_VALUE: dgemv_n:inc_x <- $x16
	#DEBUG_VALUE: dgemv_n:alpha <- $f10_d
	#DEBUG_VALUE: dgemv_n:m <- $x10
	.loc	2 156 19                        # experiments/openblas-rvv/results/2026-10-26_r192-schedule-counter-r1/llvm-tuning/build-r2/gemv_n_vector.c:156:19
	bge	a1, a0, .LBB0_31
.Ltmp82:
# %bb.20:
	#DEBUG_VALUE: dgemv_n:j <- $x5
	#DEBUG_VALUE: epr <- $x30
	#DEBUG_VALUE: dgemv_n:temp <- $f15_d
	#DEBUG_VALUE: dgemv_n:a_ptr <- $x13
	#DEBUG_VALUE: dgemv_n:y <- $x17
	#DEBUG_VALUE: dgemv_n:inc_x <- $x16
	#DEBUG_VALUE: dgemv_n:alpha <- $f10_d
	#DEBUG_VALUE: dgemv_n:m <- $x10
	.loc	2 157 22                        # experiments/openblas-rvv/results/2026-10-26_r192-schedule-counter-r1/llvm-tuning/build-r2/gemv_n_vector.c:157:22
	sub	a0, a0, a1
.Ltmp83:
	.loc	2 158 27                        # experiments/openblas-rvv/results/2026-10-26_r192-schedule-counter-r1/llvm-tuning/build-r2/gemv_n_vector.c:158:27
	slli	a1, a1, 3
	.loc	2 157 22                        # experiments/openblas-rvv/results/2026-10-26_r192-schedule-counter-r1/llvm-tuning/build-r2/gemv_n_vector.c:157:22
	vsetvli	zero, a0, e64, m8, ta, ma
.Ltmp84:
	#DEBUG_VALUE: dgemv_n:vl <- undef
	.loc	2 158 27                        # experiments/openblas-rvv/results/2026-10-26_r192-schedule-counter-r1/llvm-tuning/build-r2/gemv_n_vector.c:158:27
	add	a7, a7, a1
.Ltmp85:
	#DEBUG_VALUE: dgemv_n:y_ptr <- $x17
	.loc	2 160 39                        # experiments/openblas-rvv/results/2026-10-26_r192-schedule-counter-r1/llvm-tuning/build-r2/gemv_n_vector.c:160:39
	add	a1, a1, a3
	.loc	2 159 22                        # experiments/openblas-rvv/results/2026-10-26_r192-schedule-counter-r1/llvm-tuning/build-r2/gemv_n_vector.c:159:22
	vle64.v	v8, (a7)
.Ltmp86:
	#DEBUG_VALUE: dgemv_n:vy <- undef
	.loc	2 160 22                        # experiments/openblas-rvv/results/2026-10-26_r192-schedule-counter-r1/llvm-tuning/build-r2/gemv_n_vector.c:160:22
	vle64.v	v16, (a1)
.Ltmp87:
	#DEBUG_VALUE: dgemv_n:va <- undef
	.loc	2 161 22                        # experiments/openblas-rvv/results/2026-10-26_r192-schedule-counter-r1/llvm-tuning/build-r2/gemv_n_vector.c:161:22
	vfmadd.vf	v16, fa5, v8
	.loc	2 162 17                        # experiments/openblas-rvv/results/2026-10-26_r192-schedule-counter-r1/llvm-tuning/build-r2/gemv_n_vector.c:162:17
	vse64.v	v16, (a7)
	.loc	2 163 13                        # experiments/openblas-rvv/results/2026-10-26_r192-schedule-counter-r1/llvm-tuning/build-r2/gemv_n_vector.c:163:13
	j	.LBB0_31
.Ltmp88:
.LBB0_21:
	#DEBUG_VALUE: dgemv_n:y <- $x17
	#DEBUG_VALUE: dgemv_n:inc_x <- $x16
	#DEBUG_VALUE: dgemv_n:x <- $x15
	#DEBUG_VALUE: dgemv_n:lda <- $x14
	#DEBUG_VALUE: dgemv_n:a <- $x13
	#DEBUG_VALUE: dgemv_n:alpha <- $f10_d
	#DEBUG_VALUE: dgemv_n:n <- $x11
	#DEBUG_VALUE: dgemv_n:m <- $x10
	.loc	2 0 13 is_stmt 0                # experiments/openblas-rvv/results/2026-10-26_r192-schedule-counter-r1/llvm-tuning/build-r2/gemv_n_vector.c:0:13
	srli	t1, a1, 1
.Ltmp89:
	#DEBUG_VALUE: dgemv_n:a <- undef
	#DEBUG_VALUE: dgemv_n:x <- undef
	.loc	2 203 35 is_stmt 1              # experiments/openblas-rvv/results/2026-10-26_r192-schedule-counter-r1/llvm-tuning/build-r2/gemv_n_vector.c:203:35
	slli	t6, t0, 3
.Ltmp90:
	#DEBUG_VALUE: dgemv_n:j <- 0
	#DEBUG_VALUE: stride_y <- $x31
	.loc	2 204 9                         # experiments/openblas-rvv/results/2026-10-26_r192-schedule-counter-r1/llvm-tuning/build-r2/gemv_n_vector.c:204:9
	beqz	t1, .LBB0_27
.Ltmp91:
# %bb.22:
	#DEBUG_VALUE: stride_y <- $x31
	#DEBUG_VALUE: dgemv_n:j <- 0
	#DEBUG_VALUE: dgemv_n:y <- $x17
	#DEBUG_VALUE: dgemv_n:inc_x <- $x16
	#DEBUG_VALUE: dgemv_n:lda <- $x14
	#DEBUG_VALUE: dgemv_n:alpha <- $f10_d
	#DEBUG_VALUE: dgemv_n:n <- $x11
	#DEBUG_VALUE: dgemv_n:m <- $x10
	.loc	2 0 9 is_stmt 0                 # experiments/openblas-rvv/results/2026-10-26_r192-schedule-counter-r1/llvm-tuning/build-r2/gemv_n_vector.c:0:9
	li	t2, 0
	slli	t3, a6, 4
	slli	t4, a4, 4
	slli	a6, a6, 3
.Ltmp92:
	slli	t5, a4, 3
	j	.LBB0_24
.Ltmp93:
.LBB0_23:                               #   in Loop: Header=BB0_24 Depth=1
	#DEBUG_VALUE: dgemv_n:j <- $x7
	#DEBUG_VALUE: stride_y <- $x31
	#DEBUG_VALUE: dgemv_n:y <- $x17
	#DEBUG_VALUE: dgemv_n:x <- $x15
	#DEBUG_VALUE: dgemv_n:a <- $x13
	#DEBUG_VALUE: dgemv_n:alpha <- $f10_d
	#DEBUG_VALUE: dgemv_n:n <- $x11
	#DEBUG_VALUE: dgemv_n:m <- $x10
	.loc	2 222 15 is_stmt 1              # experiments/openblas-rvv/results/2026-10-26_r192-schedule-counter-r1/llvm-tuning/build-r2/gemv_n_vector.c:222:15
	add	a5, a5, t3
.Ltmp94:
	#DEBUG_VALUE: dgemv_n:x <- $x15
	.loc	2 204 36                        # experiments/openblas-rvv/results/2026-10-26_r192-schedule-counter-r1/llvm-tuning/build-r2/gemv_n_vector.c:204:36
	addi	t2, t2, 1
.Ltmp95:
	#DEBUG_VALUE: dgemv_n:j <- $x7
	.loc	2 223 15                        # experiments/openblas-rvv/results/2026-10-26_r192-schedule-counter-r1/llvm-tuning/build-r2/gemv_n_vector.c:223:15
	add	a3, a3, t4
.Ltmp96:
	#DEBUG_VALUE: dgemv_n:a <- $x13
	.loc	2 204 9                         # experiments/openblas-rvv/results/2026-10-26_r192-schedule-counter-r1/llvm-tuning/build-r2/gemv_n_vector.c:204:9
	beq	t2, t1, .LBB0_27
.Ltmp97:
.LBB0_24:                               # =>This Loop Header: Depth=1
                                        #     Child Loop BB0_26 Depth 2
	#DEBUG_VALUE: stride_y <- $x31
	#DEBUG_VALUE: dgemv_n:y <- $x17
	#DEBUG_VALUE: dgemv_n:alpha <- $f10_d
	#DEBUG_VALUE: dgemv_n:n <- $x11
	#DEBUG_VALUE: dgemv_n:m <- $x10
	#DEBUG_VALUE: dgemv_n:a <- $x13
	#DEBUG_VALUE: dgemv_n:x <- $x15
	#DEBUG_VALUE: dgemv_n:j <- $x7
	#DEBUG_VALUE: dgemv_n:i <- $x10
	#DEBUG_VALUE: dgemv_n:y_ptr <- $x17
	#DEBUG_VALUE: dgemv_n:a_ptr <- $x13
	#DEBUG_VALUE: dgemv_n:temp <- undef
	#DEBUG_VALUE: dgemv_n:temp2 <- undef
	#DEBUG_VALUE: dgemv_n:a2_ptr <- [DW_OP_LLVM_arg 0, DW_OP_LLVM_arg 0, DW_OP_constu 8, DW_OP_mul, DW_OP_plus, DW_OP_stack_value] undef
	.loc	2 210 13                        # experiments/openblas-rvv/results/2026-10-26_r192-schedule-counter-r1/llvm-tuning/build-r2/gemv_n_vector.c:210:13
	blez	a0, .LBB0_23
.Ltmp98:
# %bb.25:                               #   in Loop: Header=BB0_24 Depth=1
	#DEBUG_VALUE: dgemv_n:a_ptr <- $x13
	#DEBUG_VALUE: dgemv_n:y_ptr <- $x17
	#DEBUG_VALUE: dgemv_n:i <- $x10
	#DEBUG_VALUE: dgemv_n:j <- $x7
	#DEBUG_VALUE: stride_y <- $x31
	#DEBUG_VALUE: dgemv_n:y <- $x17
	#DEBUG_VALUE: dgemv_n:x <- $x15
	#DEBUG_VALUE: dgemv_n:a <- $x13
	#DEBUG_VALUE: dgemv_n:alpha <- $f10_d
	#DEBUG_VALUE: dgemv_n:n <- $x11
	#DEBUG_VALUE: dgemv_n:m <- $x10
	.loc	2 0 0 is_stmt 0                 # experiments/openblas-rvv/results/2026-10-26_r192-schedule-counter-r1/llvm-tuning/build-r2/gemv_n_vector.c:0
	add	a2, a5, a6
	fld	fa5, 0(a5)
	fld	fa4, 0(a2)
	fmul.d	fa5, fa0, fa5
.Ltmp99:
	#DEBUG_VALUE: dgemv_n:temp <- $f15_d
	fmul.d	fa4, fa0, fa4
.Ltmp100:
	#DEBUG_VALUE: dgemv_n:temp2 <- $f14_d
	.loc	2 209 24 is_stmt 1              # experiments/openblas-rvv/results/2026-10-26_r192-schedule-counter-r1/llvm-tuning/build-r2/gemv_n_vector.c:209:24
	add	a4, a3, t5
.Ltmp101:
	#DEBUG_VALUE: dgemv_n:a2_ptr <- $x14
	.loc	2 0 24 is_stmt 0                # experiments/openblas-rvv/results/2026-10-26_r192-schedule-counter-r1/llvm-tuning/build-r2/gemv_n_vector.c:0:24
	mv	a2, a3
	mv	s0, a7
	mv	s1, a0
.Ltmp102:
.LBB0_26:                               #   Parent Loop BB0_24 Depth=1
                                        # =>  This Inner Loop Header: Depth=2
	#DEBUG_VALUE: dgemv_n:a2_ptr <- $x14
	#DEBUG_VALUE: dgemv_n:temp2 <- $f14_d
	#DEBUG_VALUE: dgemv_n:temp <- $f15_d
	#DEBUG_VALUE: dgemv_n:j <- $x7
	#DEBUG_VALUE: stride_y <- $x31
	#DEBUG_VALUE: dgemv_n:y <- $x17
	#DEBUG_VALUE: dgemv_n:x <- $x15
	#DEBUG_VALUE: dgemv_n:a <- $x13
	#DEBUG_VALUE: dgemv_n:alpha <- $f10_d
	#DEBUG_VALUE: dgemv_n:n <- $x11
	#DEBUG_VALUE: dgemv_n:m <- $x10
	#DEBUG_VALUE: dgemv_n:i <- $x9
	#DEBUG_VALUE: dgemv_n:y_ptr <- $x8
	#DEBUG_VALUE: dgemv_n:a_ptr <- $x12
	#DEBUG_VALUE: dgemv_n:a2_ptr <- $x14
	.loc	2 211 22 is_stmt 1              # experiments/openblas-rvv/results/2026-10-26_r192-schedule-counter-r1/llvm-tuning/build-r2/gemv_n_vector.c:211:22
	vsetvli	s2, s1, e64, m8, ta, ma
.Ltmp103:
	#DEBUG_VALUE: dgemv_n:vl <- $x18
	.loc	2 212 22                        # experiments/openblas-rvv/results/2026-10-26_r192-schedule-counter-r1/llvm-tuning/build-r2/gemv_n_vector.c:212:22
	vlse64.v	v16, (s0), t6
.Ltmp104:
	#DEBUG_VALUE: dgemv_n:vy <- undef
	.loc	2 213 22                        # experiments/openblas-rvv/results/2026-10-26_r192-schedule-counter-r1/llvm-tuning/build-r2/gemv_n_vector.c:213:22
	vle64.v	v8, (a2)
.Ltmp105:
	#DEBUG_VALUE: dgemv_n:va <- undef
	.loc	2 214 23                        # experiments/openblas-rvv/results/2026-10-26_r192-schedule-counter-r1/llvm-tuning/build-r2/gemv_n_vector.c:214:23
	vle64.v	v24, (a4)
.Ltmp106:
	#DEBUG_VALUE: dgemv_n:va2 <- undef
	.loc	2 218 29                        # experiments/openblas-rvv/results/2026-10-26_r192-schedule-counter-r1/llvm-tuning/build-r2/gemv_n_vector.c:218:29
	mul	s3, s2, t0
.Ltmp107:
	.loc	2 210 34                        # experiments/openblas-rvv/results/2026-10-26_r192-schedule-counter-r1/llvm-tuning/build-r2/gemv_n_vector.c:210:34
	sub	s1, s1, s2
.Ltmp108:
	#DEBUG_VALUE: dgemv_n:i <- $x9
	.loc	2 215 22                        # experiments/openblas-rvv/results/2026-10-26_r192-schedule-counter-r1/llvm-tuning/build-r2/gemv_n_vector.c:215:22
	vfmadd.vf	v8, fa5, v16
	.loc	2 216 22                        # experiments/openblas-rvv/results/2026-10-26_r192-schedule-counter-r1/llvm-tuning/build-r2/gemv_n_vector.c:216:22
	vfmacc.vf	v8, fa4, v24
	.loc	2 217 17                        # experiments/openblas-rvv/results/2026-10-26_r192-schedule-counter-r1/llvm-tuning/build-r2/gemv_n_vector.c:217:17
	vsse64.v	v8, (s0), t6
	.loc	2 219 23                        # experiments/openblas-rvv/results/2026-10-26_r192-schedule-counter-r1/llvm-tuning/build-r2/gemv_n_vector.c:219:23
	slli	s2, s2, 3
.Ltmp109:
	.loc	2 218 23                        # experiments/openblas-rvv/results/2026-10-26_r192-schedule-counter-r1/llvm-tuning/build-r2/gemv_n_vector.c:218:23
	slli	s3, s3, 3
	.loc	2 219 23                        # experiments/openblas-rvv/results/2026-10-26_r192-schedule-counter-r1/llvm-tuning/build-r2/gemv_n_vector.c:219:23
	add	a2, a2, s2
.Ltmp110:
	#DEBUG_VALUE: dgemv_n:a_ptr <- $x12
	.loc	2 218 23                        # experiments/openblas-rvv/results/2026-10-26_r192-schedule-counter-r1/llvm-tuning/build-r2/gemv_n_vector.c:218:23
	add	s0, s0, s3
.Ltmp111:
	#DEBUG_VALUE: dgemv_n:y_ptr <- $x8
	.loc	2 220 24                        # experiments/openblas-rvv/results/2026-10-26_r192-schedule-counter-r1/llvm-tuning/build-r2/gemv_n_vector.c:220:24
	add	a4, a4, s2
.Ltmp112:
	#DEBUG_VALUE: dgemv_n:a2_ptr <- $x14
	.loc	2 210 13                        # experiments/openblas-rvv/results/2026-10-26_r192-schedule-counter-r1/llvm-tuning/build-r2/gemv_n_vector.c:210:13
	bgtz	s1, .LBB0_26
	j	.LBB0_23
.Ltmp113:
.LBB0_27:
	#DEBUG_VALUE: stride_y <- $x31
	#DEBUG_VALUE: dgemv_n:y <- $x17
	#DEBUG_VALUE: dgemv_n:alpha <- $f10_d
	#DEBUG_VALUE: dgemv_n:n <- $x11
	#DEBUG_VALUE: dgemv_n:m <- $x10
	.loc	2 225 15                        # experiments/openblas-rvv/results/2026-10-26_r192-schedule-counter-r1/llvm-tuning/build-r2/gemv_n_vector.c:225:15
	andi	a1, a1, 1
.Ltmp114:
	beqz	a1, .LBB0_31
.Ltmp115:
# %bb.28:
	#DEBUG_VALUE: stride_y <- $x31
	#DEBUG_VALUE: dgemv_n:y <- $x17
	#DEBUG_VALUE: dgemv_n:alpha <- $f10_d
	#DEBUG_VALUE: dgemv_n:m <- $x10
	#DEBUG_VALUE: dgemv_n:i <- $x10
	#DEBUG_VALUE: dgemv_n:y_ptr <- $x17
	#DEBUG_VALUE: dgemv_n:a_ptr <- $x13
	#DEBUG_VALUE: dgemv_n:temp <- undef
	.loc	2 229 13                        # experiments/openblas-rvv/results/2026-10-26_r192-schedule-counter-r1/llvm-tuning/build-r2/gemv_n_vector.c:229:13
	blez	a0, .LBB0_31
.Ltmp116:
# %bb.29:
	#DEBUG_VALUE: dgemv_n:a_ptr <- $x13
	#DEBUG_VALUE: dgemv_n:y_ptr <- $x17
	#DEBUG_VALUE: dgemv_n:i <- $x10
	#DEBUG_VALUE: stride_y <- $x31
	#DEBUG_VALUE: dgemv_n:y <- $x17
	#DEBUG_VALUE: dgemv_n:alpha <- $f10_d
	#DEBUG_VALUE: dgemv_n:m <- $x10
	.loc	2 0 13 is_stmt 0                # experiments/openblas-rvv/results/2026-10-26_r192-schedule-counter-r1/llvm-tuning/build-r2/gemv_n_vector.c:0:13
	fld	fa5, 0(a5)
	fmul.d	fa5, fa0, fa5
.Ltmp117:
	#DEBUG_VALUE: dgemv_n:temp <- $f15_d
.LBB0_30:                               # =>This Inner Loop Header: Depth=1
	#DEBUG_VALUE: dgemv_n:temp <- $f15_d
	#DEBUG_VALUE: dgemv_n:a_ptr <- $x13
	#DEBUG_VALUE: dgemv_n:y_ptr <- $x17
	#DEBUG_VALUE: dgemv_n:i <- $x10
	#DEBUG_VALUE: stride_y <- $x31
	#DEBUG_VALUE: dgemv_n:alpha <- $f10_d
	#DEBUG_VALUE: dgemv_n:i <- $x10
	#DEBUG_VALUE: dgemv_n:y_ptr <- $x17
	#DEBUG_VALUE: dgemv_n:a_ptr <- $x13
	.loc	2 230 22 is_stmt 1              # experiments/openblas-rvv/results/2026-10-26_r192-schedule-counter-r1/llvm-tuning/build-r2/gemv_n_vector.c:230:22
	vsetvli	a1, a0, e64, m8, ta, ma
.Ltmp118:
	#DEBUG_VALUE: dgemv_n:vl <- $x11
	.loc	2 231 22                        # experiments/openblas-rvv/results/2026-10-26_r192-schedule-counter-r1/llvm-tuning/build-r2/gemv_n_vector.c:231:22
	vlse64.v	v8, (a7), t6
.Ltmp119:
	#DEBUG_VALUE: dgemv_n:vy <- undef
	.loc	2 232 22                        # experiments/openblas-rvv/results/2026-10-26_r192-schedule-counter-r1/llvm-tuning/build-r2/gemv_n_vector.c:232:22
	vle64.v	v16, (a3)
.Ltmp120:
	#DEBUG_VALUE: dgemv_n:va <- undef
	.loc	2 235 29                        # experiments/openblas-rvv/results/2026-10-26_r192-schedule-counter-r1/llvm-tuning/build-r2/gemv_n_vector.c:235:29
	mul	a2, a1, t0
.Ltmp121:
	.loc	2 229 34                        # experiments/openblas-rvv/results/2026-10-26_r192-schedule-counter-r1/llvm-tuning/build-r2/gemv_n_vector.c:229:34
	sub	a0, a0, a1
.Ltmp122:
	#DEBUG_VALUE: dgemv_n:i <- $x10
	.loc	2 233 22                        # experiments/openblas-rvv/results/2026-10-26_r192-schedule-counter-r1/llvm-tuning/build-r2/gemv_n_vector.c:233:22
	vfmadd.vf	v16, fa5, v8
	.loc	2 234 17                        # experiments/openblas-rvv/results/2026-10-26_r192-schedule-counter-r1/llvm-tuning/build-r2/gemv_n_vector.c:234:17
	vsse64.v	v16, (a7), t6
	.loc	2 236 23                        # experiments/openblas-rvv/results/2026-10-26_r192-schedule-counter-r1/llvm-tuning/build-r2/gemv_n_vector.c:236:23
	slli	a1, a1, 3
.Ltmp123:
	.loc	2 235 23                        # experiments/openblas-rvv/results/2026-10-26_r192-schedule-counter-r1/llvm-tuning/build-r2/gemv_n_vector.c:235:23
	slli	a2, a2, 3
	add	a7, a7, a2
.Ltmp124:
	#DEBUG_VALUE: dgemv_n:y_ptr <- $x17
	.loc	2 236 23                        # experiments/openblas-rvv/results/2026-10-26_r192-schedule-counter-r1/llvm-tuning/build-r2/gemv_n_vector.c:236:23
	add	a3, a3, a1
.Ltmp125:
	#DEBUG_VALUE: dgemv_n:a_ptr <- $x13
	.loc	2 229 13                        # experiments/openblas-rvv/results/2026-10-26_r192-schedule-counter-r1/llvm-tuning/build-r2/gemv_n_vector.c:229:13
	bgtz	a0, .LBB0_30
.Ltmp126:
.LBB0_31:
	#DEBUG_VALUE: dgemv_n:alpha <- $f10_d
	.loc	2 0 13 is_stmt 0                # experiments/openblas-rvv/results/2026-10-26_r192-schedule-counter-r1/llvm-tuning/build-r2/gemv_n_vector.c:0:13
	ld	s0, 24(sp)                      # 8-byte Folded Reload
	ld	s1, 16(sp)                      # 8-byte Folded Reload
	ld	s2, 8(sp)                       # 8-byte Folded Reload
	ld	s3, 0(sp)                       # 8-byte Folded Reload
	.cfi_restore s0
	.cfi_restore s1
	.cfi_restore s2
	.cfi_restore s3
	addi	sp, sp, 32
	.cfi_def_cfa_offset 0
.Ltmp127:
.LBB0_32:
	#DEBUG_VALUE: dgemv_n:alpha <- $f10_d
	.loc	2 241 1 is_stmt 1               # experiments/openblas-rvv/results/2026-10-26_r192-schedule-counter-r1/llvm-tuning/build-r2/gemv_n_vector.c:241:1
	li	a0, 0
	ret
.Ltmp128:
.Lfunc_end0:
	.size	dgemv_n, .Lfunc_end0-dgemv_n
	.cfi_endproc
                                        # -- End function
	.file	3 "/home/uiniu/CodeData/riscv-ai-platform" "output/openblas-r185-row-tail-r1/C256/source/common.h"
	.file	4 "/home/uiniu/CodeData/riscv-ai-platform" "output/clang21-audit-r1/prefix/usr/lib/llvm-21/lib/clang/21/include/riscv_vector.h"
	.section	.debug_loc,"",@progbits
.Ldebug_loc0:
	.quad	.Lfunc_begin0-.Lfunc_begin0
	.quad	.Ltmp83-.Lfunc_begin0
	.half	1                               # Loc expr size
	.byte	90                              # DW_OP_reg10
	.quad	.Ltmp88-.Lfunc_begin0
	.quad	.Ltmp117-.Lfunc_begin0
	.half	1                               # Loc expr size
	.byte	90                              # DW_OP_reg10
	.quad	0
	.quad	0
.Ldebug_loc1:
	.quad	.Lfunc_begin0-.Lfunc_begin0
	.quad	.Ltmp67-.Lfunc_begin0
	.half	1                               # Loc expr size
	.byte	91                              # DW_OP_reg11
	.quad	.Ltmp88-.Lfunc_begin0
	.quad	.Ltmp114-.Lfunc_begin0
	.half	1                               # Loc expr size
	.byte	91                              # DW_OP_reg11
	.quad	0
	.quad	0
.Ldebug_loc2:
	.quad	.Lfunc_begin0-.Lfunc_begin0
	.quad	.Ltmp1-.Lfunc_begin0
	.half	1                               # Loc expr size
	.byte	92                              # DW_OP_reg12
	.quad	0
	.quad	0
.Ldebug_loc3:
	.quad	.Lfunc_begin0-.Lfunc_begin0
	.quad	.Ltmp69-.Lfunc_begin0
	.half	1                               # Loc expr size
	.byte	93                              # DW_OP_reg13
	.quad	.Ltmp88-.Lfunc_begin0
	.quad	.Ltmp89-.Lfunc_begin0
	.half	1                               # Loc expr size
	.byte	93                              # DW_OP_reg13
	.quad	.Ltmp93-.Lfunc_begin0
	.quad	.Ltmp113-.Lfunc_begin0
	.half	1                               # Loc expr size
	.byte	93                              # DW_OP_reg13
	.quad	0
	.quad	0
.Ldebug_loc4:
	.quad	.Lfunc_begin0-.Lfunc_begin0
	.quad	.Ltmp72-.Lfunc_begin0
	.half	1                               # Loc expr size
	.byte	94                              # DW_OP_reg14
	.quad	.Ltmp88-.Lfunc_begin0
	.quad	.Ltmp93-.Lfunc_begin0
	.half	1                               # Loc expr size
	.byte	94                              # DW_OP_reg14
	.quad	0
	.quad	0
.Ldebug_loc5:
	.quad	.Lfunc_begin0-.Lfunc_begin0
	.quad	.Ltmp72-.Lfunc_begin0
	.half	1                               # Loc expr size
	.byte	95                              # DW_OP_reg15
	.quad	.Ltmp88-.Lfunc_begin0
	.quad	.Ltmp89-.Lfunc_begin0
	.half	1                               # Loc expr size
	.byte	95                              # DW_OP_reg15
	.quad	.Ltmp93-.Lfunc_begin0
	.quad	.Ltmp113-.Lfunc_begin0
	.half	1                               # Loc expr size
	.byte	95                              # DW_OP_reg15
	.quad	0
	.quad	0
.Ldebug_loc6:
	.quad	.Lfunc_begin0-.Lfunc_begin0
	.quad	.Ltmp92-.Lfunc_begin0
	.half	1                               # Loc expr size
	.byte	96                              # DW_OP_reg16
	.quad	0
	.quad	0
.Ldebug_loc7:
	.quad	.Lfunc_begin0-.Lfunc_begin0
	.quad	.Ltmp85-.Lfunc_begin0
	.half	1                               # Loc expr size
	.byte	97                              # DW_OP_reg17
	.quad	.Ltmp88-.Lfunc_begin0
	.quad	.Ltmp117-.Lfunc_begin0
	.half	1                               # Loc expr size
	.byte	97                              # DW_OP_reg17
	.quad	0
	.quad	0
.Ldebug_loc8:
	.quad	.Lfunc_begin0-.Lfunc_begin0
	.quad	.Ltmp2-.Lfunc_begin0
	.half	2                               # Loc expr size
	.byte	114                             # DW_OP_breg2
	.byte	32                              # 32
	.quad	0
	.quad	0
.Ldebug_loc9:
	.quad	.Lfunc_begin0-.Lfunc_begin0
	.quad	.Ltmp2-.Lfunc_begin0
	.half	2                               # Loc expr size
	.byte	114                             # DW_OP_breg2
	.byte	40                              # 40
	.quad	0
	.quad	0
.Ldebug_loc10:
	.quad	.Ltmp4-.Lfunc_begin0
	.quad	.Ltmp88-.Lfunc_begin0
	.half	1                               # Loc expr size
	.byte	110                             # DW_OP_reg30
	.quad	0
	.quad	0
.Ldebug_loc11:
	.quad	.Ltmp4-.Lfunc_begin0
	.quad	.Ltmp6-.Lfunc_begin0
	.half	2                               # Loc expr size
	.byte	48                              # DW_OP_lit0
	.byte	159                             # DW_OP_stack_value
	.quad	.Ltmp6-.Lfunc_begin0
	.quad	.Ltmp8-.Lfunc_begin0
	.half	1                               # Loc expr size
	.byte	85                              # DW_OP_reg5
	.quad	.Ltmp39-.Lfunc_begin0
	.quad	.Ltmp40-.Lfunc_begin0
	.half	1                               # Loc expr size
	.byte	85                              # DW_OP_reg5
	.quad	.Ltmp63-.Lfunc_begin0
	.quad	.Ltmp88-.Lfunc_begin0
	.half	1                               # Loc expr size
	.byte	85                              # DW_OP_reg5
	.quad	.Ltmp90-.Lfunc_begin0
	.quad	.Ltmp93-.Lfunc_begin0
	.half	2                               # Loc expr size
	.byte	48                              # DW_OP_lit0
	.byte	159                             # DW_OP_stack_value
	.quad	.Ltmp93-.Lfunc_begin0
	.quad	.Ltmp113-.Lfunc_begin0
	.half	1                               # Loc expr size
	.byte	87                              # DW_OP_reg7
	.quad	0
	.quad	0
.Ldebug_loc12:
	.quad	.Ltmp10-.Lfunc_begin0
	.quad	.Ltmp32-.Lfunc_begin0
	.half	1                               # Loc expr size
	.byte	108                             # DW_OP_reg28
	.quad	0
	.quad	0
.Ldebug_loc13:
	.quad	.Ltmp11-.Lfunc_begin0
	.quad	.Ltmp33-.Lfunc_begin0
	.half	1                               # Loc expr size
	.byte	109                             # DW_OP_reg29
	.quad	0
	.quad	0
.Ldebug_loc14:
	.quad	.Ltmp12-.Lfunc_begin0
	.quad	.Ltmp37-.Lfunc_begin0
	.half	1                               # Loc expr size
	.byte	87                              # DW_OP_reg7
	.quad	0
	.quad	0
.Ldebug_loc15:
	.quad	.Ltmp13-.Lfunc_begin0
	.quad	.Ltmp38-.Lfunc_begin0
	.half	1                               # Loc expr size
	.byte	86                              # DW_OP_reg6
	.quad	0
	.quad	0
.Ldebug_loc16:
	.quad	.Ltmp14-.Lfunc_begin0
	.quad	.Ltmp39-.Lfunc_begin0
	.half	2                               # Loc expr size
	.byte	144                             # DW_OP_regx
	.byte	45                              # 45
	.quad	0
	.quad	0
.Ldebug_loc17:
	.quad	.Ltmp15-.Lfunc_begin0
	.quad	.Ltmp39-.Lfunc_begin0
	.half	2                               # Loc expr size
	.byte	144                             # DW_OP_regx
	.byte	44                              # 44
	.quad	0
	.quad	0
.Ldebug_loc18:
	.quad	.Ltmp16-.Lfunc_begin0
	.quad	.Ltmp39-.Lfunc_begin0
	.half	2                               # Loc expr size
	.byte	144                             # DW_OP_regx
	.byte	46                              # 46
	.quad	0
	.quad	0
.Ldebug_loc19:
	.quad	.Ltmp17-.Lfunc_begin0
	.quad	.Ltmp39-.Lfunc_begin0
	.half	2                               # Loc expr size
	.byte	144                             # DW_OP_regx
	.byte	47                              # 47
	.quad	0
	.quad	0
.Ldebug_loc20:
	.quad	.Ltmp17-.Lfunc_begin0
	.quad	.Ltmp20-.Lfunc_begin0
	.half	2                               # Loc expr size
	.byte	48                              # DW_OP_lit0
	.byte	159                             # DW_OP_stack_value
	.quad	.Ltmp20-.Lfunc_begin0
	.quad	.Ltmp22-.Lfunc_begin0
	.half	1                               # Loc expr size
	.byte	92                              # DW_OP_reg12
	.quad	.Ltmp26-.Lfunc_begin0
	.quad	.Ltmp28-.Lfunc_begin0
	.half	12                              # Loc expr size
	.byte	121                             # DW_OP_breg9
	.byte	0                               # 0
	.byte	142                             # DW_OP_breg30
	.byte	0                               # 0
	.byte	27                              # DW_OP_div
	.byte	142                             # DW_OP_breg30
	.byte	0                               # 0
	.byte	30                              # DW_OP_mul
	.byte	142                             # DW_OP_breg30
	.byte	0                               # 0
	.byte	34                              # DW_OP_plus
	.byte	159                             # DW_OP_stack_value
	.quad	.Ltmp44-.Lfunc_begin0
	.quad	.Ltmp46-.Lfunc_begin0
	.half	2                               # Loc expr size
	.byte	48                              # DW_OP_lit0
	.byte	159                             # DW_OP_stack_value
	.quad	.Ltmp46-.Lfunc_begin0
	.quad	.Ltmp47-.Lfunc_begin0
	.half	1                               # Loc expr size
	.byte	89                              # DW_OP_reg9
	.quad	.Ltmp54-.Lfunc_begin0
	.quad	.Ltmp55-.Lfunc_begin0
	.half	12                              # Loc expr size
	.byte	124                             # DW_OP_breg12
	.byte	0                               # 0
	.byte	142                             # DW_OP_breg30
	.byte	0                               # 0
	.byte	27                              # DW_OP_div
	.byte	142                             # DW_OP_breg30
	.byte	0                               # 0
	.byte	30                              # DW_OP_mul
	.byte	142                             # DW_OP_breg30
	.byte	0                               # 0
	.byte	34                              # DW_OP_plus
	.byte	159                             # DW_OP_stack_value
	.quad	.Ltmp69-.Lfunc_begin0
	.quad	.Ltmp72-.Lfunc_begin0
	.half	2                               # Loc expr size
	.byte	48                              # DW_OP_lit0
	.byte	159                             # DW_OP_stack_value
	.quad	.Ltmp72-.Lfunc_begin0
	.quad	.Ltmp73-.Lfunc_begin0
	.half	1                               # Loc expr size
	.byte	92                              # DW_OP_reg12
	.quad	.Ltmp79-.Lfunc_begin0
	.quad	.Ltmp81-.Lfunc_begin0
	.half	12                              # Loc expr size
	.byte	123                             # DW_OP_breg11
	.byte	0                               # 0
	.byte	142                             # DW_OP_breg30
	.byte	0                               # 0
	.byte	27                              # DW_OP_div
	.byte	142                             # DW_OP_breg30
	.byte	0                               # 0
	.byte	30                              # DW_OP_mul
	.byte	142                             # DW_OP_breg30
	.byte	0                               # 0
	.byte	34                              # DW_OP_plus
	.byte	159                             # DW_OP_stack_value
	.quad	.Ltmp97-.Lfunc_begin0
	.quad	.Ltmp102-.Lfunc_begin0
	.half	1                               # Loc expr size
	.byte	90                              # DW_OP_reg10
	.quad	.Ltmp102-.Lfunc_begin0
	.quad	.Ltmp113-.Lfunc_begin0
	.half	1                               # Loc expr size
	.byte	89                              # DW_OP_reg9
	.quad	.Ltmp115-.Lfunc_begin0
	.quad	.Ltmp126-.Lfunc_begin0
	.half	1                               # Loc expr size
	.byte	90                              # DW_OP_reg10
	.quad	0
	.quad	0
.Ldebug_loc21:
	.quad	.Ltmp21-.Lfunc_begin0
	.quad	.Ltmp28-.Lfunc_begin0
	.half	1                               # Loc expr size
	.byte	111                             # DW_OP_reg31
	.quad	.Ltmp31-.Lfunc_begin0
	.quad	.Ltmp39-.Lfunc_begin0
	.half	1                               # Loc expr size
	.byte	92                              # DW_OP_reg12
	.quad	.Ltmp48-.Lfunc_begin0
	.quad	.Ltmp55-.Lfunc_begin0
	.half	1                               # Loc expr size
	.byte	88                              # DW_OP_reg8
	.quad	.Ltmp58-.Lfunc_begin0
	.quad	.Ltmp63-.Lfunc_begin0
	.half	1                               # Loc expr size
	.byte	89                              # DW_OP_reg9
	.quad	.Ltmp74-.Lfunc_begin0
	.quad	.Ltmp81-.Lfunc_begin0
	.half	1                               # Loc expr size
	.byte	94                              # DW_OP_reg14
	.quad	.Ltmp85-.Lfunc_begin0
	.quad	.Ltmp88-.Lfunc_begin0
	.half	1                               # Loc expr size
	.byte	97                              # DW_OP_reg17
	.quad	.Ltmp97-.Lfunc_begin0
	.quad	.Ltmp102-.Lfunc_begin0
	.half	1                               # Loc expr size
	.byte	97                              # DW_OP_reg17
	.quad	.Ltmp102-.Lfunc_begin0
	.quad	.Ltmp113-.Lfunc_begin0
	.half	1                               # Loc expr size
	.byte	88                              # DW_OP_reg8
	.quad	.Ltmp115-.Lfunc_begin0
	.quad	.Ltmp126-.Lfunc_begin0
	.half	1                               # Loc expr size
	.byte	97                              # DW_OP_reg17
	.quad	0
	.quad	0
.Ldebug_loc22:
	.quad	.Ltmp103-.Lfunc_begin0
	.quad	.Ltmp109-.Lfunc_begin0
	.half	1                               # Loc expr size
	.byte	98                              # DW_OP_reg18
	.quad	.Ltmp118-.Lfunc_begin0
	.quad	.Ltmp123-.Lfunc_begin0
	.half	1                               # Loc expr size
	.byte	91                              # DW_OP_reg11
	.quad	0
	.quad	0
.Ldebug_loc23:
	.quad	.Ltmp41-.Lfunc_begin0
	.quad	.Ltmp59-.Lfunc_begin0
	.half	1                               # Loc expr size
	.byte	86                              # DW_OP_reg6
	.quad	.Ltmp69-.Lfunc_begin0
	.quad	.Ltmp88-.Lfunc_begin0
	.half	1                               # Loc expr size
	.byte	93                              # DW_OP_reg13
	.quad	.Ltmp97-.Lfunc_begin0
	.quad	.Ltmp102-.Lfunc_begin0
	.half	1                               # Loc expr size
	.byte	93                              # DW_OP_reg13
	.quad	.Ltmp102-.Lfunc_begin0
	.quad	.Ltmp113-.Lfunc_begin0
	.half	1                               # Loc expr size
	.byte	92                              # DW_OP_reg12
	.quad	.Ltmp115-.Lfunc_begin0
	.quad	.Ltmp126-.Lfunc_begin0
	.half	1                               # Loc expr size
	.byte	93                              # DW_OP_reg13
	.quad	0
	.quad	0
.Ldebug_loc24:
	.quad	.Ltmp42-.Lfunc_begin0
	.quad	.Ltmp63-.Lfunc_begin0
	.half	2                               # Loc expr size
	.byte	144                             # DW_OP_regx
	.byte	46                              # 46
	.quad	.Ltmp68-.Lfunc_begin0
	.quad	.Ltmp88-.Lfunc_begin0
	.half	2                               # Loc expr size
	.byte	144                             # DW_OP_regx
	.byte	47                              # 47
	.quad	.Ltmp99-.Lfunc_begin0
	.quad	.Ltmp113-.Lfunc_begin0
	.half	2                               # Loc expr size
	.byte	144                             # DW_OP_regx
	.byte	47                              # 47
	.quad	.Ltmp117-.Lfunc_begin0
	.quad	.Ltmp126-.Lfunc_begin0
	.half	2                               # Loc expr size
	.byte	144                             # DW_OP_regx
	.byte	47                              # 47
	.quad	0
	.quad	0
.Ldebug_loc25:
	.quad	.Ltmp43-.Lfunc_begin0
	.quad	.Ltmp63-.Lfunc_begin0
	.half	2                               # Loc expr size
	.byte	144                             # DW_OP_regx
	.byte	47                              # 47
	.quad	.Ltmp100-.Lfunc_begin0
	.quad	.Ltmp113-.Lfunc_begin0
	.half	2                               # Loc expr size
	.byte	144                             # DW_OP_regx
	.byte	46                              # 46
	.quad	0
	.quad	0
.Ldebug_loc26:
	.quad	.Ltmp44-.Lfunc_begin0
	.quad	.Ltmp63-.Lfunc_begin0
	.half	1                               # Loc expr size
	.byte	87                              # DW_OP_reg7
	.quad	.Ltmp101-.Lfunc_begin0
	.quad	.Ltmp113-.Lfunc_begin0
	.half	1                               # Loc expr size
	.byte	94                              # DW_OP_reg14
	.quad	0
	.quad	0
.Ldebug_loc27:
	.quad	.Ltmp90-.Lfunc_begin0
	.quad	.Ltmp126-.Lfunc_begin0
	.half	1                               # Loc expr size
	.byte	111                             # DW_OP_reg31
	.quad	0
	.quad	0
	.section	.debug_abbrev,"",@progbits
	.byte	1                               # Abbreviation Code
	.byte	17                              # DW_TAG_compile_unit
	.byte	1                               # DW_CHILDREN_yes
	.byte	37                              # DW_AT_producer
	.byte	14                              # DW_FORM_strp
	.byte	19                              # DW_AT_language
	.byte	5                               # DW_FORM_data2
	.byte	3                               # DW_AT_name
	.byte	14                              # DW_FORM_strp
	.byte	16                              # DW_AT_stmt_list
	.byte	23                              # DW_FORM_sec_offset
	.byte	27                              # DW_AT_comp_dir
	.byte	14                              # DW_FORM_strp
	.byte	17                              # DW_AT_low_pc
	.byte	1                               # DW_FORM_addr
	.byte	18                              # DW_AT_high_pc
	.byte	6                               # DW_FORM_data4
	.byte	0                               # EOM(1)
	.byte	0                               # EOM(2)
	.byte	2                               # Abbreviation Code
	.byte	22                              # DW_TAG_typedef
	.byte	0                               # DW_CHILDREN_no
	.byte	73                              # DW_AT_type
	.byte	19                              # DW_FORM_ref4
	.byte	3                               # DW_AT_name
	.byte	14                              # DW_FORM_strp
	.byte	58                              # DW_AT_decl_file
	.byte	11                              # DW_FORM_data1
	.byte	59                              # DW_AT_decl_line
	.byte	11                              # DW_FORM_data1
	.byte	0                               # EOM(1)
	.byte	0                               # EOM(2)
	.byte	3                               # Abbreviation Code
	.byte	36                              # DW_TAG_base_type
	.byte	0                               # DW_CHILDREN_no
	.byte	3                               # DW_AT_name
	.byte	14                              # DW_FORM_strp
	.byte	62                              # DW_AT_encoding
	.byte	11                              # DW_FORM_data1
	.byte	11                              # DW_AT_byte_size
	.byte	11                              # DW_FORM_data1
	.byte	0                               # EOM(1)
	.byte	0                               # EOM(2)
	.byte	4                               # Abbreviation Code
	.byte	46                              # DW_TAG_subprogram
	.byte	1                               # DW_CHILDREN_yes
	.byte	17                              # DW_AT_low_pc
	.byte	1                               # DW_FORM_addr
	.byte	18                              # DW_AT_high_pc
	.byte	6                               # DW_FORM_data4
	.byte	64                              # DW_AT_frame_base
	.byte	24                              # DW_FORM_exprloc
	.ascii	"\227B"                         # DW_AT_GNU_all_call_sites
	.byte	25                              # DW_FORM_flag_present
	.byte	3                               # DW_AT_name
	.byte	14                              # DW_FORM_strp
	.byte	58                              # DW_AT_decl_file
	.byte	11                              # DW_FORM_data1
	.byte	59                              # DW_AT_decl_line
	.byte	11                              # DW_FORM_data1
	.byte	39                              # DW_AT_prototyped
	.byte	25                              # DW_FORM_flag_present
	.byte	73                              # DW_AT_type
	.byte	19                              # DW_FORM_ref4
	.byte	63                              # DW_AT_external
	.byte	25                              # DW_FORM_flag_present
	.byte	0                               # EOM(1)
	.byte	0                               # EOM(2)
	.byte	5                               # Abbreviation Code
	.byte	5                               # DW_TAG_formal_parameter
	.byte	0                               # DW_CHILDREN_no
	.byte	2                               # DW_AT_location
	.byte	23                              # DW_FORM_sec_offset
	.byte	3                               # DW_AT_name
	.byte	14                              # DW_FORM_strp
	.byte	58                              # DW_AT_decl_file
	.byte	11                              # DW_FORM_data1
	.byte	59                              # DW_AT_decl_line
	.byte	11                              # DW_FORM_data1
	.byte	73                              # DW_AT_type
	.byte	19                              # DW_FORM_ref4
	.byte	0                               # EOM(1)
	.byte	0                               # EOM(2)
	.byte	6                               # Abbreviation Code
	.byte	5                               # DW_TAG_formal_parameter
	.byte	0                               # DW_CHILDREN_no
	.byte	2                               # DW_AT_location
	.byte	24                              # DW_FORM_exprloc
	.byte	3                               # DW_AT_name
	.byte	14                              # DW_FORM_strp
	.byte	58                              # DW_AT_decl_file
	.byte	11                              # DW_FORM_data1
	.byte	59                              # DW_AT_decl_line
	.byte	11                              # DW_FORM_data1
	.byte	73                              # DW_AT_type
	.byte	19                              # DW_FORM_ref4
	.byte	0                               # EOM(1)
	.byte	0                               # EOM(2)
	.byte	7                               # Abbreviation Code
	.byte	52                              # DW_TAG_variable
	.byte	0                               # DW_CHILDREN_no
	.byte	2                               # DW_AT_location
	.byte	23                              # DW_FORM_sec_offset
	.byte	3                               # DW_AT_name
	.byte	14                              # DW_FORM_strp
	.byte	58                              # DW_AT_decl_file
	.byte	11                              # DW_FORM_data1
	.byte	59                              # DW_AT_decl_line
	.byte	11                              # DW_FORM_data1
	.byte	73                              # DW_AT_type
	.byte	19                              # DW_FORM_ref4
	.byte	0                               # EOM(1)
	.byte	0                               # EOM(2)
	.byte	8                               # Abbreviation Code
	.byte	52                              # DW_TAG_variable
	.byte	0                               # DW_CHILDREN_no
	.byte	3                               # DW_AT_name
	.byte	14                              # DW_FORM_strp
	.byte	58                              # DW_AT_decl_file
	.byte	11                              # DW_FORM_data1
	.byte	59                              # DW_AT_decl_line
	.byte	11                              # DW_FORM_data1
	.byte	73                              # DW_AT_type
	.byte	19                              # DW_FORM_ref4
	.byte	0                               # EOM(1)
	.byte	0                               # EOM(2)
	.byte	9                               # Abbreviation Code
	.byte	11                              # DW_TAG_lexical_block
	.byte	1                               # DW_CHILDREN_yes
	.byte	17                              # DW_AT_low_pc
	.byte	1                               # DW_FORM_addr
	.byte	18                              # DW_AT_high_pc
	.byte	6                               # DW_FORM_data4
	.byte	0                               # EOM(1)
	.byte	0                               # EOM(2)
	.byte	10                              # Abbreviation Code
	.byte	22                              # DW_TAG_typedef
	.byte	0                               # DW_CHILDREN_no
	.byte	73                              # DW_AT_type
	.byte	19                              # DW_FORM_ref4
	.byte	3                               # DW_AT_name
	.byte	14                              # DW_FORM_strp
	.byte	58                              # DW_AT_decl_file
	.byte	11                              # DW_FORM_data1
	.byte	59                              # DW_AT_decl_line
	.byte	5                               # DW_FORM_data2
	.byte	0                               # EOM(1)
	.byte	0                               # EOM(2)
	.byte	11                              # Abbreviation Code
	.byte	15                              # DW_TAG_pointer_type
	.byte	0                               # DW_CHILDREN_no
	.byte	73                              # DW_AT_type
	.byte	19                              # DW_FORM_ref4
	.byte	0                               # EOM(1)
	.byte	0                               # EOM(2)
	.byte	12                              # Abbreviation Code
	.byte	38                              # DW_TAG_const_type
	.byte	0                               # DW_CHILDREN_no
	.byte	73                              # DW_AT_type
	.byte	19                              # DW_FORM_ref4
	.byte	0                               # EOM(1)
	.byte	0                               # EOM(2)
	.byte	13                              # Abbreviation Code
	.byte	22                              # DW_TAG_typedef
	.byte	0                               # DW_CHILDREN_no
	.byte	73                              # DW_AT_type
	.byte	19                              # DW_FORM_ref4
	.byte	3                               # DW_AT_name
	.byte	14                              # DW_FORM_strp
	.byte	0                               # EOM(1)
	.byte	0                               # EOM(2)
	.byte	14                              # Abbreviation Code
	.byte	1                               # DW_TAG_array_type
	.byte	1                               # DW_CHILDREN_yes
	.ascii	"\207B"                         # DW_AT_GNU_vector
	.byte	25                              # DW_FORM_flag_present
	.byte	73                              # DW_AT_type
	.byte	19                              # DW_FORM_ref4
	.byte	0                               # EOM(1)
	.byte	0                               # EOM(2)
	.byte	15                              # Abbreviation Code
	.byte	33                              # DW_TAG_subrange_type
	.byte	0                               # DW_CHILDREN_no
	.byte	73                              # DW_AT_type
	.byte	19                              # DW_FORM_ref4
	.byte	34                              # DW_AT_lower_bound
	.byte	13                              # DW_FORM_sdata
	.byte	47                              # DW_AT_upper_bound
	.byte	24                              # DW_FORM_exprloc
	.byte	0                               # EOM(1)
	.byte	0                               # EOM(2)
	.byte	16                              # Abbreviation Code
	.byte	36                              # DW_TAG_base_type
	.byte	0                               # DW_CHILDREN_no
	.byte	3                               # DW_AT_name
	.byte	14                              # DW_FORM_strp
	.byte	11                              # DW_AT_byte_size
	.byte	11                              # DW_FORM_data1
	.byte	62                              # DW_AT_encoding
	.byte	11                              # DW_FORM_data1
	.byte	0                               # EOM(1)
	.byte	0                               # EOM(2)
	.byte	0                               # EOM(3)
	.section	.debug_info,"",@progbits
.Lcu_begin0:
	.word	.Ldebug_info_end0-.Ldebug_info_start0 # Length of Unit
.Ldebug_info_start0:
	.half	4                               # DWARF version number
	.word	.debug_abbrev                   # Offset Into Abbrev. Section
	.byte	8                               # Address Size (in bytes)
	.byte	1                               # Abbrev [1] 0xb:0x2a7 DW_TAG_compile_unit
	.word	.Linfo_string0                  # DW_AT_producer
	.half	29                              # DW_AT_language
	.word	.Linfo_string1                  # DW_AT_name
	.word	.Lline_table_start0             # DW_AT_stmt_list
	.word	.Linfo_string2                  # DW_AT_comp_dir
	.quad	.Lfunc_begin0                   # DW_AT_low_pc
	.word	.Lfunc_end0-.Lfunc_begin0       # DW_AT_high_pc
	.byte	2                               # Abbrev [2] 0x2a:0xb DW_TAG_typedef
	.word	53                              # DW_AT_type
	.word	.Linfo_string4                  # DW_AT_name
	.byte	1                               # DW_AT_decl_file
	.byte	18                              # DW_AT_decl_line
	.byte	3                               # Abbrev [3] 0x35:0x7 DW_TAG_base_type
	.word	.Linfo_string3                  # DW_AT_name
	.byte	7                               # DW_AT_encoding
	.byte	8                               # DW_AT_byte_size
	.byte	4                               # Abbrev [4] 0x3c:0x217 DW_TAG_subprogram
	.quad	.Lfunc_begin0                   # DW_AT_low_pc
	.word	.Lfunc_end0-.Lfunc_begin0       # DW_AT_high_pc
	.byte	1                               # DW_AT_frame_base
	.byte	82
                                        # DW_AT_GNU_all_call_sites
	.word	.Linfo_string5                  # DW_AT_name
	.byte	2                               # DW_AT_decl_file
	.byte	58                              # DW_AT_decl_line
                                        # DW_AT_prototyped
	.word	595                             # DW_AT_type
                                        # DW_AT_external
	.byte	5                               # Abbrev [5] 0x55:0xf DW_TAG_formal_parameter
	.word	.Ldebug_loc0                    # DW_AT_location
	.word	.Linfo_string7                  # DW_AT_name
	.byte	2                               # DW_AT_decl_file
	.byte	58                              # DW_AT_decl_line
	.word	602                             # DW_AT_type
	.byte	5                               # Abbrev [5] 0x64:0xf DW_TAG_formal_parameter
	.word	.Ldebug_loc1                    # DW_AT_location
	.word	.Linfo_string10                 # DW_AT_name
	.byte	2                               # DW_AT_decl_file
	.byte	58                              # DW_AT_decl_line
	.word	602                             # DW_AT_type
	.byte	5                               # Abbrev [5] 0x73:0xf DW_TAG_formal_parameter
	.word	.Ldebug_loc2                    # DW_AT_location
	.word	.Linfo_string11                 # DW_AT_name
	.byte	2                               # DW_AT_decl_file
	.byte	58                              # DW_AT_decl_line
	.word	602                             # DW_AT_type
	.byte	6                               # Abbrev [6] 0x82:0xe DW_TAG_formal_parameter
	.byte	2                               # DW_AT_location
	.byte	144
	.byte	42
	.word	.Linfo_string12                 # DW_AT_name
	.byte	2                               # DW_AT_decl_file
	.byte	58                              # DW_AT_decl_line
	.word	621                             # DW_AT_type
	.byte	5                               # Abbrev [5] 0x90:0xf DW_TAG_formal_parameter
	.word	.Ldebug_loc3                    # DW_AT_location
	.word	.Linfo_string14                 # DW_AT_name
	.byte	2                               # DW_AT_decl_file
	.byte	58                              # DW_AT_decl_line
	.word	628                             # DW_AT_type
	.byte	5                               # Abbrev [5] 0x9f:0xf DW_TAG_formal_parameter
	.word	.Ldebug_loc4                    # DW_AT_location
	.word	.Linfo_string15                 # DW_AT_name
	.byte	2                               # DW_AT_decl_file
	.byte	58                              # DW_AT_decl_line
	.word	602                             # DW_AT_type
	.byte	5                               # Abbrev [5] 0xae:0xf DW_TAG_formal_parameter
	.word	.Ldebug_loc5                    # DW_AT_location
	.word	.Linfo_string16                 # DW_AT_name
	.byte	2                               # DW_AT_decl_file
	.byte	58                              # DW_AT_decl_line
	.word	628                             # DW_AT_type
	.byte	5                               # Abbrev [5] 0xbd:0xf DW_TAG_formal_parameter
	.word	.Ldebug_loc6                    # DW_AT_location
	.word	.Linfo_string17                 # DW_AT_name
	.byte	2                               # DW_AT_decl_file
	.byte	58                              # DW_AT_decl_line
	.word	602                             # DW_AT_type
	.byte	5                               # Abbrev [5] 0xcc:0xf DW_TAG_formal_parameter
	.word	.Ldebug_loc7                    # DW_AT_location
	.word	.Linfo_string18                 # DW_AT_name
	.byte	2                               # DW_AT_decl_file
	.byte	58                              # DW_AT_decl_line
	.word	628                             # DW_AT_type
	.byte	5                               # Abbrev [5] 0xdb:0xf DW_TAG_formal_parameter
	.word	.Ldebug_loc8                    # DW_AT_location
	.word	.Linfo_string19                 # DW_AT_name
	.byte	2                               # DW_AT_decl_file
	.byte	58                              # DW_AT_decl_line
	.word	602                             # DW_AT_type
	.byte	5                               # Abbrev [5] 0xea:0xf DW_TAG_formal_parameter
	.word	.Ldebug_loc9                    # DW_AT_location
	.word	.Linfo_string20                 # DW_AT_name
	.byte	2                               # DW_AT_decl_file
	.byte	58                              # DW_AT_decl_line
	.word	628                             # DW_AT_type
	.byte	7                               # Abbrev [7] 0xf9:0xf DW_TAG_variable
	.word	.Ldebug_loc11                   # DW_AT_location
	.word	.Linfo_string22                 # DW_AT_name
	.byte	2                               # DW_AT_decl_file
	.byte	63                              # DW_AT_decl_line
	.word	602                             # DW_AT_type
	.byte	7                               # Abbrev [7] 0x108:0xf DW_TAG_variable
	.word	.Ldebug_loc20                   # DW_AT_location
	.word	.Linfo_string31                 # DW_AT_name
	.byte	2                               # DW_AT_decl_file
	.byte	63                              # DW_AT_decl_line
	.word	602                             # DW_AT_type
	.byte	7                               # Abbrev [7] 0x117:0xf DW_TAG_variable
	.word	.Ldebug_loc21                   # DW_AT_location
	.word	.Linfo_string32                 # DW_AT_name
	.byte	2                               # DW_AT_decl_file
	.byte	62                              # DW_AT_decl_line
	.word	628                             # DW_AT_type
	.byte	7                               # Abbrev [7] 0x126:0xf DW_TAG_variable
	.word	.Ldebug_loc22                   # DW_AT_location
	.word	.Linfo_string33                 # DW_AT_name
	.byte	2                               # DW_AT_decl_file
	.byte	63                              # DW_AT_decl_line
	.word	602                             # DW_AT_type
	.byte	7                               # Abbrev [7] 0x135:0xf DW_TAG_variable
	.word	.Ldebug_loc23                   # DW_AT_location
	.word	.Linfo_string34                 # DW_AT_name
	.byte	2                               # DW_AT_decl_file
	.byte	62                              # DW_AT_decl_line
	.word	628                             # DW_AT_type
	.byte	7                               # Abbrev [7] 0x144:0xf DW_TAG_variable
	.word	.Ldebug_loc24                   # DW_AT_location
	.word	.Linfo_string35                 # DW_AT_name
	.byte	2                               # DW_AT_decl_file
	.byte	62                              # DW_AT_decl_line
	.word	621                             # DW_AT_type
	.byte	7                               # Abbrev [7] 0x153:0xf DW_TAG_variable
	.word	.Ldebug_loc25                   # DW_AT_location
	.word	.Linfo_string36                 # DW_AT_name
	.byte	2                               # DW_AT_decl_file
	.byte	62                              # DW_AT_decl_line
	.word	621                             # DW_AT_type
	.byte	7                               # Abbrev [7] 0x162:0xf DW_TAG_variable
	.word	.Ldebug_loc26                   # DW_AT_location
	.word	.Linfo_string37                 # DW_AT_name
	.byte	2                               # DW_AT_decl_file
	.byte	62                              # DW_AT_decl_line
	.word	628                             # DW_AT_type
	.byte	8                               # Abbrev [8] 0x171:0xb DW_TAG_variable
	.word	.Linfo_string39                 # DW_AT_name
	.byte	2                               # DW_AT_decl_file
	.byte	64                              # DW_AT_decl_line
	.word	638                             # DW_AT_type
	.byte	8                               # Abbrev [8] 0x17c:0xb DW_TAG_variable
	.word	.Linfo_string43                 # DW_AT_name
	.byte	2                               # DW_AT_decl_file
	.byte	64                              # DW_AT_decl_line
	.word	638                             # DW_AT_type
	.byte	8                               # Abbrev [8] 0x187:0xb DW_TAG_variable
	.word	.Linfo_string44                 # DW_AT_name
	.byte	2                               # DW_AT_decl_file
	.byte	64                              # DW_AT_decl_line
	.word	638                             # DW_AT_type
	.byte	9                               # Abbrev [9] 0x192:0xa3 DW_TAG_lexical_block
	.quad	.Ltmp3                          # DW_AT_low_pc
	.word	.Ltmp88-.Ltmp3                  # DW_AT_high_pc
	.byte	7                               # Abbrev [7] 0x19f:0xf DW_TAG_variable
	.word	.Ldebug_loc10                   # DW_AT_location
	.word	.Linfo_string21                 # DW_AT_name
	.byte	2                               # DW_AT_decl_file
	.byte	68                              # DW_AT_decl_line
	.word	633                             # DW_AT_type
	.byte	9                               # Abbrev [9] 0x1ae:0x86 DW_TAG_lexical_block
	.quad	.Ltmp8                          # DW_AT_low_pc
	.word	.Ltmp39-.Ltmp8                  # DW_AT_high_pc
	.byte	7                               # Abbrev [7] 0x1bb:0xf DW_TAG_variable
	.word	.Ldebug_loc12                   # DW_AT_location
	.word	.Linfo_string23                 # DW_AT_name
	.byte	2                               # DW_AT_decl_file
	.byte	81                              # DW_AT_decl_line
	.word	628                             # DW_AT_type
	.byte	7                               # Abbrev [7] 0x1ca:0xf DW_TAG_variable
	.word	.Ldebug_loc13                   # DW_AT_location
	.word	.Linfo_string24                 # DW_AT_name
	.byte	2                               # DW_AT_decl_file
	.byte	82                              # DW_AT_decl_line
	.word	628                             # DW_AT_type
	.byte	7                               # Abbrev [7] 0x1d9:0xf DW_TAG_variable
	.word	.Ldebug_loc14                   # DW_AT_location
	.word	.Linfo_string25                 # DW_AT_name
	.byte	2                               # DW_AT_decl_file
	.byte	83                              # DW_AT_decl_line
	.word	628                             # DW_AT_type
	.byte	7                               # Abbrev [7] 0x1e8:0xf DW_TAG_variable
	.word	.Ldebug_loc15                   # DW_AT_location
	.word	.Linfo_string26                 # DW_AT_name
	.byte	2                               # DW_AT_decl_file
	.byte	84                              # DW_AT_decl_line
	.word	628                             # DW_AT_type
	.byte	7                               # Abbrev [7] 0x1f7:0xf DW_TAG_variable
	.word	.Ldebug_loc16                   # DW_AT_location
	.word	.Linfo_string27                 # DW_AT_name
	.byte	2                               # DW_AT_decl_file
	.byte	85                              # DW_AT_decl_line
	.word	621                             # DW_AT_type
	.byte	7                               # Abbrev [7] 0x206:0xf DW_TAG_variable
	.word	.Ldebug_loc17                   # DW_AT_location
	.word	.Linfo_string28                 # DW_AT_name
	.byte	2                               # DW_AT_decl_file
	.byte	86                              # DW_AT_decl_line
	.word	621                             # DW_AT_type
	.byte	7                               # Abbrev [7] 0x215:0xf DW_TAG_variable
	.word	.Ldebug_loc18                   # DW_AT_location
	.word	.Linfo_string29                 # DW_AT_name
	.byte	2                               # DW_AT_decl_file
	.byte	87                              # DW_AT_decl_line
	.word	621                             # DW_AT_type
	.byte	7                               # Abbrev [7] 0x224:0xf DW_TAG_variable
	.word	.Ldebug_loc19                   # DW_AT_location
	.word	.Linfo_string30                 # DW_AT_name
	.byte	2                               # DW_AT_decl_file
	.byte	88                              # DW_AT_decl_line
	.word	621                             # DW_AT_type
	.byte	0                               # End Of Children Mark
	.byte	0                               # End Of Children Mark
	.byte	9                               # Abbrev [9] 0x235:0x1d DW_TAG_lexical_block
	.quad	.Ltmp89                         # DW_AT_low_pc
	.word	.Ltmp126-.Ltmp89                # DW_AT_high_pc
	.byte	7                               # Abbrev [7] 0x242:0xf DW_TAG_variable
	.word	.Ldebug_loc27                   # DW_AT_location
	.word	.Linfo_string38                 # DW_AT_name
	.byte	2                               # DW_AT_decl_file
	.byte	203                             # DW_AT_decl_line
	.word	602                             # DW_AT_type
	.byte	0                               # End Of Children Mark
	.byte	0                               # End Of Children Mark
	.byte	3                               # Abbrev [3] 0x253:0x7 DW_TAG_base_type
	.word	.Linfo_string6                  # DW_AT_name
	.byte	5                               # DW_AT_encoding
	.byte	4                               # DW_AT_byte_size
	.byte	10                              # Abbrev [10] 0x25a:0xc DW_TAG_typedef
	.word	614                             # DW_AT_type
	.word	.Linfo_string9                  # DW_AT_name
	.byte	3                               # DW_AT_decl_file
	.half	276                             # DW_AT_decl_line
	.byte	3                               # Abbrev [3] 0x266:0x7 DW_TAG_base_type
	.word	.Linfo_string8                  # DW_AT_name
	.byte	5                               # DW_AT_encoding
	.byte	8                               # DW_AT_byte_size
	.byte	3                               # Abbrev [3] 0x26d:0x7 DW_TAG_base_type
	.word	.Linfo_string13                 # DW_AT_name
	.byte	4                               # DW_AT_encoding
	.byte	8                               # DW_AT_byte_size
	.byte	11                              # Abbrev [11] 0x274:0x5 DW_TAG_pointer_type
	.word	621                             # DW_AT_type
	.byte	12                              # Abbrev [12] 0x279:0x5 DW_TAG_const_type
	.word	602                             # DW_AT_type
	.byte	10                              # Abbrev [10] 0x27e:0xc DW_TAG_typedef
	.word	650                             # DW_AT_type
	.word	.Linfo_string42                 # DW_AT_name
	.byte	4                               # DW_AT_decl_file
	.half	386                             # DW_AT_decl_line
	.byte	13                              # Abbrev [13] 0x28a:0x9 DW_TAG_typedef
	.word	659                             # DW_AT_type
	.word	.Linfo_string41                 # DW_AT_name
	.byte	14                              # Abbrev [14] 0x293:0x17 DW_TAG_array_type
                                        # DW_AT_GNU_vector
	.word	621                             # DW_AT_type
	.byte	15                              # Abbrev [15] 0x298:0x11 DW_TAG_subrange_type
	.word	682                             # DW_AT_type
	.byte	0                               # DW_AT_lower_bound
	.byte	10                              # DW_AT_upper_bound
	.byte	146
	.ascii	"\2428"
	.byte	0
	.byte	56
	.byte	27
	.byte	56
	.byte	30
	.byte	49
	.byte	28
	.byte	0                               # End Of Children Mark
	.byte	16                              # Abbrev [16] 0x2aa:0x7 DW_TAG_base_type
	.word	.Linfo_string40                 # DW_AT_name
	.byte	8                               # DW_AT_byte_size
	.byte	7                               # DW_AT_encoding
	.byte	0                               # End Of Children Mark
.Ldebug_info_end0:
	.section	.debug_str,"MS",@progbits,1
.Linfo_string0:
	.asciz	"Ubuntu clang version 21.1.8 (++20251221032842+2078da43e25a-1~exp1~20251221153008.77)" # string offset=0
.Linfo_string1:
	.asciz	"/home/uiniu/CodeData/riscv-ai-platform/experiments/openblas-rvv/results/2026-10-26_r192-schedule-counter-r1/llvm-tuning/build-r2/gemv_n_vector.c" # string offset=85
.Linfo_string2:
	.asciz	"/home/uiniu/CodeData/riscv-ai-platform" # string offset=230
.Linfo_string3:
	.asciz	"unsigned long"                 # string offset=269
.Linfo_string4:
	.asciz	"size_t"                        # string offset=283
.Linfo_string5:
	.asciz	"dgemv_n"                       # string offset=290
.Linfo_string6:
	.asciz	"int"                           # string offset=298
.Linfo_string7:
	.asciz	"m"                             # string offset=302
.Linfo_string8:
	.asciz	"long"                          # string offset=304
.Linfo_string9:
	.asciz	"BLASLONG"                      # string offset=309
.Linfo_string10:
	.asciz	"n"                             # string offset=318
.Linfo_string11:
	.asciz	"dummy1"                        # string offset=320
.Linfo_string12:
	.asciz	"alpha"                         # string offset=327
.Linfo_string13:
	.asciz	"double"                        # string offset=333
.Linfo_string14:
	.asciz	"a"                             # string offset=340
.Linfo_string15:
	.asciz	"lda"                           # string offset=342
.Linfo_string16:
	.asciz	"x"                             # string offset=346
.Linfo_string17:
	.asciz	"inc_x"                         # string offset=348
.Linfo_string18:
	.asciz	"y"                             # string offset=354
.Linfo_string19:
	.asciz	"inc_y"                         # string offset=356
.Linfo_string20:
	.asciz	"buffer"                        # string offset=362
.Linfo_string21:
	.asciz	"epr"                           # string offset=369
.Linfo_string22:
	.asciz	"j"                             # string offset=373
.Linfo_string23:
	.asciz	"ap0"                           # string offset=375
.Linfo_string24:
	.asciz	"ap1"                           # string offset=379
.Linfo_string25:
	.asciz	"ap2"                           # string offset=383
.Linfo_string26:
	.asciz	"ap3"                           # string offset=387
.Linfo_string27:
	.asciz	"t0"                            # string offset=391
.Linfo_string28:
	.asciz	"t1"                            # string offset=394
.Linfo_string29:
	.asciz	"t2"                            # string offset=397
.Linfo_string30:
	.asciz	"t3"                            # string offset=400
.Linfo_string31:
	.asciz	"i"                             # string offset=403
.Linfo_string32:
	.asciz	"y_ptr"                         # string offset=405
.Linfo_string33:
	.asciz	"vl"                            # string offset=411
.Linfo_string34:
	.asciz	"a_ptr"                         # string offset=414
.Linfo_string35:
	.asciz	"temp"                          # string offset=420
.Linfo_string36:
	.asciz	"temp2"                         # string offset=425
.Linfo_string37:
	.asciz	"a2_ptr"                        # string offset=431
.Linfo_string38:
	.asciz	"stride_y"                      # string offset=438
.Linfo_string39:
	.asciz	"va"                            # string offset=447
.Linfo_string40:
	.asciz	"__ARRAY_SIZE_TYPE__"           # string offset=450
.Linfo_string41:
	.asciz	"__rvv_float64m8_t"             # string offset=470
.Linfo_string42:
	.asciz	"vfloat64m8_t"                  # string offset=488
.Linfo_string43:
	.asciz	"vy"                            # string offset=501
.Linfo_string44:
	.asciz	"va2"                           # string offset=504
	.ident	"Ubuntu clang version 21.1.8 (++20251221032842+2078da43e25a-1~exp1~20251221153008.77)"
	.section	".note.GNU-stack","",@progbits
	.addrsig
	.section	.debug_line,"",@progbits
.Lline_table_start0:
