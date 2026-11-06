#include <inttypes.h>
#include <stdio.h>
#include "../common/smoke_kernel.h"
/* x86 本地的独立标量计算，不读预置答案，也不调用 QEMU。 */
int main(void)
{
    uint64_t sum = 0;
    for (unsigned i = 0; i < SMOKE_LENGTH; ++i) {
        sum += smoke_left(i) + smoke_right(i);
    }
    printf("BUILD_SMOKE_PASS checksum=%016" PRIx64 "\n", sum);
    return 0;
}

