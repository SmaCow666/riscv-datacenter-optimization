/* Scheduling contracts exercised after changing a task-to-task OS yield. */
#define _GNU_SOURCE
#include <dlfcn.h>
#include <omp.h>
#include <stdatomic.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#define N 128
static int tokens[N], values[N];
static _Atomic unsigned produced[N], consumed[N], errors;
int main(int argc,char **argv) {
  if(argc!=2)return 2;
  int threads=atoi(argv[1]);if(threads!=1 && threads!=2 && threads!=4)return 2;
  const char *expected=getenv("OPENMP_EXPECTED_LIBRARY");Dl_info info;
  if(!expected || !dladdr((void *)omp_get_num_threads,&info) || strcmp(info.dli_fname,expected))return 3;
  alarm(20);omp_set_dynamic(0);omp_set_num_threads(threads);int actual=0;
#pragma omp parallel shared(actual)
  {
#pragma omp single
    {
      actual=omp_get_num_threads();
      for(int i=0;i<N;++i) {
#pragma omp task firstprivate(i) depend(out: tokens[i])
        {
          int original=omp_get_thread_num();
#pragma omp task firstprivate(i)
          {values[i]=i*17+5;}
#pragma omp taskwait
#pragma omp taskyield
          if(omp_get_thread_num()!=original)atomic_fetch_add(&errors,1);
          atomic_fetch_add(&produced[i],1);
        }
#pragma omp task firstprivate(i) depend(in: tokens[i])
        {
          if(values[i]!=i*17+5 || atomic_load(&produced[i])!=1)atomic_fetch_add(&errors,1);
          atomic_fetch_add(&consumed[i],1);
        }
      }
#pragma omp taskwait
    }
  }
  if(actual!=threads)atomic_fetch_add(&errors,1);
  for(int i=0;i<N;++i)if(atomic_load(&produced[i])!=1 || atomic_load(&consumed[i])!=1)atomic_fetch_add(&errors,1);
  printf("HANDOFF_CONTRACTS {\"actual_team\":%d,\"pairs\":%d,\"nested_tasks\":%d,\"errors\":%u,\"library\":\"%s\"}\n",actual,N,N,atomic_load(&errors),info.dli_fname);
  alarm(0);return atomic_load(&errors)?1:0;
}
