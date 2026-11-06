/* Same inputs and scalar C algorithm on native x86 and RISC-V.
 * CROSS_RVV replaces only the four integer array operations with RVV. */
#include <stdint.h>
#ifdef CROSS_HOST
#include <stdio.h>
static void put(char c) { putchar(c); }
#else
static void put(char c) { volatile uint8_t *u=(void *)0x10000000UL; while(!(u[5]&32)){} u[0]=c; }
#endif
static void text(const char *s) { while(*s) put(*s++); }
static void hex(uint64_t n) { for(int i=15;i>=0;--i) put("0123456789abcdef"[(n>>(i*4))&15]); }
static uint32_t a[257],b[257],out[257];
static uint64_t rng;
static uint32_t next(void) { rng^=rng<<13; rng^=rng>>7; rng^=rng<<17; return (uint32_t)rng; }
static uint32_t scalar(unsigned op,uint32_t x,uint32_t y) {
    switch(op) { case 0:return x+y;case 1:return x^y;case 2:return x*y;default:return x<y?x:y; }
}
static void calculate(unsigned op,unsigned n) {
#ifdef CROSS_RVV
    unsigned at=0;
    while(at<n) {
        uintptr_t vl;
        if(n-at>=4) __asm__ volatile("vsetivli %0,4,e32,m1,tu,mu":"=r"(vl)::"memory");
        else __asm__ volatile("vsetvli %0,%1,e32,m1,tu,mu":"=r"(vl):"r"((uintptr_t)(n-at)):"memory");
        __asm__ volatile("vle32.v v8,(%0);vle32.v v9,(%1)"::"r"(a+at),"r"(b+at):"memory");
        switch(op) {
        case 0:__asm__ volatile("vadd.vv v10,v8,v9":::"memory");break;
        case 1:__asm__ volatile("vxor.vv v10,v8,v9":::"memory");break;
        case 2:__asm__ volatile("vmul.vv v10,v8,v9":::"memory");break;
        default:__asm__ volatile("vminu.vv v10,v8,v9":::"memory");break;
        }
        __asm__ volatile("vse32.v v10,(%0)"::"r"(out+at):"memory");at+=(unsigned)vl;
    }
#else
    for(unsigned i=0;i<n;i++) out[i]=scalar(op,a[i],b[i]);
#endif
}
int main(void) {
#ifndef CROSS_HOST
    __asm__ volatile("csrs mstatus,%0"::"r"((3UL<<9)|(3UL<<13)):"memory");
#endif
    const unsigned lengths[]={0,1,3,4,5,7,8,15,16,17,31,32,33,127,257};
    const uint64_t seeds[]={1,0x8000000000000000ULL,~0ULL};
    unsigned cases=0,values=0;
    for(unsigned s=0;s<3;s++)for(unsigned l=0;l<15;l++)for(unsigned op=0;op<4;op++) {
        unsigned n=lengths[l];rng=seeds[s];
        for(unsigned i=0;i<n;i++){a[i]=next();b[i]=next();out[i]=0xabcdef01;}
        calculate(op,n);text("CROSS ");hex(s);put(' ');hex(n);put(' ');hex(op);
        for(unsigned i=0;i<n;i++) {
            if(out[i]!=scalar(op,a[i],b[i])) { text(" CROSS_FAIL\n");goto failure; }
            put(' ');hex(out[i]);values++;
        }
        put('\n');cases++;
    }
    /* Dyadic finite values: exact binary FP reference, no tolerance hiding. */
    for(unsigned i=0;i<64;i++) {
        volatile double x=(double)i/2.0,y=(double)(63-i)/4.0;
        union {double d;uint64_t u;} z;z.d=(x+y)*0.5;
        text("FP ");hex(i);put(' ');hex(z.u);put('\n');
    }
    text("CROSS_PASS cases=");hex(cases);text(" values=");hex(values);put('\n');
#ifndef CROSS_HOST
    *(volatile unsigned *)0x100000=0x5555;
#endif
    return 0;
failure:
#ifndef CROSS_HOST
    *(volatile unsigned *)0x100000=0x13333;
#endif
    return 1;
}
