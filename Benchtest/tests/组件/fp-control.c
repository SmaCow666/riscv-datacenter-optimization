/* Characterize documented FP-control inheritance on cold/reused OpenMP teams. */
#define _GNU_SOURCE
#include <dlfcn.h>
#include <fenv.h>
#include <math.h>
#include <omp.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
static volatile double positive=1.5,negative=-1.5;
static const int modes[]={FE_UPWARD,FE_DOWNWARD,FE_TOWARDZERO,FE_TONEAREST};
int main(int argc,char **argv) {
  if(argc!=3)return 2;
  int threads=atoi(argv[1]),local=!strcmp(argv[2],"local");
  if((threads!=1 && threads!=2) || (!local && strcmp(argv[2],"inherit")))return 2;
  const char *expected=getenv("OPENMP_EXPECTED_LIBRARY");Dl_info info;
  if(!expected || !dladdr((void *)omp_get_num_threads,&info) || strcmp(info.dli_fname,expected))return 3;
  printf("FP_RUNTIME {\"library\":\"%s\"}\n",info.dli_fname);
  omp_set_dynamic(0);omp_set_num_threads(threads);alarm(20);
  for(unsigned stage=0;stage<sizeof(modes)/sizeof(modes[0]);++stage) {
    if(fesetround(modes[stage]))return 4;
    double expected_pos=nearbyint(positive),expected_neg=nearbyint(negative);
    int actual=0,observed[2]={-1,-1},mismatch[2]={0,0};double pos[2]={0,0},neg[2]={0,0};
#pragma omp parallel shared(actual,observed,mismatch,pos,neg)
    {
      int tid=omp_get_thread_num();
      if(tid==0)actual=omp_get_num_threads();
      if(local && fesetround(modes[stage]))_exit(170);
      observed[tid]=fegetround();pos[tid]=nearbyint(positive);neg[tid]=nearbyint(negative);
      mismatch[tid]=observed[tid]!=modes[stage] || pos[tid]!=expected_pos || neg[tid]!=expected_neg;
    }
    if(actual!=threads)return 5;
    printf("FP_CONTROL {\"stage\":%u,\"local\":%d,\"expected_mode\":%d,\"actual_team\":%d,\"expected_positive\":%.0f,\"expected_negative\":%.0f,\"threads\":[",stage,local,modes[stage],actual,expected_pos,expected_neg);
    for(int i=0;i<actual;++i)printf("%s{\"tid\":%d,\"mode\":%d,\"positive\":%.0f,\"negative\":%.0f,\"mismatch\":%d}",i?",":"",i,observed[i],pos[i],neg[i],mismatch[i]);
    puts("]}");
  }
  if(fesetround(FE_TONEAREST))return 6;
  alarm(0);return 0;
}
