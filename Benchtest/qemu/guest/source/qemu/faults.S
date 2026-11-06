.section .text
.option norvc
.globl fault_entry
fault_entry:
 addi sp,sp,-256
 sd ra,0(sp)
 sd t0,8(sp)
 sd t1,16(sp)
 sd t2,24(sp)
 sd a0,32(sp)
 sd a1,40(sp)
 sd a2,48(sp)
 sd a3,56(sp)
 sd a4,64(sp)
 sd a5,72(sp)
 sd a6,80(sp)
 sd a7,88(sp)
 sd t3,96(sp)
 sd t4,104(sp)
 sd t5,112(sp)
 sd t6,120(sp)
 call handle_fault
 ld ra,0(sp)
 ld t0,8(sp)
 ld t1,16(sp)
 ld t2,24(sp)
 ld a0,32(sp)
 ld a1,40(sp)
 ld a2,48(sp)
 ld a3,56(sp)
 ld a4,64(sp)
 ld a5,72(sp)
 ld a6,80(sp)
 ld a7,88(sp)
 ld t3,96(sp)
 ld t4,104(sp)
 ld t5,112(sp)
 ld t6,120(sp)
 addi sp,sp,256
 mret
.globl load_fault
.globl load_fault_pc
load_fault:
 vsetivli zero,31,e32,m1,tu,mu
load_fault_pc:
 vle32.v v8,(a0)
 ret
.globl store_fault
.globl store_fault_pc
store_fault:
 vsetivli zero,31,e32,m1,tu,mu
store_fault_pc:
 vse32.v v8,(a0)
 ret
