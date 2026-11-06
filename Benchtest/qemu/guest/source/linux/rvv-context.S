/* Linux U-mode context preservation across preemption and signal delivery.
 * Vector instructions live only in these functions; the C probe is rv64gc.
 */
.text
.balign 4
.globl rvv_context
.type rvv_context,@function
rvv_context:
    addi sp,sp,-32
    mv t0,a0                       /* positive 32-bit per-thread value */
    mv t4,a1                       /* signal counter address */
    mv t5,a2                       /* active flag address */
    mv t1,a3                       /* minimum async signals */
    li t2,0
    li a5,50000000                  /* bounded busy loop, no syscalls */
    vsetivli t3,31,e32,m1,tu,mu
    li t6,4
    bne t3,t6,9f
    vmv.v.x v8,t0
    li t6,1
    sw t6,0(t5)
1:
    csrr t3,vl
    li t6,4
    bne t3,t6,9f
    csrr t3,vtype
    li t6,16                       /* e32/m1/tu/mu */
    bne t3,t6,9f
    csrr t3,vstart
    bnez t3,9f
    vmv.x.s t3,v8
    bne t3,t0,9f
    addi t2,t2,1
    bgeu t2,a5,9f
    lwu t3,0(t4)
    bltu t3,t1,1b
    sw zero,0(t5)
    vse32.v v8,(sp)
    lwu t3,0(sp)
    bne t3,t0,9f
    lwu t3,4(sp)
    bne t3,t0,9f
    lwu t3,8(sp)
    bne t3,t0,9f
    lwu t3,12(sp)
    bne t3,t0,9f
    li a0,0
    addi sp,sp,32
    ret
9:
    sw zero,0(t5)
    li a0,1
    addi sp,sp,32
    ret
.size rvv_context,.-rvv_context

.globl rvv_clobber
.type rvv_clobber,@function
rvv_clobber:
    vsetivli zero,1,e8,m1,ta,ma
    vmv.v.i v8,-1
    ret
.size rvv_clobber,.-rvv_clobber

.globl rvv_after_syscall
.type rvv_after_syscall,@function
rvv_after_syscall:
    vsetivli zero,31,e32,m1,tu,mu
    vmv.v.x v1,a0
    vadd.vi v2,v1,1
    vmv.x.s a0,v2
    ret
.size rvv_after_syscall,.-rvv_after_syscall
.section .note.GNU-stack,"",@progbits
