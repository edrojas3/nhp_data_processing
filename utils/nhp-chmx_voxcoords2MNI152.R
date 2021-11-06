#!/usr/bin/Rscript 
formals(print.data.frame)$row.names <- FALSE

args <- commandArgs(T)

file=as.character(args[1])
matrix_x_y_z = as.matrix(read.csv(file, header = F))


voxel_size = c(2,2,2)
x <- matrix_x_y_z[,1]
y <- matrix_x_y_z[,2]
z <- matrix_x_y_z[,3]

x1 <- -voxel_size[1]* (x - 90/voxel_size)
y1 <- voxel_size[2]* (y -126/voxel_size)
z1 <- voxel_size[2]* (z - 72/voxel_size)


m <- cbind(x1,y1,z1)
colnames(m) <- c("x","y","z")

print(as.data.frame(m))
