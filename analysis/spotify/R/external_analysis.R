#!/usr/bin/env Rscript
# Public data is fetched independently by fetch_external.py. This module is offline.
suppressPackageStartupMessages({library(jsonlite);library(dplyr)})
normalize_name <- function(x) tolower(trimws(gsub('[[:space:]]+', ' ', x)))
unique_candidate_keys <- function(candidates) candidates %>% group_by(artistKey,trackKey) %>% summarise(candidates=n_distinct(mbid),.groups='drop') %>% filter(candidates==1) %>% select(artistKey,trackKey)
share_lift <- function(user, community) (user / sum(user)) / (community / sum(community))
run_external <- function(input, cache, output) {
 files <- file.path(input,paste0('StreamingHistory_music_',0:5,'.json'))
 stopifnot(all(file.exists(files)))
 raw <- bind_rows(lapply(files,fromJSON))
 h <- raw %>% filter(msPlayed>=30000,!is.na(artistName),!is.na(trackName),trimws(artistName)!='',trimws(trackName)!='', tolower(trimws(artistName))!='unknown artist', !tolower(trimws(trackName)) %in% c('unknown track','unknown','unknown title'))
 h <- h %>% mutate(artistKey=normalize_name(artistName),trackKey=normalize_name(trackName))
 chart <- fromJSON(file.path(cache,'artists.json'))$payload
 eventTime <- as.POSIXct(h$endTime,format='%Y-%m-%d %H:%M',tz='UTC')
 window_h <- h[as.numeric(eventTime)>=chart$from_ts & as.numeric(eventTime)<chart$to_ts,]
 artists <- window_h %>% group_by(artistKey) %>% summarise(artist=first(artistName),userPlays=n(),.groups='drop')
 tracks <- h %>% group_by(artistKey,trackKey) %>% summarise(artist=first(artistName),track=first(trackName),plays=n(),.groups='drop')
 chart <- fromJSON(file.path(cache,'artists.json'))$payload
 community <- chart$artists %>% mutate(artistKey=normalize_name(artist_name)) %>% group_by(artistKey) %>% summarise(communityPlays=sum(listen_count),.groups='drop')
 matched <- inner_join(artists,community,by='artistKey') %>% mutate(userShare=userPlays/sum(userPlays),communityShare=communityPlays/sum(communityPlays),lift=share_lift(userPlays,communityPlays),matchConfidence='Normalized exact artist name; homonyms remain possible') %>% arrange(desc(userPlays))
 enrichment <- fromJSON(file.path(cache,'enrichment.json'),simplifyVector=FALSE)
 release_catalog <- list(); sonic_catalog <- list()
 candidates <- bind_rows(lapply(enrichment$rows,function(r) data.frame(artistKey=normalize_name(r$recording$artist_name),trackKey=normalize_name(r$recording$track_name),mbid=r$recording$recording_mbid)))
 unique_keys <- unique_candidate_keys(candidates)
 for (r in enrichment$rows) {
  rec <- r$recording; mb <- r$musicbrainz; ac <- r$acousticbrainz
  key <- paste(normalize_name(rec$artist_name),normalize_name(rec$track_name),sep='\t')
  date <- mb[['first-release-date']]
  if (!is.null(date) && grepl('^[0-9]{4}',date)) release_catalog[[length(release_catalog)+1]] <- data.frame(artistKey=normalize_name(rec$artist_name),trackKey=normalize_name(rec$track_name),firstReleaseDate=date,year=as.integer(substr(date,1,4)),mbid=rec$recording_mbid)
  # Audio descriptors only, not mood, lyrics or inferred mental state.
  bpm <- ac$rhythm$bpm; centroid <- ac$lowlevel$spectral_centroid$mean; loudness <- ac$lowlevel$average_loudness
  if (all(vapply(list(bpm,centroid,loudness),function(x) is.numeric(x)&&length(x)==1&&is.finite(x),logical(1)))) sonic_catalog[[length(sonic_catalog)+1]] <- data.frame(artistKey=normalize_name(rec$artist_name),trackKey=normalize_name(rec$track_name),mbid=rec$recording_mbid,bpm=bpm,spectralCentroid=centroid,averageLoudness=loudness)
 }
 rel <- if(length(release_catalog)) bind_rows(release_catalog) else data.frame(artistKey=character(),trackKey=character(),firstReleaseDate=character(),year=integer(),mbid=character())
 # Exclude ambiguous normalized keys with multiple recording MBIDs rather than guess versions.
 rel <- semi_join(rel,unique_keys,by=c('artistKey','trackKey')) %>% group_by(artistKey,trackKey) %>% filter(n_distinct(mbid)==1) %>% ungroup() %>% distinct(artistKey,trackKey,.keep_all=TRUE)
 rel <- inner_join(tracks,rel,by=c('artistKey','trackKey')) %>% mutate(matchConfidence='Normalized exact artist + title; recording version unverified') %>% arrange(desc(plays))
 decades <- rel %>% mutate(decade=paste0(floor(year/10)*10,'s')) %>% group_by(decade) %>% summarise(plays=sum(plays),tracks=n(),.groups='drop')
 sonic <- if(length(sonic_catalog)) bind_rows(sonic_catalog) else data.frame(artistKey=character(),trackKey=character(),mbid=character(),bpm=double(),spectralCentroid=double(),averageLoudness=double())
 sonic <- semi_join(sonic,unique_keys,by=c('artistKey','trackKey')) %>% group_by(artistKey,trackKey) %>% filter(n_distinct(mbid)==1) %>% ungroup() %>% distinct(artistKey,trackKey,.keep_all=TRUE)
 sonic <- inner_join(tracks,sonic,by=c('artistKey','trackKey'))
 acoustic_status <- if(nrow(sonic)) 'descriptors_only' else 'no_matched_audio'
 pca <- NULL
 if(nrow(sonic)>=5 && all(vapply(sonic[c('bpm','spectralCentroid','averageLoudness')],sd,double(1))>0)) {
  fit <- prcomp(sonic[c('bpm','spectralCentroid','averageLoudness')],center=TRUE,scale.=TRUE)
  sonic$x <- fit$x[,1];sonic$y <- fit$x[,2];pca <- list(varianceExplained=unname(fit$sdev[1:2]^2/sum(fit$sdev^2)),features=rownames(fit$rotation),loadings=unname(fit$rotation[,1:2]));acoustic_status <- 'available'
 }
 coverage <- function(rows) list(matchedTracks=nrow(rows),totalTracks=nrow(tracks),matchedPlays=sum(rows$plays),totalPlays=nrow(h),playPercent=100*sum(rows$plays)/nrow(h))
 public_rows <- function(rows) if(nrow(rows)) select(rows,-any_of(c('artistKey','trackKey'))) else list()
 result <- list(schemaVersion=1,filters=list(minimumMs=30000,rawEvents=nrow(raw),eligibleEvents=nrow(h),excludedEvents=nrow(raw)-nrow(h),communityWindowEvents=nrow(window_h),timestampConvention='Export timestamps treated as UTC; Spotify export does not state timezone'),generatedAt=format(Sys.time(),'%Y-%m-%dT%H:%M:%SZ',tz='UTC'),sources=c(enrichment$sources,list(list(name='MusicBrainz recording catalog',url='https://musicbrainz.org/doc/Recording',license='CC0 core data',retrievedAt=enrichment$rows[[1]]$retrievedAt),list(name='AcousticBrainz audio descriptors',url='https://acousticbrainz.org/',license='CC0',retrievedAt=enrichment$rows[[1]]$retrievedAt))),
 community=list(status='available',window=list(from=format(as.POSIXct(chart$from_ts,origin='1970-01-01',tz='UTC'),'%Y-%m-%d'),to=format(as.POSIXct(chart$to_ts,origin='1970-01-01',tz='UTC'),'%Y-%m-%d')),coverage=list(matchedArtists=nrow(matched),totalArtists=nrow(artists),matchedPlays=sum(matched$userPlays),totalPlays=nrow(window_h),playPercent=100*sum(matched$userPlays)/nrow(window_h)),rows=public_rows(matched),caveats=c('Shares and lift use only artists present in both datasets. Unmatched artists are excluded, not treated as zero.','ListenBrainz is a self-selected community, not all music listeners or Spotify. Personal and community events use the same returned monthly window, interpreted as UTC (export timezone unspecified).','Top-1000 chart truncation and normalized exact-name matching affect coverage; duplicate name rows are summed and homonyms may remain.','Personal plays count known artist/title events of at least 30 seconds; ListenBrainz community counting rules can differ.')),
 releases=list(status=if(nrow(rel)) 'available' else 'no_matches',coverage=coverage(rel),rows=public_rows(rel),decades=if(nrow(decades)) decades else list(),sampleSize=length(enrichment$rows),catalogDatesAvailable=length(release_catalog),sampleRule=enrichment$sampleRule,caveats=c('Pilot uses an independent chart sample, not the full personal catalog. Coverage is selective and not representative.','MusicBrainz first-release-date is the earliest cataloged release of this recording, not necessarily the original composition or first performance.','Exact artist/title matching cannot verify Spotify recording versions. Decades describe matched events only. Coverage denominators count normalized artist/title pairs, which can merge whitespace/case variants.')),
 acoustic=list(status=acoustic_status,coverage=coverage(sonic),rows=public_rows(sonic),pca=pca,sampleSize=length(enrichment$rows),descriptorsAvailable=length(sonic_catalog),caveats=c('Normalized exact artist/title is only a recording candidate; Spotify recording versions are unverified. Coverage denominators count normalized artist/title pairs, which can merge whitespace/case variants.','AcousticBrainz stopped accepting submissions in 2022; many newer recordings have no analysis.','Only matched recordings with finite tempo, spectral centroid and average loudness are included. These descriptors are not emotional-state measurements.','PCA uses standardized descriptors and requires at least five matched tracks. Axes are relative to this small sample, not universal sonic traits.')))
 dir.create(dirname(output),recursive=TRUE,showWarnings=FALSE)
 write_json(result,output,pretty=TRUE,auto_unbox=TRUE,na='null',digits=12)
 invisible(result)
}
if(sys.nframe()==0) {
 args <- commandArgs(trailingOnly=TRUE)
 if(length(args)!=3) stop('Usage: Rscript external_analysis.R EXPORT_DIRECTORY PUBLIC_CACHE OUTPUT_JSON')
 run_external(args[1],args[2],args[3])
}
