"""Dedicated project identities, share URLs, and old-link compatibility."""
import hashlib
import re
import unittest
from urllib.parse import urlparse
from test_site import Document, ROOT

class StandaloneProjectTests(unittest.TestCase):
    def test_project_identity_and_sharing(self):
        for path, name, url in (
            ('spotify-title-lab/index.html', 'Spotify Title Lab', 'https://gabrielcirker.github.io/spotify-title-lab/'),
            ('desktop-widgets/index.html', 'DESKTOP IN STEREO', 'https://gabrielcirker.github.io/desktop-widgets/'),
        ):
            with self.subTest(path=path):
                text=(ROOT/path).read_text()
                elements=Document(text).elements
                self.assertIn(name,text)
                canonical=[a['href'] for t,a in elements if t=='link' and a.get('rel')=='canonical']
                self.assertEqual(canonical,[url])
                og_url=[a['content'] for t,a in elements if t=='meta' and a.get('property')=='og:url']
                self.assertEqual(og_url,[url])
                self.assertEqual([a['data-share-project'] for t,a in elements if 'data-share-project' in a],[url])
                nav=re.search(r'<nav[^>]*aria-label="Main navigation"[^>]*>.*?</nav>',text,re.S).group()
                self.assertNotIn('resume.html',nav)
                self.assertNotIn('research.html',nav)
                self.assertNotIn('side-projects.html',nav)
                for tag,attrs in Document(nav).elements:
                    if tag=='a':self.assertEqual(attrs['href'],'./')
                self.assertIn('navigator.clipboard.writeText(url)',text)
                self.assertIn('fallback.select()',text)
                self.assertIn('Project link copied.',text)
                self.assertIn('https://gabrielcirker.github.io/',text)

    def test_old_spotify_links_preserve_query_and_fragment(self):
        text=(ROOT/'projects/spotify-title-lab/index.html').read_text()
        self.assertIn('window.location.replace("../../spotify-title-lab/" + window.location.search + window.location.hash)',text)
        self.assertIn('<noscript>',text)
        self.assertIn('href="../../spotify-title-lab/"',text)
        self.assertIn('name="robots" content="noindex"',text)
        for name in ('about.html','side-projects.html','search.json','sitemap.xml'):
            self.assertNotIn('projects/spotify-title-lab/',(ROOT/name).read_text())

    def test_every_portfolio_project_has_a_separate_destination(self):
        pages=''.join((ROOT/name).read_text() for name in ('index.html','research.html','side-projects.html'))
        for project in ('rowing-research','bridge-research','math-463-miniproject'):
            self.assertIn('https://gabrielcirker.github.io/'+project+'/',pages)
        for project in ('spotify-title-lab','desktop-widgets'):
            self.assertIn('href="'+project+'/"',pages)

    def test_report_and_walkthrough_content_preserved(self):
        expected = {
            'spotify-title-lab/index.html': '5c2652369356605943d1a044ab6dea38836a34913e1ef5e92e0c094a733f7749',
            'desktop-widgets/index.html': '40e293e67db2883ab489f295ebcac337ca1453bd1bdf0c4aa01d4bca1a0bd602',
        }
        for path,digest in expected.items():
            text=(ROOT/path).read_text()
            main=re.search(r'<main\b[\s\S]*?</main>',text).group()
            self.assertEqual(hashlib.sha256(main.encode()).hexdigest(),digest,path)

if __name__=='__main__':unittest.main()
