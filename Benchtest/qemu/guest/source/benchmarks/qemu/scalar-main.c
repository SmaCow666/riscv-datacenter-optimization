#include "../kernel.h"
static volatile unsigned char *const uart = (void *)0x10000000UL;
static volatile uint32_t *const finisher = (void *)0x100000UL;
static void putc_uart(char c)
{
    while (!(uart[5] & 0x20)) { }
    uart[0] = (unsigned char)c;
}
static void puts_uart(const char *s)
{
    while (*s) putc_uart(*s++);
}
int main(void)
{
    volatile uint32_t selfcheck = 0;
    for (uint32_t i = 1; i <= 64; ++i) selfcheck += i;
    if (selfcheck != 2080) {
        puts_uart("RVWORK_FAIL\n");
        *finisher = (1u << 16) | 0x3333;
        return 1;
    }
    puts_uart("RVWORK_READY\n");
    uint32_t sum = rvwork_compute();
    puts_uart("RVWORK_DONE ");
    for (int i = 7; i >= 0; --i) putc_uart("0123456789abcdef"[(sum >> (4 * i)) & 15]);
    puts_uart("\n");
    *finisher = 0x5555;
    return 0;
}
