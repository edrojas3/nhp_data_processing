#!/usr/bin/Rscript
# 
# Network group level analysis.
#
# USAGE: nhp-chmnx_network_analysis_2.R <network_1> <outdir>
#
#
############## libraries ############
library(dplyr)

if (!require(pheatmap)){
  install.packages("pheatmat") 
}
library(pheatmap) # library for heatmap with dendrogram

if (!require(corrr)){
  install.packages("corrr") 
}
library(corrr) # library for networkplot

############# READ INPUTS ############
args <- commandArgs(T)
ssdir = as.character(args[1]) # Path to single subject analysis
outdir = as.character(args[2]) # Path to output directory

if(!dir.exists(outdir)){
  dir.create(outdir)
}
	
subs=list.files(ssdir)

############# FUNCTIONS ############
mean_rvals = function (corr_df) {
  roinames = unique(corr_df$roi1)
  rmean = c()
  
  for (r1 in roinames){
    for (r2 in roinames){
      corr_filt = corr_df %>%
        filter(roi1 == r1 & roi2 == r2)
      rmean = append(rmean, mean(corr_filt$rval))
    }
    
  }
  
  corr_mean_df = data.frame(rep(roinames, each = length(roinames)),
                            rep(roinames, times = length(roinames)),
                            rmean)
  colnames(corr_mean_df) <- c("roi1", "roi2", "rmean")
  
  corr_mean_wide = reshape(corr_mean_df, idvar="roi1", timevar="roi2", direction="wide")
  
  corr_mean_wide = corr_mean_wide[,-c(1)]
  colnames(corr_mean_wide)<-roinames
  rownames(corr_mean_wide)<-roinames
  
  return(corr_mean_wide)
}

############# GROUP ANALYSIS FOR FULL-RANK CORRELATION ############
#
print ("Full Rank Correlation...")

# Concatenate R-values across subjects
print("Concatenating single subject correlation matrices...")

paths = paste(ssdir, subs,"cormat_long.tsv", sep="/")
corr_files = lapply(paths, function(f) {read.delim(file = f)})
corr_df = do.call("rbind", lapply(corr_files, as.data.frame))

examp_df = read.delim(paths[1])
df_nrow = nrow(examp_df)
corr_df$sub = rep(subs, each = df_nrow)

# Mean R-values
print("Calculating mean values...")
corr_mean_wide = mean_rvals(corr_df)
corrfile = paste(outdir, "corr_mean.csv", sep="/")
write.csv(corr_mean_wide, corrfile)

# Heatmap: manhattan distance
print("Creating heatmap...")
hm_file = paste(outdir, "corr_heatmap.png", sep="/")
png(hm_file)
  pheatmap(corr_mean_wide, clustering_distance_rows = "manhattan",
           clustering_distance_cols = "manhattan")
dev.off()

# Network plot
print("Creating network plot")

corr_mean_dist = dist(corr_mean_wide, method="manhattan")
corr_mean_hc = hclust(corr_mean_dist)

corr_mean_ro_wide = corr_mean_wide[corr_mean_hc$order, corr_mean_hc$order]

corr_mean_ro_wide[corr_mean_ro_wide == 1] = NA

nw_file = paste(outdir, 'corr_nwplot.png', sep="/")
png(nw_file)
  network_plot(corr_mean_ro_wide, min_cor= 0.1, 
               colors = c("#edf8b1","#31a354","#de2d26"),
               )
dev.off()

print ("FULL RANK DONE")

############# GROUP ANALYSIS FOR PARTIAL CORRELATION ############
print("PARTIAL CORRELATION ANALYSIS")

# Concatenate R-values across subjects
print("Concatenating single subject partial correlation matrices...")

paths = paste(ssdir, subs, "pcormat_long.tsv", sep="/")

corr_files = lapply(paths, function(f) {read.delim(file = f)})
corr_df = do.call("rbind", lapply(corr_files, as.data.frame))
corr_df$sub = rep(subs, each = df_nrow)

# Mean R-values
print("Calculating mean values...")
corr_mean_wide = mean_rvals(corr_df)
pcorrfile = paste(outdir, "pcorr_mean.csv", sep="/")
write.csv(corr_mean_wide, pcorrfile)

# Heatmap: manhattan distance
print("Creating heatmap...")

hm_file = paste(outdir, "pcorr_heatmap.png", sep="/")
png(hm_file)
pheatmap(corr_mean_wide, clustering_distance_rows = "manhattan",
         clustering_distance_cols = "manhattan")
dev.off()

# Network plot
print("Creating network plot...")
corr_mean_dist = dist(corr_mean_wide, method="manhattan")
corr_mean_hc = hclust(corr_mean_dist)

corr_mean_ro_wide = corr_mean_wide[corr_mean_hc$order, corr_mean_hc$order]

corr_mean_ro_wide[corr_mean_ro_wide == 1] = NA

nw_file = paste(outdir, 'pcorr_nwplot.png', sep="/")
png(nw_file)
network_plot(corr_mean_ro_wide, min_cor= 0.1, 
             colors = c("#edf8b1","#31a354","#de2d26"),
)
dev.off()

print("DONE.")
