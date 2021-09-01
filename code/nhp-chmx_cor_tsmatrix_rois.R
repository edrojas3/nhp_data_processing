#!/usr/bin/Rscript
# Creation Date: september 1st 2021
# Author: Alfonso Fajardo
# Github: https://github.com/alffajardo

###############################################################################################################
###############################################################################################################
# Description: 
# This script runs in the bash shell and returns a correlation matrix (txt; pearsons rho) 
# between each voxel timeseries computed in the previous step (output of nhp-chmx_get_timeseries.R)
# and the mean timeseries of every ROI present in a mask (ROI indexes € [1, ∞ )). 
# 
# Compulsory arguments (positional):
# 1. voxel timeseries file
# 2. functional 4d Nifti file 
# 3. non-binary ROIs mask
# 4. output names
#
# Usage: run the script in the bash shell (tested only on linux OSs).
#
# ./nhp-chmx_cor_ts_matrix_rois.R <timeseries_file.tsv> < functional_dataset.nii.gz> <mask_rois.nii.gz> \
# <output_name.tsv> 
#
# #Example:  
# ./nhp-chmx_cor_ts_matrix_rois.R  sub-032125_vmPFC_timeseries.tsv errts.sub-032125.tproject+tlrc_masked.nii.gz \
#  D99_atlas_in_sub-032125.nii.gz vmPFC_D99_correlation_matrix.tsv
#
################################################################################################################
################################################################################################################

# Section 0: set-up commanline arguments and load required packages
print("")
print("starting analysis... This may take few minutes!!!")
args <- commandArgs(T)

timeseries <- as.character(args[1])
dataset <- as.character(args[2])
rois <- as.character(args[3])
output <- as.character(args[4])
  # Load packages
  library(neurobase)
  library(magrittr)



# Section 1:  Import vmPFC timeseries file

timeseries<- read.table(timeseries, header = T) 
  
  # Store the dimensions of the matrix 

dim_timeseries <- dim(timeseries)


# Section 2: Import nifti files 

print ("Importing Nifti files")
func <- RNifti::readNifti("errts.sub-032125.tproject+tlrc_masked.nii.gz")
print("functional dataset imported... importing ROIs mask")
rois <- readNIfTI(rois, reorient =  FALSE)
print("ROIs mask imported")
# Section 3 define a function to extract the time series at a given ROI index

get_meants <- function (nifti4d, mask, index) {
  
  D <- dim(nifti4d)
  vals <- matrix(nifti4d[mask == index], ncol = D[4])
  meants <- (colMeans(vals))
  return(meants)
  
}

# section 3 Extract the time series of each roi. 

  # found each roi index in the mask

roi_indexes <- rois[rois != 0] %>% unique() %>% sort

print("Extracting timeseries por each ROI index")
rois_ts <- sapply(X = roi_indexes, FUN = get_meants,nifti4d = func, mask = rois)

 # Section 5: create a correlation matrix: 
 
 #  step 1:  create and empty matrix with the correct dimensions

  
 correlation_matrix  <- matrix(NA, ncol = length(roi_indexes), nrow = dim_timeseries[2])

# step 2: fill the empty matrix using a foor loop
 
 for (i in 1:ncol(timeseries)){
   print(paste("Calculating correlation values  for voxel", i, sep = " "))
  correlation_matrix[i,] <- apply(rois_ts,MARGIN = 2, cor,timeseries[,i]) 
   rm(i)
 }
 
 correlation_matrix <- data.frame(names(timeseries), correlation_matrix) %>%
   set_names(c("voxel_coords", paste("ROI",roi_indexes,sep = "_")))

 write.table(x = correlation_matrix,file = output, sep = ' ', quote = F,row.names = F,col.names = T)

print("DONE!!!!")   
print(paste("Output has been written to", output))


 