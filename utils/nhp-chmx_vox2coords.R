#!/usr/bin/Rscript 

formals(print.data.frame)$row.names <- FALSE

args <- commandArgs(T)

file=as.character(args[1])
matrix_x_y_z = as.matrix(read.csv(file,header = FALSE))

voxel_size = c(0.25,0.25,0.25)
vox0 = c(120, 200, 88)
x <- matrix_x_y_z[,1]
y <- matrix_x_y_z[,2]
z <- matrix_x_y_z[,3]

x1 <- voxel_size*(x - vox0[1])
y1 <-voxel_size*(y - vox0[2])
z1 <- voxel_size*(z - vox0[3])

m <- cbind(x1,y1,z1)
colnames(m) <- c("x","y","z")

print(as.data.frame(m))
