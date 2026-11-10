"""Independent public sampling and published comparison integrity."""
import importlib.util,json,unittest,hashlib
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
spec=importlib.util.spec_from_file_location('fetch_external',ROOT/'analysis/spotify/fetch_external.py')
fetch=importlib.util.module_from_spec(spec);spec.loader.exec_module(fetch)
class ExternalTests(unittest.TestCase):
 def test_sample_deduplicates_and_ignores_null(self):
  rows=[{'recording_mbid':None}]+[{'recording_mbid':str(i//2)} for i in range(20)]
  self.assertEqual([r['recording_mbid'] for r in fetch.sample_recordings(rows,3)],['0','3','6','9'])
 def test_reference_hashes(self):
  folder=ROOT/'analysis/spotify/reference'
  manifest=json.loads((folder/'manifest.json').read_text())
  for name,digest in manifest['files'].items():self.assertEqual(hashlib.sha256((folder/name).read_bytes()).hexdigest(),digest)
  self.assertEqual(manifest['sampleSize'],len(json.loads((folder/'enrichment.json').read_text())['rows']))
 def test_fetcher_has_no_private_input(self):
  source=(ROOT/'analysis/spotify/fetch_external.py').read_text()
  self.assertNotIn('StreamingHistory',source);self.assertNotIn('artistName',source)
 def test_shares_and_coverage(self):
  data=json.loads((ROOT/'docs/spotify-title-lab/data/external.json').read_text())
  c=data['community'];self.assertEqual(c['status'],'available')
  self.assertAlmostEqual(sum(r['userShare'] for r in c['rows']),1,places=6)
  self.assertAlmostEqual(sum(r['communityShare'] for r in c['rows']),1,places=6)
  for r in c['rows']:self.assertAlmostEqual(r['lift'],r['userShare']/r['communityShare'],places=4)
  self.assertLessEqual(c['coverage']['matchedPlays'],c['coverage']['totalPlays'])
  for section in ['releases','acoustic']:
   self.assertEqual(data[section]['coverage']['matchedTracks'],len(data[section]['rows']))
  for r in data['releases']['rows']: self.assertEqual(int(r['firstReleaseDate'][:4]),r['year'])
  if data['acoustic']['status']=='available':
   self.assertGreaterEqual(len(data['acoustic']['rows']),5)
   self.assertLessEqual(sum(data['acoustic']['pca']['varianceExplained']),1.000001)
   for r in data['acoustic']['rows']: self.assertTrue(all(isinstance(r[k],(int,float)) for k in ['x','y','bpm','spectralCentroid','averageLoudness']))
if __name__=='__main__':unittest.main()
