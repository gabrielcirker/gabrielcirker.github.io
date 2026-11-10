a<-analysis$audit
stopifnot(a$records==55643,a$known_records==53443,a$distinct_pairs==12622,a$total_ms==9271656050,nrow(analysis$salience)==279,nrow(analysis$drift$vocabulary)==1273,analysis$annotation$counts$changed_pairs==1458,analysis$annotation$counts$changed_records==8030)
p<-analysis$primary
for(w in names(c(i=679,you=741,we=115,not=63,love=389))){r<-p[p$scope=='all'&p$word==w,];stopifnot(r$numerator[r$weighting=='Distinct pairs']==c(i=679,you=741,we=115,not=63,love=389)[[w]],r$numerator[r$weighting=='Listening records']==c(i=3010,you=2765,we=340,not=243,love=1756)[[w]])}
stopifnot(all(p$denominator[p$scope=='at_least_30s'&p$weighting=='Distinct pairs']==11769),all(p$denominator[p$scope=='at_least_30s'&p$weighting=='Listening records']==44091))
d<-analysis$diversity
stopifnot(abs(d$expected_pairs[d$month=='2025-12']-405.2532799510)<1e-6,abs(d$expected_pairs[d$month=='2026-10']-480.9017692196)<1e-6,abs(d$artist_effective_number[d$month=='2025-12']-244.4454070356797)<1e-7,abs(d$artist_effective_number[d$month=='2026-10']-513.1209335622026)<1e-7)
j<-analysis$drift$comparisons
for(m in names(c('2026-01'=.15298997354245558,'2026-02'=.24463431971498936,'2026-05'=.12998220292040108,'2026-10'=.05732193062103465)))stopifnot(abs(j$vocabulary_jsd[j$month==m]-c('2026-01'=.15298997354245558,'2026-02'=.24463431971498936,'2026-05'=.12998220292040108,'2026-10'=.05732193062103465)[[m]])<1e-7)
stopifnot(abs(j$artist_composition_jsd[j$month=='2026-10']-.21850756158275308)<1e-7,abs(j$pair_composition_jsd[j$month=='2026-10']-.5126226667420765)<1e-7)
message('All independent numerical checkpoints passed.')
