#!/usr/bin/Rscript

# spiderplots_from_corrtable.R file.tsv outdir 
args = commandArgs(T)

if (!require(fmsb)){
  install.packages("fmsb") 
}
library(fmsb)

print('reading file')
file = as.character(args[1])
outfile=as.character(args[2])

file = "/home/eduardo/mri/tezca/data/primeDE/site-ucdavis/sbca/sub-032126/corrtable.tsv"

df = read.delim(file)

if (length(args) > 2) {
  target_names = args[3]
} else {
  outdir = args[2]
  target_names=sort(unique(df$target))
}

df[,3] = abs(df[,3])

seed_names = sort(unique(df$seed))
# seeds_n=length(seed_names)

print('starting spider plots')
for (tn in target_names) {
  
  print(tn)
  targ_subset = df[df$target == tn,]
  min_val = min(targ_subset[,3])
  max_val = max(targ_subset[,3])
  
  if (length(args)>2) {
    outname = args[2]
  } else {
    outname=paste(paste(outdir, tn, sep='/'), 'png', sep='.')
  }
  
  png(outname)
  seeds_n = length(unique(targ_subset$seed))
  
  print('creating dataframe for radarchart')
  spider_df <- as.data.frame(rbind(rep(max_val,seeds_n),
                     rep(0,seeds_n),
                     targ_subset[,3]))
  
  colnames(spider_df)<-unique(targ_subset$seed)
  
  print('radarchart')
  radarchart(spider_df, axistype = 1, 
             cglcol="black", 
             cglty=1, 
             axislabcol="gray",
             caxislabels=round(seq(0, max_val, max_val/4), digits=2),
             cglwd=0.5,
             vlcex=0.8,
             title=tn)
  dev.off()
  
}
print('done')
