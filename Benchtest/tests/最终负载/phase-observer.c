#define _GNU_SOURCE
#include <petscksp.h>
#include "StrumpackSparseSolver.h"
#include <dlfcn.h>
#include <math.h>
#include <omp.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>

#ifndef HOTSPOT_SHAPES
#define HOTSPOT_SHAPES 1
#endif
#ifndef HOTSPOT_TIMERS
#define HOTSPOT_TIMERS 1
#endif
/* Each OS thread owns its buckets. Phase changes only surround synchronous
   public solver calls whose tasks have completed before returning. */
enum { OTHER, REORDER, FACTOR, FIRST_SOLVE, REUSE_SOLVE, PHASES };
enum { API, NKERNEL, GEMM };
struct bucket { int used, phase, kind; long m,n,k,lda,ix,iy; char trans;
  unsigned long calls; double cpu; unsigned long serial; void *caller; };
struct thread_data { struct bucket entries[4096]; unsigned long task[PHASES],yield[PHASES],handoff[PHASES]; };
static struct thread_data data[8];
static unsigned threads; static _Thread_local int slot = -1;
static int phase; static uintptr_t omp_base, ras[8]; static int nr;
struct stage { unsigned calls; double wall, cpu; };
static struct stage stages[PHASES], ksp_setup, ksp_solve;
static _Thread_local int ksp_active;
static unsigned nested_setup;
static double bracket;
static unsigned long sequence;
static double clock_(clockid_t id) { struct timespec t; if(clock_gettime(id,&t))abort();return t.tv_sec+t.tv_nsec*1e-9; }
static void *resolve(const char *s) { void *p=dlsym(RTLD_NEXT,s);if(!p){fprintf(stderr,"HOTSPOT_MISSING %s\n",s);abort();}return p; }
static struct thread_data *thread_(void) { if(slot<0)slot=(int)__atomic_fetch_add(&threads,1,__ATOMIC_RELAXED);if(slot>=8)abort();return &data[slot]; }
static struct bucket *bucket_(int kind,long m,long n,long k,long lda,long ix,long iy,char trans,void *caller) {
  struct thread_data *d=thread_();int p=__atomic_load_n(&phase,__ATOMIC_ACQUIRE);
  uint64_t hash=(uint64_t)m*31u+(uint64_t)n*131u+(uint64_t)lda*17u+(uint64_t)kind*8191u+(uint64_t)p*65537u+(uint64_t)(uintptr_t)caller;
  for(unsigned j=0;j<4096;j++) {
    struct bucket *b=&d->entries[(hash+j)%4096];
    if(!b->used){*b=(struct bucket){.used=1,.phase=p,.kind=kind,.m=m,.n=n,.k=k,.lda=lda,.ix=ix,.iy=iy,.trans=trans,.caller=caller,.serial=__atomic_fetch_add(&sequence,1,__ATOMIC_RELAXED)};return b;}
    if(b->phase==p&&b->kind==kind&&b->m==m&&b->n==n&&b->k==k&&b->lda==lda&&b->ix==ix&&b->iy==iy&&b->trans==trans&&b->caller==caller)return b;
  }
  fprintf(stderr,"HOTSPOT_BUCKET_OVERFLOW\n");abort();
}
typedef STRUMPACK_RETURN_CODE(*Reorder)(STRUMPACK_SparseSolver,int,int,int,int,int);
typedef STRUMPACK_RETURN_CODE(*Factor)(STRUMPACK_SparseSolver);
typedef STRUMPACK_RETURN_CODE(*Solve)(STRUMPACK_SparseSolver,const void*,void*,int);
typedef PetscErrorCode(*KSPCall)(KSP);
typedef PetscErrorCode(*KSPSolveCall)(KSP,Vec,Vec);
typedef void(*Gemv)(const char*,const int*,const int*,const double*,const double*,const int*,const double*,const int*,const double*,double*,const int*);
typedef int(*Kernel)(long,long,long,double,double*,long,double*,long,double*,long,double*);
typedef void(*Gemm)(const char*,const char*,const int*,const int*,const int*,const double*,const double*,const int*,const double*,const int*,const double*,double*,const int*);
typedef int(*Task)(void*,int,void*);typedef int(*Yield)(void);
static Reorder reorder_;static Factor factor_;static Solve solve_;static KSPCall setup_;static KSPSolveCall kspsolve_;
static Gemv gemv_;static Kernel kernel_;static Gemm gemm_;static Task task_;static Yield yield_;
static void begin_(int p,double *wall,double *cpu) {__atomic_store_n(&phase,p,__ATOMIC_RELEASE);*wall=clock_(CLOCK_MONOTONIC);*cpu=clock_(CLOCK_THREAD_CPUTIME_ID);}
static void end_(int p,double wall,double cpu) {stages[p].wall+=clock_(CLOCK_MONOTONIC)-wall;stages[p].cpu+=clock_(CLOCK_THREAD_CPUTIME_ID)-cpu;stages[p].calls++;__atomic_store_n(&phase,OTHER,__ATOMIC_RELEASE);}
STRUMPACK_RETURN_CODE STRUMPACK_reorder_regular(STRUMPACK_SparseSolver s,int nx,int ny,int nz,int components,int width) {
  double w,c;begin_(REORDER,&w,&c);STRUMPACK_RETURN_CODE r=reorder_(s,nx,ny,nz,components,width);end_(REORDER,w,c);return r;
}
STRUMPACK_RETURN_CODE STRUMPACK_factor(STRUMPACK_SparseSolver s) {
  double w,c;begin_(FACTOR,&w,&c);STRUMPACK_RETURN_CODE r=factor_(s);end_(FACTOR,w,c);return r;
}
STRUMPACK_RETURN_CODE STRUMPACK_solve(STRUMPACK_SparseSolver s,const void*b,void*x,int guess) {
  int p=stages[FIRST_SOLVE].calls?REUSE_SOLVE:FIRST_SOLVE;double w,c;begin_(p,&w,&c);STRUMPACK_RETURN_CODE r=solve_(s,b,x,guess);end_(p,w,c);return r;
}
PetscErrorCode KSPSetUp(KSP ksp) {if(ksp_active){nested_setup++;return setup_(ksp);}double w=clock_(CLOCK_MONOTONIC),c=clock_(CLOCK_THREAD_CPUTIME_ID);PetscErrorCode r=setup_(ksp);ksp_setup.wall+=clock_(CLOCK_MONOTONIC)-w;ksp_setup.cpu+=clock_(CLOCK_THREAD_CPUTIME_ID)-c;ksp_setup.calls++;return r;}
PetscErrorCode KSPSolve(KSP ksp,Vec b,Vec x) {double w=clock_(CLOCK_MONOTONIC),c=clock_(CLOCK_THREAD_CPUTIME_ID);ksp_active++;PetscErrorCode r=kspsolve_(ksp,b,x);ksp_active--;ksp_solve.wall+=clock_(CLOCK_MONOTONIC)-w;ksp_solve.cpu+=clock_(CLOCK_THREAD_CPUTIME_ID)-c;ksp_solve.calls++;return r;}
#if HOTSPOT_SHAPES
void dgemv_(const char*t,const int*m,const int*n,const double*a,const double*A,const int*lda,const double*x,const int*ix,const double*b,double*y,const int*iy) {
  struct bucket *s=bucket_(API,*m,*n,0,*lda,*ix,*iy,*t,__builtin_return_address(0));
  double c=HOTSPOT_TIMERS?clock_(CLOCK_THREAD_CPUTIME_ID):0;gemv_(t,m,n,a,A,lda,x,ix,b,y,iy);if(HOTSPOT_TIMERS)s->cpu+=clock_(CLOCK_THREAD_CPUTIME_ID)-c;s->calls++;
}
int dgemv_n(long m,long n,long d,double a,double*A,long lda,double*x,long ix,double*y,long iy,double*w) {
  struct bucket *s=bucket_(NKERNEL,m,n,0,lda,ix,iy,'N',__builtin_return_address(0));
  double c=HOTSPOT_TIMERS?clock_(CLOCK_THREAD_CPUTIME_ID):0;int r=kernel_(m,n,d,a,A,lda,x,ix,y,iy,w);if(HOTSPOT_TIMERS)s->cpu+=clock_(CLOCK_THREAD_CPUTIME_ID)-c;s->calls++;return r;
}
void dgemm_(const char*ta,const char*tb,const int*m,const int*n,const int*k,const double*a,const double*A,const int*lda,const double*B,const int*ldb,const double*b,double*C,const int*ldc) {
  struct bucket*s=bucket_(GEMM,*m,*n,*k,*lda,0,0,*ta,__builtin_return_address(0));
  double c=HOTSPOT_TIMERS?clock_(CLOCK_THREAD_CPUTIME_ID):0;gemm_(ta,tb,m,n,k,a,A,lda,B,ldb,b,C,ldc);if(HOTSPOT_TIMERS)s->cpu+=clock_(CLOCK_THREAD_CPUTIME_ID)-c;s->calls++;
}
int __kmpc_omp_task(void*l,int gtid,void*t) {struct thread_data*d=thread_();int p=__atomic_load_n(&phase,__ATOMIC_ACQUIRE);d->task[p]++;return task_(l,gtid,t);}
int sched_yield(void) {struct thread_data*d=thread_();int p=__atomic_load_n(&phase,__ATOMIC_ACQUIRE);uintptr_t pc=(uintptr_t)__builtin_return_address(0);d->yield[p]++;for(int i=0;i<nr;i++)if(pc==omp_base+ras[i])d->handoff[p]++;return yield_();}
#endif
__attribute__((constructor))static void init(void) {
  reorder_=(Reorder)resolve("STRUMPACK_reorder_regular");factor_=(Factor)resolve("STRUMPACK_factor");solve_=(Solve)resolve("STRUMPACK_solve");setup_=(KSPCall)resolve("KSPSetUp");kspsolve_=(KSPSolveCall)resolve("KSPSolve");
  gemv_=(Gemv)resolve("dgemv_");kernel_=(Kernel)resolve("dgemv_n");gemm_=(Gemm)resolve("dgemm_");task_=(Task)resolve("__kmpc_omp_task");yield_=(Yield)resolve("sched_yield");
  Dl_info info={0};if(!dladdr((void*)task_,&info))abort();omp_base=(uintptr_t)info.dli_fbase;
  const char*s=getenv("STRUMPACK_HANDOFF_RAS");if(!s)abort();char*copy=strdup(s),*save;for(char*p=strtok_r(copy,",",&save);p;p=strtok_r(NULL,",",&save)){if(nr>=8)abort();ras[nr++]=strtoull(p,NULL,16);}free(copy);
  const char*names[]={"KSPSolve","STRUMPACK_solve","dgemv_","dgemv_n","__kmpc_omp_task"};void*ptrs[]={(void*)kspsolve_,(void*)solve_,(void*)gemv_,(void*)kernel_,(void*)task_};
  for(int i=0;i<5;i++){if(!dladdr(ptrs[i],&info))abort();printf("HOTSPOT_PROVIDER {\"symbol\":\"%s\",\"path\":\"%s\"}\n",names[i],info.dli_fname);}
  double sum=0;for(int i=0;i<1000;i++){double t=clock_(CLOCK_THREAD_CPUTIME_ID);sum+=clock_(CLOCK_THREAD_CPUTIME_ID)-t;}bracket=sum/1000;
}
__attribute__((destructor))static void report(void) {
  printf("HOTSPOT_META {\"shapes\":%s,\"per_call_timers\":%s,\"empty_clock_pair_mean\":%.17g,\"threads_observed\":%u,\"overflow\":false}\n",HOTSPOT_SHAPES?"true":"false",HOTSPOT_TIMERS?"true":"false",bracket,threads);
  printf("HOTSPOT_KSP {\"setup_calls\":%u,\"setup_wall\":%.17g,\"solve_calls\":%u,\"solve_wall\":%.17g,\"nested_setup_calls_excluded\":%u}\n",ksp_setup.calls,ksp_setup.wall,ksp_solve.calls,ksp_solve.wall,nested_setup);
  for(int p=0;p<PHASES;p++) {
    unsigned long task=0,y=0,h=0;for(unsigned t=0;t<threads;t++){task+=data[t].task[p];y+=data[t].yield[p];h+=data[t].handoff[p];}
    printf("HOTSPOT_STAGE {\"phase\":%d,\"calls\":%u,\"wall\":%.17g,\"caller_cpu\":%.17g,\"task_api_calls\":%lu,\"sched_yield_calls\":%lu,\"handoff_yield_calls\":%lu}\n",p,stages[p].calls,stages[p].wall,stages[p].cpu,task,y,h);
  }
  for(unsigned t=0;t<threads;t++)for(unsigned j=0;j<4096;j++) {
    struct bucket*b=&data[t].entries[j];if(!b->used)continue;Dl_info info={0};if(!dladdr(b->caller,&info))abort();
    printf("HOTSPOT_SHAPE {\"phase\":%d,\"kind\":%d,\"m\":%ld,\"n\":%ld,\"k\":%ld,\"lda\":%ld,\"incx\":%ld,\"incy\":%ld,\"trans\":\"%c\",\"calls\":%lu,\"cpu_sum\":%.17g,\"thread_slot\":%u,\"caller\":\"%s\",\"caller_symbol\":\"%s\",\"return_offset\":%llu}\n",b->phase,b->kind,b->m,b->n,b->k,b->lda,b->ix,b->iy,b->trans,b->calls,b->cpu,t,info.dli_fname,info.dli_sname?info.dli_sname:"UNKNOWN",(unsigned long long)((uintptr_t)b->caller-(uintptr_t)info.dli_fbase));
  }
}
