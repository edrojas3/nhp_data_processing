#!/usr/bin/Rscript

args <- commandArgs(trailingOnly = T)



anat <- as.character(args[1])
prefix <-  as.character(args[2])

xmin <- as.numeric(args[3])
xsize <- as.numeric(args[4])
xmax <- xmin + xsize
ymin <- as.numeric(args[5])
ysize <- as.numeric(args[6])
ymax <- ymin + ysize 
zmin <- as.numeric(args[7])
zsize <- as.numeric(args[8])
zmax <- zmin + zsize

output <- paste(prefix,"_cropping.png",sep='')

if (!require(fslr)){
  install.packages("fslr")
  library(fslr)
}

if (!require(neurobase)){
  install.packages("neurobase")
  library(neurobase)
}

if (!require(scales)){
  install.packages("scales")
  library(scales)
}


print("Reading NIFTI...")

anat <- readNIfTI(anat,reorient = F)
cropping_rectangle <- anat
cropping_rectangle[anat > 0] <- 0

print("Calculating Cropped Image...")
cropping_rectangle[xmin:xmax,ymin:ymax,zmin:zmax] <- 1


png( filename = output ,height =500,width = 1400,res = 200,units = "px")

ortho2(anat,y = cropping_rectangle,crosshairs = F,mfrow = c(1,3),
       col.y  =  alpha("yellow",0.2),
       NA.x = T,NA.y = T,main = 
    paste(xmin,"->",xsize," ; ",
          ymin,"->",ysize," ; ",
          zmin,"->",zsize,sep = ""),
       col.main = "white",mar = c(0,0,3,0))
dev.off()


print("DONE!!!!!!")











