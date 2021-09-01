#!/usr/bin/Rscript

library(neurobase)
library(purrr)

# command args 

# Section 1:  Import vmPFC timeseries file

print("starting analysis... Wait a few seconds")

timeseries<- read.table("sub-032125_vmPFC_timeseries.tsv", sep = " ", header = T) 
  
# Store the dimensions of the matrix 

dim_timeseries <- dim(timeseries)


# Section 2: Import nifti files 

func <- RNifti::readNifti("errts.sub-032125.tproject+tlrc_masked.nii.gz")
rois <- readNIfTI("D99_atlas_in_sub-032125.nii.gz")


# Section 3 define a function to extract time series

get_meants <- function (nifti4d, mask, index) {
  
  D <- dim(nifti4d)
  vals <- matrix(nifti4d[mask == index], ncol = D[4])
  meants <- (colMeans(vals))
  return(meants)
  
}

# section 3 Extract the time series of each roi. 

  # found each roi index in the mask

 roi_indexes <- rois[rois != 0] %>% unique() %>% sort
 
 rois_ts <- sapply(X = roi_indexes, FUN = get_meants,nifti4d = func, mask = rois)

 # Section 5: create a correlation matrix: 
 
 #  I am pretty sure that there is a vectorized way to do it 
 # but by now I will create a foor loop to fill an matrix(
   
 #  step 1: create the empty correlation matrix
  
 correlation_matrix  <- matrix(NA, ncol = length(roi_indexes), nrow = dim_timeseries[2])

# step 2: fill the matrix using a foor loop
 
 for (i in 1:ncol(timeseries)){
  correlation_matrix[i,] <- apply(rois_ts,MARGIN = 2, cor,timeseries[,i]) 
   rm(i)
 }
 
 correlation_matrix <- data.frame(names(timeseries), correlation_matrix) %>%
   set_names(c("voxel_coords", paste("ROI",roi_indexes,sep = "_")))

 write.table(x = correlation_matrix,file = "prueba_corrmat.tsv", sep = ' ', quote = F,row.names = F,col.names = T)
   
print("Output has been written to ")




# Calculate a

  
