#define _GNU_SOURCE
#include <dlfcn.h>
#include <math.h>
#include <sched.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
static void need(int ok,const char *s){if(!ok){fprintf(stderr,"FINAL_BLAS_FAIL %s\n",s);exit(1);}}
static long long ns(clockid_t c){struct timespec t;need(!clock_gettime(c,&t),"clock");return(long long)t.tv_sec*1000000000+t.tv_nsec;}
static uint64_t hash(const void*p,size_t n){uint64_t h=14695981039346656037ULL;const unsigned char*b=p;while(n--){h^=*b++;h*=1099511628211ULL;}return h;}
static void*allocate(size_t n){void*p=NULL;need(!posix_memalign(&p,64,n),"allocation");return p;}
#define PRECISION(T,P) \
static void run_##P(void*h,const char*kind,const char*mode,long m,long n,long lda,long ix,long iy,long reps,int samples){ \
 typedef int(*G)(long,long,long,T,T*,long,T*,long,T*,long,T*); \
 typedef int(*X)(long,long,long,T,T*,long,T*,long,T*,long); \
 typedef void(*GA)(int,int,int,int,T,const T*,int,const T*,int,T,T*,int); \
 typedef void(*XA)(int,T,const T*,int,T*,int); \
 int gemv=!strcmp(kind,"gemv"),api=!strcmp(mode,"api");char symbol[64];snprintf(symbol,sizeof(symbol),"%s%s%s",api?"cblas_":"",#P,gemv?(api?"gemv":"gemv_n"):(api?"axpy":"axpy_k")); \
 void*fn=dlsym(h,symbol);Dl_info identity;need(fn&&dladdr(fn,&identity),"symbol/provider"); \
 printf("FINAL_BLAS_ID {\"provider\":\"%s\",\"symbol\":\"%s\",\"cpu\":%d}\n",identity.dli_fname,symbol,sched_getcpu()); \
 size_t an=gemv?(size_t)lda*n:1,xn=1+(size_t)((gemv?n:m)-1)*ix,yn=1+(size_t)(m-1)*iy; \
 T *ar=allocate((an+16)*sizeof(T)),*xr=allocate((xn+16)*sizeof(T)),*yr=allocate((yn+16)*sizeof(T)); \
 T *a=ar+8,*x=xr+8,*y=yr+8,guard=(T)0x1.234p20;double *reference=allocate(m*sizeof(double)); \
 for(size_t i=0;i<an+16;i++)ar[i]=guard;for(size_t i=0;i<xn+16;i++)xr[i]=guard;for(size_t i=0;i<yn+16;i++)yr[i]=guard; \
 for(long j=0;j<(gemv?n:m);j++)x[j*ix]=(T)((j*7+3)%11-5)/(T)32; \
 if(gemv)for(long j=0;j<n;j++)for(long i=0;i<m;i++)a[i+(size_t)j*lda]=(T)((i*13+j*7)%17-8)/(T)32; \
 for(long i=0;i<m;i++){reference[i]=gemv?0:(double)x[i*ix];if(gemv)for(long j=0;j<n;j++)reference[i]+=(double)a[i+(size_t)j*lda]*x[j*ix];} \
 uint64_t ah=hash(ar,(an+16)*sizeof(T)),xh=hash(xr,(xn+16)*sizeof(T)); \
 /* A complete result is checked once before timing. Timed inverse pairs keep \
    all sums within exact dyadic FP32/FP64 range, without resetting y in-loop. */ \
 for(int phase=-2;phase<samples;phase++){for(long i=0;i<m;i++)y[i*iy]=0;long count=phase==-2?1:reps; \
  long long cpu0=ns(CLOCK_THREAD_CPUTIME_ID),wall0=ns(CLOCK_MONOTONIC); \
  for(long r=0;r<count;r++)for(int sign=0;sign<(phase==-2?1:2);sign++){T alpha=sign?(T)-1:(T)1; \
   if(gemv){if(api)((GA)fn)(102,111,m,n,alpha,a,lda,x,ix,(T)1,y,iy);else need(!((G)fn)(m,n,0,alpha,a,lda,x,ix,y,iy,NULL),"kernel return");} \
   else if(api)((XA)fn)(m,alpha,x,ix,y,iy);else need(!((X)fn)(m,0,0,alpha,x,ix,y,iy,NULL,0),"kernel return"); \
  } \
  long long wall=ns(CLOCK_MONOTONIC)-wall0,cpu=ns(CLOCK_THREAD_CPUTIME_ID)-cpu0; \
  for(long i=0;i<m;i++)need(isfinite(y[i*iy])&&(double)y[i*iy]==(phase==-2?reference[i]:0.),"all output exact"); \
  for(int i=0;i<8;i++)need(ar[i]==guard&&ar[an+8+i]==guard&&xr[i]==guard&&xr[xn+8+i]==guard&&yr[i]==guard&&yr[yn+8+i]==guard,"boundary guards"); \
  for(size_t i=0;i<yn;i++)if(i%iy)need(y[i]==guard,"output stride holes"); \
  need(ah==hash(ar,(an+16)*sizeof(T))&&xh==hash(xr,(xn+16)*sizeof(T)),"input immutability");need(sched_getcpu()==0,"CPU0"); \
  if(phase>=-1)printf("FINAL_BLAS_ROUND {\"round\":%d,\"repeats\":%ld,\"calls\":%ld,\"wall_ns\":%lld,\"thread_cpu_ns\":%lld,\"correct\":true,\"guards\":true}\n",phase,reps,2*reps,wall,cpu); \
 }free(ar);free(xr);free(yr);free(reference); \
}
PRECISION(float,s)
PRECISION(double,d)
int main(int argc,char**argv){
 need(argc==12,"library kind precision mode M N lda incx incy repeats samples");
 long v[7];for(int i=0;i<7;i++){char*e;v[i]=strtol(argv[i+5],&e,10);need(!*e,"integer argument");}
 long m=v[0],n=v[1],lda=v[2],ix=v[3],iy=v[4],reps=v[5],samples=v[6];
 need((!strcmp(argv[2],"gemv")||!strcmp(argv[2],"axpy"))&&(!strcmp(argv[3],"s")||!strcmp(argv[3],"d"))&&(!strcmp(argv[4],"kernel")||!strcmp(argv[4],"api")),"case kind");
 need(m>=1&&m<=4096&&n>=1&&n<=4096&&lda>=m&&lda<=8192&&ix>=1&&ix<=2&&iy>=1&&iy<=2&&reps>=1&&reps<=2000000&&samples>=1&&samples<=3,"case limits");
 cpu_set_t set,actual;CPU_ZERO(&set);CPU_SET(0,&set);need(!sched_setaffinity(0,sizeof(set),&set)&&!sched_getaffinity(0,sizeof(actual),&actual)&&CPU_EQUAL(&set,&actual),"CPU0 binding");
 void*h=dlopen(argv[1],RTLD_NOW|RTLD_LOCAL);need(h!=NULL,dlerror()?"dlopen failed":"dlopen");
 int(*threads)(void)=dlsym(h,"openblas_get_num_threads");need(threads&&threads()==1,"single-thread BLAS");
 if(!strcmp(argv[3],"s"))run_s(h,argv[2],argv[4],m,n,lda,ix,iy,reps,samples);else run_d(h,argv[2],argv[4],m,n,lda,ix,iy,reps,samples);
 dlclose(h);puts("FINAL_BLAS_EXIT=0");return 0;
}
