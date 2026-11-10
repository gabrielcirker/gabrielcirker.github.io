"""Privacy, accessibility, and integrity checks for the public widget walkthrough."""
from pathlib import Path
from html.parser import HTMLParser
from urllib.parse import urlparse
import re
import unittest

ROOT = Path(__file__).resolve().parents[1] / 'docs'
PAGE = ROOT / 'desktop-widgets/index.html'

class Document(HTMLParser):
    def __init__(self, text):
        super().__init__(); self.elements=[]; self.feed(text)
    def handle_starttag(self, tag, attrs):
        self.elements.append((tag,dict(attrs)))

class WidgetTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.text=PAGE.read_text(); cls.elements=Document(cls.text).elements
    def test_document_accessibility(self):
        ids=[a['id'] for _,a in self.elements if 'id' in a]
        self.assertEqual(len(ids),len(set(ids)))
        self.assertEqual(sum(t=='h1' for t,_ in self.elements),1)
        self.assertEqual(sum(t=='main' for t,_ in self.elements),1)
        self.assertIn('prefers-reduced-motion',self.text)
        self.assertIn('IntersectionObserver',self.text)
        self.assertIn(':focus-visible',self.text)
        labels={a.get('for') for t,a in self.elements if t=='label'}
        for t,a in self.elements:
            for ref in a.get('aria-controls','').split(): self.assertIn(ref,ids)
            if t in ('input','select'): self.assertTrue(a.get('id') in labels or a.get('aria-label'))
    def test_only_safe_local_interactions(self):
        for t,a in self.elements:
            if t=='script': self.assertNotIn('src',a)
            self.assertNotIn(t,('audio','video','iframe','form'))
            if t=='a':
                u=urlparse(a['href'])
                if u.fragment and not u.path: self.assertTrue(any(x.get('id')==u.fragment for _,x in self.elements))
                if u.netloc: self.assertEqual(u.netloc,'gabrielcirker.github.io')
        self.assertNotRegex(self.text,r'\b(?:fetch|XMLHttpRequest|WebSocket|getUserMedia|AudioContext)\s*\(')
        for forbidden in ['/Users/', 'C:\\Users\\', '127.0.0.1', 'localhost:', 'Authorization:', 'Bearer ', 'sp_dc', 'client_secret', 'access_token', '@gmail.com', 'file://', 'AIza', 'ghp_', 'gho_', 'BEGIN PRIVATE KEY']:
            self.assertNotIn(forbidden,self.text)
    def test_scope_and_source_boundaries(self):
        for phrase in ['All tracks, artwork, and activity shown here are fictional', 'Not affiliated with Spotify', 'complete widget repository remains private', 'No live integrations', 'work in progress', 'not an installer', 'opt-in', 'marked staged', 'not verified current settings']:
            self.assertIn(phrase,self.text)
        self.assertEqual(sum('data-api' in a for _,a in self.elements),6)
        self.assertEqual(sum('data-scene-track' in a for _,a in self.elements),3)
        self.assertEqual(sum('data-code' in a for _,a in self.elements),5)
    def test_resilient_project_illustration(self):
        import xml.etree.ElementTree as ET
        image = ROOT / 'assets/desktop-in-stereo.svg'
        svg = ET.parse(image)
        self.assertEqual(svg.getroot().get('viewBox'), '0 0 800 680')
        self.assertNotIn('<script', image.read_text())
        for name in ['index.html', 'side-projects.html']:
            text = (ROOT / name).read_text()
            doc = Document(text)
            images = [a for t,a in doc.elements if t == 'img' and a.get('src') == 'assets/desktop-in-stereo.svg']
            self.assertEqual(len(images), 1)
            self.assertEqual((images[0]['width'], images[0]['height']), ('800', '680'))
            self.assertIn('width:100%', images[0]['style'])
            self.assertIn('styles.css?v=outline-4', text)
            self.assertNotIn('class="feature-sleeve"', text)

    def test_widget_tablet_navigation_visible(self):
        self.assertIn(".mast .nav a{display:block!important}", self.text)

    def test_portfolio_entry_points(self):
        home=(ROOT/'index.html').read_text()
        self.assertIn('id="widgets"',home)
        self.assertIn('Enter Desktop in Stereo',home)
        for name in ['index.html','about.html','side-projects.html']:
            self.assertIn('href="desktop-widgets/"',(ROOT/name).read_text())
        self.assertIn('spotify-title-lab/',(ROOT/'side-projects.html').read_text())
        self.assertIn('https://gabrielcirker.github.io/desktop-widgets/',(ROOT/'sitemap.xml').read_text())

if __name__=='__main__': unittest.main()
