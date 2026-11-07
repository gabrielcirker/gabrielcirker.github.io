# Gabriel Cirker · Personal website

**[Visit the homepage](https://gabrielcirker.github.io/)**

A small, responsive portfolio connecting the public rowing, bridge, and MATH 463 research projects. It is built with HTML and CSS, with no JavaScript, third-party fonts, tracking, package dependencies, or build step.

## Public projects

- [Rowing energy transfer](https://gabrielcirker.github.io/rowing-research/) · [Repository](https://github.com/gabrielcirker/rowing-research)
- [Bridge geometry comparison](https://gabrielcirker.github.io/bridge-research/) · [Repository](https://github.com/gabrielcirker/bridge-research)
- [MATH 463 immune dynamics](https://gabrielcirker.github.io/math-463-miniproject/) · [Repository](https://github.com/gabrielcirker/math-463-miniproject)

## Structure

- `docs/index.html`: homepage and selected projects
- `docs/about.html`: background and project scope
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

The homepage links only to public project repositories and uses the U-M contact address. Keep personal contact information and unpublished résumé/CV drafts out of the public repository. Historical manuscripts retain the distinctions between original and revision affiliations. The MATH 463 project credits all three authors.

## Updating content

Edit the HTML and CSS directly. Keep project claims aligned with their linked reports and label simulation limitations. Before publishing, run tests, check desktop and narrow-screen layouts, verify external links, and inspect the author/committer metadata. Add résumé/CV links only after the documents have been reviewed and approved for public release.
