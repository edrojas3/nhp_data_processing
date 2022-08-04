#!/usr/bin/Rscript
#
# USAGE: nhp-chmx_get_group_zvals.R sbcadir outfile
# 
# creates a table with the zvalues obtained from a linear model of the single-subject sbca analysis.
# 
# It also saves a tsv file with a join of all the subject's corrtable files.
# 
# nhp-chmx_get_group_zvals_table.R sbcadir outfile
#
args = commandArgs(T)
# 

library(dplyr)

sbcadir = as.character(args[1])
outdir=as.character(args[2])

dirs = list.dirs(sbcadir, recursive = F, full.names = F)
subs = dirs[grepl("sub", dirs)]

paths = c()
for (s in subs){
  p = paste(sbcadir, s, 'corrtable.tsv', sep = '/')
  paths = append(paths, p)
}

examp_df = read.delim(p)
df_nrow = nrow(df)

print("concatenating corrtables")

corrfiles = lapply(paths, function(f) {read.delim(file = f)})
corr_df = do.call("rbind", lapply(corrfiles, as.data.frame))

corr_df$sub = rep(subs, each = df_nrow)
corr_df$seed = factor(corr_df$seed)

outfile_join = paste(outdir, 'corrtable_join.tsv', sep='/')
write.table(corr_df, outfile_join, sep='\t', row.names=F)

target_names = sort(unique(corr_df$target))
seed_names = sort(unique(corr_df$seed))

print("getting zvalues")
zval = c()
for (tn in target_names) {
  
  targ_df = corr_df %>%
    filter(target == tn)
  
  targ_df$rval_demean = targ_df$rval - mean(targ_df$rval)
  
  model = lm(rval_demean ~ seed, data=targ_df)
  model_sum = summary(model)
  coefs = as.data.frame(model_sum$coefficients)
  zval = append(zval, coefs$`t value`)
}

print("creating data frame")
targets = rep(target_names, each = length(seed_names))
seeds = rep(seed_names, times = length(target_names))

zval_df = data.frame(targets, seeds, zval)

outfile_zval = paste(outdir, 'group_zval_table.tsv', sep='/')
write.table(zval_df, outfile_zval, row.names = F, sep='\t')


