# Usage: Rscript prepare_local_input.R /path/to/extracted/Spotify\ Account\ Data
args<-commandArgs(trailingOnly=TRUE)
if(length(args)!=1L)stop('Supply the folder containing StreamingHistory_music_0.json through _5.json')
if(!requireNamespace('jsonlite',quietly=TRUE)||!requireNamespace('readr',quietly=TRUE))stop('jsonlite and readr are required')
files<-file.path(args[1],paste0('StreamingHistory_music_',0:5,'.json'))
if(!all(file.exists(files)))stop('Six expected music-history files not found')
x<-do.call(rbind,lapply(files,function(p){r<-jsonlite::fromJSON(p);data.frame(end_month_utc=substr(r$endTime,1,7),artist=r$artistName,title=r$trackName,ms_played=r$msPlayed)}))
dir.create('data',showWarnings=FALSE);readr::write_csv(x,'data/music_history_minimal.csv')
message('Wrote minimized music history only; repeated rows retained.')
