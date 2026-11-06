.section .text.init
.globl _start
_start:
    .option push
    .option norelax
    la gp, __global_pointer$
    .option pop
    la sp, __stack_top
    bnez a0, 2f
    la t0, __bss_start
    la t1, __bss_end
1:  bgeu t0, t1, 3f
    sb zero, 0(t0)
    addi t0, t0, 1
    j 1b
3:  call main
2:  wfi
    j 2b
