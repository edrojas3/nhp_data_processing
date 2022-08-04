library(dplyr)
library(fmsb)

d = '/home/eduardo/mri/data/primeDE/site-ucdavis/sbca'
filename = 'corrtable_join.tsv'
full_file = paste(d, filename, sep='/')
df = read.delim(full_file)
df_copy = df

setwd(d)

df$rval[df$rval > 0.75] = 0.7
M = max(df$rval)
targets = unique(df$target)
seeds = unique(df$seed)
sub = unique(df$sub)

for (targ in targets){
  df_subset = df %>%
    filter(target == targ) %>%
    mutate(rval = abs(rval)) %>%
    select(c('sub', 'seed', 'rval'))
  
  
  df_wide = reshape(df_subset, idvar='sub', timevar='seed', direction='wide')
  colnames(df_wide) <- append(c('sub'), seeds)
  rownames(df_wide)<-df_wide$sub
  df_wide = select(df_wide, -sub)
  
  seeds_n = length(seeds)
  min_val = min(sapply(df_wide, min))
  max_val = max(sapply(df_wide, max))
  av = sapply(df_wide, mean)
  
  spider_df <- as.data.frame(rbind(rep(M,seeds_n),
                                   rep(0,seeds_n),
                                   av,
                                   df_wide))
  
  rownames(spider_df)<-append(c('max', 'min', 'mean'), sub)
  
  
  filename=paste(targ, 'pdf', sep='.')
  pdf(filename)
  opar <- par() 
  # Define settings for plotting in a 5x4 grid, with appropriate margins:
  par(mar = rep(0.8,4))
  par(mfrow = c(5,4))
  # Produce a radar-chart for each student
  for (i in 4:nrow(spider_df)) {
    radarchart(
      spider_df[c(1:3, i), ],
      cglty=1, cglwd=1, cglcol="gray",
      pfcol = c("#99999980",NA),
      pcol= c(NA,2), plty = 1, plwd = 2,
      vlcex = 0.5,
      seg = 4,
      caxislabels = as.character(round(seq(0, M, M/5), 2 )),
      axislabcol = "gray",
      calcex = 10,
      title = row.names(spider_df)[i]
    )
  }
  mtext(targ, side = 3, line = -2, outer = T)
  # Restore the standard par() settings
  
  par <- par(opar)
  dev.off()
  
}
