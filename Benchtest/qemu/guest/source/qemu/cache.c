#include <stdint.h>
#define BLOCKS 8192
static uint32_t code[BLOCKS][8] __attribute__((aligned(4096)));
static uint64_t checks,digest;
static void put(char c){volatile uint8_t*p=(void*)0x10000000UL;while(!(p[5]&32)){}p[0]=c;}
static void text(const char*s){while(*s)put(*s++);}
static void hex(uint64_t n){for(int i=15;i>=0;i--)put("0123456789abcdef"[(n>>(i*4))&15]);}
static void eq(uint64_t a,uint64_t b){checks++;if(a!=b){text("CACHE_FAIL ");hex(checks);put(' ');hex(a);put(' ');hex(b);put('\n');*(volatile unsigned*)0x100000=0x13333;for(;;){}}digest=(digest^a)*0x100000001b3ULL;}
int main(void){
 __asm__ volatile("csrs mstatus,%0"::"r"(3UL<<9):"memory");
 for(unsigned pass=0;pass<4;pass++){
  for(unsigned i=0;i<BLOCKS;i++){
   unsigned type=((i+pass)&1)?16:24,avl=(i+pass)%32;
   code[i][0]=0xc0007057u|(type<<20)|(avl<<15)|(10u<<7);
   code[i][1]=(((i+pass)%31)<<20)|(10u<<15)|(10u<<7)|0x13;
   code[i][2]=0x00008067; /* uncompressed ret */
  }
  __asm__ volatile("fence rw,rw;fence.i":::"memory");
  for(unsigned i=0;i<BLOCKS;i++){
   unsigned type=((i+pass)&1)?16:24,avl=(i+pass)%32,max=type==16?4:2;
   uint64_t expected=(avl<max?avl:max)+(i+pass)%31;
   __asm__ volatile("csrwi vstart,3":::"memory");
   uint64_t result=((uint64_t(*)(void))(uintptr_t)code[i])(),vl,start,vtype;
   __asm__ volatile("csrr %0,vl;csrr %1,vstart;csrr %2,vtype":"=r"(vl),"=r"(start),"=r"(vtype));
   eq(result,expected);eq(vl,avl<max?avl:max);eq(start,0);eq(vtype,type);
  }
 }
 text("CACHE_PASS blocks=8192 passes=4 checks=");hex(checks);text(" digest=");hex(digest);put('\n');
 *(volatile unsigned*)0x100000=0x5555;return 0;
}
