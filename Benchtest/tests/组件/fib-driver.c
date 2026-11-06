/* Time unchanged BOTS fib0; reuse original source/objects and verifier. */
#define _GNU_SOURCE
#include <dlfcn.h>
#include <inttypes.h>
#include <omp.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include <unistd.h>
extern void __real_fib0(int);
extern int fib_verify(int);
static uint64_t now(clockid_t clock) {
  struct timespec t;if(clock_gettime(clock,&t))_exit(170);
  return (uint64_t)t.tv_sec*UINT64_C(1000000000)+t.tv_nsec;
}
void __wrap_fib0(int n) {
  Dl_info image;const char *expected=getenv("OPENMP_EXPECTED_LIBRARY");
  void *symbol=dlsym(RTLD_DEFAULT,"__kmpc_omp_task_alloc");
  if(n!=28||!expected||!symbol||!dladdr(symbol,&image)||strcmp(expected,image.dli_fname))_exit(171);
  int requested=omp_get_max_threads(),actual=0;
#pragma omp parallel
#pragma omp single
  actual=omp_get_num_threads();
  if(actual!=requested)_exit(173);
  printf("FIB_RUNTIME {\"library\":\"%s\",\"team\":%d}\n",image.dli_fname,actual);
  const char *w=getenv("TASK_COST_WARMUP"),*r=getenv("TASK_COST_ROUNDS");
  int warmup=w?atoi(w):1,rounds=r?atoi(r):3;
  if(warmup<1||warmup>3||rounds<1||rounds>5)_exit(174);
  alarm(60);
  for(int round=-warmup;round<rounds;++round) {
    uint64_t cpu=now(CLOCK_PROCESS_CPUTIME_ID),wall=now(CLOCK_MONOTONIC);
    __real_fib0(n);
    wall=now(CLOCK_MONOTONIC)-wall;cpu=now(CLOCK_PROCESS_CPUTIME_ID)-cpu;
    if(fib_verify(n)!=1)_exit(172);
    printf("FIB_BENCH {\"round\":%d,\"n\":%d,\"cutoff\":10,\"expected\":317811,\"actual_team\":%d,"
           "\"wall_ns\":%" PRIu64 ",\"cpu_ns\":%" PRIu64 ",\"check\":1}\n",round,n,actual,wall,cpu);
  }
  alarm(0);
}
