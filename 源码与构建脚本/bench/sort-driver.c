/* Warm an unchanged BOTS Sort kernel; reset through its original input code.
 * SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
 */
#define _GNU_SOURCE
#include <dlfcn.h>
#include <inttypes.h>
#include <stdatomic.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include <unistd.h>
#ifndef TASK_COST_NO_PREDICATE
#include "bakery-site.h"
#endif
extern long *array;
extern int bots_arg_size;
extern void fill_array(long *), scramble_array(long *), __real_sort_par(void);
extern int sort_verify(void);
#ifndef TASK_COST_NO_PREDICATE
typedef uint32_t (*check_t)(void *, uint32_t);
#endif
static uint64_t now(clockid_t clock) {
  struct timespec t;
  if (clock_gettime(clock, &t)) _exit(130);
  return (uint64_t)t.tv_sec * UINT64_C(1000000000) + t.tv_nsec;
}
#ifndef TASK_COST_NO_PREDICATE
static void predicate_cost(check_t check, unsigned match) {
  _Atomic uint32_t flag = match ? 2 : 1;
  for (int i = 0; i < 10000; ++i) if (check(&flag, 2) != match) _exit(131);
  for (int round = 0; round < 3; ++round) {
    uint64_t sum = 0, cpu = now(CLOCK_PROCESS_CPUTIME_ID), wall = now(CLOCK_MONOTONIC);
    for (int i = 0; i < 100000; ++i) sum += check(&flag, 2);
    wall = now(CLOCK_MONOTONIC) - wall; cpu = now(CLOCK_PROCESS_CPUTIME_ID) - cpu;
    if (sum != 100000U * match) _exit(132);
    printf("BAKERY_COST {\"match\":%u,\"round\":%d,\"iterations\":100000,\"wall_ns\":%" PRIu64
           ",\"cpu_ns\":%" PRIu64 ",\"sum\":%" PRIu64 "}\n", match, round, wall, cpu, sum);
  }
}
#endif
void __wrap_sort_par(void) {
  const char *expected = getenv("OPENMP_EXPECTED_LIBRARY");
  Dl_info info;
  void *symbol = dlsym(RTLD_DEFAULT, "__kmpc_omp_task");
  if (!symbol || !expected || !dladdr(symbol, &info) || strcmp(info.dli_fname, expected)) _exit(133);
#ifndef TASK_COST_NO_PREDICATE
  unsigned char *entry = (unsigned char *)info.dli_fbase + BAKERY_OFFSET;
  if (memcmp(entry, bakery_prefix, sizeof(bakery_prefix))) _exit(134);
  printf("COST_RUNTIME {\"library\":\"%s\",\"base\":\"0x%" PRIxPTR "\",\"predicate_pc\":\"0x%" PRIxPTR "\"}\n",
         info.dli_fname, (uintptr_t)info.dli_fbase, (uintptr_t)entry);
  predicate_cost((check_t)entry, 0);
  predicate_cost((check_t)entry, 1);
#else
  printf("COST_RUNTIME {\"library\":\"%s\",\"base\":\"0x%" PRIxPTR "\"}\n",
         info.dli_fname, (uintptr_t)info.dli_fbase);
#endif
  const char *w = getenv("TASK_COST_WARMUP"), *r = getenv("TASK_COST_ROUNDS");
  int warmup = w ? atoi(w) : 1, rounds = r ? atoi(r) : 3;
  if (warmup < 1 || warmup > 8 || rounds < 1 || rounds > 8) _exit(137);
  uint64_t expected_hash = 0;
  for (int round = -warmup; round < rounds; ++round) {
    fill_array(array); scramble_array(array);
    uint64_t hash = UINT64_C(14695981039346656037);
    for (int i = 0; i < bots_arg_size; ++i) { hash ^= (uint64_t)array[i]; hash *= UINT64_C(1099511628211); }
    if (round == -warmup) expected_hash = hash;
    if (hash != expected_hash) _exit(135);
    uint64_t cpu = now(CLOCK_PROCESS_CPUTIME_ID), wall = now(CLOCK_MONOTONIC);
    __real_sort_par();
    wall = now(CLOCK_MONOTONIC) - wall; cpu = now(CLOCK_PROCESS_CPUTIME_ID) - cpu;
    if (sort_verify() != 1) _exit(136);
    printf("TASK_BENCH {\"round\":%d,\"n\":%d,\"input_hash\":\"%016" PRIx64 "\",\"wall_ns\":%" PRIu64
           ",\"cpu_ns\":%" PRIu64 ",\"check\":1}\n", round, bots_arg_size, hash, wall, cpu);
  }
}
