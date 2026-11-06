#!/usr/bin/env python3
"""Manual native execution only, using the same fixed QEMU protocol."""
import argparse,hashlib,json,os,platform,shutil,signal,subprocess,tarfile
from pathlib import Path
from metrics import need,parse_cell,PROFILES
from analyze import analyze
HERE=Path(__file__).resolve().parent
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def save(p,v):p.write_text(json.dumps(v,indent=2)+'\n')
def main():
 ap=argparse.ArgumentParser();ap.add_argument('--out',type=Path,required=True);a=ap.parse_args();out=a.out.resolve();out.mkdir(parents=True,exist_ok=False);state=dict(status='STARTED',mode='native');commands=[];payload=HERE/'payload';protocol=json.loads((HERE/'protocol.json').read_text());env=dict(os.environ)
 for k in list(env):
  if k.startswith(('OMP_','KMP_','OPENBLAS_','STRUMPACK_','SYSTEM_'))or k in ['LD_PRELOAD','LD_LIBRARY_PATH']:env.pop(k,None)
 env.update(SYSTEM_PAYLOAD_ROOT=str(payload),OMP_NUM_THREADS='2',OMP_DYNAMIC='FALSE',OMP_PROC_BIND='close',OMP_PLACES='cores',OMP_TOOL='disabled',OPENBLAS_NUM_THREADS='1')
 for role,ras in protocol['handoff_ras'].items():env['SYSTEM_HANDOFF_'+role.upper()]=','.join(f'{v:x}'for v in ras)
 def run(label,argv,kind,cell=None):
  print('RUN',label,flush=True);proc=subprocess.Popen(list(map(str,argv)),stdout=subprocess.PIPE,stderr=subprocess.PIPE,text=True,env=env,start_new_session=True)
  try:t,e=proc.communicate(timeout=300)
  except subprocess.TimeoutExpired:
   os.killpg(proc.pid,signal.SIGKILL);t,e=proc.communicate()
   for rd in [-1,0,1,2]:
    name=Path('/dev/shm')/f'system-line-{proc.pid}-{rd}.log'
    if name.exists():name.unlink()
   (out/(label+'.stdout')).write_text(t);(out/(label+'.stderr')).write_text(e);raise RuntimeError(label+' timeout; owned process group killed')
  (out/(label+'.stdout')).write_text(t);(out/(label+'.stderr')).write_text(e);commands.append(dict(label=label,kind=kind,argv=list(map(str,argv)),exit_code=proc.returncode,cell=cell));save(out/'commands.json',commands);need(proc.returncode==0,label+' exit');return t
 try:
  need(platform.machine()=='riscv64','Native RISC-V only');need(not any(c.isspace()for c in str(payload)),'Kit path without whitespace');need({0,1}.issubset(os.sched_getaffinity(0)),'CPU0/1 available')
  for line in(HERE/'SHA256SUMS').read_text().splitlines():h,n=line.split('  ',1);need(sha(HERE/n)==h,'Kit SHA '+n)
  with(out/'owned-io-probe').open('xb')as f:f.write(bytes(1048576));f.flush();os.fsync(f.fileno())
  (out/'owned-io-probe').unlink();inventory=dict(uname=list(os.uname()),allowed_cpus=sorted(os.sched_getaffinity(0)))
  for name,path in [('cpuinfo','/proc/cpuinfo'),('memory','/proc/meminfo'),('governor','/sys/devices/system/cpu/cpu0/cpufreq/scaling_governor'),('frequency','/sys/devices/system/cpu/cpu0/cpufreq/scaling_cur_freq')]:
   try:inventory[name]=Path(path).read_text()
   except OSError as e:inventory[name]='UNKNOWN '+str(e)
  save(out/'inventory.json',inventory);run('capability',[payload/'capability'],'gate');save(out/'record.json',dict(mode='native',protocol_sha256=sha(HERE/'protocol.json'),payload_root=str(payload)));shutil.copy2(__file__,out/'native-executed.py');shutil.copy2(HERE/'SHA256SUMS',out/'kit-SHA256SUMS')
  for name in ['P0','P3','P4']:
   cell=dict(stage='gate',slot=0,arm='A',profile=name);text=run('gate-'+name,[payload/'system-launch','64',name],'gate',cell);parse_cell(text,cell,str(payload))
  for cell in protocol['cells']:
   label=cell['stage']+'-'+str(cell['slot']);text=run(label,[payload/'system-launch','64',cell['profile']],'measurement',cell);parse_cell(text,cell,str(payload))
  result=analyze(HERE,out,out/'analysis');state.update(status='SYSTEM_LINE_NATIVE_COMPLETE',result=result)
 except BaseException as e:state.update(status='FAILED_WITH_EVIDENCE_RETAINED',error=repr(e));raise
 finally:
  save(out/'status.json',state);save(out/'commands.json',commands);(out/'SHA256SUMS').write_text(''.join(sha(p)+'  '+str(p.relative_to(out))+'\n'for p in sorted(out.rglob('*'))if p.is_file()));archive=out.with_name(out.name+'-results.tar.gz')
  with tarfile.open(archive,'x:gz')as t:t.add(out,arcname=out.name)
  print('RETURN_DIRECTORY='+str(out)+'\nRETURN_ARCHIVE='+str(archive)+'\nRETURN_SHA256='+sha(archive),flush=True)
if __name__=='__main__':main()
