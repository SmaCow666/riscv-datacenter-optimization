#!/usr/bin/env python3
"""Run the finite component/application suite against a sibling source-package build."""
import argparse
import importlib.util
import json
import math
import os
from pathlib import Path
import platform
import signal
import statistics
import subprocess
import time

ROOT=Path(__file__).resolve().parents[1]
ORDER='ABBABAAB'

def need(ok,why):
    if not ok:raise ValueError(why)
def events(text,tag):return[json.loads(line[len(tag)+1:])for line in text.splitlines()if line.startswith(tag+' ')]
def save(p,data):p.write_text(json.dumps(data,ensure_ascii=False,indent=2)+'\n')

def main():
    p=argparse.ArgumentParser(description=__doc__)
    p.add_argument('--build',type=Path,required=True,help='第一部分构建输出目录，含 install/')
    p.add_argument('--target',choices=['native','x86'],default='native')
    p.add_argument('--suite',choices=['correctness','components','application'],default='correctness')
    p.add_argument('--out',type=Path);p.add_argument('--plan',action='store_true');a=p.parse_args()
    cases=json.loads((ROOT/'configs/cases.json').read_text());build=a.build.resolve();install=build/'install'
    if a.plan:
        print(json.dumps(dict(suite=a.suite,target=a.target,public_math_cases=len(cases),omp_cases=3,
            build=str(build),order=ORDER*2,calibration_order=ORDER,
            application=dict(grid=64,steps=100,threads=2),execution=False),ensure_ascii=False,indent=2));return
    need(a.out is not None,'执行时必须提供新的 --out 目录')
    need(platform.system()=='Linux','需要 Linux')
    need(platform.machine()==('x86_64'if a.target=='x86'else'riscv64'),'当前架构与 --target 不符')
    need({0,1}<=os.sched_getaffinity(0),'测试源码固定绑定CPU0/1，请使用允许这些CPU的Linux环境')
    if a.suite=='components':need({0,1,2,3}<=os.sched_getaffinity(0),'Sort4需要CPU0..3')
    out=a.out.resolve();out.mkdir(parents=True,exist_ok=False);(out/'raw').mkdir()
    env={k:v for k,v in os.environ.items()if not k.startswith(('LD_','OMP_','KMP_','GOMP_','OPENBLAS_','MKL_'))}
    env.update(LC_ALL='C',OPENBLAS_NUM_THREADS='1',OMP_DYNAMIC='FALSE',OMP_TOOL='disabled',OMP_PROC_BIND='close',TASK_COST_WARMUP='1',TASK_COST_ROUNDS='3')
    state=dict(status='STARTED',suite=a.suite,target=a.target,commands=[],checks=[],measurements=[],
               new_results=True,comparison_order=ORDER*2,calibration_order=ORDER)
    save(out/'environment.json',dict(uname=list(platform.uname()),affinity=sorted(os.sched_getaffinity(0)),
        cpuinfo=Path('/proc/cpuinfo').read_text(),loadavg=Path('/proc/loadavg').read_text()))
    spec=importlib.util.spec_from_file_location('paired_analysis',ROOT/'scripts/analysis.py')
    analysis=importlib.util.module_from_spec(spec);spec.loader.exec_module(analysis)
    bins=install/'bench/bin'
    def omp(role,n=2):
        lib=install/'omp'/role/'lib/libomp.so';need(lib.exists(),'请先构建 OpenMP '+role)
        return dict(LD_LIBRARY_PATH=str(lib.parent),OPENMP_EXPECTED_LIBRARY=str(lib),OMP_NUM_THREADS=str(n),OMP_PLACES=','.join('{'+str(i)+'}'for i in range(n)))
    def blas(role):
        lib=install/'blas'/role/'lib/libopenblas.so.0';need(lib.exists(),'请先构建 OpenBLAS '+role);return lib
    def invoke(label,argv,updates=None):
        argv=list(map(str,argv));print('RUN '+label,flush=True)
        begin=time.monotonic_ns();child=subprocess.Popen(argv,env=dict(env,**(updates or{})),cwd=out,stdout=subprocess.PIPE,stderr=subprocess.PIPE,start_new_session=True)
        interruption=None
        try:stdout,stderr=child.communicate(timeout=600 if a.suite=='application'else 120)
        except BaseException as error:
            interruption=repr(error)
            try:os.killpg(child.pid,signal.SIGTERM)
            except ProcessLookupError:pass
            try:stdout,stderr=child.communicate(timeout=3)
            except subprocess.TimeoutExpired:
                try:os.killpg(child.pid,signal.SIGKILL)
                except ProcessLookupError:pass
                stdout,stderr=child.communicate()
        elapsed_ns=time.monotonic_ns()-begin
        (out/'raw'/(label+'.stdout')).write_bytes(stdout);(out/'raw'/(label+'.stderr')).write_bytes(stderr)
        state['commands'].append(dict(id=label,argv=argv,environment=updates or{},exit_code=child.returncode,interruption=interruption,parent_wall_ns=elapsed_ns))
        save(out/'status.json',state);need(child.returncode==0 and interruption is None,'执行失败，已保留原始输出：'+label)
        return(stdout+stderr).decode(errors='replace')
    def mathcase(case,role,repeats=None):
        lib=blas(role);reps=case['repeats']if repeats is None else repeats
        if case['family']=='trsv':return[bins/'trsv-check','bench',lib,case['precision'],case['n'],reps],'TRSV_ROUND'
        return[bins/'blas-perf',lib,*case['shape'],reps,3],'FINAL_BLAS_ROUND'
    def parsed(text,tag):
        rows=events(text,tag);need(rows,'缺少记录 '+tag)
        need(all(r.get('correct',True)and r.get('guards',True)for r in rows),'数值/边界检查失败')
        need(all(r['wall_ns']>0 for r in rows),'计时无效');return rows
    def paired(name,call):
        cal=[];rows=[]
        for phase,order,dest in [('calibration',ORDER,cal),('comparison',ORDER*2,rows)]:
            for slot,arm in enumerate(order):
                role='A'if phase=='calibration'else arm
                for record in call(name+'-'+phase+'-'+str(slot),role):dest.append(dict(slot=slot,arm=arm,**record))
        result=analysis.compare(rows,cal)
        state['measurements'].append(dict(name=name,baseline_normalized=100,candidate_normalized=100*result['candidate_median_ns']/result['baseline_median_ns'],**result))
        save(out/(name+'-rounds.json'),dict(calibration=cal,comparison=rows));save(out/'summary.json',state['measurements'])
    try:
        if a.suite=='correctness':
            for role in ['general','batch']:
                for n in [1,2]:
                    records=events(invoke('task-'+role+'-'+str(n),[bins/'task-contracts',n],omp(role,n)),'HANDOFF_CONTRACTS')
                    need(len(records)==1 and records[0]['errors']==0 and records[0]['actual_team']==n,'任务契约')
                    state['checks'].append(dict(test='task',role=role,threads=n,status='PASS'))
            for role in ['baseline','general']:
                text=invoke('fp-'+role,[bins/'fp-control',2,'inherit'],omp(role))
                records=events(text,'FP_CONTROL');need(len(records)==4,'四种舍入模式')
                mismatches=sum(t['mismatch']for r in records for t in r['threads'])
                if role=='general'or a.target=='x86':need(mismatches==0,'修复版/官方x86浮点环境')
                state['checks'].append(dict(test='fp-control',role=role,mismatches=mismatches,interpretation='BASELINE_OBSERVATION'if role=='baseline'else'PASS'))
            candidate='baseline'if a.target=='x86'else'trsv-fused'
            rs=events(invoke('trsv-known-solution',[bins/'trsv-check','check',blas('baseline'),blas(candidate)]),'TRSV_CHECK')
            need(len(rs)==1 and rs[0]['cases']==5120,'TRSV 5120已知解/保护页组合')
            state['checks'].append(dict(test='trsv',status='PASS',result=rs[0],same_provider=a.target=='x86'))
            names=['baseline']*4 if a.target=='x86'else['baseline','short-vector','zero-stride','zero-stride']
            rs=events(invoke('zero-output-stride',[bins/'zero-stride',*[blas(n)for n in names]]),'ZERO_STRIDE')
            need(len(rs)==12,'零步长记录')
            for r in rs:
                if a.target=='x86'or r['role']>=3:need(r['single_matches']and r['double_matches'],'零步长修复/官方x86')
            state['checks'].append(dict(test='zero-output-stride',records=rs))
            for case in cases:
                roles=['baseline']if a.target=='x86'else[case['baseline'],case['candidate']]
                for role in roles:
                    argv,tag=mathcase(case,role,1);parsed(invoke('gate-'+case['id']+'-'+role,argv),tag)
                    state['checks'].append(dict(test=case['id'],role=role,status='PASS'))
        elif a.suite=='components':
            for case in cases:
                def call(label,arm):
                    argv,tag=mathcase(case,case['baseline']if arm=='A'else case['candidate']);return parsed(invoke(label,argv),tag)
                if a.target=='x86':
                    rows=[]
                    for slot in range(8):
                        argv,tag=mathcase(case,'baseline');rows.extend(dict(slot=slot,**r)for r in parsed(invoke(case['id']+'-'+str(slot),argv),tag))
                    values=[r['wall_ns']for r in rows if r['round']>=0];median=statistics.median(values)
                    state['measurements'].append(dict(name=case['id'],role='OFFICIAL_X86_REFERENCE',median_ns=median,MAD_ns=statistics.median(abs(v-median)for v in values),calls_per_batch=case['calls'],ns_per_call=median/case['calls']))
                    save(out/(case['id']+'-rounds.json'),rows)
                else:paired(case['id'],call)
            for kind,n in [('fib',2),('sort',2),('sort',4)]:
                def call(label,arm):
                    argv=[bins/kind,'-n',28,'-c','-o',3]if kind=='fib'else[bins/kind,'-n',1048576,'-c']
                    tag='FIB_BENCH'if kind=='fib'else'TASK_BENCH'
                    records=parsed(invoke(label,argv,omp('general'if arm=='A'else'batch',n)),tag)
                    need(all(r.get('check',1)==1 for r in records),'BOTS校验');return records
                paired(kind+'-'+str(n),call)
        else:
            need(a.target=='native','最终负载的既有协议面向RISC-V Linux')
            app=install/'application';observer=app/'lib/phase-observer.so';need(observer.exists(),'请先构建完整 application')
            def call(label,arm):
                role='baseline'if arm=='A'else'combined';updates=omp('general'if arm=='A'else'batch')
                updates.update(LD_PRELOAD=str(observer)+' '+str(blas(role)),STRUMPACK_HANDOFF_RAS='')
                updates['LD_LIBRARY_PATH']=':'.join([updates['LD_LIBRARY_PATH'],str(app/'lib'),str(install/'backend/lib'),str(install/'support/lib')])
                text=invoke(label,[app/'bin/petsc-heat','-heat_grid',64,'-heat_steps',100,'-ksp_view'],updates)
                result=events(text,'PETSC_HEAT_RESULT');need(len(result)==1 and result[0]['max_residual']<1e-10 and result[0]['max_discrete_error']<1e-10,'业务正确性')
                ksp=events(text,'HOTSPOT_KSP');reuse=[r for r in events(text,'HOTSPOT_STAGE')if r['phase']==4]
                need(len(ksp)==len(reuse)==1 and ksp[0]['solve_calls']==100 and reuse[0]['calls']==99,'KSP/Reuse阶段计数')
                # One application process is one observation; no reuse of 100 solves as independent samples.
                save(out/(label+'-stages.json'),dict(ksp=ksp[0],reuse=reuse[0],correctness=result[0]))
                return[dict(round=0,wall_ns=state['commands'][-1]['parent_wall_ns'],
                    ksp_ns=1e9*(ksp[0]['setup_wall']+ksp[0]['solve_wall']),reuse_ns=1e9*reuse[0]['wall'])]
            paired('application',call)
            data=json.loads((out/'application-rounds.json').read_text())
            state['measurements'].append(dict(name='application-ksp',**analysis.compare(data['comparison'],data['calibration'],'ksp_ns')))
            state['measurements'].append(dict(name='application-reuse',**analysis.compare(data['comparison'],data['calibration'],'reuse_ns')))
        state['status']='PASS';save(out/'summary.json',state['measurements'])
    except BaseException as error:state.update(status='FAILED',error=repr(error));raise
    finally:save(out/'status.json',state)

if __name__=='__main__':main()
