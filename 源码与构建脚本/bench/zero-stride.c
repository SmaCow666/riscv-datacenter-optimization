#define _GNU_SOURCE
#include <dlfcn.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>
static void need(int b,const char*s){if(!b){fprintf(stderr,"ZERO_PROBE_FAIL %s\n",s);exit(1);}}
typedef void(*SF)(int*,float*,float*,int*,float*,int*);typedef void(*DF)(int*,double*,double*,int*,double*,int*);
int main(int argc,char**argv){need(argc==5,"A B U C paths");for(int role=1;role<argc;role++){
 void*h=dlopen(argv[role],RTLD_NOW|RTLD_LOCAL);need(h!=NULL,"load");SF s=dlsym(h,"saxpy_");DF d=dlsym(h,"daxpy_");need(s&&d,"APIs");Dl_info info;need(dladdr((void*)d,&info),"provider");
 for(int which=0;which<3;which++){int n=(int[]){2,9,17}[which],ix=1,iy=0;float sx[32],sy[2],sa=1;double dx[32],dy[2],da=1;for(int i=0;i<32;i++){sx[i]=1;dx[i]=1;}sy[0]=2;sy[1]=99;dy[0]=2;dy[1]=99;s(&n,&sa,sx,&ix,sy,&iy);d(&n,&da,dx,&ix,dy,&iy);need(sy[1]==99&&dy[1]==99,"guards");for(int i=0;i<32;i++)need(sx[i]==1&&dx[i]==1,"input");printf("ZERO_STRIDE {\"role\":%d,\"provider\":\"%s\",\"n\":%d,\"incx\":1,\"incy\":0,\"seed\":2,\"expected\":%d,\"single\":%.17g,\"double\":%.17g,\"single_matches\":%s,\"double_matches\":%s}\n",role,info.dli_fname,n,n+2,(double)sy[0],dy[0],sy[0]==n+2?"true":"false",dy[0]==n+2?"true":"false");}
 dlclose(h);
 }puts("ZERO_PROBE_EXIT=0");return 0;}
