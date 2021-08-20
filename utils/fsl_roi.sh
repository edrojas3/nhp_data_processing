#!/bin/bash

# $1 = input
# $2 = xyz
# $3 = size
# $4 = roi_name

input=$1
xyz=($(echo $2))
echo ${#xyz[@]}
size=$3
roi=$4

fslmaths $input -mul 0 -add 1 -roi ${xyz[0]} 1 ${xyz[1]} 1 ${xyz[2]} 1 0 1 ${roi}_point -odt float

fslmaths ${roi}_point -kernel sphere $size -fmean ${roi}_sphere -odt float

fslmaths ${roi}_sphere -thr 0.0001 ${roi}_thresh

fslmaths ${roi}_thresh -bin ${roi}_bin



