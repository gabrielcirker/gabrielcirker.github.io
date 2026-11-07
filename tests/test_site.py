"""Dependency-free checks for the published portfolio files."""
import json
import hashlib
from html.parser import HTMLParser
from pathlib import Path
from urllib.parse import urlparse, unquote
import unittest
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parents[1] / "docs"
PAGES = [ROOT / name for name in ("index.html", "about.html", "resume.html", "404.html")]
class Document(HTMLParser):
    def __init__(self, text):
        super().__init__(convert_charrefs=True)
        self.elements = []
        self.feed(text)
    def handle_starttag(self, tag, attrs):
        self.elements.append((tag, dict(attrs)))

class PortfolioTests(unittest.TestCase):
    def test_basic_document_accessibility(self):
        for path in PAGES:
            with self.subTest(page=path.name):
                doc = Document(path.read_text())
                tags = [tag for tag, _ in doc.elements]
                self.assertEqual(tags.count("h1"), 1)
                self.assertEqual(tags.count("main"), 1)
                self.assertTrue(any(t == "html" and a.get("lang") == "en" for t, a in doc.elements))
                self.assertTrue(any(t == "meta" and a.get("name") == "viewport" for t, a in doc.elements))
                ids = [a["id"] for t, a in doc.elements if "id" in a]
                self.assertEqual(len(ids), len(set(ids)))
                for tag, attrs in doc.elements:
                    if tag == "img":
                        self.assertTrue(attrs.get("alt"))
                        self.assertTrue(attrs.get("width") and attrs.get("height"))
    def test_local_links_assets_and_fragments(self):
        for path in PAGES:
            for tag, attrs in Document(path.read_text()).elements:
                for attr in ("href", "src"):
                    if attr not in attrs:
                        continue
                    url = urlparse(attrs[attr])
                    if url.scheme or url.netloc:
                        continue
                    local = (ROOT / unquote(url.path.lstrip("/"))) if url.path.startswith("/") else path.parent / unquote(url.path)
                    if not url.path:
                        local = path
                    if local.is_dir():
                        local = local / "index.html"
                    self.assertTrue(local.is_file(), (path.name, attrs[attr]))
                    if url.fragment:
                        ids = [a.get("id") for _, a in Document(local.read_text()).elements]
                        self.assertIn(url.fragment, ids)
    def test_public_destinations_and_privacy(self):
        for path in PAGES:
            text = path.read_text()
            self.assertNotIn("@gmail.com", text)
            self.assertNotIn("bridge-optimization", text)
            self.assertNotIn("rowing-energy-transfer", text)
            self.assertNotIn("DesktopWidgets", text)
            self.assertNotIn("<script", text)
            for tag, attrs in Document(text).elements:
                if tag == "a":
                    url = urlparse(attrs["href"])
                    if url.scheme == "mailto":
                        self.assertEqual(url.path, "gcirker@umich.edu")
                    elif url.netloc:
                        self.assertEqual(url.scheme, "https")
                        self.assertIn(url.netloc, ("github.com", "gabrielcirker.github.io", "www.linkedin.com"))
                        if url.netloc == "www.linkedin.com":
                            self.assertEqual(attrs["href"], "https://www.linkedin.com/in/gabrielcirker001/")
    def test_approved_linkedin_profile(self):
        profile = "https://www.linkedin.com/in/gabrielcirker001/"
        for name, count in (("index.html", 2), ("about.html", 2), ("resume.html", 1)):
            with self.subTest(page=name):
                text = (ROOT / name).read_text()
                links = [attrs for tag, attrs in Document(text).elements if tag == "a" and attrs.get("href") == profile]
                self.assertEqual(len(links), count)
                self.assertIn('<a href="' + profile + '">LinkedIn <span aria-hidden="true">↗</span></a></nav>', text)
                for attrs in links:
                    self.assertNotIn("target", attrs)
                    self.assertNotIn("tabindex", attrs)
        text = (ROOT / "index.html").read_text()
        self.assertIn('<a href="' + profile + '">Connect on LinkedIn <span aria-hidden="true">↗</span></a>', text)
    def test_project_links_and_attribution(self):
        text = (ROOT / "index.html").read_text()
        for project in ("rowing-research", "bridge-research", "math-463-miniproject"):
            self.assertIn("https://gabrielcirker.github.io/" + project + "/", text)
            self.assertIn("https://github.com/gabrielcirker/" + project, text)
        self.assertIn("Kennedy Jamison", text)
        self.assertIn("Cecilia Pirozzi", text)
        self.assertIn("not a clinical model", text)
        self.assertIn("not rowing or metabolic efficiency", text)
    def test_metadata_files(self):
        ET.parse(ROOT / "sitemap.xml")
        ET.parse(ROOT / "assets/favicon.svg")
        expected = {"index.html", "about.html", "resume.html"}
        entries = json.loads((ROOT / "search.json").read_text())
        self.assertEqual({entry["href"] for entry in entries}, expected)
        sitemap = ET.parse(ROOT / "sitemap.xml")
        urls = {node.text for node in sitemap.findall(".//{http://www.sitemaps.org/schemas/sitemap/0.9}loc")}
        self.assertIn("https://gabrielcirker.github.io/resume.html", urls)
        self.assertTrue((ROOT / ".nojekyll").exists())
    def test_resume_navigation_and_publication_status(self):
        for name in ("index.html", "about.html", "resume.html"):
            doc = Document((ROOT / name).read_text())
            links = [attrs for tag, attrs in doc.elements if tag == "a" and attrs.get("href") == "resume.html"]
            self.assertEqual(len(links), 1, name)
            self.assertEqual(links[0].get("aria-current"), "page" if name == "resume.html" else None)
        text = (ROOT / "resume.html").read_text()
        self.assertEqual(text.count('class="document-status">Coming soon'), 2)
        for tag, attrs in Document(text).elements:
            if tag == "a":
                self.assertNotIn("download", attrs)
                self.assertNotIn(Path(urlparse(attrs["href"]).path).suffix.lower(), (".pdf", ".docx", ".doc"))
    def test_approved_homepage_portrait(self):
        text = (ROOT / "index.html").read_text()
        images = [attrs for tag, attrs in Document(text).elements if tag == "img" and attrs.get("src") == "assets/gabriel-cirker-headshot.png"]
        self.assertEqual(len(images), 1)
        self.assertEqual((images[0]["width"], images[0]["height"]), ("1024", "1536"))
        self.assertIn("Gabriel Cirker", images[0]["alt"])
        self.assertEqual(images[0].get("fetchpriority"), "high")
        portrait = (ROOT / "assets/gabriel-cirker-headshot.png").read_bytes()
        self.assertEqual(hashlib.sha256(portrait).hexdigest(), "cd5bc1fac47174fdf817e41acadfa586f0ded19bf4113f370347f61f7d13e2fd")
        self.assertEqual(text.count('aria-label="Portfolio overview"'), 1)
    def test_responsive_and_keyboard_styles(self):
        css = (ROOT / "styles.css").read_text()
        for term in ("max-width:700px", ":focus-visible", ".skip-link:focus", "prefers-reduced-motion", "@media print"):
            self.assertIn(term, css)
if __name__ == "__main__":
    unittest.main()
