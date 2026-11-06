/* Minimal independent-spec reproducer. PASS means the observation matches
 * the saved baseline deviation, NOT that this instruction conforms to ISA. */
#include <stdint.h>
static void put(char c){volatile uint8_t*p=(void*)0x10000000UL;while(!(p[5]&32)){}p[0]=c;}
static void text(const char*s){while(*s)put(*s++);}
static void hex(uint64_t n){for(int i=15;i>=0;i--)put("0123456789abcdef"[(n>>(i*4))&15]);}
int main(void){
 uint32_t a[4]={1,2,3,4},b[4]={0x22222222,5,6,7},old[4]={0x11111111,8,9,10},out[4];uint64_t tmp;
 __asm__ volatile("csrs mstatus,%0"::"r"(3UL<<9):"memory");
 __asm__ volatile("vsetivli %0,4,e32,m1,tu,mu;vle32.v v8,(%1);vle32.v v9,(%2);vle32.v v10,(%3);vsetivli zero,0,e32,m1,tu,mu;vredsum.vs v10,v8,v9;vsetivli %0,4,e32,m1,tu,mu;vse32.v v10,(%4)":"=&r"(tmp):"r"(a),"r"(b),"r"(old),"r"(out):"memory");
 text("VL0_REDUCTION_OBSERVED_PASS got=");hex(out[0]);text(" spec_expected=0000000011111111 baseline_expected=0000000022222222\n");
 *(volatile unsigned*)0x100000=out[0]==0x22222222?0x5555:0x13333;return 0;
}
