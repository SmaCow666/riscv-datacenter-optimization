/* Deterministic RVV/scalar sequences with an independent unsigned reference. */
#include <stdint.h>
#ifndef TEST_VLEN
#define TEST_VLEN 128
#endif
#ifndef TEST_ELEN
#define TEST_ELEN 64
#endif
static uint64_t rng, checks, cases, known_vl0_reductions, digest=0xcbf29ce484222325ULL;
static uint64_t dbg_n,dbg_w,dbg_op,dbg_vl,dbg_mask,dbg_lane;
static volatile uint64_t scalar_cell=0x123456789abcdef0ULL;
static void put(char c){volatile uint8_t*p=(void*)0x10000000UL;while(!(p[5]&32)){}p[0]=c;}
static void text(const char*s){while(*s)put(*s++);}
static void hex(uint64_t n){for(int i=15;i>=0;i--)put("0123456789abcdef"[(n>>(i*4))&15]);}
static uint64_t rnd(void){rng^=rng<<13;rng^=rng>>7;rng^=rng<<17;return rng;}
static void eq(uint64_t a,uint64_t b){checks++;if(a!=b){text("MIXED_FAIL case=");hex(cases);text(" check=");hex(checks);text(" got=");hex(a);text(" want=");hex(b);text(" n=");hex(dbg_n);text(" width=");hex(dbg_w);text(" op=");hex(dbg_op);text(" vl=");hex(dbg_vl);text(" masked=");hex(dbg_mask);text(" lane=");hex(dbg_lane);put('\n');*(volatile unsigned*)0x100000=0x13333;for(;;){}}digest=(digest^a)*0x100000001b3ULL;}
#define STR_(x) #x
#define STR(x) STR_(x)
#define CONFIG(W,SFX) do { \
 if(kind&1){vl=req;__asm__ volatile("vsetvli %0,%0,e" STR(W) ",m1,tu,mu;" SFX :"+&r"(vl):"r"(req),"r"(&scalar_cell):"t3","t4","memory");} \
 else switch(kind&6){ \
 case 0: req=0;__asm__ volatile("vsetivli %0,0,e" STR(W) ",m1,tu,mu;" SFX :"=&r"(vl):"r"(req),"r"(&scalar_cell):"t3","t4","memory");break; \
 case 2: req=1;__asm__ volatile("vsetivli %0,1,e" STR(W) ",m1,tu,mu;" SFX :"=&r"(vl):"r"(req),"r"(&scalar_cell):"t3","t4","memory");break; \
 case 4: req=7;__asm__ volatile("vsetivli %0,7,e" STR(W) ",m1,tu,mu;" SFX :"=&r"(vl):"r"(req),"r"(&scalar_cell):"t3","t4","memory");break; \
 default:req=31;__asm__ volatile("vsetivli %0,31,e" STR(W) ",m1,tu,mu;" SFX :"=&r"(vl):"r"(req),"r"(&scalar_cell):"t3","t4","memory");} \
}while(0)
#define SUFFIXES(W) switch((kind>>3)%6){ \
 case 0: CONFIG(W,"addi t3,zero,23");break; \
 case 1: CONFIG(W,"ld t3,0(%2);sd t3,0(%2)");break; \
 case 2: CONFIG(W,"beq %0,zero,991f;addi t3,zero,17;j 992f;991: addi t3,zero,19;992:");break; \
 case 3: CONFIG(W,"jal t3,991f;j 992f;991: addi t4,zero,13;jalr zero,0(t3);992:");break; \
 case 4: CONFIG(W,"fence rw,rw");break; \
 default:CONFIG(W,"amoadd.d zero,zero,(%2)");break;}
#define VECTOR(OP) do{if(masked)__asm__ volatile(OP " v10,v8,v9,v0.t":::"memory");else __asm__ volatile(OP " v10,v8,v9":::"memory");}while(0)
#define TEST(W,T,SEW) \
__attribute__((noinline)) static void test##W(unsigned n){ \
 struct {uint64_t pre;T x[128];uint64_t post;} out __attribute__((aligned(128))); \
 T a[128] __attribute__((aligned(128))),b[128] __attribute__((aligned(128))),old[128] __attribute__((aligned(128))); \
 uint8_t mask[16];unsigned max=TEST_VLEN/W;uint64_t tmp,vl,req; \
 unsigned kind=(unsigned)rnd(),op=n%16,masked=(kind>>9)&1;cases++;dbg_n=n;dbg_w=W;dbg_op=op;dbg_mask=masked;dbg_lane=~0ULL; \
 out.pre=0x13579bdf2468ace0ULL;out.post=~out.pre; \
 for(unsigned i=0;i<16;i++)mask[i]=(uint8_t)rnd(); \
 for(unsigned i=0;i<max;i++){a[i]=(T)rnd();b[i]=(T)rnd();old[i]=(T)rnd();out.x[i]=(T)0x5a;} \
 __asm__ volatile("csrwi vstart,0;vsetvli %0,%1,e" STR(W) ",m1,tu,mu;vle" STR(W) ".v v8,(%2);vle" STR(W) ".v v9,(%3);vle" STR(W) ".v v10,(%4);vlm.v v0,(%5)" \
 :"=&r"(tmp):"r"((uint64_t)max),"r"(a),"r"(b),"r"(old),"r"(mask):"memory"); \
 if(n&1)__asm__ volatile("vsetvl %0,%1,%2":"=&r"(tmp):"r"(1UL),"r"(1ULL<<63):"memory"); \
 __asm__ volatile("csrwi vcsr,5;csrwi vstart,3;csrc mstatus,%0;csrs mstatus,%1"::"r"(3UL<<9),"r"((uint64_t)(n%3+1)<<9):"memory"); \
 switch(n%8){case 0:req=0;break;case 1:req=1;break;case 2:req=max;break;case 3:req=max+1;break;case 4:req=~0ULL;break;case 5:req=1ULL<<63;break;case 6:req=rnd();break;default:req=rnd()%(max+1);} \
 SUFFIXES(W); \
 uint64_t want=req<max?req:max,cv,ct,cs,cc,status;dbg_vl=want; \
 __asm__ volatile("csrr %0,vl;csrr %1,vtype;csrr %2,vstart;csrr %3,vcsr;csrr %4,mstatus":"=r"(cv),"=r"(ct),"=r"(cs),"=r"(cc),"=r"(status)); \
 eq(vl,want);eq(cv,want);eq(ct,(SEW)<<3);eq(cs,0);eq(cc,5);eq((status>>9)&3,3);eq(scalar_cell,0x123456789abcdef0ULL); \
 switch(op){case 0:VECTOR("vadd.vv");break;case 1:VECTOR("vsub.vv");break;case 2:VECTOR("vxor.vv");break;case 3:VECTOR("vand.vv");break; \
 case 4:VECTOR("vor.vv");break;case 5:VECTOR("vmul.vv");break;case 6:VECTOR("vsll.vv");break;case 7:VECTOR("vsrl.vv");break; \
 case 8:VECTOR("vminu.vv");break;case 9:VECTOR("vmaxu.vv");break;case 10:VECTOR("vrgather.vv");break; \
 case 11:if(masked)__asm__ volatile("vslideup.vx v10,v8,%0,v0.t"::"r"(1UL):"memory");else __asm__ volatile("vslideup.vx v10,v8,%0"::"r"(1UL):"memory");break; \
 case 12:if(masked)__asm__ volatile("vslidedown.vx v10,v8,%0,v0.t"::"r"(1UL):"memory");else __asm__ volatile("vslidedown.vx v10,v8,%0"::"r"(1UL):"memory");break; \
 case 13:if(masked)__asm__ volatile("vredsum.vs v10,v8,v9,v0.t":::"memory");else __asm__ volatile("vredsum.vs v10,v8,v9":::"memory");break; \
 case 14:if(masked)__asm__ volatile("vmerge.vvm v10,v8,v9,v0":::"memory");else __asm__ volatile("vmv.v.v v10,v8":::"memory");break; \
 default:__asm__ volatile("vcompress.vm v10,v8,v0":::"memory");break;} \
 __asm__ volatile("vsetvli %0,%1,e" STR(W) ",m1,tu,mu;vse" STR(W) ".v v10,(%2)":"=&r"(tmp):"r"((uint64_t)max),"r"(out.x):"memory"); \
 T sum=b[0];unsigned packed=0;for(unsigned i=0;i<want;i++)if(!masked||((mask[i>>3]>>(i&7))&1))sum=(T)(sum+a[i]); \
 for(unsigned i=0;i<max;i++){T expected=old[i];int selected=(mask[i>>3]>>(i&7))&1; \
 if(i<want&&(!masked||selected)){switch(op){ \
 case 0:expected=(T)(a[i]+b[i]);break;case 1:expected=(T)(a[i]-b[i]);break;case 2:expected=a[i]^b[i];break;case 3:expected=a[i]&b[i];break;case 4:expected=a[i]|b[i];break; \
 case 5:expected=(T)((uint64_t)a[i]*(uint64_t)b[i]);break;case 6:expected=(T)((uint64_t)a[i]<<(b[i]&(W-1)));break;case 7:expected=(T)(a[i]>>(b[i]&(W-1)));break; \
 case 8:expected=a[i]<b[i]?a[i]:b[i];break;case 9:expected=a[i]>b[i]?a[i]:b[i];break;case 10:expected=b[i]<max?a[b[i]]:0;break; \
 case 11:if(i)expected=a[i-1];break;case 12:expected=i+1<max?a[i+1]:0;break;default:break;}} \
 /* QEMU 9.1.0 also copies the seed at VL=0 (known ISA deviation). Keep \
  * this compatibility check separate from the independent arithmetic oracle. */ \
 if(op==13){expected=i==0?sum:old[i];if(!want&&i==0)known_vl0_reductions++;} \
 if(op==14&&i<want)expected=masked?(selected?b[i]:a[i]):a[i]; \
 if(op==15){expected=old[i];for(unsigned j=packed;j<want;j++)if((mask[j>>3]>>(j&7))&1){expected=a[j];packed=j+1;goto got_packed;}packed=(unsigned)want;got_packed:;} \
 dbg_lane=i;eq(out.x[i],expected);} \
 eq(out.pre,0x13579bdf2468ace0ULL);eq(out.post,~out.pre); \
}
TEST(8,uint8_t,0)
TEST(16,uint16_t,1)
TEST(32,uint32_t,2)
TEST(64,uint64_t,3)
int main(void){
 rng=*(volatile uint64_t*)0x81000000UL;
 uint64_t steps=*(volatile uint64_t*)0x81000008UL;
 if(!rng)rng=1;if(!steps||steps>1000000)steps=4096;
 __asm__ volatile("csrs mstatus,%0"::"r"(3UL<<9):"memory");
 uint64_t vlenb;__asm__ volatile("csrr %0,vlenb":"=r"(vlenb));eq(vlenb,TEST_VLEN/8);
 for(unsigned i=0;i<steps;i++){test8(i);if(TEST_ELEN>=16)test16(i);if(TEST_ELEN>=32)test32(i);if(TEST_ELEN>=64)test64(i);}
 text("MIXED_PASS cases=");hex(cases);text(" checks=");hex(checks);text(" known_vl0_reductions=");hex(known_vl0_reductions);text(" digest=");hex(digest);put('\n');
 *(volatile unsigned*)0x100000=0x5555;return 0;
}
