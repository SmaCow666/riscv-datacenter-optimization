#include <stdint.h>
extern void fault_entry(void),load_fault(uint64_t),store_fault(uint64_t);
extern const uint32_t load_fault_pc[],store_fault_pc[];
static uint64_t checks,rounds,expected_cause,expected_pc,expected_start,expected_address;
static void put(char c){volatile uint8_t*p=(void*)0x10000000UL;while(!(p[5]&32)){}p[0]=c;}
static void text(const char*s){while(*s)put(*s++);}
static void hex(uint64_t n){for(int i=15;i>=0;i--)put("0123456789abcdef"[(n>>(i*4))&15]);}
static void eq(uint64_t a,uint64_t b){checks++;if(a!=b){text("FAULT_FAIL ");hex(checks);put(' ');hex(a);put(' ');hex(b);put('\n');*(volatile unsigned*)0x100000=0x13333;for(;;){}}}
void handle_fault(void){
 uint64_t cause,pc,start,type,vl,address;
 __asm__ volatile("csrr %0,mcause;csrr %1,mepc;csrr %2,vstart;csrr %3,vtype;csrr %4,vl;csrr %5,mtval":"=r"(cause),"=r"(pc),"=r"(start),"=r"(type),"=r"(vl),"=r"(address));
 eq(cause,expected_cause);eq(pc,expected_pc);eq(start,expected_start);eq(address,expected_address);eq(type,16);eq(vl,4);
 __asm__ volatile("csrw mepc,%0"::"r"(pc+4):"memory");rounds++;
}
int main(void){
 __asm__ volatile("csrw mtvec,%0;csrs mstatus,%1"::"r"(fault_entry),"r"(3UL<<9):"memory");
 *(volatile uint32_t*)0x87fffffcUL=0x12345678;
 for(unsigned n=0;n<64;n++){
  uint64_t address=n&1?0x87fffffcUL:0x88000000UL;
  expected_start=n&1?1:0;expected_address=0x88000000UL;
  expected_pc=(uintptr_t)load_fault_pc;expected_cause=5;load_fault(address);
  expected_pc=(uintptr_t)store_fault_pc;expected_cause=7;store_fault(address);
  uint64_t start,vl;__asm__ volatile("vsetivli %0,31,e32,m1,tu,mu;csrr %1,vstart":"=r"(vl),"=r"(start));eq(start,0);eq(vl,4);
 }
 eq(rounds,128);text("FAULT_PASS faults=128 checks=");hex(checks);put('\n');
 *(volatile unsigned*)0x100000=0x5555;return 0;
}
