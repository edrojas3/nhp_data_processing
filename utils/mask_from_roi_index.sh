#!/bin/bash

help(){
echo
echo "USAGE: $(basename $0) roi_3dvol.nii.gz index output"
echo
echo "Extracts the voxels of a specific ROI from a NIFTI with many ROIs. The output is a binary mask of the ROI."
echo 
echo "Inputs:"
echo "-roi_3dvol.nii.gz: NIFTI with many ROIS. Each ROI has an index value."
echo "-index: value of the wanted ROI."
echo "-output: name of the output. Better without the ".nii.gz""

}

if [ $# -lt 3 ]; then help; exit 1; fi

input=$1
index=$2
output=$3

low=$(echo $(($index-1)).5)
upper=${index}.5

fslmaths $input -thr $low ${output}_thr_temp.nii.gz
fslmaths $input -uthr $upper ${output}_uthr_temp.nii.gz
fslmaths ${output}_thr_temp.nii.gz -mul ${output}_uthr_temp.nii.gz $output
fslmaths $output.nii.gz -bin $output
rm $output*temp.nii.gz



