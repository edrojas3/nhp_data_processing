#!/usr/bin/Rscript
#
# USAGE: nhp-chmx_net_corrmat.R eigdir outdir
# 
# creates a table with the rvalues obtained from partial correlation 
# 
# It also saves a tsv file with a join of all the subject's corrtable files.
# 
# nhp-chmx_get_group_zvals_table.R sbcadir outfile
#

# Load libraries
library(reshape2)
library(ppcor)
library(ggplot2)

# INPUTS
args = commandArgs(T)
eigdir = args[1]
outdir = args[2]

# Load eigts file
tsfile=paste(eigdir, 'eigts.tsv', sep = "/")
ts_df = read.delim(tsfile)
ts_df = na.omit(ts_df)

# Load confound ts file
confile = paste(eigdir, 'confounds.txt', sep="/")
conf_df = read.delim(confile)
conf_df = na.omit(conf_df)

# Correlation
ts_cor_wide = cor(ts_df)
ts_cor_long = melt(ts_cor)
colnames(ts_cor_long)<-c("roi1", "roi2", "rval")

# Partial correlation
roinames = colnames(ts_df)
rval=c()
pval=c()
stat=c()
roi1=c()
roi2=c()

for (ii in seq(1,length(roinames))){
  roi1 = append(roi1, rep(roinames[ii], times=length(roinames)))
  
  for (jj in seq(1,length(targetnames))){
    roi2 = append(roi2, targetnames[jj])
    
    parcor_df = data.frame(ts_df[,c(ii,jj)], conf_df)
    pcor_results = pcor(parcor_df)
    
    rval = append(rval, pcor_results$estimate[1,2])
    pval = append(pval, pcor_results$p.value[1,2])
    stat = append(stat, pcor_results$statistic[1,2])
  }
  
}

ts_pcor_long = data.frame(roi1, roi2, rval)
ts_pcor_long[ts_pcor_long < -0.9999] = 1

ts_pcor_wide = reshape(ts_pcor_long, idvar="roi1", timevar="roi2", direction="wide")
ts_pcor_wide = ts_pcor_wide[,-c(1)]
rownames(ts_pcor_wide)<-roinames

# correlation and partial-correlation side2side
cor_pcor = data.frame(roi1, roi2, ts_cor_long$rval, ts_pcor_long$rval)
colnames(cor_pcor) <- c("roi1", "roi2", "cor_rval", "pcor_rval")

# HEATMAPS AND DENDROGRAMS
# 
# Correlation heats and dends
# 
outimg=paste(outdir, 'corr_dend.png', sep="/")
png(outimg)
ts_cor_dist = dist(abs(ts_cor_wide))
ts_cor_hc = hclust(ts_cor_dist)
plot(ts_cor_hc)
dev.off()

outimg=paste(outdir, 'corr_heatmap.png', sep="/")
png(outimg)
ts_cor_ro = ts_cor_wide[ts_cor_hc$order, ts_cor_hc$order]
ts_cor_ro_long = melt(ts_cor_ro)
ggplot(ts_cor_ro_long, aes(Var1, Var2, fill=value)) +
  geom_tile()
dev.off()

outimg=paste(outdir, 'pcorr_dend.png', sep="/")
png(outimg)
ts_pcor_dist = dist(abs(ts_pcor_wide))
ts_pcor_hc = hclust(ts_pcor_dist)
plot(ts_pcor_hc)
dev.off()

outimg=paste(outdir, 'pcorr_heatmap.png', sep="/")
png(outimg)
ts_pcor_ro = as.matrix(ts_pcor_wide[ts_pcor_hc$order, ts_pcor_hc$order])
ts_pcor_ro_long = melt(ts_pcor_ro)
ggplot(ts_pcor_ro_long, aes(Var1, Var2, fill = value)) +
  geom_tile()
dev.off()

# Save tsv's with correlation tables
outdir = "/home/eduardo/mri/hahn2/site-ucdavis/target_net_ap_vox/sub-032132"

## Correlation files
outfile = paste(outdir, 'corr_long.tsv', sep='/')
write.table(ts_cor_long, outfile, row.names = F, sep='\t')

outfile = paste(outdir, 'corr_wide.tsv', sep='/')
write.table(ts_cor_wide, outfile, row.names = T, sep='\t')

## Partial-correlation files
outfile = paste(outdir, 'pcorr_long.tsv', sep='/')
write.table(ts_pcor_long, outfile, row.names = F, sep='\t')

outfile = paste(outdir, 'pcorr_wide.tsv', sep='/')
write.table(ts_pcor_wide, outfile, row.names = F, sep='\t')