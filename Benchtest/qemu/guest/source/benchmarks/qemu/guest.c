/* RVV instruction workload v1: constant configuration and vector addition. */
#include <stdint.h>
#define LOOPS 262144u
static uint32_t lanes[4] __attribute__((aligned(4096)));
static void put(char c) {volatile uint8_t*u=(void*)0x10000000UL;while(!(u[5]&32)){}u[0]=c;}
static void text(const char*s) {while(*s)put(*s++);}
static void input(char c) {volatile uint8_t*u=(void*)0x10000000UL;for(;;)if((u[5]&1)&&u[0]==(uint8_t)c)return;}
__attribute__((noinline,noclone)) static uint64_t kernel(unsigned count) {
    uint64_t sum=0;
    for(unsigned i=0;i<count;i++) {
        uint64_t vl,value;
#ifdef BENCH_DYNAMIC
        __asm__ volatile("vsetvli %0,%1,e32,m1,tu,mu":"=r"(vl):"r"((uint64_t)((i&31)+1)));
#else
        __asm__ volatile("vsetivli %0,31,e32,m1,tu,mu":"=r"(vl));
#endif
        __asm__ volatile("vmv.v.x v1,%1\n\tvadd.vi v2,v1,1\n\tvmv.x.s %0,v2"
                         :"=r"(value):"r"((uint64_t)i):"memory");
        sum+=value;
    }
    __asm__ volatile("vse32.v v2,(%0)"::"r"(lanes):"memory");
    return sum;
}
int main(void) {
    /* Guest vector state must be enabled in addition to -cpu ...,v=true. */
    __asm__ volatile("csrs mstatus,%0"::"r"(3UL<<9));
    uint64_t vlenb;
    __asm__ volatile("csrr %0,vlenb":"=r"(vlenb));
    if(vlenb!=16)goto fail;
    if(kernel(8192)!=(uint64_t)8192*8193/2)goto fail;
    for(unsigned i=0;i<4;i++)if(lanes[i]!=8192)goto fail;
    text("RVWORK_RVV v1 e32 m1 VLEN128 loops262144\n");
    text("RVWORK_READY\n");input('g');
    uint64_t sum=kernel(LOOPS);
    if(sum!=(uint64_t)LOOPS*(LOOPS+1)/2)goto fail;
    for(unsigned i=0;i<4;i++)if(lanes[i]!=LOOPS)goto fail;
    uint32_t checksum=(uint32_t)(sum^(sum>>32));
    text("RVWORK_DONE ");for(int n=7;n>=0;n--)put("0123456789abcdef"[(checksum>>(n*4))&15]);put('\n');
    input('e');*(volatile uint32_t*)0x100000=0x5555;return 0;
fail:
    text("RVWORK_FAIL\n");*(volatile uint32_t*)0x100000=0x13333;return 1;
}
