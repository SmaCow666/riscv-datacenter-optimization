#define _GNU_SOURCE
#include <dlfcn.h>
#include <math.h>
#include <sched.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
typedef int(*Kernel)(long,long,long,double,double*,long,double*,long,double*,long,double*);
struct item{int id,m,n,lda,ix,iy,weight,group;double *ar,*xr,*yr,*a,*x,*y,*ref;uint64_t ah,xh;};
static struct item items[1024];static int count;
static void need(int ok,const char*s){if(!ok){fprintf(stderr,"MIX_FAILED %s\n",s);exit(1);}}
static long long ns(clockid_t c){struct timespec t;need(!clock_gettime(c,&t),"clock");return(long long)t.tv_sec*1000000000+t.tv_nsec;}
static uint64_t hash(const void*p,size_t n){uint64_t h=14695981039346656037ULL;const unsigned char*b=p;for(size_t i=0;i<n;i++){h^=b[i];h*=1099511628211ULL;}return h;}
static double* alloc(size_t n){void*p;need(!posix_memalign(&p,64,n*sizeof(double)),"allocate");return p;}
static int selected(struct item*c,int group){return group==3||c->group==group;}
int main(int argc,char**argv){
 need(argc==4,"library shapes.tsv groups.tsv");cpu_set_t wanted,actual;CPU_ZERO(&wanted);CPU_SET(0,&wanted);need(!sched_setaffinity(0,sizeof(wanted),&wanted)&&!sched_getaffinity(0,sizeof(actual),&actual)&&CPU_EQUAL(&actual,&wanted),"CPU0");
 unsigned long vlenb;__asm__ volatile("csrr %0, 0xc22":"=r"(vlenb));need(vlenb==32,"VLEN256");void*h=dlopen(argv[1],RTLD_NOW|RTLD_LOCAL);need(h!=NULL,"dlopen");Kernel kernel=(Kernel)dlsym(h,"dgemv_n");Dl_info d={0};need(kernel&&dladdr((void*)kernel,&d),"provider");
 int(*threads)(void)=(int(*)(void))dlsym(h,"openblas_get_num_threads");const char*(*config)(void)=(const char*(*)(void))dlsym(h,"openblas_get_config");need(threads&&threads()==1&&config&&strstr(config(),"USE_LOCKING"),"serial locking");printf("MIX_ID {\"provider\":\"%s\",\"cpu\":%d,\"vlenb\":%lu}\n",d.dli_fname,sched_getcpu(),vlenb);
 FILE*f=fopen(argv[2],"r");need(f!=NULL,"shapes");struct item c={0};const double guard=0x1.2345p30;
 while(fscanf(f,"%d %d %d %d %d %d %d",&c.id,&c.m,&c.n,&c.lda,&c.ix,&c.iy,&c.weight)==7){
  need(count<1024&&c.m>0&&c.n>0&&c.lda>=c.m&&c.ix==1&&c.iy==1&&c.weight>0,"shape bounds");
  c.group=c.n<4?2:c.m<32?0:1;size_t an=(size_t)c.lda*c.n; c.ar=alloc(an+16);c.xr=alloc(c.n+16);c.yr=alloc(c.m+16);c.ref=alloc(c.m);
  for(size_t i=0;i<an+16;i++)c.ar[i]=guard;for(int i=0;i<c.n+16;i++)c.xr[i]=guard;for(int i=0;i<c.m+16;i++)c.yr[i]=guard;c.a=c.ar+8;c.x=c.xr+8;c.y=c.yr+8;
  for(int j=0;j<c.n;j++){c.x[j]=(double)((j*11+3)%31-15)/64.;for(int i=0;i<c.lda;i++)c.a[i+(size_t)j*c.lda]=(double)((i*13+j*7)%29-14)/64.;}
  for(int i=0;i<c.m;i++){c.ref[i]=0;for(int j=0;j<c.n;j++)c.ref[i]-=c.a[i+(size_t)j*c.lda]*c.x[j];}
  c.ah=hash(c.ar,(an+16)*sizeof(double));c.xh=hash(c.xr,(c.n+16)*sizeof(double));items[count++]=c;
 }
 need(feof(f)&&count>0,"shape completeness");fclose(f);f=fopen(argv[3],"r");need(f!=NULL,"groups");int group,reps,rounds;
 while(fscanf(f,"%d %d %d",&group,&reps,&rounds)==3){need(group>=0&&group<=3&&reps>=1&&reps<=4096&&rounds>=1&&rounds<=3,"group bounds");unsigned long calls=0,flops=0;
  for(int i=0;i<count;i++)if(selected(&items[i],group)){calls+=items[i].weight;flops+=2UL*items[i].m*items[i].n*items[i].weight;}need(calls>0,"group coverage");
  for(int round=-1;round<rounds;round++){
   for(int i=0;i<count;i++)memset(items[i].y,0,items[i].m*sizeof(double));
   long long cpu0=ns(CLOCK_THREAD_CPUTIME_ID),wall0=ns(CLOCK_MONOTONIC);
   for(int rep=0;rep<reps;rep++)for(int i=0;i<count;i++){struct item*c=&items[i];if(selected(c,group))for(int k=0;k<c->weight;k++)need(!kernel(c->m,c->n,0,-1.,c->a,c->lda,c->x,c->ix,c->y,c->iy,NULL),"kernel");}
   long long wall=ns(CLOCK_MONOTONIC)-wall0,cpu=ns(CLOCK_THREAD_CPUTIME_ID)-cpu0;
   for(int i=0;i<count;i++){struct item*c=&items[i];for(int j=0;j<c->m;j++)need(isfinite(c->y[j])&&c->y[j]==(selected(c,group)?c->ref[j]*reps*c->weight:0.),"exact result");for(int j=0;j<8;j++)need(c->yr[j]==guard&&c->yr[8+c->m+j]==guard,"y guards");need(hash(c->ar,((size_t)c->lda*c->n+16)*sizeof(double))==c->ah&&hash(c->xr,(c->n+16)*sizeof(double))==c->xh,"A/x unchanged");}
   need(sched_getcpu()==0,"CPU drift");printf("MIX_ROUND {\"group\":%d,\"repeats\":%d,\"round\":%d,\"calls_per_iteration\":%lu,\"flops_per_iteration\":%lu,\"wall_ns\":%lld,\"thread_cpu_ns\":%lld,\"correct\":true,\"guards\":true}\n",group,reps,round,calls,flops,wall,cpu);fflush(stdout);
  }
 }
 need(feof(f),"groups completeness");fclose(f);for(int i=0;i<count;i++){free(items[i].ar);free(items[i].xr);free(items[i].yr);free(items[i].ref);}dlclose(h);puts("MIX_EXIT=0");return 0;
}
