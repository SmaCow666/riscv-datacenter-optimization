#define _GNU_SOURCE
#include <arpa/inet.h>
#include <errno.h>
#include <fcntl.h>
#include <pthread.h>
#include <sched.h>
#include <signal.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/auxv.h>
#include <sys/mman.h>
#include <sys/socket.h>
#include <sys/stat.h>
#include <sys/syscall.h>
#include <sys/time.h>
#include <sys/types.h>
#include <sys/utsname.h>
#include <sys/wait.h>
#include <time.h>
#include <unistd.h>

extern int rvv_context(uint64_t,volatile sig_atomic_t*,volatile sig_atomic_t*,unsigned);
extern void rvv_clobber(void);
extern uint64_t rvv_after_syscall(uint64_t);
static _Thread_local volatile sig_atomic_t vector_signals;
static _Thread_local volatile sig_atomic_t vector_active;
static volatile sig_atomic_t alarm_seen;
static unsigned checks;
static void require(int ok,const char *what) {
    checks++;
    if(!ok){fprintf(stderr,"OS_PROBE_FAIL check=%u %s errno=%d\n",checks,what,errno);exit(2);}
}
static void transfer(int fd,void *data,size_t size,int writing) {
    char *p=data;
    while(size){ssize_t n=writing?write(fd,p,size):read(fd,p,size);
        if(n<0&&errno==EINTR)continue;
        require(n>0,"complete read/write");p+=n;size-=n;}
}
static void child_ok(pid_t child) {
    int status;require(waitpid(child,&status,0)==child,"waitpid");
    require(WIFEXITED(status)&&WEXITSTATUS(status)==0,"child success");
}
static uint8_t pattern(size_t i){return (uint8_t)((i*37u+(i>>8)*13u)^0x5a);}
static void memory_and_process(void) {
    const size_t size=4*1024*1024;
    uint8_t *p=mmap(NULL,size,PROT_READ|PROT_WRITE,MAP_PRIVATE|MAP_ANONYMOUS,-1,0);
    require(p!=MAP_FAILED,"anonymous mmap");
    for(size_t i=0;i<size;i++)p[i]=pattern(i);
    require(!mprotect(p,size,PROT_READ),"mprotect read only");
    for(size_t i=0;i<size;i++)if(p[i]!=pattern(i))require(0,"memory contents");
    require(!mprotect(p,size,PROT_READ|PROT_WRITE),"mprotect read write");
    pid_t child=fork();require(child>=0,"fork COW");
    if(!child){p[0]^=255;p[size-1]^=255;_exit((p[0]==(uint8_t)(pattern(0)^255))?0:1);}
    child_ok(child);require(p[0]==pattern(0)&&p[size-1]==pattern(size-1),"parent COW isolation");
    require(!munmap(p,size),"munmap");
    int fds[2];require(!pipe(fds),"pipe");child=fork();require(child>=0,"fork pipe");
    if(!child){close(fds[0]);uint8_t b[4096];for(size_t i=0;i<sizeof b;i++)b[i]=pattern(i);
        for(int i=0;i<8;i++)transfer(fds[1],b,sizeof b,1);
        close(fds[1]);_exit(0);}
    close(fds[1]);uint8_t b[4096];for(int i=0;i<8;i++){
        transfer(fds[0],b,sizeof b,0);for(size_t j=0;j<sizeof b;j++)if(b[j]!=pattern(j))require(0,"pipe data");}
    close(fds[0]);child_ok(child);puts("OS_CHECK process_pipe_COW_mmap_mprotect PASS");
}
static void alarm_handler(int sig){(void)sig;alarm_seen=1;}
static void timers(void) {
    struct sigaction action={0};action.sa_handler=alarm_handler;sigemptyset(&action.sa_mask);
    require(!sigaction(SIGALRM,&action,NULL),"sigaction timer");
    struct timespec a,b;require(!clock_gettime(CLOCK_MONOTONIC,&a),"monotonic start");
    struct itimerval timer={.it_value={.tv_sec=0,.tv_usec=20000},.it_interval={.tv_sec=0,.tv_usec=20000}};
    require(!setitimer(ITIMER_REAL,&timer,NULL),"setitimer");
    while(!alarm_seen)pause();
    memset(&timer,0,sizeof timer);require(!setitimer(ITIMER_REAL,&timer,NULL),"stop timer");
    require(!clock_gettime(CLOCK_MONOTONIC,&b),"monotonic end");
    require(b.tv_sec>a.tv_sec||(b.tv_sec==a.tv_sec&&b.tv_nsec>a.tv_nsec),"clock progressed");
    puts("OS_CHECK timer_signal_clock PASS");
}
static void file_io(const char *directory) {
    char file[512],renamed[512];
    require(snprintf(file,sizeof file,"%s/io.tmp",directory)<(int)sizeof file,"file path");
    require(snprintf(renamed,sizeof renamed,"%s/io.checked",directory)<(int)sizeof renamed,"rename path");
    int fd=open(file,O_CREAT|O_TRUNC|O_RDWR,0600);require(fd>=0,"ext4 create");
    uint8_t b[4096],actual[4096];for(size_t i=0;i<sizeof b;i++)b[i]=pattern(i);
    for(unsigned block=0;block<1024;block++)transfer(fd,b,sizeof b,1);
    require(!fsync(fd),"ext4 fsync");require(lseek(fd,0,SEEK_SET)==0,"file seek");
    for(unsigned block=0;block<1024;block++){transfer(fd,actual,sizeof actual,0);require(!memcmp(b,actual,sizeof b),"ext4 block content");}
    uint8_t *shared=mmap(NULL,4096,PROT_READ|PROT_WRITE,MAP_SHARED,fd,0);
    require(shared!=MAP_FAILED,"file mmap");shared[0]=0xa5;shared[4095]=0x3c;
    require(!msync(shared,4096,MS_SYNC),"msync");require(!munmap(shared,4096),"file munmap");
    require(pread(fd,actual,sizeof actual,0)==sizeof actual,"file pread");b[0]=0xa5;b[4095]=0x3c;
    require(!memcmp(b,actual,sizeof b),"mmap file coherence");require(!close(fd),"file close");
    require(!rename(file,renamed),"atomic rename");
    fd=open(directory,O_DIRECTORY|O_RDONLY);require(fd>=0&&!fsync(fd),"directory fsync");close(fd);
    puts("OS_CHECK virtio_ext4_4MiB_read_write_fsync_mmap_rename PASS");
}
static void tcp_loopback(void) {
    int server=socket(AF_INET,SOCK_STREAM,0);require(server>=0,"TCP socket");
    struct sockaddr_in address={.sin_family=AF_INET,.sin_addr.s_addr=htonl(INADDR_LOOPBACK)};
    require(!bind(server,(void*)&address,sizeof address),"TCP bind");socklen_t len=sizeof address;
    require(!getsockname(server,(void*)&address,&len)&&!listen(server,1),"TCP listen");
    pid_t child=fork();require(child>=0,"fork TCP");
    if(!child){close(server);int client=socket(AF_INET,SOCK_STREAM,0);
        require(client>=0&&!connect(client,(void*)&address,sizeof address),"TCP connect");
        uint8_t b[4096];for(size_t i=0;i<sizeof b;i++)b[i]=pattern(i);
        for(unsigned i=0;i<64;i++)transfer(client,b,sizeof b,1);
        uint32_t ack;transfer(client,&ack,sizeof ack,0);close(client);_exit(ack==0x1234abcd?0:1);}
    int peer=accept(server,NULL,NULL);require(peer>=0,"TCP accept");uint8_t b[4096];
    for(unsigned i=0;i<64;i++){transfer(peer,b,sizeof b,0);for(size_t j=0;j<sizeof b;j++)if(b[j]!=pattern(j))require(0,"TCP payload");}
    uint32_t ack=0x1234abcd;transfer(peer,&ack,sizeof ack,1);close(peer);close(server);child_ok(child);
    puts("OS_CHECK TCP_loopback_256KiB PASS");
}
static void vector_handler(int sig){(void)sig;if(vector_active){vector_signals++;rvv_clobber();}}
struct worker {unsigned id;int result,signals;};
static void *vector_worker(void *arg) {
    struct worker *w=arg;long cpus=sysconf(_SC_NPROCESSORS_ONLN);cpu_set_t set;
    CPU_ZERO(&set);CPU_SET(w->id%(unsigned)cpus,&set);
    if(pthread_setaffinity_np(pthread_self(),sizeof set,&set)){w->result=99;return NULL;}
    struct sigevent event={.sigev_notify=SIGEV_THREAD_ID,.sigev_signo=SIGUSR1};
    event._sigev_un._tid=syscall(SYS_gettid);timer_t timer;
    if(timer_create(CLOCK_MONOTONIC,&event,&timer)){w->result=98;return NULL;}
    struct itimerspec schedule={.it_value={.tv_nsec=10000000},.it_interval={.tv_nsec=10000000}};
    if(timer_settime(timer,0,&schedule,NULL)){w->result=97;return NULL;}
    w->result=rvv_context(0x123400u+w->id,&vector_signals,&vector_active,16);
    w->signals=vector_signals;
    if(timer_delete(timer))w->result=96;
    /* Linux deliberately clobbers vector state at syscall entry. Reconfigure
     * on return; preservation is required for asynchronous signals/preemption. */
    for(unsigned i=0;i<128;i++){
        uint64_t seed=0x456700u+w->id+i;
        if(sched_yield()||rvv_after_syscall(seed)!=seed+1)w->result=95;
    }
    return NULL;
}
static void vectors(void) {
    require((getauxval(AT_HWCAP)&(1UL<<('V'-'A')))!=0,"Linux HWCAP V enabled");
    struct sigaction action={0};action.sa_handler=vector_handler;sigemptyset(&action.sa_mask);
    require(!sigaction(SIGUSR1,&action,NULL),"sigaction vector");
    pthread_t threads[2];struct worker workers[2]={{.id=0},{.id=1}};
    for(unsigned i=0;i<2;i++)require(!pthread_create(&threads[i],NULL,vector_worker,&workers[i]),"pthread create");
    for(unsigned i=0;i<2;i++){require(!pthread_join(threads[i],NULL),"pthread join");
        require(workers[i].result==0,"RVV registers/vtype/VL/vstart across asynchronous preemption/signals; syscall reinitialization");
        require(workers[i].signals>=16,"directed async signal count");}
    printf("OS_CHECK RVV_threads=2 syscall_reinit=256 async_signals=%d online_cpus=%ld PASS\n",workers[0].signals+workers[1].signals,sysconf(_SC_NPROCESSORS_ONLN));
}
int main(int argc,char **argv) {
    setvbuf(stdout,NULL,_IOLBF,0);require(argc==2,"usage os-probe DIRECTORY");
    struct utsname u;require(!uname(&u)&&!strcmp(u.machine,"riscv64"),"uname riscv64");
    printf("OS_KERNEL %s %s online_cpus=%ld\n",u.release,u.machine,sysconf(_SC_NPROCESSORS_ONLN));
    memory_and_process();timers();file_io(argv[1]);tcp_loopback();vectors();
    printf("OS_PROBE_PASS checks=%u\n",checks);return 0;
}
