# Aggregate-only Spotify research. Run from repository root with Rscript.
suppressPackageStartupMessages(library(jsonlite))
suppressPackageStartupMessages(library(dplyr))
set.seed(343)
key <- function(artist, title) paste(artist, title, sep='\u241f')
classify_lifecycle <- function(n, active, peak, gap) {
  if (n < 10) 'limited evidence' else if (gap >= 28) 'return' else if (active >= 6 && peak <= .35) 'steady' else if (peak >= .60) 'burst' else 'mixed'
}
jaccard <- function(a,b) {u <- union(a,b); if (!length(u)) 0 else length(intersect(a,b))/length(u)}
minute_groups <- function(x) {
  x %>% group_by(time) %>% summarise(artist=if(n_distinct(artistName)==1) first(artistName) else NA_character_, events=n(), .groups='drop') %>% arrange(time)
}
rank_names <- function(x) names(sort(table(x), decreasing=TRUE))
wilson <- function(k,n) {if(!n) return(c(NA_real_,NA_real_)); p<-k/n; z<-1.96; c((p+z*z/(2*n)-z*sqrt(p*(1-p)/n+z*z/(4*n*n)))/(1+z*z/n),(p+z*z/(2*n)+z*sqrt(p*(1-p)/n+z*z/(4*n*n)))/(1+z*z/n))}
predict_rolling <- function(x) {
 g<-minute_groups(x); g$previous<-lag(g$artist); g$gap<-as.numeric(difftime(g$time,lag(g$time),units='mins'))
 # Adjacent groups only: never bridge an ambiguous tied-minute group.
 eligible<-!is.na(g$artist)&!is.na(g$previous)&!is.na(g$gap)&g$gap>0&g$gap<=30
 months<-sort(unique(format(g$time,'%Y-%m'))); cut<-unique(pmax(2,floor(length(months)*c(.5,.65,.8))))
 folds<-list(); scores<-list()
 for(f in seq_along(cut)) {
  start<-cut[f]+1; finish<-if(f<length(cut))cut[f+1] else length(months)
  if(start>finish)next
  train<-format(g$time,'%Y-%m')<=months[cut[f]]; test<-format(g$time,'%Y-%m')%in%months[start:finish]&eligible
  tr<-which(train&eligible); te<-which(test)
  freq<-rank_names(x$artistName[format(x$time,'%Y-%m')<=months[cut[f]]])
  transitions<-split(g$artist[tr],g$previous[tr]); transitions<-lapply(transitions,rank_names)
  # Recency ordering is updated only after a complete minute group is observed.
  recent<-unique(rev(na.omit(g$artist[train]))); hits<-matrix(0,length(te),6); colnames(hits)<-c('frequency1','frequency5','recency1','recency5','transition1','transition5')
  testindices<-which(!train & format(g$time,'%Y-%m')<=months[finish]); row<-0L
  for(i in testindices) {
   if(test[i]) {row<-row+1L; lists<-list(freq,unique(c(recent,freq)),unique(c(transitions[[g$previous[i]]],freq)))
    for(m in 1:3) {p<-head(lists[[m]],5); hits[row,2*m-1]<-as.integer(length(p)>0&&g$artist[i]==p[1]); hits[row,2*m]<-as.integer(g$artist[i]%in%p)}
   }
   if(!is.na(g$artist[i]))recent<-unique(c(g$artist[i],recent))
  }
  models<-lapply(1:3,function(m){k<-sum(hits[,2*m-1]);ci<-wilson(k,length(te));list(model=c('frequency','recency','transition')[m],accuracy=if(length(te))k/length(te)else NA_real_,top5Accuracy=if(length(te))mean(hits[,2*m])else NA_real_,correct=k,top5Correct=sum(hits[,2*m]),testCount=length(te),accuracyInterval=ci)})
  folds[[length(folds)+1]]<-list(fold=f,trainThrough=months[cut[f]],testMonths=months[start:finish],trainingEvents=sum(format(x$time,'%Y-%m')<=months[cut[f]]),trainingTransitions=length(tr),testCount=length(te),unseenTargetCount=sum(!g$artist[te]%in%freq),models=models)
 }
 agg<-lapply(c('frequency','recency','transition'),function(m){rows<-unlist(lapply(folds,function(f)Filter(function(r)r$model==m,f$models)),recursive=FALSE);n<-sum(vapply(rows,function(r)r$testCount,0));k<-sum(vapply(rows,function(r)r$correct,0));k5<-sum(vapply(rows,function(r)r$top5Correct,0));list(model=m,testCount=n,correct=k,top5Correct=k5,accuracy=k/n,top5Accuracy=k5/n,accuracyInterval=wilson(k,n))})
 list(methodology=list(target='Artist of the next adjacent unambiguous qualifying-play minute group, no more than 30 minutes later. Short or unknown-artist rows are excluded before grouping.',split='Three expanding-window monthly training folds, nonoverlapping future test periods. Model counts frozen at each cutoff. Recency context updates after each observed minute group.',frequency='All prior training events ranked by artist frequency.',recency='Most recently observed unambiguous artists, most recent first; training frequency fallback.',transition='Training next-artist counts conditional on current artist; training frequency fallback.',ties='All events with the same minute timestamp form one group. Groups containing multiple artists are ambiguous; exclude transitions into or out of them. Never infer an order within a minute.',uncertainty='Wilson 95% intervals are descriptive only; correlated listening events violate independent-trial assumptions. No statistical superiority claim.',limits='Offline prediction, not causal evidence or a recommendation-quality test. Only qualifying rows of at least 30 seconds with known artists count. Model definitions and thresholds fixed before evaluation; no tuning on any holdout, including final fold. Unseen test artists are retained and count as errors.'),minuteGroups=nrow(g),ambiguousGroups=sum(is.na(g$artist)),eligibleTransitions=sum(eligible),folds=folds,aggregate=agg)
}
run_local <- function(input, output) {
 files<-file.path(input,paste0('StreamingHistory_music_',0:5,'.json')); stopifnot(all(file.exists(files)))
 x<-bind_rows(lapply(files,fromJSON)); stopifnot(all(c('artistName','trackName','endTime','msPlayed')%in%names(x)),all(is.finite(x$msPlayed)),all(x$msPlayed>=0))
 unknownTitle<-is.na(x$trackName)|trimws(x$trackName)==''|tolower(trimws(x$trackName))%in%c('unknown','unknown track','unknown title');unknownTitleEvents<-sum(unknownTitle)
 allEvents<-nrow(x);allMinutes<-sum(x$msPlayed)/60000;zeroDurationEvents<-sum(x$msPlayed==0);shortUnder30Seconds<-sum(x$msPlayed<30000);unknownArtistEvents<-sum(is.na(x$artistName)|trimws(x$artistName)==''|tolower(trimws(x$artistName))=='unknown artist');duplicateExactRows<-sum(duplicated(x[c('endTime','artistName','trackName','msPlayed')]))
 x<-x[!unknownTitle&!is.na(x$artistName)&trimws(x$artistName)!=''&tolower(trimws(x$artistName))!='unknown artist'&x$msPlayed>=30000,]
 x$time<-as.POSIXct(x$endTime,format='%Y-%m-%d %H:%M',tz='UTC');stopifnot(!anyNA(x$time));x<-arrange(x,time)
 x$id<-key(x$artistName,x$trackName);x$month<-format(x$time,'%Y-%m');x$week<-format(as.Date(x$time)-as.integer(format(x$time,'%u'))+1,'%Y-%m-%d')
 months<-sort(unique(x$month));bounds<-range(as.Date(x$time));events<-nrow(x)
 monthly<-x%>%group_by(month)%>%summarise(events=n(),minutes=sum(msPlayed)/60000,.groups='drop')
 weekly<-x%>%group_by(week)%>%summarise(events=n(),minutes=sum(msPlayed)/60000,.groups='drop')
 trackmonthly<-x%>%group_by(id,month)%>%summarise(events=n(),minutes=sum(msPlayed)/60000,.groups='drop')
 tracks<-x%>%group_by(id)%>%summarise(artist=first(artistName),title=first(trackName),events=n(),minutes=sum(msPlayed)/60000,firstMonth=min(month),lastMonth=max(month),activeMonths=n_distinct(month),maxGapDays=max(c(0,diff(sort(unique(as.numeric(as.Date(time))))))),.groups='drop')
 tracks$maxGapDays[!is.finite(tracks$maxGapDays)]<-0
 peak<-trackmonthly%>%group_by(id)%>%summarise(peakMonthShare=max(events)/sum(events),.groups='drop');tracks<-left_join(tracks,peak,by='id')
 tracks$label<-mapply(classify_lifecycle,tracks$events,tracks$activeMonths,tracks$peakMonthShare,tracks$maxGapDays)
 tracks$steadyPattern<-tracks$events>=10&tracks$activeMonths>=6&tracks$peakMonthShare<=.35
 tracks$returnPattern<-tracks$events>=10&tracks$maxGapDays>=28
 tracks$burstPattern<-tracks$events>=10&tracks$peakMonthShare>=.60
 tracks$leftBoundary<-tracks$firstMonth==min(months);tracks$rightBoundary<-tracks$lastMonth==max(months);tracks<-arrange(tracks,desc(events),artist,title)
 tracks$id<-match(tracks$id,unique(x$id));idmap<-setNames(tracks$id,key(tracks$artist,tracks$title));trackmonthly$id<-unname(idmap[trackmonthly$id])
 artists<-x%>%group_by(artist=artistName)%>%summarise(events=n(),minutes=sum(msPlayed)/60000,tracks=n_distinct(trackName),activeMonths=n_distinct(month),.groups='drop')%>%arrange(desc(events))
 artistmonthly<-x%>%group_by(artist=artistName,month)%>%summarise(events=n(),minutes=sum(msPlayed)/60000,.groups='drop')
 playlists<-unlist(lapply(file.path(input,paste0('Playlist',1:5,'.json')),function(f)fromJSON(f,simplifyVector=FALSE)$playlists),recursive=FALSE)
 catalog<-list();sets<-list();nodes<-list()
 for(i in seq_along(playlists)){
  rows<-lapply(playlists[[i]]$items,function(z){t<-z$track;if(is.null(t)||is.null(t$trackUri))return(NULL);data.frame(artist=t$artistName,title=t$trackName,uri=t$trackUri)})
  r<-bind_rows(rows); if(!nrow(r))r<-data.frame(artist=character(),title=character(),uri=character())
  catalog[[i]]<-r;sets[[i]]<-unique(r$uri);nodes[[i]]<-list(id=sprintf('p%03d',i),label=sprintf('Playlist %03d',i),tracks=length(sets[[i]]),items=nrow(r))
 }
 lib<-fromJSON(file.path(input,'YourLibrary.json'))$tracks
 catalog<-bind_rows(catalog,data.frame(artist=lib$artist,title=lib$track,uri=lib$uri))%>%distinct()
 catalog$key<-key(catalog$artist,catalog$title);mapping<-split(catalog$uri,catalog$key);mapping<-lapply(mapping,unique)
 matches<-vapply(unique(x$id),function(k)length(mapping[[k]]),0L);eventmatches<-matches[match(x$id,unique(x$id))]
 edges<-list()
 if(length(sets)>1)for(i in 1:(length(sets)-1))for(j in (i+1):length(sets)){
  shared<-intersect(sets[[i]],sets[[j]]);if(!length(shared))next
  ex<-catalog[match(head(shared,5),catalog$uri),c('artist','title','uri')]
  edges[[length(edges)+1]]<-list(source=nodes[[i]]$id,target=nodes[[j]]$id,shared=length(shared),jaccard=jaccard(sets[[i]],sets[[j]]),examples=ex)
 }
 matching<-list(method='Exact case-sensitive artist + title, no normalization or fuzzy matching. URI candidates from playlist and saved-library snapshot, not historical identity proof.',uniqueHistoryTracks=length(matches),unambiguousTracks=sum(matches==1),ambiguousTracks=sum(matches>1),unmatchedTracks=sum(matches==0),unambiguousTrackShare=mean(matches==1),unambiguousEvents=sum(eventmatches==1),ambiguousEvents=sum(eventmatches>1),unmatchedEvents=sum(eventmatches==0),unambiguousEventShare=mean(eventmatches==1))
 tracks$uriMatchCount<-vapply(key(tracks$artist,tracks$title),function(k)length(mapping[[k]]),0L)
 tracks$uri<-vapply(key(tracks$artist,tracks$title),function(k){v<-mapping[[k]];if(length(v)==1)v else NA_character_},'')
 lifecycleCounts<-as.data.frame(table(tracks$label),stringsAsFactors=FALSE);names(lifecycleCounts)<-c('label','count')
 outputdata<-list(schemaVersion=1,summary=list(allEvents=allEvents,allMinutes=allMinutes,unknownArtistEvents=unknownArtistEvents,unknownTitleEvents=unknownTitleEvents,qualifyingEvents=events,events=events,minutes=sum(x$msPlayed)/60000,tracks=nrow(tracks),artists=nrow(artists),months=months,zeroDurationEvents=zeroDurationEvents,shortUnder30Seconds=shortUnder30Seconds,duplicateExactRows=duplicateExactRows),methodology=list(seed=343,inputs='Six StreamingHistory_music files, five Playlist files, YourLibrary.json only.',counting='Primary analyses use rows with msPlayed >= 30000 and known nonblank artist and title. All-row counts retained for context. 30-second duration is time recorded within a row, not completion or skip probability. Exact duplicate-looking qualifying rows retained because minute precision cannot establish duplication. Track identity is artist + title, not verified recording identity.',time='Export has minute-resolution end times and no explicit timezone offset. Parsed in UTC only for consistent arithmetic; timezone is not claimed.',privacy='Only aggregates, monthly/week trajectories, track and artist labels, and music URI examples published. Playlist labels anonymized; no raw event timestamps.',limits='This is a bounded observation window, not lifetime listening. First observed does not mean discovered. Playlist snapshot is not playlist listening attribution. No audio, mood, lyrical sentiment, or causality inferred from metadata.'),trajectories=list(monthly=monthly,weekly=weekly),artists=artists,artistMonthly=artistmonthly,lifecycle=list(rules=list(traits='Independent steadyPattern (6+ active months and peak share <=35%), returnPattern (28+ day gap), and burstPattern (peak share >=60%) overlap; all require 10+ events. Primary labels retain the explicit precedence below. A steady track can also return after a gap.',minimumEvents=10,precedence=c('limited evidence','return','steady','burst','mixed'),return='At least 10 events and an observed gap of at least 28 days between plays.',steady='At least 10 events, activity in at least 6 calendar months, no month over 35% of events, and no return gap.',burst='At least 10 events, 60% or more in one calendar month, and neither return nor steady.',censoring='All histories are left- and right-censored. Boundary flags indicate activity in the first/last export month; even unflagged tracks may have earlier/later listening. Partial boundary months may affect class. First month is first observed, never discovery.'),counts=lifecycleCounts,traitCounts=list(steady=sum(tracks$steadyPattern),returning=sum(tracks$returnPattern),burst=sum(tracks$burstPattern),steadyAndReturning=sum(tracks$steadyPattern&tracks$returnPattern)),tracks=tracks,monthly=trackmonthly),playlists=list(nodes=nodes,edges=edges,matching=matching,methodology='One node per exported playlist snapshot entry. Unique Spotify track URIs define sets; duplicate items do not increase overlap. All nonzero-overlap edges retained. Jaccard = intersection / union. Names are anonymized. Snapshot does not show which playlist generated a listening event.'),prediction=predict_rolling(x))
 stopifnot(sum(monthly$events)==events,sum(tracks$events)==events,sum(artists$events)==events,matching$unambiguousEvents+matching$ambiguousEvents+matching$unmatchedEvents==events)
 dir.create(dirname(output),recursive=TRUE,showWarnings=FALSE);write_json(outputdata,output,auto_unbox=TRUE,pretty=FALSE,digits=8,na='null')
 cat('Wrote',output,'with',events,'events,',nrow(tracks),'tracks,',length(nodes),'playlist nodes and',length(edges),'edges\n')
 invisible(outputdata)
}
if(sys.nframe()==0){args<-commandArgs(trailingOnly=TRUE);input<-if(length(args))args[1]else file.path(path.expand('~'),'Downloads','Spotify Account Data');output<-if(length(args)>1)args[2]else 'docs/spotify-title-lab/data/local.json';run_local(input,output)}
