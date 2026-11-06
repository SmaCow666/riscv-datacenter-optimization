#ifndef SUITE_SMOKE_KERNEL_H
#define SUITE_SMOKE_KERNEL_H
#include <stdint.h>
#define SMOKE_LENGTH 19
static inline uint32_t smoke_left(unsigned i) { return i; }
static inline uint32_t smoke_right(unsigned i) { return 2U * i + 1U; }
#endif

