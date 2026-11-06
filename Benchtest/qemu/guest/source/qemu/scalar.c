#include <stdint.h>
static uint64_t a[512],rng,digest;
static void put(char c){volatile uint8_t*p=(void*)0x10000000UL;while(!(p[5]&32)){}p[0]=c;}
static void text(const char*s){while(*s)put(*s++);}
static void hex(uint64_t n){for(int i=15;i>=0;i--)put("0123456789abcdef"[(n>>(i*4))&15]);}
static uint64_t rnd(void){rng^=rng<<13;rng^=rng>>7;rng^=rng<<17;return rng;}
int main(void){
 __asm__ volatile("csrs mstatus,%0"::"r"(3UL<<13):"memory");
 rng=*(volatile uint64_t*)0x81000000UL;if(!rng)rng=1;
 for(unsigned i=0;i<512;i++)a[i]=rnd();
 for(unsigned n=0;n<200000;n++){
  uint64_t x=rnd(),y=a[n&511],v=(x+y)^(x*(y|1));
  v=(v>>((n%63)+1))|(v<<(64-((n%63)+1)));
  v^=x/(y|1);a[n&511]=v;digest=(digest^v)*0x100000001b3ULL;
 }
 uint64_t cell=7,old;
 for(unsigned i=0;i<4096;i++){
  __asm__ volatile("amoadd.d %0,%2,(%1)":"=r"(old):"r"(&cell),"r"(1UL):"memory");
  if(old!=7+i){text("SCALAR_FAIL atomic\n");*(volatile unsigned*)0x100000=0x13333;for(;;){}}
 }
 float f=0;double d=0;
 for(unsigned i=0;i<1024;i++){f=f+0.5f;d=d+0.25;}
 if(f!=512.0f||d!=256.0||cell!=4103){text("SCALAR_FAIL fp\n");*(volatile unsigned*)0x100000=0x13333;for(;;){}}
 text("SCALAR_PASS digest=");hex(digest);text(" atomic=4103 fp=512,256\n");
 *(volatile unsigned*)0x100000=0x5555;return 0;
}
