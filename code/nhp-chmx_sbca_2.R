##### LIBRARIES
library(tidyverse)
library(ggradar)
library(reshape2)
##### READ INPUT ARGUMENTS FROM COMMAND LINE

# args <- commandArgs(T)
# 
# site = args[1]
site = "~/mri/alfonso/primates/monkeys/data/site-oxford"
if (length(args) == 2) {
  sbcadir = args[2]
} else {
  sbcadir = paste(site, 'sbca', sep = '/')
}

##### JOIN CORRTABLES OF EACH SUBJECT IN ONE DATA FRAME
subs = list.files(sbcadir)

paths = c()
for (s in subs){
  p = paste(sbcadir, s, 'corrtable.tsv', sep = '/')
  paths = append(paths, p)
}

sbca_files = lapply(paths, function(f) {read.delim(file = f)})
sbca_df = do.call("rbind", lapply(sbca_files, as.data.frame))

targets = unique(sbca_df$target)
ntargets = length(targets)
seeds = unique(sbca_df$seed)
nseeds = length(seeds) 
sbca_df$sub = rep(subs, each = ntargets*nseeds)

#### LINEAR MODEL PER TARGET
stat = c()
beta = c()
for (t in targets){
  sbca_subset = sbca_df %>%
    filter(target == t)
  linmod = lm(rval ~ seed, sbca_subset)
  lm_sum = summary(linmod)
  stat = append(stat, lm_sum$coefficients[,3])
  beta = append(beta, lm_sum$coefficients[,1])
}

seeds_sorted = sort(seeds[1:17])
nseeds=length(seeds_sorted)
lm_df = data.frame(rep(targets, each = nseeds),
                   rep(seeds_sorted, times = ntargets),
                   beta,
                   stat)
colnames(lm_df)<-c("target", "seed", "beta", "stat")