#!/usr/bin/Rscript
# Calculate full rank correlation and partial correlation with specified subject timeseries.
# 
# USAGE: nhp-chmx_correlation_between_nodes.R <timeseries_file.tsv> <confounds_file.tsv > <outdir>
#
# INPUTS:
# timeseries_file: tab separated file with the timeseries of each roi per column. 
# confounds_file: tab separated file with the timeseries of each confound variable per column
# output_basename: outdir to add to output files (ex: path/to/sub-001)
# 
# OUTPUTS:
# cormat_wide.tsv: full rank correlation matrix between columns of timeseries file. Presented in wide format. 
# cormat_long.tsv: full rank correlation matrix between columns of timeseries file. Presented in long format. 
# pcormat_wide.tsv: partial correlation matrix between columns of timeseries file. Presented in wide format. 
# pcormat_long.tsv: partial correlation matrix between columns of timeseries file. Presented in wide format. 


############# READ INPUTS ############
args <- commandArgs(T)
ts_file = as.character(args[1]) # File with time series of each ROI
conf_file = as.character(args[2]) # File with time series of confound variables
outdir = as.character(args[3]) # Add this outdir to ouput files (ex: path/to/outdir_file.tsv)

############ LIBRARIES ############

# Check if exists. If not, install.

if (!require(ppcor)){
   install.packages("ppcor") 
}
library(ppcor) # partial correlation

if (!require(reshape2)){
   install.packages("reshape2") 
}
library(reshape2) # transform wide format to long

# library(pheatmap) # best heatmap function I could find

############ LOAD FILES ############

print("Loading files...")
# Eigen timeseries of rois
ts = read.delim(ts_file)

# Confound variables
conf = read.delim(conf_file, header=F)

print("CORRELATION ANALYSIS")
############ FULL RANGE CORRELATION ############

# CORRELATION MATRIX
print("Going full rank...")
cormat = cor(ts)
cormat[cormat == 1] = NA

## Change cormat to long format
cormat_long = melt(cormat)
colnames(cormat_long) = c("roi1", "roi2", "rval")

## Save files correlation matrices
print("Saving for the future...")
widefile=paste(outdir, "cormat_wide.tsv", sep="/")
write.table(cormat, file=widefile, sep="\t", row.names = F)

longfile=paste(outdir, "cormat_long.tsv", sep="/")
write.table(cormat_long, file=longfile, sep="\t", row.names = F)


 ############ PARTIAL CORRELATION ############
print("Now the partials...")
targetnames = colnames(ts)
rval=c()
pval=c()
stat=c()
roi1=c()
roi2=c()

for (ii in seq(1,length(targetnames))){
roi1 = append(roi1, rep(targetnames[ii], times=length(targetnames)))

for (jj in seq(1,length(targetnames))){
  roi2 = append(roi2, targetnames[jj])
  
  parcor_df = data.frame(ts[,c(ii,jj)], conf)
  pcor_results = pcor(parcor_df)
  
  rval = append(rval, pcor_results$estimate[1,2])
  pval = append(pval, pcor_results$p.value[1,2])
  stat = append(stat, pcor_results$statistic[1,2])
}

}

pcormat_long=data.frame(roi1, roi2, rval)
pcormat_long$rval[round(abs(pcormat_long$rval)) == 1] = NA

 ## Change pcormat to wide format
pcormat = reshape(pcormat_long, idvar="roi1", timevar="roi2", direction="wide")
colnames(pcormat) = (c("roi", targetnames))

## Save partial correlation matrices with outdir
print("Saving...")
widefile=paste(outdir, "pcormat_wide.tsv", sep="/")
write.table(cormat, file=widefile, sep="\t", row.names = F)

longfile=paste(outdir, "pcormat_long.tsv", sep="/")
write.table(cormat_long, file=longfile, sep="\t", row.names = F)
