# Spotify Listening Lab

A reproducible expansion of Spotify Title Lab: community comparisons, song lifecycles, playlist overlap, recording release history, chronological prediction, and an acoustic-data coverage experiment.

[Explore the public lab](https://gabrielcirker.github.io/spotify-title-lab/) · [Read the original title study](https://gabrielcirker.github.io/spotify-title-lab/title-analysis.html)

## Inputs and publication boundaries

The personal input is an ordinary Spotify account export, not lifetime history. The supplied music window runs from November 5, 2025 to November 5, 2026. Only the six numbered music-history files, five playlist files and saved-library file are needed. Account, address, payment, message, search, inference and podcast files are not used.

The public site contains aggregate listening measures, song/artist names, anonymized playlist labels, and public catalog reference data. It does not contain the original export, individual event rows, exact listening timestamps, playlist titles, account identifiers or credentials. Files under `cache/`, `private/`, and the original title pipeline's generated data directories are ignored. Keep private exports outside this repository.

The endTime strings have minute resolution but no timezone offset. Timestamp parsing uses a fixed arithmetic clock; this does not verify the export's real timezone. Equal rows are retained because separate listening events may have equal exported values. An artist/title pair is not a unique recording ID.

## Run local analyses

Requirements: R, jsonlite and dplyr. Dependencies are never installed automatically.

From the repository root:

```sh
Rscript --vanilla analysis/spotify/tests/test_local.R
Rscript --vanilla analysis/spotify/R/local_analysis.R "/path/to/Spotify Account Data" docs/spotify-title-lab/data/local.json
```

The primary analysis keeps known artist/title records with at least 30 seconds played. That is a reproducible inclusion rule, not a completed-track or skip classifier. Audit totals retain the full export count and exclusions.

- Lifecycles: monthly counts, first/last observed month, long return gaps, concentration, active months and overlapping descriptive traits. First observed is not first discovery. Boundary months are partial, and tracks outside the observed window may have very different histories.
- Playlist graph: distinct Spotify URI sets and Jaccard overlap. Duplicate occurrences within one playlist do not increase overlap. Edges are undirected. Snapshot membership cannot identify which playlist produced any listening event. Artist/title-to-URI matching explicitly separates unique, ambiguous and unmatched candidates.
- Prediction: three expanding chronological training windows and disjoint future holdouts. Frequency and transition counts are frozen at each cutoff; recency context updates only after a minute group has occurred. Ambiguous multi-artist minute groups and transitions across them are excluded. Predictions target the next unambiguous group within 30 minutes. The experiment includes a repeat/recency baseline, not only a more complex model. No playlist snapshot or later count is used for earlier predictions.

The output JSON contains configuration, coverage, definitions, test periods and results for the browser. Aggregate top-1/top-5 scores are weighted by test-target counts. Any Wilson intervals are descriptive; correlated musical sequences are not independent binomial trials.

See [the external-data reproduction guide](EXTERNAL.md) for the exact snapshot rebuild and refresh commands.

## Public comparison sources

`fetch_external.py` accepts no private-history argument. It downloads a broad independent ListenBrainz chart and a deterministic recording sample before any personal-data join. It uses rate-limited MusicBrainz and AcousticBrainz lookups on public recording IDs only. Private counts, timestamps, usernames and repertoire are not uploaded to any service.

- [ListenBrainz](https://listenbrainz.org/data/): CC0 listening data from its contributors, not a representative sample of Spotify users or the world. The API's returned window, not the word “month” in its URL, defines the baseline.
- [MusicBrainz](https://musicbrainz.org/doc/MusicBrainz_Database): core recording identifiers and release metadata, CC0. Earliest documented release of a matched recording is not necessarily the song's composition date or first recording.
- [AcousticBrainz](https://acousticbrainz.org/download): historical algorithmic audio features, CC0; collection stopped in 2022. Matching and historical coverage govern what can be compared. Features are not a measure of the listener's mood.

The external module's committed reference extract and JSON provenance document its actual sample and coverage. Missing data remain missing; a small matched sample must not be presented as a portrait of the full collection.

## Original title analysis

The original report is preserved. Its R functions, config, fixtures and numerical reference assertions are under `title-analysis/`. This chapter has its own original all-known-records estimand, with the 30-second threshold as sensitivity analysis, rather than silently adopting the new modules' primary filter.

```sh
cd analysis/spotify/title-analysis
Rscript prepare_local_input.R "/path/to/Spotify Account Data"
Rscript --vanilla -e 'source("run_analysis.R"); source("validate_reference.R"); source("publication_plots.R")'
```

This requires the original tidyverse-related packages listed in `R/functions.R`. The reference assertions intentionally target the supplied export. The report's historical field name `end_month_utc` is retained for compatibility; it should be understood as exported calendar month, not an independently verified timezone.

## Site and tests

The frontend is static HTML/CSS/JavaScript, with no CDN, tracker, font service or API call from the browser. It reads the committed aggregate JSON. The original chapter keeps its six embedded figures and local searchable lexicon.

```sh
python3 -m unittest discover -s tests -v
python3 -m http.server 8769 --directory docs --bind 127.0.0.1
```

GitHub Pages publishes `docs/` on `main`. Inspect all staged files for raw exports and secrets before publishing. Analysis dates and source windows explain the data; decorative publication dates are omitted.
