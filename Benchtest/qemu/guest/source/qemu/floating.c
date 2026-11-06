/* RVV/scalar FP comparison: bit patterns, all five standard rounding modes. */
#include <stdint.h>
#ifndef TEST_VLEN
#define TEST_VLEN 128
#endif
static uint64_t checks,cases,digest=0xcbf29ce484222325ULL;
static void put(char c){volatile uint8_t*p=(void*)0x10000000UL;while(!(p[5]&32)){}p[0]=c;}
static void text(const char*s){while(*s)put(*s++);}
static void hex(uint64_t n){for(int i=15;i>=0;i--)put("0123456789abcdef"[(n>>(i*4))&15]);}
static void eq(uint64_t a,uint64_t b){checks++;if(a!=b){text("FLOAT_FAIL case=");hex(cases);text(" check=");hex(checks);text(" got=");hex(a);text(" want=");hex(b);put('\n');*(volatile unsigned*)0x100000=0x13333;for(;;){}}digest=(digest^a)*0x100000001b3ULL;}
static const uint32_t p32[]={0,0x80000000,0x3f800000,0xbf800000,0x7f800000,0xff800000,0x7fc00001,0x7f800001,1,0x80000001,0x007fffff,0x00800000,0x7f7fffff,0xff7fffff,0x3f000001,0x33800000};
static const uint64_t p64[]={0,0x8000000000000000ULL,0x3ff0000000000000ULL,0xbff0000000000000ULL,0x7ff0000000000000ULL,0xfff0000000000000ULL,0x7ff8000000000001ULL,0x7ff0000000000001ULL,1,0x8000000000000001ULL,0x000fffffffffffffULL,0x0010000000000000ULL,0x7fefffffffffffffULL,0xffefffffffffffffULL,0x3fe0000000000001ULL,0x3ca0000000000000ULL};
#define STR_(x) #x
#define STR(x) STR_(x)
#define SCALAR(OP,SUFFIX) __asm__ volatile("csrw fcsr,%4;" OP "." SUFFIX " %0,%2,%3;csrr %1,fflags":"=&f"(result.f),"=&r"(flags):"f"(aa.f),"f"(bb.f),"r"((uint64_t)rm<<5):"memory")
#define VECTOR(OP) do {if(masked)__asm__ volatile(OP " v10,v8,v9,v0.t":::"memory");else __asm__ volatile(OP " v10,v8,v9":::"memory");}while(0)
#define TEST(W,FP,U,PATTERN,SUFFIX,TYPE) \
static void test##W(unsigned n,unsigned op,unsigned rm,unsigned masked){ \
 union Number{FP f;U u;}; \
 U a[128] __attribute__((aligned(128))),b[128] __attribute__((aligned(128))),old[128] __attribute__((aligned(128))),out[128] __attribute__((aligned(128))),expected[128]; \
 uint8_t mask[16];unsigned max=TEST_VLEN/W;uint64_t tmp,vl,flags,allflags=0;cases++; \
 uint64_t req=n%3==0?31:n%3==2?0:n%5==0?~0ULL:n%5==1?1:n%5==2?max:max+1;unsigned want=req<max?req:max; \
 for(unsigned i=0;i<16;i++)mask[i]=(uint8_t)(0x96u^(n+i)); \
 for(unsigned i=0;i<max;i++){a[i]=PATTERN[(n+i)%16];b[i]=PATTERN[(n*7+i*3+op)%16];old[i]=(U)(0x5a5a5a5a5a5a5a5aULL+i);expected[i]=old[i]; \
  if(i<want&&(!masked||((mask[i>>3]>>(i&7))&1))){union Number aa,bb,result;aa.u=a[i];bb.u=b[i]; \
   switch(op){case 0:SCALAR("fadd",SUFFIX);break;case 1:SCALAR("fsub",SUFFIX);break;case 2:SCALAR("fmul",SUFFIX);break;default:SCALAR("fdiv",SUFFIX);break;} \
   expected[i]=result.u;allflags|=flags;}} \
 __asm__ volatile("csrwi vstart,0;vsetvli %0,%1,e" STR(W) ",m1,tu,mu;vle" STR(W) ".v v8,(%2);vle" STR(W) ".v v9,(%3);vle" STR(W) ".v v10,(%4);vlm.v v0,(%5)":"=&r"(tmp):"r"((uint64_t)max),"r"(a),"r"(b),"r"(old),"r"(mask):"memory"); \
 __asm__ volatile("csrw fcsr,%0;csrwi vstart,3"::"r"((uint64_t)rm<<5):"memory"); \
 if(n%3==0)__asm__ volatile("vsetivli %0,31,e" STR(W) ",m1,tu,mu":"=r"(vl)::"memory"); \
 else if(n%3==2)__asm__ volatile("vsetivli %0,0,e" STR(W) ",m1,tu,mu":"=r"(vl)::"memory"); \
 else {vl=req;__asm__ volatile("vsetvli %0,%0,e" STR(W) ",m1,tu,mu":"+r"(vl)::"memory");} \
 eq(vl,want);uint64_t start,type;__asm__ volatile("csrr %0,vstart;csrr %1,vtype":"=r"(start),"=r"(type));eq(start,0);eq(type,TYPE); \
 switch(op){case 0:VECTOR("vfadd.vv");break;case 1:VECTOR("vfsub.vv");break;case 2:VECTOR("vfmul.vv");break;default:VECTOR("vfdiv.vv");break;} \
 __asm__ volatile("csrr %0,fflags":"=r"(flags));eq(flags,allflags); \
 __asm__ volatile("vsetvli %0,%1,e" STR(W) ",m1,tu,mu;vse" STR(W) ".v v10,(%2)":"=&r"(tmp):"r"((uint64_t)max),"r"(out):"memory"); \
 for(unsigned i=0;i<max;i++)eq(out[i],expected[i]); \
}
TEST(32,float,uint32_t,p32,"s",16)
TEST(64,double,uint64_t,p64,"d",24)
int main(void){
 __asm__ volatile("csrs mstatus,%0"::"r"((3UL<<9)|(3UL<<13)):"memory");
 for(unsigned n=0;n<32;n++)for(unsigned op=0;op<4;op++)for(unsigned rm=0;rm<5;rm++)for(unsigned masked=0;masked<2;masked++){test32(n,op,rm,masked);test64(n,op,rm,masked);}
 text("FLOAT_PASS cases=");hex(cases);text(" checks=");hex(checks);text(" digest=");hex(digest);put('\n');
 *(volatile unsigned*)0x100000=0x5555;return 0;
}
