#define _GNU_SOURCE
#include <dlfcn.h>
#include <math.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/mman.h>
#include <unistd.h>
#include <time.h>
#include <sched.h>
static void need(int ok,const char*s){if(!ok){fprintf(stderr,"AXPY_TOOL_FAIL %s\n",s);exit(1);}}
static int unit_only, zero_fix_mode;
typedef int(*D)(long,long,long,double,double*,long,double*,long,double*,long);
typedef int(*S)(long,long,long,float,float*,long,float*,long,float*,long);
static long long ns(clockid_t c){struct timespec t;need(!clock_gettime(c,&t),"clock");return(long long)t.tv_sec*1000000000+t.tv_nsec;}
static void*open_(const char*p){void*h=dlopen(p,RTLD_NOW|RTLD_LOCAL);if(!h)fprintf(stderr,"%s\n",dlerror());need(h!=NULL,"dlopen");return h;}
#define CHECK(T,F,FP,TYPE) \
static void check_##TYPE(void*left,void*right){ \
 F a=(F)dlsym(left,#TYPE "axpy_k"),b=(F)dlsym(right,#TYPE "axpy_k");need(a&&b,"precision symbols"); \
 const int cap=5000,guard=16;T*x=malloc(cap*sizeof(T)),*oldx=malloc(cap*sizeof(T)),*ya=malloc(cap*sizeof(T)),*yb=malloc(cap*sizeof(T)),*ref=malloc(cap*sizeof(T));need(x&&oldx&&ya&&yb&&ref,"check allocation");long cases=0; \
 for(int select=0;select<136;select++){int n=select<=129?select:(int[]){255,256,257,1023,1024,1025}[select-130]; \
 for(int ix=-2;ix<=2;ix++)for(int iy=-2;iy<=2;iy++)for(int al=0;al<5;al++){if(unit_only&&(ix!=1||iy!=1))continue;T alpha=zero_fix_mode?(T[]){0,.1,-.7,INFINITY,NAN}[al]:(T[]){0,.5,-1,INFINITY,NAN}[al];int limit=2*guard+2*(n?n:1); \
 for(int i=0;i<limit;i++){x[i]=zero_fix_mode?(T)((i*17+3)%101-50)/(T)37:(T)((i&1)?-.125:.125);ya[i]=yb[i]=ref[i]=zero_fix_mode?(T)((i%17)-8)/(T)13:(T)(.25+(i%16)/64.);}memcpy(oldx,x,limit*sizeof(T)); \
 int sx=guard+(ix<0?(n-1)*(-ix):0),sy=guard+(iy<0?(n-1)*(-iy):0);if(n==0){sx=sy=guard;} \
 need(!a(n,0,0,alpha,x+sx,ix,ya+sy,iy,NULL,0)&&!b(n,0,0,alpha,x+sx,ix,yb+sy,iy,NULL,0),"kernel return"); \
 if(alpha!=(T)0)for(int i=0;i<n;i++)ref[sy+i*iy]=FP(alpha,x[sx+i*ix],ref[sy+i*iy]); \
 for(int i=0;i<limit;i++){ \
  if(!(zero_fix_mode&&iy==0)&&!((isnan(ya[i])&&isnan(yb[i]))||!memcmp(ya+i,yb+i,sizeof(T)))){fprintf(stderr,"AXPY_DIFFERENCE precision=" #TYPE " n=%d ix=%d iy=%d alpha=%a index=%d left=%a right=%a scalar=%a\n",n,ix,iy,(double)alpha,i,(double)ya[i],(double)yb[i],(double)ref[i]);need(0,"B/C numeric/guard difference");} \
  if(iy!=0||n<2||zero_fix_mode)need((isnan(yb[i])&&isnan(ref[i]))||!memcmp(yb+i,ref+i,sizeof(T)),"scalar fused reference"); \
  int distance=i-sy;int active=n>0&&(iy==0?distance==0:(distance%iy==0&&distance/iy>=0&&distance/iy<n));if(!active)need(!memcmp(yb+i,ref+i,sizeof(T)),"output holes/guards"); \
 }need(!memcmp(x,oldx,limit*sizeof(T)),"input changed");cases++; \
 }} \
 /* Guard pages: unit paths end exactly at the inaccessible page. */ \
 long pages=sysconf(_SC_PAGESIZE); \
 for(int n=1;n<=129;n++){size_t middle=((n*sizeof(T)+pages-1)/pages)*pages,total=middle+2*pages;void*mx=mmap(NULL,total,PROT_NONE,MAP_PRIVATE|MAP_ANONYMOUS,-1,0);void*my=mmap(NULL,total,PROT_NONE,MAP_PRIVATE|MAP_ANONYMOUS,-1,0);need(mx!=MAP_FAILED&&my!=MAP_FAILED,"guard mmap");need(!mprotect((char*)mx+pages,middle,PROT_READ|PROT_WRITE)&&!mprotect((char*)my+pages,middle,PROT_READ|PROT_WRITE),"guard protect");T*gx=(T*)((char*)mx+pages+middle)-n,*gy=(T*)((char*)my+pages+middle)-n;for(int j=0;j<n;j++){gx[j]=(T).125;gy[j]=(T).25;}need(!b(n,0,0,(T).5,gx,1,gy,1,NULL,0),"guard call");for(int j=0;j<n;j++)need(gy[j]==(T).3125&&gx[j]==(T).125,"guard result");need(!munmap(mx,total)&&!munmap(my,total),"guard unmap");} \
 need(!b(8,0,0,(T)0,NULL,1,NULL,1,NULL,0)&&!b(0,0,0,(T)NAN,NULL,1,NULL,1,NULL,0),"no-access zero alpha/length"); \
 printf("AXPY_CHECK {\"precision\":\"" #TYPE "\",\"cases\":%ld,\"guard_pages\":129,\"inputs_unchanged\":true,\"scalar_reference_nonzero_incy\":true,\"zero_incy_reference\":%s}\n",cases,zero_fix_mode?"true":"false");free(x);free(oldx);free(ya);free(yb);free(ref);}
CHECK(double,D,fma,d)
CHECK(float,S,fmaf,s)
struct shape{long n,weight;double*x,*y;};
static void bench(const char*lib,const char*table,long repeats,int group){
 void*h=open_(lib);D f=(D)dlsym(h,"daxpy_k");need(f!=NULL,"bench symbol");Dl_info info;need(dladdr((void*)f,&info),"actual provider");printf("AXPY_PROVIDER {\"path\":\"%s\",\"symbol\":\"%s\"}\n",info.dli_fname,info.dli_sname); \
 FILE*in=fopen(table,"r");need(in!=NULL,"shapes file");struct shape shapes[128];int count=0;long n,w,total_calls=0,flops=0;
 while(fscanf(in,"%ld %ld",&n,&w)==2){need(n>0&&n<=4096&&w>0&&count<128,"shape range");if((group==0&&n>8)||(group==1&&n<=8)||(group==3&&n!=4096)||(group!=3&&n==4096))continue;struct shape*s=&shapes[count++];s->n=n;s->weight=w;s->x=malloc((n+2)*sizeof(double));s->y=malloc((n+2)*sizeof(double));need(s->x&&s->y,"bench allocation");for(int j=0;j<n+2;j++){s->x[j]=.125;s->y[j]=.25;}total_calls+=w;flops+=2*n*w;}fclose(in);need(count>0&&repeats>0,"nonempty bench");
 for(int round=-1;round<3;round++){long long c=ns(CLOCK_THREAD_CPUTIME_ID),t=ns(CLOCK_MONOTONIC);
  for(long r=0;r<repeats;r++)for(int k=0;k<count;k++){struct shape*s=&shapes[k];for(long j=0;j<s->weight;j++){need(!f(s->n,0,0,.5,s->x+1,1,s->y+1,1,NULL,0),"positive bench");need(!f(s->n,0,0,-.5,s->x+1,1,s->y+1,1,NULL,0),"negative bench");}}
  long long wall=ns(CLOCK_MONOTONIC)-t,cpu=ns(CLOCK_THREAD_CPUTIME_ID)-c;
  for(int k=0;k<count;k++)for(int j=0;j<shapes[k].n+2;j++)need(shapes[k].x[j]==.125&&shapes[k].y[j]==.25,"exact pair result/guards");
  printf("AXPY_ROUND {\"group\":%d,\"round\":%d,\"repeats\":%ld,\"calls_per_mix\":%ld,\"useful_flops_per_mix\":%ld,\"wall_ns\":%lld,\"thread_cpu_ns\":%lld,\"correct\":true}\n",group,round,repeats,2*total_calls,2*flops,wall,cpu);fflush(stdout);
 }for(int k=0;k<count;k++){free(shapes[k].x);free(shapes[k].y);}dlclose(h);
}
int main(int argc,char**argv){need(argc>=4,"arguments");cpu_set_t set,actual;CPU_ZERO(&set);CPU_SET(0,&set);need(!sched_setaffinity(0,sizeof(set),&set)&&!sched_getaffinity(0,sizeof(actual),&actual)&&CPU_EQUAL(&set,&actual),"CPU0 binding");
 if(!strcmp(argv[1],"check")||!strcmp(argv[1],"check-unit")||!strcmp(argv[1],"check-fixed")){unit_only=!strcmp(argv[1],"check-unit");zero_fix_mode=!strcmp(argv[1],"check-fixed");need(argc==4,"check arguments");void*a=open_(argv[2]),*b=open_(argv[3]);check_s(a,b);check_d(a,b);dlclose(a);dlclose(b);puts("AXPY_CHECK_EXIT=0");}
 else{need(!strcmp(argv[1],"bench")&&argc==6,"bench arguments");bench(argv[2],argv[3],strtol(argv[4],NULL,10),atoi(argv[5]));puts("AXPY_BENCH_EXIT=0");}return 0;
}
