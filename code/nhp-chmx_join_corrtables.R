#!/usr/bin/Rscript
#
# USAGE: nhp-chmx_join_corrtables.R sbcadir subject_list.txt outfile.tsv
# 
# Creates tsv with the sbca of all subjects in "subject_list.txt"
# 

# INPUTS
args = commandArgs(T)

sourcedir = args[1]
subsfile = args[2]
outfile = args[3]

# SUBJECTS
subs = read.delim(subsfile, header=F)

# PATHS TO CORRTABLE FILES
paths = c()
for (s in subs$V1){
  p = paste(sourcedir, s, 'corrtable.tsv', sep = '/')
  paths = append(paths, p)
}

# EXAMPLE DATAFRAME TO KNOW HOW MANY DATA THERE IS PER SUBJECT
examp_df = read.delim(p)
n = nrow(examp_df)

# JOIN FILES
files = lapply(paths, function(f) {read.delim(file = f)})
df = do.call("rbind", lapply(files, as.data.frame))
df$sub = rep(subs$V1, each = n)

# SAVE OUTPUT
write.table(df, file=outfile, sep = "\t")
