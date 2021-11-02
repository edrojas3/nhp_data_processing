#!/usr/bin/Rscript

args = commandArgs(T)

if (!require(fmsb)){
  install.packages("fmsb") 
}
library(fmsb)

file = as.character(args[1])
outfile=as.character(args[2])

df = read.delim(file)

if (length(args) > 2) {
  target_names = args[3]
} else {
  outdir = args[2]
  target_names=unique(df$target)
}

seed_names = unique(df$seed)
seeds_n=length(seed_names)

for (tn in target_names) {
  
  rvals=df[df$target==tn, 3]
  
  if (length(args)>2) {
    outname = args[2]
  } else {
    outname=paste(paste(outdir, tn, sep='/'), 'png', sep='.')
  }
  
  png(outname)
    spider_df = as.data.frame(matrix(data=c(rvals), nrow=1, byrow = T))
    colnames(spider_df) <- seed_names
  
    spider_df <- rbind(rep(1,seeds_n) , rep(0,seeds_n) , spider_df)
  
    radarchart(spider_df, axistype = 1, cglcol="black", cglty=1, axislabcol="gray", caxislabels=seq(0,0.4,.1), cglwd=0.5,
               vlcex=0.8, title=tn)
  dev.off()
  
}
