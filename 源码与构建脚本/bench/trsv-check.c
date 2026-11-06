#define _GNU_SOURCE
#include <dlfcn.h>
#include <math.h>
#include <sched.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/mman.h>
#include <time.h>
#include <unistd.h>

typedef void (*Solve)(const char *,const char *,const char *,const int *,const void *,const int *,void *,const int *);
static void need(int x,const char *s){if(!x){fprintf(stderr,"TRSV_FAIL %s\n",s);exit(1);}}
static uint64_t clock_(clockid_t id){struct timespec t;need(!clock_gettime(id,&t),"clock");return (uint64_t)t.tv_sec*1000000000+t.tv_nsec;}
static void *get(void *h,const char *s,const char *expected){void *p=dlsym(h,s);Dl_info i;need(p&&dladdr(p,&i)&&!strcmp(i.dli_fname,expected),"actual provider");return p;}
static void set(void *p,int i,long double v,int single){if(single)((float *)p)[i]=v;else ((double *)p)[i]=v;}
static long double at(const void *p,int i,int single){return single?((const float *)p)[i]:((const double *)p)[i];}
static void *guard(size_t bytes,void **mapping,size_t *length){size_t page=sysconf(_SC_PAGESIZE),data=(bytes+page-1)/page*page;if(!data)data=page;*length=data+2*page;*mapping=mmap(NULL,*length,PROT_NONE,MAP_PRIVATE|MAP_ANONYMOUS,-1,0);need(*mapping!=MAP_FAILED,"map");need(!mprotect((char *)*mapping+page,data,PROT_READ|PROT_WRITE),"protect");return (char *)*mapping+page+data-bytes;}
static void fill(int n,int lda,int stride,int lower,int unit,int trans,int single,void *a,void *b){
  int size=single?4:8;
  for(int j=0;j<n;j++)for(int i=0;i<lda;i++)set(a,i+j*lda,NAN,single);
  for(int j=0;j<n;j++)for(int i=0;i<n;i++)if((lower&&i>=j)||(!lower&&i<=j))set(a,i+j*lda,i==j?(unit?NAN:2):((i*3+j*5)%9-4)/16384.0L,single);
  memset(b,0x5a,(size_t)(n?n:1)*(abs(stride))*size);
  for(int i=0;i<n;i++){
    long double sum=0;
    for(int j=0;j<n;j++){
      int r=trans?j:i,c=trans?i:j;
      if((lower&&r>=c)||(!lower&&r<=c))sum+=(i==j&&unit?1:at(a,r+c*lda,single))*((j%7)-3)/8;
    }
    int k=stride>0?i*stride:(n-1-i)*(-stride);set(b,k,sum,single);
  }
}
int main(int argc,char **argv){
 need(argc>=4,"check B C | bench lib precision n repeats");
 cpu_set_t mask,actual;CPU_ZERO(&mask);CPU_SET(0,&mask);need(!sched_setaffinity(0,sizeof(mask),&mask)&&!sched_getaffinity(0,sizeof(actual),&actual)&&CPU_EQUAL(&mask,&actual),"CPU0 binding");
 if(!strcmp(argv[1],"check")){
  void *handles[2]={dlopen(argv[2],RTLD_NOW|RTLD_LOCAL),dlopen(argv[3],RTLD_NOW|RTLD_LOCAL)};need(handles[0]&&handles[1],dlerror()?dlerror():"open libraries");
  int cases=0;long double worst[2]={0,0};int dims[40];for(int i=0;i<34;i++)dims[i]=i;int tail[6]={63,64,65,127,128,129};memcpy(dims+34,tail,sizeof(tail));
  for(int single=0;single<2;single++){
   Solve fn[2]={(Solve)get(handles[0],single?"strsv_":"dtrsv_",argv[2]),(Solve)get(handles[1],single?"strsv_":"dtrsv_",argv[3])};
   for(int di=0;di<40;di++)for(int pad=0;pad<2;pad++)for(int lower=0;lower<2;lower++)for(int unit=0;unit<2;unit++)for(int trans=0;trans<2;trans++)for(int si=0;si<4;si++){
    int n=dims[di],lda=(n?n:1)+pad*3,stride=(int[]){1,2,-1,-2}[si],size=single?4:8;size_t ab=(size_t)(n?n:1)*lda*size,bb=(size_t)(n?n:1)*abs(stride)*size;
    void *am,*bm[2];size_t al,bl[2];void *a=guard(ab,&am,&al),*b[2]={guard(bb,&bm[0],&bl[0]),guard(bb,&bm[1],&bl[1])};fill(n,lda,stride,lower,unit,trans,single,a,b[0]);memcpy(b[1],b[0],bb);void *backup=malloc(ab),*b0=malloc(bb);need(backup&&b0,"backup");memcpy(backup,a,ab);memcpy(b0,b[0],bb);
    char u=lower?'L':'U',t=trans?'T':'N',d=unit?'U':'N';for(int role=0;role<2;role++){
     fn[role](&u,&t,&d,&n,a,&lda,b[role],&stride);need(!memcmp(a,backup,ab),"matrix unchanged");
     for(int i=0;i<n;i++){int k=stride>0?i*stride:(n-1-i)*(-stride);long double err=fabsl(at(b[role],k,single)-((i%7)-3)/8.0L);need(isfinite((double)err)&&err<(single?2e-6L:2e-13L),"reference result");if(err>worst[single])worst[single]=err;}
     for(int i=0;i<(n?n:1)*abs(stride);i++)if(n==0||i%abs(stride))need(!memcmp((char*)b[role]+i*size,(char*)b0+i*size,size),"stride sentinel");
    }
    need(!memcmp(b[0],b[1],bb),"bitwise B/C equality");cases++;free(backup);free(b0);munmap(am,al);munmap(bm[0],bl[0]);munmap(bm[1],bl[1]);
   }
  }
  printf("TRSV_CHECK {\"cases\":%d,\"double_max_error\":%.17g,\"single_max_error\":%.17g,\"bitwise_equal\":true,\"guard\":true,\"matrix_unchanged\":true}\n",cases,(double)worst[0],(double)worst[1]);puts("TRSV_CHECK_EXIT=0");return 0;
 }
 need(!strcmp(argv[1],"bench")&&argc==6,"bench arguments");int single=!strcmp(argv[3],"s"),n=atoi(argv[4]),reps=atoi(argv[5]),size=single?4:8,lda=n+3,stride=1;need(n>0&&n<=1024&&reps>0&&reps<=2000000,"finite workload");
 void *handle=dlopen(argv[2],RTLD_NOW|RTLD_LOCAL);need(handle!=NULL,"library");Solve fn=(Solve)get(handle,single?"strsv_":"dtrsv_",argv[2]);get(handle,single?"strsv_NLU":"dtrsv_NLU",argv[2]);
 void *a=malloc((size_t)n*lda*size),*seed=malloc((size_t)n*size),*vectors=malloc((size_t)n*size*reps);need(a&&seed&&vectors,"alloc");fill(n,lda,stride,1,1,0,single,a,seed);char u='L',t='N',d='U';
 for(int round=-1;round<3;round++){
  for(int r=0;r<reps;r++)memcpy((char*)vectors+(size_t)r*n*size,seed,(size_t)n*size);
  uint64_t w=clock_(CLOCK_MONOTONIC),c=clock_(CLOCK_THREAD_CPUTIME_ID);for(int r=0;r<reps;r++)fn(&u,&t,&d,&n,a,&lda,(char*)vectors+(size_t)r*n*size,&stride);c=clock_(CLOCK_THREAD_CPUTIME_ID)-c;w=clock_(CLOCK_MONOTONIC)-w;
  for(int r=0;r<reps;r++)for(int i=0;i<n;i++)need(fabsl(at((char*)vectors+(size_t)r*n*size,i,single)-((i%7)-3)/8.0L)<(single?2e-6L:2e-13L),"timing result");
  printf("TRSV_ROUND {\"round\":%d,\"single\":%d,\"n\":%d,\"repeats\":%d,\"wall_ns\":%lu,\"thread_cpu_ns\":%lu,\"cpu\":%d,\"library\":\"%s\",\"correct\":true}\n",round,single,n,reps,(unsigned long)w,(unsigned long)c,sched_getcpu(),argv[2]);
 }
 free(a);free(seed);free(vectors);puts("TRSV_BENCH_EXIT=0");return 0;
}
