#!/usr/bin/Rscript
#
# SBCA group level analysis
# USAGE: nhp-chmx_sbca2.R <site> [sbcadir] [outdir]
#
# This script:
# 1. joins the corrtable.tsv of each subject in the sbcadir
# 2. creates a linearmodel to see at group level the relation between seed and target; in other words calculates beta values
# 3. creates and saves a spiderplot per target. In each plot the vertices of the polygon represent the betas for each seed (excentricity equals greater beta value). Both hemispheres are plotted in the same spiderplot.
# 4. text files for the joined corrtables, and linear models are saved in outdir.

##### LIBRARIES
library(tidyverse)
library(reshape2)

if(!require(ggradar)){
  install.packages("ggradar")  
}
library(ggradar)

##### READ INPUT ARGUMENTS FROM COMMAND LINE

args <- commandArgs(T)

# Mandatory arguments
site = args[1]

# Optional arguments and their defaults
if (length(args) == 2) {
  sbcadir = args[2]
} else {
  sbcadir = paste(site, 'sbca', sep = '/')
}

if (length(args) == 3) {
  outdir = args[3]
} else {
  outdir = paste(site, 'sbca_2', sep = '/')
}

# Check that sbca dir exists, exit if not
if (!dir.exists(sbcadir)) {
  print("sbca directory not found.")
  exit()
}

# Create outdir if needed
if (!dir.exists(outdir)) {
  dir.create(outdir)
}

##### JOIN CORRTABLES OF EACH SUBJECT IN ONE DATA FRAME
print("Joining corrtables")

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

sbca_df_fname = paste(site, outdir, "sbca_all_subjects.tsv", sep="/")
write_tsv(sbca_df, file=sbca_df_name)

#### LINEAR MODEL PER TARGET
print("Calculating betas")
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

stat = stat[names(stat) != "(Intercept)"]
beta = beta[names(beta) != "(Intercept)"]

seeds_sorted = sort(seeds[1:17])
nseeds=length(seeds_sorted)
lm_df = data.frame(rep(targets, each = nseeds),
                   rep(seeds_sorted, times = ntargets),
                   beta,
                   stat)
colnames(lm_df)<-c("target", "seed", "beta", "stat")

lm_file = paste(site, outdir, "linmod_results.tsv", sep="/")
write_tsv(lm_df, file=lm_file)

##### Spider plots
print("Radar charts")
# Transform dataframe to wide format... for some reason... I think it's because it's easier to sort the seednames.
lm_df_wide = reshape(lm_df[, -c(4)], idva="target", timevar="seed", direction="wide")
colnames(lm_df_wide)<-c("target",seeds_sorted)
rownames(lm_df_wide)<-targets


# Create a list with only the name region, without the hemisphere reference to create the plot of both hemispheres in one plot
target_rh = targets[seq(1, ntargets, 2)] 
target_list = unlist(strsplit(target_rh, "[.]"))
target_list = target_list[target_list != "R"]

# Loop to print a spiderplot for each target
for (t in target_list){
  print(paste("Radar:", t))
  
  # Extract data for each target
  target_right = paste("R", t, sep=".")
  target_left = paste("L", t, sep=".")
  target_wide = lm_df_wide[lm_df_wide$target == c(target_right, target_left),]
  
  # ggradar likes it long
  target_long = melt(target_wide)
  
  # Min-max values and other parameters for scaling and formatting the plot
  statmin = min(target_long$value)
  statmax = max(target_long$value)
  statmid = (statmax - abs(statmin))/2
  valradar = round(c(statmin, statmid, statmax),2)
  
  # Create and save spider/radar plot
  plotname = paste(site, "ggradar_test.png", sep="/")
  png(plotname)
    ggradar(target_wide,
            values.radar = valradar,
            grid.min=statmin, 
            grid.mid=statmid, 
            grid.max=statmax,
            gridline.mid.colour = "gray",
            group.line.width = 0.8,
            group.point.size = 2)
  dev.off()
}