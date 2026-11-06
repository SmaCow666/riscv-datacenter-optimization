#!/usr/bin/env python3
"""Portable, offline component/application build entrypoint for the source package."""
import argparse
import json
import os
from pathlib import Path
import platform
import re
import shlex
import shutil
import subprocess
import sys

ROOT=Path(__file__).resolve().parents[1]


def load(p):return json.loads(Path(p).read_text())
def save(p,j):p.parent.mkdir(parents=True,exist_ok=True);p.write_text(json.dumps(j,ensure_ascii=False,indent=2)+'\n')
def require(ok,s):
    if not ok:raise RuntimeError(s)


class Builder:
    def __init__(self,args):
        self.args=args;self.out=args.out.resolve();self.out.mkdir(parents=True,exist_ok=True)
        self.install=self.out/'install';self.install.mkdir(exist_ok=True);(self.out/'logs').mkdir(exist_ok=True)
        self.cross=args.target=='riscv-cross';self.x86=args.target=='x86'
        if args.target=='native':require(platform.machine()=='riscv64','native目标需要RISC-V Linux；x86参考请显式使用--target x86')
        self.cc=os.environ.get('CC','clang');self.cxx=os.environ.get('CXX','clang++');self.fc=os.environ.get('FC','riscv64-linux-gnu-gfortran'if self.cross else'gfortran')
        self.cmake=os.environ.get('CMAKE','cmake');self.ar=os.environ.get('AR','riscv64-linux-gnu-ar'if self.cross else'ar')
        self.ranlib=os.environ.get('RANLIB','riscv64-linux-gnu-ranlib'if self.cross else'ranlib')
        self.env={k:v for k,v in os.environ.items()if not k.startswith(('LD_','OMP_','KMP_','GOMP_','OPENBLAS_','MKL_'))}
        self.env.update(LC_ALL='C',PYTHONDONTWRITEBYTECODE='1',PYTHONHASHSEED='0')
        self.flags=[]if self.x86 else['-march=rv64gc','-mabi=lp64d']
        if self.cross:self.flags=['--target=riscv64-linux-gnu','--gcc-toolchain=/usr','--sysroot=/','-isystem','/usr/riscv64-linux-gnu/include',*self.flags]
        (self.out/'toolchain').mkdir(exist_ok=True)
        self.ccwrap=self.wrapper('cc',self.cc,self.flags);self.cxxwrap=self.wrapper('cxx',self.cxx,self.flags)
        self.commands=[]
        self.toolchain=self.out/'toolchain/native.cmake'
        lines=[f'set(CMAKE_C_COMPILER "{self.ccwrap}")',f'set(CMAKE_CXX_COMPILER "{self.cxxwrap}")',
               f'set(CMAKE_Fortran_COMPILER "{self.fc}")','set(CMAKE_POSITION_INDEPENDENT_CODE ON)']
        if self.cross:lines+=['set(CMAKE_SYSTEM_NAME Linux)','set(CMAKE_SYSTEM_PROCESSOR riscv64)','set(CMAKE_TRY_COMPILE_TARGET_TYPE STATIC_LIBRARY)']
        if not self.x86:lines+=['set(CMAKE_Fortran_FLAGS_INIT "-march=rv64gc -mabi=lp64d -fPIC")']
        self.toolchain.write_text('\n'.join(lines)+'\n')
    def wrapper(self,name,compiler,flags):
        argv=shlex.split(compiler);require(shutil.which(argv[0])is not None,'缺少编译器 '+argv[0])
        path=self.out/'toolchain'/name;path.write_text('#!/bin/sh\nexec '+shlex.join([*argv,*flags])+' "$@"\n');path.chmod(0o755);return path
    def run(self,name,argv,cwd=None):
        argv=list(map(str,argv));print('BUILD '+name,flush=True)
        log=self.out/'logs'/(name+'.log')
        with log.open('w')as stream:
            stream.write('$ '+shlex.join(argv)+'\n');stream.flush()
            r=subprocess.run(argv,cwd=cwd,env=self.env,stdout=stream,stderr=subprocess.STDOUT)
        self.commands.append(dict(step=name,argv=argv,cwd=str(cwd)if cwd else None,exit_code=r.returncode))
        save(self.out/'commands.json',self.commands)
        if r.returncode:raise RuntimeError(name+'失败；完整日志：'+str(log))
        return log
    def source(self,name,vendor,patches=()):
        dst=self.out/'sources'/name
        require(not dst.exists(),'构建目录已存在，请复用已完成组件或换--out：'+str(dst))
        shutil.copytree(ROOT/vendor,dst,symlinks=True)
        for i,p in enumerate(patches):self.run(name+'-patch-'+str(i),['patch','--batch','--fuzz=0','-p1','-i',ROOT/p],dst)
        return dst
    def omp(self,name):
        mapping=load(ROOT/'components/openmp/profiles.json');community=load(ROOT/'components/openmp/community.json');mapping.update(community)
        require(name in mapping,'未知OpenMP配置 '+name);p=mapping[name];dest=self.install/'omp'/name
        if (dest/'lib/libomp.so').exists():return dest
        src=self.source('omp-'+name,p['source'],p['patches']);build=self.out/'objects'/('omp-'+name)
        self.run('omp-'+name+'-configure',[self.cmake,'-G','Ninja','-S',src/'runtimes','-B',build,'-DLLVM_ENABLE_RUNTIMES=openmp',
            '-DCMAKE_TOOLCHAIN_FILE='+str(self.toolchain),'-DCMAKE_BUILD_TYPE=Release','-DCMAKE_INSTALL_PREFIX='+str(dest),
            '-DOPENMP_ENABLE_LIBOMPTARGET=OFF','-DOPENMP_ENABLE_OMPT_TOOLS=OFF','-DLIBOMP_FORTRAN_MODULES=OFF',
            '-DLIBOMP_OMPD_SUPPORT=OFF','-DLIBOMP_ENABLE_ASSERTIONS=OFF','-DLIBOMP_COPY_EXPORTS=FALSE'])
        self.run('omp-'+name+'-build',[self.cmake,'--build',build,'-j',self.args.jobs]);self.run('omp-'+name+'-install',[self.cmake,'--install',build]);return dest
    def blas(self,name):
        dest=self.install/('support'if name=='support'else'blas/'+name)
        if (dest/'lib/libopenblas.so.0').exists():return dest
        mapping=load(ROOT/'components/openblas/profiles.json')
        if name in ['baseline','support']:
            src=self.source('blas-'+name,'vendor/openblas');target='HASWELL'if self.x86 else'RISCV64_ZVL256B'
            opts=['TARGET='+target,'HOSTCC=gcc','BINARY=64','NOFORTRAN=1','BUILD_SINGLE=1','BUILD_DOUBLE=1',
                'BUILD_COMPLEX='+('1'if name=='support'else'0'),'BUILD_COMPLEX16='+('1'if name=='support'else'0'),
                'USE_THREAD=0','NUM_THREADS=1','USE_OPENMP=0','DYNAMIC_ARCH=0','BUILD_BFLOAT16=0','BUILD_HFLOAT16=0',
                'CFLAGS=-O2 -gdwarf-4'+(''if self.x86 else' -DUSE_LOCKING=1'),'CC='+str(self.ccwrap),'AR='+self.ar,'RANLIB='+self.ranlib]
            opts+=['C_LAPACK=1','NO_LAPACKE=1']if name=='support'else['NO_LAPACK=1']
            if self.cross:opts+=['CROSS=1','CROSS_SUFFIX=riscv64-linux-gnu-']
            log=self.run('blas-'+name+'-make',['make','-j'+str(self.args.jobs),'all',*opts],src)
            archives=[p for p in src.glob('libopenblas*.a')if not p.is_symlink()];require(len(archives)==1,'需要唯一OpenBLAS静态库')
            dest.mkdir(parents=True,exist_ok=True);(dest/'lib').mkdir(exist_ok=True);shutil.copy2(archives[0],dest/'lib/libopenblas.a')
            for header in ['cblas.h','f77blas.h','openblas_config.h','config.h']:
                if (src/header).exists():(dest/'include').mkdir(exist_ok=True);shutil.copy2(src/header,dest/'include'/header)
            commands={}
            wanted={'sgemv_n','dgemv_n','saxpy_k','daxpy_k',*[p+'trsv_N'+u+d for p in 'sd'for u in 'UL'for d in 'UN']}
            for line in log.read_text(errors='replace').splitlines():
                if not line.startswith(str(self.ccwrap)+' '):continue
                argv=shlex.split(line)
                if '-c'not in argv or'-o'not in argv:continue
                obj=Path(argv[argv.index('-o')+1]).stem
                if obj not in wanted:continue
                file=next((x for x in argv if x.endswith('.c')),None);require(file is not None,'对象源文件')
                cwd=src/('driver/level2'if'trsv'in obj else'kernel')
                require((cwd/file).is_file(),'编译工作目录 '+file)
                commands[obj]=dict(arguments=argv,cwd=str(cwd.relative_to(src)))
            save(dest/'compile-objects.json',commands)
        else:
            require(not self.x86,'RVV专用优化不适用于x86；该平台只构建官方参考')
            require(name in mapping,'未知数学库配置 '+name);base=self.blas('baseline');base_src=self.out/'sources/blas-baseline';p=mapping[name]
            src=self.out/'sources'/('blas-'+name);require(not src.exists(),'请换新构建目录');src.mkdir(parents=True)
            for h in base_src.glob('*.h'):shutil.copy2(h,src/h.name)
            for patch in p['patches']:
                for rel in re.findall(r'^\+\+\+ b/(.+)$',(ROOT/patch).read_text(),re.M):
                    if (ROOT/'vendor/openblas'/rel).exists()and not(src/rel).exists():
                        (src/rel).parent.mkdir(parents=True,exist_ok=True);shutil.copy2(ROOT/'vendor/openblas'/rel,src/rel)
                self.run('blas-'+name+'-'+Path(patch).stem,['patch','--batch','--fuzz=0','-p1','-i',ROOT/patch],src)
            dest.mkdir(parents=True);(dest/'lib').mkdir();shutil.copytree(base/'include',dest/'include')
            archive=dest/'lib/libopenblas.a';shutil.copy2(base/'lib/libopenblas.a',archive);objects=[]
            commands=load(base/'compile-objects.json')
            for obj in p['objects']:
                command=commands[obj];argv=command['arguments'];argv=list(argv);output=src/(obj+'.o');argv[argv.index('-o')+1]=str(output)
                cwd=src/command['cwd'];cwd.mkdir(parents=True,exist_ok=True)
                self.run('blas-'+name+'-'+obj,argv,cwd);objects.append(output)
            self.run('blas-'+name+'-archive',[self.ar,'r',archive,*objects]);self.run('blas-'+name+'-ranlib',[self.ranlib,archive])
        soname='libopenblas_support.so.0'if name=='support'else'libopenblas.so.0'
        self.run('blas-'+name+'-link',[self.ccwrap,'-shared','-Wl,--whole-archive',dest/'lib/libopenblas.a','-Wl,--no-whole-archive',
            '-Wl,-soname,'+soname,'-lm','-pthread','-o',dest/'lib'/soname])
        if name=='support':(dest/'lib/libopenblas.so.0').symlink_to(soname)
        return dest
    def dependencies(self):
        prefix=self.install/'backend';omp=self.omp('general');support=self.blas('support')
        common=['-G','Ninja','-DCMAKE_TOOLCHAIN_FILE='+str(self.toolchain),'-DCMAKE_INSTALL_PREFIX='+str(prefix),'-DCMAKE_BUILD_TYPE=Release','-DCMAKE_POSITION_INDEPENDENT_CODE=ON']
        for name in ['gklib','metis']:
            if (prefix/'lib'/('libGKlib.a'if name=='gklib'else'libmetis.a')).exists():continue
            src=self.source(name,'vendor/'+name);build=self.out/'objects'/name
            opts=['-DOPENMP=OFF','-DNO_X86=ON']if name=='gklib'else['-DOPENMP=OFF','-DGKLIB_PATH='+str(prefix),'-DSHARED=OFF']
            if name=='metis':
                generated=src/'build/xinclude';generated.mkdir(parents=True);(generated/'metis.h').write_text('#define IDXTYPEWIDTH 32\n#define REALTYPEWIDTH 32\n'+(src/'include/metis.h').read_text());shutil.copy2(src/'include/CMakeLists.txt',generated/'CMakeLists.txt')
            self.run(name+'-configure',[self.cmake,'-S',src,'-B',build,*common,*opts]);self.run(name+'-build',[self.cmake,'--build',build,'-j',self.args.jobs]);self.run(name+'-install',[self.cmake,'--install',build])
        library=prefix/'lib/libstrumpack.so.8.0'
        if not library.exists():
            require(shutil.which(shlex.split(self.fc)[0]),'完整业务需要系统Fortran编译器；设置FC')
            src=self.source('strumpack','vendor/strumpack');build=self.out/'objects/strumpack'
            disabled=['MPI','CUDA','HIP','SYCL'];tpl=['SLATE','PARMETIS','SCOTCH','PTSCOTCH','BPACK','ZFP','SZ3','PAPI','COMBBLAS','MAGMA','KBLAS','MATLAB']
            opts=['-DSTRUMPACK_USE_'+k+'=OFF'for k in disabled]+['-DTPL_ENABLE_'+k+'=OFF'for k in tpl]
            opts+=['-DBUILD_SHARED_LIBS=ON','-DCMAKE_CXX_FLAGS_RELEASE=-O2 -DNDEBUG','-DCMAKE_CXX_FLAGS=-I'+str(omp/'include'),
                '-DSTRUMPACK_USE_OPENMP=ON','-DSTRUMPACK_USE_BLAS64=OFF','-DOpenMP_C_FLAGS=-fopenmp=libomp','-DOpenMP_CXX_FLAGS=-fopenmp=libomp',
                '-DOpenMP_C_LIB_NAMES=omp','-DOpenMP_CXX_LIB_NAMES=omp','-DOpenMP_omp_LIBRARY='+str(omp/'lib/libomp.so'),
                '-DTPL_BLAS_LIBRARIES='+str(support/'lib/libopenblas_support.so.0'),'-DTPL_LAPACK_LIBRARIES='+str(support/'lib/libopenblas_support.so.0'),
                '-DTPL_METIS_INCLUDE_DIRS='+str(prefix/'include'),'-DTPL_METIS_LIBRARIES='+str(prefix/'lib/libmetis.a')+';'+str(prefix/'lib/libGKlib.a')+';m']
            self.run('strumpack-configure',[self.cmake,'-S',src,'-B',build,*common,*opts]);self.run('strumpack-build',[self.cmake,'--build',build,'--target','strumpack','-j',self.args.jobs]);self.run('strumpack-install',[self.cmake,'--install',build])
        return prefix
    def application(self):
        require(not self.x86,'最终负载程序含RVV能力检查；x86参考执行组件Benchtest')
        prefix=self.dependencies();support=self.blas('support');src=self.out/'sources/petsc';arch='arch-submission'
        if not(src/arch/'lib/libpetsc.so').exists():
            src=self.source('petsc','vendor/petsc');(src/'.nagged').touch()
            self.run('petsc-configure',[sys.executable,'./configure','PETSC_ARCH='+arch,'--with-cc='+str(self.ccwrap),'--with-cxx=0','--with-fc=0',
                '--with-fortran-bindings=0','--with-mpi=0','--with-openmp=0','--with-debugging=0','--with-shared-libraries=1','--with-batch=1',
                '--with-scalar-type=real','--with-precision=double','--with-64-bit-indices=0','--with-blaslapack-lib='+str(support/'lib/libopenblas_support.so.0'),
                '--known-64-bit-blas-indices=0','--known-sdot-returns-double=0','--known-snrm2-returns-double=0','--with-x=0',
                '--with-make-np='+str(self.args.jobs),'COPTFLAGS=-O2 -gdwarf-4','--with-strumpack=0'],src)
            self.run('petsc-build',['make','PETSC_DIR='+str(src),'PETSC_ARCH='+arch,'-j'+str(self.args.jobs),'all'],src)
        dest=self.install/'application';(dest/'lib').mkdir(parents=True,exist_ok=True);(dest/'bin').mkdir(exist_ok=True)
        real=(src/arch/'lib/libpetsc.so').resolve();shutil.copy2(real,dest/'lib'/real.name)
        for name in ['libpetsc.so','libpetsc.so.3.26']:
            p=dest/'lib'/name
            if not p.exists():p.symlink_to(real.name)
        omp=self.omp('general')
        self.run('pcshell-application',[self.ccwrap,'-O2','-gdwarf-4','-std=c11','-fopenmp=libomp',
            '-I'+str(src/'include'),'-I'+str(src/arch/'include'),'-I'+str(prefix/'include'),'-I'+str(omp/'include'),
            ROOT/'application/pcshell/heat_petsc.c',ROOT/'application/pcshell/pcshell_mt.c',
            '-L'+str(dest/'lib'),'-lpetsc','-L'+str(prefix/'lib'),'-lstrumpack','-L'+str(support/'lib'),'-l:libopenblas_support.so.0',
            '-L'+str(omp/'lib'),'-lomp','-Wl,-rpath-link,'+str(prefix/'lib'),'-Wl,-rpath-link,'+str(support/'lib'),'-lm','-ldl','-o',dest/'bin/petsc-heat'])
        self.run('application-phase-observer',[self.ccwrap,'-O2','-shared','-fPIC','-DHOTSPOT_SHAPES=0','-DHOTSPOT_TIMERS=0',
            '-I'+str(src/'include'),'-I'+str(src/arch/'include'),'-I'+str(prefix/'include'),'-I'+str(omp/'include'),
            ROOT/'application/pcshell/phase-observer.c','-ldl','-o',dest/'lib/phase-observer.so'])
    def bench(self):
        general=self.omp('general');self.omp('baseline');self.omp('batch');self.blas('baseline')
        dest=self.install/'bench/bin';dest.mkdir(parents=True,exist_ok=True)
        for name in ['blas-perf','trsv-check','task-contracts','fp-control','zero-stride']:
            src=ROOT/'bench'/(name+'.c');opts=[]
            if name in ['task-contracts','fp-control']:opts=['-fopenmp=libomp','-I'+str(general/'include'),'-L'+str(general/'lib'),'-lomp']
            if name=='fp-control':opts+=['-frounding-math','-fno-builtin-nearbyint']
            self.run('bench-'+name,[self.ccwrap,'-O2',src,*opts,'-ldl','-lm','-o',dest/name])
        for name in ['fib','sort']:
            tree=ROOT/'bench/bots'/name;build=self.out/'objects'/('bench-'+name);build.mkdir(parents=True,exist_ok=True)
            includes=['-I'+str(general/'include'),'-I'+str(tree/'common'),'-I'+str(tree/'omp-tasks'/name)]
            flags=['-DMANUAL_CUTOFF']if name=='fib'else[]
            flags+=['-DBOTS_MODEL="OpenMP Tasks"','-DCDATE="source-package"','-DCC="Clang"','-DLD="Clang"','-DCMESSAGE="submission"','-DCFLAGS="O3"','-DLDFLAGS="libomp"']
            objs=[]
            for rel in ['common/bots_common.c','common/bots_main.c','omp-tasks/'+name+'/'+name+'.c']:
                obj=build/(Path(rel).stem+'.o');self.run('bench-'+name+'-'+obj.stem,[self.ccwrap,'-O3','-fopenmp=libomp',*includes,*flags,'-c',tree/rel,'-o',obj]);objs.append(obj)
            obj=build/'driver.o';extra=['-DTASK_COST_NO_PREDICATE']if name=='sort'else[]
            self.run('bench-'+name+'-driver',[self.ccwrap,'-O2','-fopenmp=libomp',*includes,*extra,'-c',ROOT/'bench'/(name+'-driver.c'),'-o',obj]);objs.append(obj)
            self.run('bench-'+name+'-link',[self.ccwrap,*objs,'-Wl,--wrap='+('fib0'if name=='fib'else'sort_par'),'-L'+str(general/'lib'),'-lomp','-lm','-ldl','-pthread','-o',dest/name])


def run_qemu(args):
    require(args.target!='x86','QEMU component builds a RISC-V-hosted QEMU and cannot use --target x86')
    profile_file=ROOT/'components/qemu/profiles.json'
    profiles=load(profile_file)['profiles']
    require(args.qemu_profile in profiles,'unknown QEMU profile '+args.qemu_profile)
    env=os.environ.copy();env['QEMU_PROFILE']=args.qemu_profile;env['BUILD_ROOT']=str(args.out.resolve()/'qemu');env['JOBS']=str(args.jobs)
    if args.target=='riscv-cross':env.setdefault('CROSS_PREFIX','riscv64-linux-gnu-')
    command=['bash',str(ROOT/'qemu/scripts/build.sh')]
    print('BUILD qemu-'+args.qemu_profile,flush=True)
    result=subprocess.run(command,cwd=ROOT,env=env)
    if result.returncode:raise RuntimeError('QEMU build failed with exit code '+str(result.returncode))
    save(args.out.resolve()/'qemu-build-result.json',dict(status='BUILD_PASS',component='qemu',profile=args.qemu_profile,
        target=args.target,outputs=[str(args.out.resolve()/'qemu/baseline/qemu-system-riscv64'),
        str(args.out.resolve()/'qemu/optimized/qemu-system-riscv64')],patches=profiles[args.qemu_profile]['patches'],execution=False))


def main():
    p=argparse.ArgumentParser(description=__doc__);p.add_argument('--component',choices=['all','openmp','openblas','application','bench','qemu'],default='all')
    p.add_argument('--qemu-profile',default='composite');p.add_argument('--profile',default='batch');p.add_argument('--target',choices=['native','riscv-cross','x86'],default='native')
    p.add_argument('--jobs',type=int,default=2);p.add_argument('--out',type=Path,default=ROOT/'build');p.add_argument('--plan',action='store_true')
    a=p.parse_args();require(1<=a.jobs<=32,'jobs范围1..32')
    if a.plan:
        if a.component=='qemu':
            mapping=load(ROOT/'components/qemu/profiles.json')['profiles'];require(a.qemu_profile in mapping,'unknown QEMU profile '+a.qemu_profile)
            print(json.dumps(dict(component='qemu',profile=a.qemu_profile,target=a.target,out=str(a.out.resolve()),
                source='QEMU 9.1.0',patches=mapping[a.qemu_profile]['patches'],steps=['build baseline','apply selected patch series','build optimized'],
                execution=False),ensure_ascii=False,indent=2));return
        print(json.dumps(dict(component=a.component,profile=a.profile,target=a.target,out=str(a.out.resolve()),
            steps=['LLVM runtime profiles','OpenBLAS baseline/independent RVV configurations','full C LAPACK support','GKlib/METIS/STRUMPACK','PETSc+PCSHELL','bench frontends'],
            execution=False,operating_system='Existing RISC-V Linux, not included'),ensure_ascii=False,indent=2));return
    if a.component=='qemu':
        try:run_qemu(a)
        except BaseException as e:
            save(a.out.resolve()/'qemu-build-result.json',dict(status='FAILED',error=repr(e)));raise
        return
    b=Builder(a)
    try:
        if a.component=='openmp':b.omp(a.profile)
        elif a.component=='openblas':b.blas(a.profile)
        elif a.component=='application':b.application()
        elif a.component=='bench':b.bench()
        else:
            for name in ['baseline','general','batch']:b.omp(name)
            profiles=['baseline']if b.x86 else list(load(ROOT/'components/openblas/profiles.json'))
            for name in profiles:b.blas(name)
            if not b.x86:b.application()
            b.bench()
        save(b.out/'build-result.json',dict(status='BUILD_PASS',component=a.component,target=a.target,install=str(b.install),commands=b.commands))
    except BaseException as e:
        save(b.out/'build-result.json',dict(status='FAILED',error=repr(e),commands=b.commands));raise


if __name__=='__main__':main()
