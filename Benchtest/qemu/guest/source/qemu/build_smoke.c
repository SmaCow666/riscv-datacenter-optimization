#include "../common/smoke_kernel.h"
static uint32_t left[SMOKE_LENGTH], right[SMOKE_LENGTH], out[SMOKE_LENGTH];
static void put(char c)
{
    volatile uint8_t *uart = (void *)0x10000000UL;
    while (!(uart[5] & 32)) { }
    uart[0] = c;
}
static void text(const char *s) { while (*s) { put(*s++); } }
static void hex(uint64_t n)
{
    for (int i = 15; i >= 0; --i) { put("0123456789abcdef"[(n >> (i * 4)) & 15]); }
}
int main(void)
{
    __asm__ volatile("csrs mstatus,%0" :: "r"(3UL << 9) : "memory");
    for (unsigned i = 0; i < SMOKE_LENGTH; ++i) {
        left[i] = smoke_left(i);
        right[i] = smoke_right(i);
    }
    unsigned offset = 0;
    while (SMOKE_LENGTH - offset >= 4) {
        __asm__ volatile("vsetivli zero,4,e32,m1,tu,mu\n\t"
                         "vle32.v v0,(%0)\n\t"
                         "vle32.v v1,(%1)\n\t"
                         "vadd.vv v2,v0,v1\n\t"
                         "vse32.v v2,(%2)"
                         :: "r"(left + offset), "r"(right + offset), "r"(out + offset) : "memory");
        offset += 4;
    }
    if (offset < SMOKE_LENGTH) {
        uintptr_t vl;
        uintptr_t remaining = SMOKE_LENGTH - offset;
        __asm__ volatile("vsetvli %0,%1,e32,m1,tu,mu" : "=r"(vl) : "r"(remaining) : "memory");
        if (vl != remaining) { text("BUILD_SMOKE_FAIL vl\n"); goto failure; }
        __asm__ volatile("vle32.v v0,(%0)\n\t"
                         "vle32.v v1,(%1)\n\t"
                         "vadd.vv v2,v0,v1\n\t"
                         "vse32.v v2,(%2)"
                         :: "r"(left + offset), "r"(right + offset), "r"(out + offset) : "memory");
    }
    uint64_t sum = 0;
    for (unsigned i = 0; i < SMOKE_LENGTH; ++i) {
        if (out[i] != left[i] + right[i]) { text("BUILD_SMOKE_FAIL value\n"); goto failure; }
        sum += out[i];
    }
    text("BUILD_SMOKE_PASS checksum="); hex(sum); put('\n');
    *(volatile unsigned *)0x100000UL = 0x5555;
    return 0;
failure:
    *(volatile unsigned *)0x100000UL = 0x13333;
    for (;;) { }
}

