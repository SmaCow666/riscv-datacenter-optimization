#define _GNU_SOURCE
#include <errno.h>
#include <fcntl.h>
#include <poll.h>
#include <signal.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/resource.h>
#include <sys/stat.h>
#include <sys/wait.h>
#include <time.h>
#include <unistd.h>
#include "expected.h"
static const char *reference_name = "original";
typedef struct { double ready,total,cpu,region_wall,region_cpu,stop_delay;long rss; } Sample;
static double clk(clockid_t id) {struct timespec t;if(clock_gettime(id,&t)) {perror("clock_gettime");exit(2);}return t.tv_sec*1000.+t.tv_nsec/1e6;}
static double now(void){return clk(CLOCK_MONOTONIC);}
static void die(const char *s){perror(s);exit(2);}
static double stop(pid_t p,clockid_t id) {
    int status;if(kill(p,SIGSTOP))die("SIGSTOP");
    if(waitpid(p,&status,WUNTRACED)!=p||!WIFSTOPPED(status))die("wait stopped child");
    return clk(id);
}
static void copy(const char *root,const char *out,const char *name) {
    char a[4096],b[4096];snprintf(a,sizeof a,"%s/%s",root,name);snprintf(b,sizeof b,"%s/%s",out,name);
    FILE *x=fopen(a,"rb"),*y=fopen(b,"wb");if(!x||!y)die("copy provenance");int c;while((c=fgetc(x))!=EOF)fputc(c,y);fclose(x);fclose(y);
}
static int run(const char *root,const char *out,const char *variant,int round,Sample *s) {
    char loader[4096],libs[4096],exe[4096],elf[4096],path[4096],expected[80];
    snprintf(loader,sizeof loader,"%s/qemu/%s/lib/ld-linux-riscv64-lp64d.so.1",root,variant);
    snprintf(libs,sizeof libs,"%s/qemu/%s/lib",root,variant);
    snprintf(exe,sizeof exe,"%s/qemu/%s/bin/qemu-system-riscv64",root,variant);
    if(!strcmp(variant,"baseline") && strcmp(reference_name,"original"))
        snprintf(exe,sizeof exe,"%s/rvv/references/%s/qemu-system-riscv64",root,reference_name);
    snprintf(elf,sizeof elf,"%s/rvv/bench.elf",root);
    snprintf(path,sizeof path,"%s/commands.txt",out);
    FILE *commands=fopen(path,"a");if(!commands)die("commands");
    fprintf(commands,"round=%d variant=%s: %s --library-path %s %s -machine virt -accel tcg,thread=single -cpu rv64,v=true,vlen=128,elen=64 -m 64M -smp 1 -bios none -kernel %s -display none -monitor none -serial stdio -nic none -no-reboot\n",round,variant,loader,libs,exe,elf);
    fclose(commands);
    snprintf(path,sizeof path,"%s/%s-%02d.log",out,variant,round);
    snprintf(expected,sizeof expected,"RVWORK_DONE %08x\n",EXPECTED_CHECKSUM);
    FILE *log=fopen(path,"wb");if(!log)die("serial log");
    int rx[2],tx[2];if(pipe(rx)||pipe(tx))die("pipe");double begin=now();pid_t child=fork();if(child<0)die("fork");
    if(!child) {
        dup2(tx[0],0);dup2(rx[1],1);dup2(rx[1],2);close(tx[0]);close(tx[1]);close(rx[0]);close(rx[1]);
        execl(loader,loader,"--library-path",libs,exe,"-machine","virt","-accel","tcg,thread=single",
            "-cpu","rv64,v=true,vlen=128,elen=64","-m","64M","-smp","1","-bios","none","-kernel",elf,
            "-display","none","-monitor","none","-serial","stdio","-nic","none","-no-reboot",(char *)0);
        perror("exec");_exit(127);
    }
    close(rx[1]);close(tx[0]);fcntl(rx[0],F_SETFL,O_NONBLOCK);
    clockid_t cpuclock;if(clock_getcpuclockid(child,&cpuclock))die("clock_getcpuclockid child");
    char text[65536]={0};size_t used=0;int stage=0,status=0,ended=0,eof=0,failed=0;
    double start_cpu=0,start_wall=0;struct rusage usage={0};memset(s,0,sizeof *s);
    while(!ended||!eof) {
        struct pollfd fd={rx[0],POLLIN|POLLHUP,0};poll(&fd,1,20);
        char block[4096];ssize_t n;
        while((n=read(rx[0],block,sizeof block))>0) {
            fwrite(block,1,n,log);fflush(log);if(used+n>=sizeof text){failed=1;break;}
            memcpy(text+used,block,n);used+=n;text[used]=0;
            if(stage==0&&strstr(text,"RVWORK_READY\n")) {
                s->ready=now()-begin;start_cpu=stop(child,cpuclock);
                if(write(tx[1],"g",1)!=1)die("send go");start_wall=now();
                if(kill(child,SIGCONT))die("resume go");stage=1;
            }
            if(stage==1&&strstr(text,expected)) {
                double observed=now();s->region_wall=observed-start_wall;
                double end_cpu=stop(child,cpuclock);s->region_cpu=end_cpu-start_cpu;
                s->stop_delay=now()-observed;
                if(write(tx[1],"e",1)!=1)die("send exit");if(kill(child,SIGCONT))die("resume exit");stage=2;
            }
        }
        if(n==0)eof=1;
        if(!ended&&wait4(child,&status,WNOHANG,&usage)==child)ended=1;
        if(strstr(text,"RVWORK_FAIL")||now()-begin>120000||failed){failed=1;break;}
    }
    if(!ended){kill(child,SIGKILL);kill(child,SIGCONT);wait4(child,&status,0,&usage);}
    s->total=now()-begin;s->cpu=(usage.ru_utime.tv_sec+usage.ru_stime.tv_sec)*1000.+(usage.ru_utime.tv_usec+usage.ru_stime.tv_usec)/1000.;s->rss=usage.ru_maxrss;
    close(rx[0]);close(tx[1]);fclose(log);
    if(failed||stage!=2)fprintf(stderr,"phase failure stage=%d output=%s\n",stage,text);
    return failed||stage!=2||!WIFEXITED(status)||WEXITSTATUS(status)||s->region_cpu<=0;
}
static int cmp(const void *a,const void *b){double x=*(double *)a,y=*(double *)b;return(x>y)-(x<y);}
static double median(double *a,int n){qsort(a,n,sizeof *a,cmp);return n&1?a[n/2]:(a[n/2-1]+a[n/2])/2;}
int main(int argc,char **argv) {
    if(argc!=5)return 2;
    int compare=!strcmp(argv[3],"compare");
    int selected=!strcmp(argv[3],"candidate");
    if(!compare && strcmp(argv[3],"baseline") && !selected)return 2;
    if(getenv("RVWORK_RVV_REFERENCE"))reference_name=getenv("RVWORK_RVV_REFERENCE");
    if(strcmp(reference_name,"p5") && strcmp(reference_name,"p6") && strcmp(reference_name,"p7") && strcmp(reference_name,"p8") && strcmp(reference_name,"original"))return 2;
    for(const char *p=argv[2];*p;p++)if(!((*p>='a'&&*p<='z')||(*p>='A'&&*p<='Z')||(*p>='0'&&*p<='9')||*p=='-'||*p=='_'))return 2;
    char *end;int runs=strtol(argv[4],&end,10);if(*end||runs<1||runs>100)return 2;
    char root[4096],out[4096],path[4096];if(!realpath(argv[1],root))die("root");
    snprintf(out,sizeof out,"%s/results/%s",root,argv[2]);if(mkdir(out,0755))die("result exists");
    copy(root,out,"build-info.json");copy(root,out,"SHA256SUMS");copy(root,out,"BUILD_TAG");
    char source[4096],target[4096];
    snprintf(source,sizeof source,"%s/rvv/build-info.json",root);
    snprintf(target,sizeof target,"%s/rvv-build-info.json",out);
    FILE *src=fopen(source,"rb"),*dst=fopen(target,"wb");if(!src||!dst)die("RVV provenance");
    int ch;while((ch=fgetc(src))!=EOF)fputc(ch,dst);fclose(src);fclose(dst);
    snprintf(target,sizeof target,"%s/reference.json",out);dst=fopen(target,"w");if(!dst)die("reference");
    fprintf(dst,"{\"workload\":\"rvv-vector-add-v1\",\"baseline_reference\":\"%s\",\"candidate\":\"current QEMU\",\"cpu\":\"rv64,v=true,vlen=128,elen=64\",\"hashes\":\"rvv-build-info.json\",\"guest\":\"rvv/bench.elf\"}\n",reference_name);fclose(dst);
    snprintf(path,sizeof path,"%s/metrics.csv",out);FILE *csv=fopen(path,"w");if(!csv)die("metrics");
    fputs("round,variant,warmup,ready_ms,total_ms,cpu_ms,maxrss_kib,checksum,region_wall_ms,region_cpu_ms,stop_delay_ms\n",csv);
    Sample samples[2][100];
    for(int round=0;round<=runs;round++)for(int turn=0;turn<(compare?2:1);turn++) {
        int v=compare?((round+turn)&1):selected;const char *name=v?"candidate":"baseline";Sample s;
        if(run(root,out,name,round,&s)){fprintf(stderr,"FAIL: %s round %d\n",name,round);return 1;}
        fprintf(csv,"%d,%s,%d,%.6f,%.6f,%.6f,%ld,%08x,%.6f,%.6f,%.6f\n",round,name,round==0,s.ready,s.total,s.cpu,s.rss,EXPECTED_CHECKSUM,s.region_wall,s.region_cpu,s.stop_delay);fflush(csv);
        printf("%s %d: region CPU %.3f ms, wall %.3f ms, stop delay %.3f ms\n",name,round,s.region_cpu,s.region_wall,s.stop_delay);fflush(stdout);
        if(round)samples[v][round-1]=s;
    }
    fclose(csv);snprintf(path,sizeof path,"%s/summary.json",out);FILE *f=fopen(path,"w");if(!f)die("summary");
    fprintf(f,"{\"method\":\"stopped-process-cpu-clock-v1\",\"workload\":\"rvv-vector-add-v1\",\"reference\":\"%s\",\"variants\":{",reference_name);
    int printed=0;
    for(int v=0;v<2;v++) {
        if(!compare && v!=selected)continue;
        double c[100],w[100],ready[100],total[100],sum=0,whole=0;long rss=0;
        for(int n=0;n<runs;n++){
            c[n]=samples[v][n].region_cpu;w[n]=samples[v][n].region_wall;sum+=c[n];
            ready[n]=samples[v][n].ready;total[n]=samples[v][n].total;whole+=samples[v][n].cpu;
            if(samples[v][n].rss>rss)rss=samples[v][n].rss;
        }
        fprintf(f,"%s\"%s\":{\"runs\":%d,\"median_region_cpu_ms\":%.6f,\"median_region_wall_ms\":%.6f,\"region_tasks_per_cpu_s\":%.6f,\"median_ready_ms\":%.6f,\"median_total_ms\":%.6f,\"cpu_ms_sum\":%.6f,\"tasks_per_cpu_s\":%.6f,\"peak_rss_kib\":%ld}",printed++?",":"",v?"candidate":"baseline",runs,median(c,runs),median(w,runs),runs*1000./sum,median(ready,runs),median(total,runs),whole,runs*1000./whole,rss);
    }
    fputs("}}\n",f);fclose(f);snprintf(path,sizeof path,"%s/COMPLETE",out);f=fopen(path,"w");fputs("Phase checksum/exit passed\n",f);fclose(f);puts("RVWORK_BENCH_PASS");return 0;
}
