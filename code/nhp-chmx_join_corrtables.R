#!/usr/bin/Rscript
#
# USAGE: nhp-chmx_join_corrtables.R sbcadir subject_list.txt outfile.tsv
# 
# Creates tsv with the sbca of all subjects in "subjec_list.txt"
# 

#
args = commandArgs(T)

sourcedir = args[1]
subsfile = args[2]
outfile = args[3]

subs = read.delim(subsfile, header=F)

paths = c()
for (s in subs$V1){
  p = paste(sourcedir, s, 'corrtable.tsv', sep = '/')
  paths = append(paths, p)
}

files = lapply(paths, function(f) {read.delim(file = f)})
df = do.call("rbind", lapply(sbca_files, as.data.frame))
df$sub = rep(subs$V1, each = 690)

write_delim(df, outfile)
