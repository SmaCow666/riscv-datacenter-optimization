/* Deterministic integer feature transform and dot product. SPDX-License-Identifier: MIT */
#include <stdint.h>
#include <stddef.h>
#if defined(PIPELINE_HOST) || defined(PIPELINE_LINUX)
#include <stdio.h>
#endif
#define CAPACITY 16387u
#ifndef PIPELINE_ROUNDS
#define PIPELINE_ROUNDS 64u
#endif
static const unsigned lengths[]={0,1,3,4,5,31,257,1021,CAPACITY};
static uint32_t a[CAPACITY],b[CAPACITY],out[CAPACITY+2],expected[CAPACITY];
static volatile uint32_t observed;
static void put(char c){
#if defined(PIPELINE_HOST) || defined(PIPELINE_LINUX)
    putchar(c);
#else
    volatile uint8_t *u=(void*)0x10000000UL;while(!(u[5]&32)){}u[0]=c;
#endif
}
static void text(const char *s){while(*s)put(*s++);}
static void hex(uint32_t n){for(int s=28;s>=0;s-=4)put("0123456789abcdef"[(n>>s)&15]);}
static void input(char want){
#if defined(PIPELINE_LINUX)
    fflush(stdout);int c;do{c=getchar();}while(c!=want&&c!=EOF);
#elif !defined(PIPELINE_HOST)
    volatile uint8_t *u=(void*)0x10000000UL;for(;;)if((u[5]&1)&&u[0]==(uint8_t)want)return;
#else
    (void)want;
#endif
}
__attribute__((noinline,noclone))
static uint32_t scalar(unsigned n,uint32_t *dst){
    uint32_t dot=0;
    for(unsigned i=0;i<n;i++){
        uint32_t z=a[i]*3u+b[i];z=(z&0x80000000u)?0u:z;
        dst[i]=z;dot+=z*b[i];
    }
    return dot;
}
#ifdef PIPELINE_RVV
__attribute__((noinline,noclone))
static uint32_t vector(unsigned n,uint32_t *dst){
    unsigned off=0;uint32_t dot=0;
    while(off<n){
        size_t vl;uintptr_t part;
        /* Only positive AVL: do not exercise the baseline VL=0 reduction bug. */
        __asm__ volatile(
            "vsetvli %0,%2,e32,m1,ta,ma\n\t"
            "vle32.v v1,(%3)\n\tvle32.v v2,(%4)\n\t"
            "vmul.vx v3,v1,%6\n\tvadd.vv v3,v3,v2\n\t"
            "vmax.vx v3,v3,zero\n\tvse32.v v3,(%5)\n\t"
            "vmul.vv v4,v3,v2\n\tvmv.v.i v5,0\n\t"
            "vredsum.vs v6,v4,v5\n\tvmv.x.s %1,v6"
            :"=&r"(vl),"=&r"(part)
            :"r"((size_t)(n-off)),"r"(a+off),"r"(b+off),"r"(dst+off),"r"((uintptr_t)3)
            :"memory");
        if(!vl||vl>n-off)return 0xffffffffu;
        dot+=(uint32_t)part;off+=(unsigned)vl;
    }
    return dot;
}
#define KERNEL vector
#else
#define KERNEL scalar
#endif
static uint32_t workload(unsigned rounds){
    uint32_t digest=0;
    for(unsigned r=0;r<rounds;r++)for(unsigned k=0;k<sizeof lengths/sizeof lengths[0];k++){
        uint32_t dot=KERNEL(lengths[k],out+1);
        digest=(digest<<5)|(digest>>27);digest^=dot+lengths[k]+r;observed=dot;
    }
    return digest;
}
static int validate(void){
    for(unsigned k=0;k<sizeof lengths/sizeof lengths[0];k++){
        unsigned n=lengths[k];uint32_t dot=scalar(n,expected);
        for(unsigned i=0;i<CAPACITY+2;i++)out[i]=0xa5a55a5au;
        if(KERNEL(n,out+1)!=dot)return 1;
        if(out[0]!=0xa5a55a5au||out[n+1]!=0xa5a55a5au)return 2;
        for(unsigned i=0;i<n;i++)if(out[i+1]!=expected[i])return 3;
#ifdef PIPELINE_DUMP
        text("PIPELINE n=");hex(n);text(" dot=");hex(dot);put('\n');
        for(unsigned i=0;i<n;i++){hex(out[i+1]);put((i&7)==7?'\n':' ');}put('\n');
#endif
    }
    return 0;
}
static int final_equal(void){
    /* Inspect the actual last timed output before any validation rerun overwrites it. */
    uint32_t dot=scalar(CAPACITY,expected);
    if(observed!=dot||out[0]!=0xa5a55a5au||out[CAPACITY+1]!=0xa5a55a5au)return 1;
    for(unsigned i=0;i<CAPACITY;i++)if(out[i+1]!=expected[i])return 1;
    return 0;
}
int main(void){
#if !defined(PIPELINE_HOST) && !defined(PIPELINE_LINUX)
    __asm__ volatile("csrs mstatus,%0"::"r"(3UL<<9));
#endif
    for(unsigned i=0;i<CAPACITY;i++){
        uint32_t x=(uint32_t)i*1664525u+1013904223u;
        a[i]=x^(x>>13);b[i]=(x*22695477u+1u)^0x80000000u;
    }
    if(validate())goto fail;
#if defined(PIPELINE_HOST) || defined(PIPELINE_DUMP)
    uint32_t checksum=workload(PIPELINE_ROUNDS);
    if(final_equal())goto fail;
    text("PIPELINE_PASS checksum=");hex(checksum);put('\n');
#else
    workload(1); /* Explicit warm cache, identical for both QEMU versions. */
    text("RVWORK_READY\n");input('g');
    uint32_t checksum=workload(PIPELINE_ROUNDS);
    text("RVWORK_DONE ");hex(checksum);put('\n');input('e');
    if(final_equal()||validate())goto fail;
    text("PIPELINE_PASS\n");
#endif
#if !defined(PIPELINE_HOST) && !defined(PIPELINE_LINUX)
    *(volatile uint32_t*)0x100000=0x5555;
#endif
    return 0;
fail:text("PIPELINE_FAIL\n");
#if !defined(PIPELINE_HOST) && !defined(PIPELINE_LINUX)
    *(volatile uint32_t*)0x100000=0x13333;
#endif
    return 1;
}
