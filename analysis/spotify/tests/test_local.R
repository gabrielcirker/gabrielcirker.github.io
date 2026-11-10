source('analysis/spotify/R/local_analysis.R')
stopifnot(classify_lifecycle(9,1,1,0)=='limited evidence',classify_lifecycle(20,6,.2,30)=='return',classify_lifecycle(20,6,.2,7)=='steady',classify_lifecycle(20,2,.7,7)=='burst',classify_lifecycle(20,3,.4,7)=='mixed')
stopifnot(jaccard(c('a','a','b'),c('b','c'))==1/3,jaccard(character(),character())==0)
f<-data.frame(time=as.POSIXct(c('2026-01-01 12:00','2026-01-01 12:00','2026-01-01 12:01','2026-01-01 12:02'),tz='UTC'),artistName=c('A','B','C','C'))
g<-minute_groups(f);stopifnot(nrow(g)==3,is.na(g$artist[1]),g$artist[2]=='C')
# Reordering tied events must never change grouping or predictions.
stopifnot(identical(minute_groups(f),minute_groups(f[c(2,1,3,4),])))
f<-data.frame(time=as.POSIXct(paste0('2026-',sprintf('%02d',rep(1:10,each=4)),'-02 12:',sprintf('%02d',rep(0:3,10))),tz='UTC'),artistName=rep(c('A','B','A','B'),10))
p<-predict_rolling(f);stopifnot(length(p$folds)==3,all(vapply(p$aggregate,function(z)z$testCount,0)==15),all(vapply(p$aggregate,function(z)z$accuracy>=0&&z$accuracy<=1,TRUE)))
# Future unseen artist remains an error instead of silently removing the case.
f$artistName[40]<-'UNSEEN';p2<-predict_rolling(f);stopifnot(p2$folds[[3]]$unseenTargetCount==1)
cat('Local analysis fixture tests passed\n')
stopifnot(identical(p$folds[1:2],p2$folds[1:2])) # Future edits cannot affect earlier folds.
stopifnot(classify_lifecycle(10,1,.60,0)=='burst',classify_lifecycle(10,6,.35,27)=='steady',classify_lifecycle(10,1,1,28)=='return')
cat('Threshold and chronological leakage fixtures passed\n')
