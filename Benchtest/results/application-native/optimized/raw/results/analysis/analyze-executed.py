#!/usr/bin/env python3
"""Replay QEMU/native application outputs for the fixed system line."""
import argparse,csv,hashlib,json,re,shutil
from pathlib import Path
from metrics import need,parse_cell,summarize,schedule

def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def analyze(kit,record,out):
 out.mkdir(parents=True,exist_ok=False);state=dict(status='STARTED')
 try:
  p=json.loads((kit/'protocol.json').read_text());meta=json.loads((record/'record.json').read_text());need(p['cells']==schedule(),'Frozen balanced schedule');need(meta['protocol_sha256']==sha(kit/'protocol.json'),'Protocol identity')
  for line in(kit/'SHA256SUMS').read_text().splitlines():h,n=line.split('  ',1);need(sha(kit/n)==h,'Kit unchanged '+n)
  rows=[]
  if meta['mode']=='qemu':
   text=(record/'qemu/console.log').read_text().replace('\r','');boot=json.loads((record/'qemu/boot-status.json').read_text());need(boot['status']=='guest-completed'and all(boot[k]for k in ['script_removed','overlay_removed','boot_hashes_unchanged'])and'execution_plugin'not in boot,'Untraced isolated QEMU and cleanup')
   for cell in p['cells']:
    label=cell['stage']+'-'+str(cell['slot']);m=re.search('SYSTEM_CELL_BEGIN_'+label+r'\n(.*?)SYSTEM_CELL_END_'+label+r'\n',text,re.S);need(m is not None and'SYSTEM_EXIT_'+label+'=0'in m[1],'Exact guest exit '+label);rows+=parse_cell(m[1],cell,'/mnt/cost')
  elif meta['mode']=='native':
   commands=json.loads((record/'commands.json').read_text());selected=[x for x in commands if x['kind']=='measurement'];need(len(selected)==len(p['cells']),'Forty measurement processes')
   for c,cell in zip(selected,p['cells']):
    need(c['cell']==cell and c['exit_code']==0,'Exact native order and exit');rows+=parse_cell((record/(c['label']+'.stdout')).read_text(),cell,meta['payload_root'])
  else:raise RuntimeError('Known execution mode')
  need(len(rows)==4*len(p['cells']),'All stack workflows');summaries=summarize(rows,kit/'analysis.py')
  with(out/'rounds.csv').open('w',newline='')as f:w=csv.DictWriter(f,fieldnames=list(dict.fromkeys(k for x in rows for k in x)));w.writeheader();w.writerows(rows)
  with(out/'summary.csv').open('w',newline='')as f:w=csv.DictWriter(f,fieldnames=list(dict.fromkeys(k for x in summaries for k in x)));w.writeheader();w.writerows(summaries)
  (out/'analysis.json').write_text(json.dumps(summaries,indent=2)+'\n');state.update(status='PASS_SYSTEM_LINE_APPLICATION_REPLAY',mode=meta['mode'],workflows=len(rows),formal_workflows=sum(x['round']>=0 for x in rows),field_values=sum(x['field_values']for x in rows),maximum_error=max(x['max_discrete_error']for x in rows),maximum_residual=max(x['max_residual']for x in rows),primary=[x for x in summaries if x['comparison']=='increment'],all_comparisons=summaries,default_replaced=False,new_libraries=True,new_kernel_mechanism=False)
 except BaseException as e:state.update(status='FAILED_WITH_EVIDENCE_RETAINED',error=repr(e));raise
 finally:(out/'status.json').write_text(json.dumps(state,indent=2)+'\n');shutil.copy2(__file__,out/'analyze-executed.py')
 return state

def main():
 ap=argparse.ArgumentParser();ap.add_argument('--kit',type=Path,default=Path(__file__).resolve().parent);ap.add_argument('--record',required=True,type=Path);ap.add_argument('--out',required=True,type=Path);a=ap.parse_args();s=analyze(a.kit,a.record,a.out);print(s['status'])
if __name__=='__main__':main()
