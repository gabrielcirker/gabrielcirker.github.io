source('analysis/spotify/R/external_analysis.R')
stopifnot(identical(normalize_name(c('  Radiohead ','A   B','Song - Live')),c('radiohead','a b','song - live')))
stopifnot(isTRUE(all.equal(share_lift(c(2,2),c(1,3)),c(2,2/3))))
stopifnot(normalize_name('Song - Live') != normalize_name('Song'))
cat('External R helper checks passed\n')

candidates <- data.frame(artistKey=c('a','a','b'),trackKey=c('song','song','other'),mbid=c('1','2','3'))
stopifnot(nrow(unique_candidate_keys(candidates))==1,unique_candidate_keys(candidates)$artistKey=='b')
