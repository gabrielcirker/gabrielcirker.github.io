# Gabriel Cirker · Personal website

**[Visit the homepage](https://gabrielcirker.github.io/)**

A personal, responsive portfolio for school projects, research, and passion projects. The first selected work connects the public rowing, bridge, and MATH 463 projects. The portfolio pages use HTML and CSS with no third-party fonts, tracking, package dependencies, or build step. The Spotify Listening Lab uses static HTML/CSS/JavaScript and public aggregate JSON for interactive experiments. The preserved title-study chapter is a self-contained Quarto HTML document; neither loads external assets or calls third-party APIs in the browser.

## Public projects

- [Rowing energy transfer](https://gabrielcirker.github.io/rowing-research/) · [Repository](https://github.com/gabrielcirker/rowing-research)
- [Bridge geometry comparison](https://gabrielcirker.github.io/bridge-research/) · [Repository](https://github.com/gabrielcirker/bridge-research)
- [MATH 463 immune dynamics](https://gabrielcirker.github.io/math-463-miniproject/) · [Repository](https://github.com/gabrielcirker/math-463-miniproject)

## Side projects

- [Desktop in Stereo](https://gabrielcirker.github.io/desktop-widgets/): a music-led, interactive widget walkthrough. Fictional scenes, original CSS art, vetted short code excerpts, API explanations, and clear native-runtime limitations. No live account integration or private runtime data.

- [Spotify Listening Lab](https://gabrielcirker.github.io/spotify-title-lab/): interactive experiments in song lifecycles, playlist overlap, community comparison, release history, chronological prediction, and acoustic features. The original six-chart title study and 279-word lexicon are preserved. [Reproducible source](analysis/spotify/README.md). The original export and individual listening records are not published.
- [Side Projects](https://gabrielcirker.github.io/side-projects.html): the portfolio entry point for personal experiments.

## Structure

- `docs/index.html`: concise homepage with selected research and creative projects
- `docs/research.html`: full research summaries, source links, collaborator credits, and model limitations
- `docs/about.html`: background and project scope
- `docs/resume.html`: Resume & CV tab with PDF view and download links
- `docs/assets/documents/`: reviewed public resume and CV PDFs
- `docs/side-projects.html`: side-project index with the Spotify project blurb
- `docs/spotify-title-lab/index.html`: interactive Spotify Listening Lab; `title-analysis.html` preserves the original report
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

Edit the HTML and CSS directly. Keep project claims aligned with their linked reports and label simulation limitations. Before publishing, run tests, check desktop and narrow-screen layouts, verify external links, and inspect the author/committer metadata. The Resume & CV tab links to the reviewed and approved public PDFs. Future document replacements also require review and approval for public release; keep editable drafts and private comments out of the repository.

## Adding a school or passion project

Add a research summary to `docs/research.html` and a concise visual card to `docs/index.html`, using the existing structure: a clear category, project title, short summary, methods, an authentic image with descriptive alt text, and working public links. Credit collaborators and identify prototype limitations where relevant. Add only finished public materials, not placeholders or private repository links. Update `docs/about.html` and this README if the collection changes. The layout automatically stacks project content on narrow screens.

## Page navigation and design

Primary navigation links to distinct pages or approved external profiles. Research summaries live on a dedicated Research page; long report contents and widget tools are separately labeled inside their pages. Keep headings concise, allow whitespace between sections, and preserve the versioned stylesheet URL when updating layout. The original Spotify title chapter retains its research prose, six embedded figures, lexicon data and scripts. New listening experiments have separate aggregate data and reproducible source. Original PDFs, the approved portrait, and the standalone widget illustration retain their verified bytes.

The core portfolio uses a persistent outline on the left on wide screens, with the same hierarchy in a native, keyboard-accessible Explore disclosure on smaller screens. All entries open pages or approved external profiles; none are section-jump tabs. Active pages are marked with `aria-current`. The Spotify report and widget walkthrough keep their project-specific navigation and separately labeled in-page tools.

## Standalone project sites

The portfolio is a directory, not a wrapper around the projects. All five projects open at their own directly shareable URLs. Spotify Listening Lab and Desktop in Stereo have project-specific branding and a Copy project link control; their report/walkthrough navigation stays inside the project. The personal portfolio is a secondary author link. The research projects are already independent GitHub Pages sites with their own repositories.

Spotify Listening Lab is served at `/spotify-title-lab/`. The old `/projects/spotify-title-lab/` URL redirects while preserving the query string and section fragment. Keep that compatibility redirect. Neither a new domain nor a separate repository is required to share one of these static project websites. No private source or raw listening records are published.
