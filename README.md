# Gabriel Cirker · Personal website

**[Visit the homepage](https://gabrielcirker.github.io/)**

A personal, responsive portfolio for school projects, research, and passion projects. The first selected work connects the public rowing, bridge, and MATH 463 projects. The portfolio pages use HTML and CSS with no third-party fonts, tracking, package dependencies, or build step. The Spotify report is a self-contained Quarto HTML document with embedded JavaScript for local search, sorting, and report navigation; it loads no external assets.

## Public projects

- [Rowing energy transfer](https://gabrielcirker.github.io/rowing-research/) · [Repository](https://github.com/gabrielcirker/rowing-research)
- [Bridge geometry comparison](https://gabrielcirker.github.io/bridge-research/) · [Repository](https://github.com/gabrielcirker/bridge-research)
- [MATH 463 immune dynamics](https://gabrielcirker.github.io/math-463-miniproject/) · [Repository](https://github.com/gabrielcirker/math-463-miniproject)

## Side projects

- [Desktop in Stereo](https://gabrielcirker.github.io/desktop-widgets/): a music-led, interactive widget walkthrough. Fictional scenes, original CSS art, vetted short code excerpts, API explanations, and clear native-runtime limitations. No live account integration or private runtime data.

- [Spotify Title Lab](https://gabrielcirker.github.io/projects/spotify-title-lab/): a public aggregate report with six charts and an interactive 279-word lexicon. The original export and individual listening records are not included.
- [Side Projects](https://gabrielcirker.github.io/side-projects.html): the portfolio entry point for personal experiments.

## Structure

- `docs/index.html`: homepage and selected projects
- `docs/about.html`: background and project scope
- `docs/resume.html`: Resume & CV tab with public-download availability
- `docs/side-projects.html`: side-project index with the Spotify project blurb
- `docs/projects/spotify-title-lab/index.html`: self-contained public Spotify report
- `docs/desktop-widgets/index.html`: self-contained creative widget showcase with local JavaScript interactions
- `docs/styles.css`: responsive layout, accessibility, and print styles
- `docs/assets/`: original project figures and favicon; provenance in `SOURCES.md`
- `docs/404.html`, `robots.txt`, `sitemap.xml`: navigation and indexing support
- `tests/test_site.py`: local integrity, accessibility basics, and privacy checks

GitHub Pages publishes the **`docs/` folder on `main`**. Preserve that setting. Changes pushed to `main` trigger the Pages deployment. The older Quarto libraries remain in `docs/site_libs/` for history compatibility but are not loaded by the new pages; no Quarto rebuild is needed.

## Preview and check

From the repository directory:

```sh
python3 -m http.server 8769 --directory docs --bind 127.0.0.1
```

Open http://127.0.0.1:8769. In another terminal:

```sh
python3 -m unittest discover -s tests -v
```

The homepage links to public project repositories and the approved LinkedIn profile, and uses the U-M contact address. Keep personal contact information and unpublished résumé/CV drafts out of the public repository. Historical manuscripts retain the distinctions between original and revision affiliations. The MATH 463 project credits all three authors.

## Updating content

Edit the HTML and CSS directly. Keep project claims aligned with their linked reports and label simulation limitations. Before publishing, run tests, check desktop and narrow-screen layouts, verify external links, and inspect the author/committer metadata. The Resume & CV tab currently shows a coming-soon status without document links. Add résumé/CV downloads only after the documents have been reviewed and approved for public release.

## Adding a school or passion project

Add another project article to `docs/index.html` using the existing structure: a clear category, project title, short summary, methods, an authentic image with descriptive alt text, and working public links. Credit collaborators and identify prototype limitations where relevant. Add only finished public materials, not placeholders or private repository links. Update `docs/about.html` and this README if the collection changes. The layout automatically stacks project content on narrow screens.
