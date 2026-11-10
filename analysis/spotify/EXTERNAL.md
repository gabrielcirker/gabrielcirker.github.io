# Independent music baselines

This pilot joins the personal export **locally** to public data. The fetcher never reads Spotify files, accepts a username, or sends personal repertoire, listening times, or counts to music APIs.

## Reproduce this published snapshot

Run from the repository root, with R packages `jsonlite` and `dplyr` installed:

```sh
Rscript analysis/spotify/R/external_analysis.R "/path/to/Spotify Account Data" analysis/spotify/reference docs/spotify-title-lab/data/external.json
Rscript analysis/spotify/R/test_external.R
python3 -m unittest discover -s tests -p 'test_spotify_external.py'
```

Only `StreamingHistory_music_0.json` through `_5.json` are read. The private export is not committed. The compact public baseline in `reference/` is enough to recreate the comparison. `manifest.json` records its hashes. Rebuilding changes `generatedAt`, but results remain identical for the same export.

## Refresh the independent baseline

```sh
python3 analysis/spotify/fetch_external.py --refresh
python3 analysis/spotify/fetch_external.py --export-only analysis/spotify/reference
```

The cache defaults to `~/.cache/spotify-external`, outside the repository. Without `--refresh`, completed requests are reused. Fetching uses system curl with TLS verification enabled and a descriptive User-Agent. MusicBrainz calls are sequential with at least 1.1 seconds between requests. HTTP failures are recorded; they do not become fabricated dates or descriptors.

ListenBrainz global monthly top-1000 artist and recording chart endpoints are requested without private query terms. The recording sample is every eighth distinct non-null recording MBID, in global chart order. Selection happens before, and independently of, any personal-history join. Only these public-chart IDs are sent to MusicBrainz and AcousticBrainz. Charts are retrieved as returned, including their actual window and update timestamps; “month” does not guarantee the current month.

## Interpretation

- Personal eligible events have known artist/title and at least 30 seconds played. Raw and excluded event counts are included in the output. No playback duration is treated as track length.
- Community comparison restricts personal events to the exact returned chart interval, treating export timestamps as UTC because the export does not supply a timezone. Both shares are conditional on artists matched in both datasets. Lift is personal share divided by community share, not a population rarity score. Unmatched names are excluded, not assigned zero. ListenBrainz listeners are self-selected and its event collection rules differ from Spotify's export.
- Artist names use lowercase, trimmed and collapsed whitespace only. Accents, punctuation, remix/live suffixes and artist collaborations are preserved. Normalized artist-name chart rows are summed; homonyms may remain.
- Release and sonic analyses use all eligible personal archive events, but only those covered by the independent recording sample. Matches are exact normalized artist + title candidates. Multiple MBIDs for one key within the sampled catalog are excluded. Spotify recording versions remain unverified. Coverage is prominently reported and findings are not extrapolated.
- MusicBrainz `first-release-date` is the earliest documented release of the **matched recording**, not necessarily the original song/composition. Years and decades cover matched events only.
- AcousticBrainz stopped accepting new submissions in 2022. Its available recordings are biased toward older catalog. Sonic PCA standardizes tempo (BPM), mean spectral centroid, and average loudness across matched tracks, with one point per track. At least five tracks and nonzero variance are required. Listening counts do not fit or weight the PCA; they are annotations. The axes describe this sample, not a universal similarity space, mood, emotional state, lyrics or Spotify audio features.

## Sources and licensing

- [ListenBrainz public listening-data terms](https://listenbrainz.org/data/): CC0. Artist and recording chart URL, download time and original SHA-256 are preserved.
- [MusicBrainz database licensing](https://musicbrainz.org/doc/About/Data_License): core recording metadata is CC0. Each sampled lookup URL and retrieval time is preserved.
- [AcousticBrainz](https://acousticbrainz.org/): CC0 descriptors. Only the three numeric PCA features are committed, not large full analysis payloads. Each sampled lookup URL, retrieval time, and missing/error outcome is preserved.

The output is a deliberately selective pilot, not a complete discography enrichment or a representative population study.
