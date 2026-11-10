#!/usr/bin/env python3
"""Download independent public charts; never accepts personal-history inputs.
Use system curl's verified TLS trust store. Cache lives outside the repository.
Sampling: every eighth distinct recording in global chart order, independent of user.
"""
import argparse, datetime, hashlib, json, subprocess, time
from pathlib import Path
BASE='https://api.listenbrainz.org/1/stats/sitewide/'
UA='GabrielMusicResearch/1.0 (https://gabrielcirker.github.io/spotify-title-lab/)'
def fetch(url):
    p=subprocess.run(['curl','--fail','--silent','--show-error','--max-time','25','-A',UA,url],capture_output=True,text=True)
    if p.returncode: return {'error':p.stderr.strip()}
    try:return json.loads(p.stdout)
    except ValueError:return {'error':'Response was not JSON'}
def sample_recordings(rows,stride=8):
    seen=set(); unique=[]
    for row in rows:
        mid=row.get('recording_mbid')
        if mid and mid not in seen: unique.append(row);seen.add(mid)
    return unique[::stride]
def export_reference(cache, target):
    """Publish only the independent baseline and three numeric audio features."""
    target.mkdir(parents=True,exist_ok=True)
    original=json.loads((cache/'enrichment.json').read_text())
    for row in original['rows']:
        ac=row['acousticbrainz']; mb=row['musicbrainz']
        row['musicbrainz']={k:mb[k] for k in ('id','title','first-release-date','error') if k in mb}
        row['acousticbrainz']={'rhythm':{'bpm':ac.get('rhythm',{}).get('bpm')},'lowlevel':{'spectral_centroid':{'mean':ac.get('lowlevel',{}).get('spectral_centroid',{}).get('mean')},'average_loudness':ac.get('lowlevel',{}).get('average_loudness')},'error':ac.get('error'),'message':ac.get('message')}
        row['recording']={k:row['recording'][k] for k in ('artist_name','track_name','recording_mbid','listen_count') if k in row['recording']}
    (target/'artists.json').write_bytes((cache/'artists.json').read_bytes())
    (target/'enrichment.json').write_text(json.dumps(original,indent=2))
    manifest={'samplingRule':original['sampleRule'],'sampleSize':len(original['rows']),'musicbrainzDatesAvailable':sum(bool(r['musicbrainz'].get('first-release-date')) for r in original['rows']),'acousticDescriptorsAvailable':sum(all(isinstance(v,(int,float)) for v in [r['acousticbrainz']['rhythm']['bpm'],r['acousticbrainz']['lowlevel']['spectral_centroid']['mean'],r['acousticbrainz']['lowlevel']['average_loudness']]) for r in original['rows']),'musicbrainzErrors':sum(bool(r['musicbrainz'].get('error')) for r in original['rows']),'acousticErrors':sum(bool(r['acousticbrainz'].get('error') or r['acousticbrainz'].get('message')) for r in original['rows']),'files':{p.name:hashlib.sha256(p.read_bytes()).hexdigest() for p in target.glob('*.json') if p.name!='manifest.json'}}
    (target/'manifest.json').write_text(json.dumps(manifest,indent=2))
def main():
    p=argparse.ArgumentParser();p.add_argument('--cache',type=Path,default=Path.home()/'.cache/spotify-external');p.add_argument('--refresh',action='store_true');p.add_argument('--export-only',type=Path);a=p.parse_args();a.cache.mkdir(parents=True,exist_ok=True)
    if a.export_only:
        export_reference(a.cache,a.export_only);return
    sources=[]
    for kind in ['artists','recordings']:
        url=BASE+kind+'?range=month&count=1000'; path=a.cache/(kind+'.json')
        if a.refresh or not path.exists():path.write_text(json.dumps(fetch(url)))
        sources.append({'name':'ListenBrainz global monthly '+kind,'url':url,'retrievedAt':datetime.datetime.fromtimestamp(path.stat().st_mtime,datetime.timezone.utc).isoformat(),'sha256':hashlib.sha256(path.read_bytes()).hexdigest(),'license':'CC0 listening data'})
    rows=json.loads((a.cache/'recordings.json').read_text())['payload']['recordings'];sample=sample_recordings(rows)
    out=[]
    for i,row in enumerate(sample):
        mid=row['recording_mbid']; path=a.cache/(mid+'.json')
        if a.refresh or not path.exists():
            mburl='https://musicbrainz.org/ws/2/recording/'+mid+'?fmt=json'
            mb=fetch(mburl);time.sleep(1.1)
            acurl='https://acousticbrainz.org/api/v1/'+mid+'/low-level'
            ac=fetch(acurl)
            path.write_text(json.dumps({'recording':row,'musicbrainz':mb,'acousticbrainz':ac,'retrievedAt':datetime.datetime.now(datetime.timezone.utc).isoformat(),'musicbrainzUrl':mburl,'acousticbrainzUrl':acurl}))
        out.append(json.loads(path.read_text()));print(f'{i+1}/{len(sample)}',flush=True)
    (a.cache/'enrichment.json').write_text(json.dumps({'sampleRule':'Every eighth distinct recording in global monthly top-1000 chart order; chosen without consulting personal history.','sources':sources,'rows':out},indent=2))
if __name__=='__main__':main()
