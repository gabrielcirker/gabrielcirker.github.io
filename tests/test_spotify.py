"""Integrity and publication boundaries for the approved Spotify report."""
import base64
import hashlib
import re
import unittest
from html.parser import HTMLParser
from pathlib import Path
from urllib.parse import urlparse
from test_site import Document, ROOT

REPORT = ROOT / 'projects/spotify-title-lab/index.html'
class TextOnly(HTMLParser):
    def __init__(self, text):
        super().__init__(); self.parts=[]; self.skip=0; self.feed(text)
    def handle_starttag(self, tag, attrs):
        if tag in ('script','style'): self.skip+=1
    def handle_endtag(self, tag):
        if tag in ('script','style'): self.skip-=1
    def handle_data(self, text):
        if not self.skip: self.parts.append(text)

class SpotifyTests(unittest.TestCase):
    def test_navigation_and_project_entry(self):
        for name in ('index.html','about.html','resume.html','side-projects.html'):
            links=[a for t,a in Document((ROOT/name).read_text()).elements if t=='a' and a.get('href')=='side-projects.html']
            self.assertEqual(len(links),1,name)
            self.assertEqual(links[0].get('aria-current'),'page' if name=='side-projects.html' else None)
        text=(ROOT/'side-projects.html').read_text()
        self.assertIn('projects/spotify-title-lab/',text)
        self.assertIn('mental jungle gym',text)
        self.assertIn('my own Spotify data',text)
    def test_report_structure_and_return_links(self):
        text=REPORT.read_text(); doc=Document(text)
        ids=[a['id'] for t,a in doc.elements if 'id' in a]
        self.assertEqual(len(ids),len(set(ids)))
        self.assertEqual(sum(t=='h1' for t,_ in doc.elements),1)
        self.assertIn('project-story-title',ids)
        self.assertIn('lex-search',ids);self.assertIn('lex-sort',ids);self.assertIn('lex-count',ids)
        self.assertIn('279',text)
        self.assertIn('https://gabrielcirker.github.io/projects/spotify-title-lab/',text)
        for t,a in doc.elements:
            for attr in ('src','href'):
                if attr not in a: continue
                u=urlparse(a[attr])
                if u.scheme or u.netloc: continue
                target=REPORT.parent/u.path if u.path else REPORT
                if target.is_dir():target=target/'index.html'
                self.assertTrue(target.is_file(),a[attr])
                if u.fragment:
                    self.assertIn(u.fragment,[x.get('id') for _,x in Document(target.read_text()).elements])
    def test_embedded_figures_and_resources(self):
        elements=Document(REPORT.read_text()).elements
        images=[a for t,a in elements if t=='img']
        self.assertEqual(len(images),6)
        for a in images:
            self.assertTrue(a['src'].startswith('data:image/png;base64,'))
            data=base64.b64decode(a['src'].split(',',1)[1])
            self.assertTrue(data.startswith(b'\x89PNG\r\n\x1a\n'))
            self.assertGreater(len(a.get('alt','')),40)
            self.assertEqual(a['width'],'1870')
            self.assertTrue(a['height'].isdigit())
        first=base64.b64decode(images[0]['src'].split(',',1)[1])
        self.assertEqual(hashlib.sha256(first).digest(),hashlib.sha256((ROOT/'assets/spotify-word-weighting.png').read_bytes()).digest())
        for t,a in elements:
            if t in ('script','img','link'):
                url=a.get('src') or a.get('href','')
                if a.get('rel')!='canonical':self.assertFalse(url.startswith(('http:','https:')))
    def test_public_data_boundary_and_blurb(self):
        html=REPORT.read_text();visible=' '.join(TextOnly(html).parts)
        self.assertIn('Music is a big part of my life.',visible)
        self.assertIn('mental jungle gym',visible)
        self.assertIn('individual listening records are not included',visible)
        self.assertNotRegex(visible,r'[\w.+-]+@[\w.-]+\.[A-Za-z]{2,}')
        for forbidden in ('/Users/','@gmail.com','Private working material','Nothing has been published','owner-only','tripledecor4.chatgpt.site'):
            self.assertNotIn(forbidden,html)
        files={p.name for p in REPORT.parent.iterdir()}
        self.assertEqual(files,{'index.html'})
        self.assertNotIn('.json', ''.join(files));self.assertNotIn('.csv',''.join(files))

if __name__=='__main__':unittest.main()
