#!/bin/bash

if [ $# -lt 4 ]
then
echo
echo "USAGE: $(basename $0) template file size output"
echo
echo "INPUTS:"
echo "template: .nii.gz file for template volume"
echo "file: text file with the coordinates. The script takes the 4th column to extract the coordinates"
echo "size: radius of the sphere"
echo "output: output file"
echo
exit 0
fi

echo "voxel column in file = 4"
echo "roi shape = sphere"

template=$1
file=$2
size=$3
output=$4

voxcol=4

roi_val=1
while read line
do
	
	x=$(echo $line | awk -v var="$voxcol" '{print $var}' | awk -F, '{print $1}')
	y=$(echo $line | awk -v var="$voxcol" '{print $var}' | awk -F, '{print $2}')
	z=$(echo $line | awk -v var="$voxcol" '{print $var}' | awk -F, '{print $3}')
	
	echo $x $y $z
	
	if [ $roi_val -eq 1 ]
	then
		fslmaths $template -mul 0 -add 1 -roi $x 1 $y 1 $z 1 0 1 ${output}
		fslmaths ${output} -kernel sphere $size -fmean $output
		fslmaths $output -thr 0.001 $output 
		fslmaths $output -bin $output
	else
		fslmaths $template -mul 0 -add 1 -roi $x 1 $y 1 $z 1 0 1 ${output}_temp.nii.gz
		fslmaths ${output}_temp.nii.gz -kernel sphere $size -fmean ${output}_temp.nii.gz
		fslmaths ${output}_temp.nii.gz -bin ${output}_temp.nii.gz
		fslmaths ${output}_temp.nii.gz -mul $roi_val ${output}_temp.nii.gz
		fslmaths ${output}.nii.gz -add ${output}_temp.nii.gz $output.nii.gz

	fi
	
	roi_val=$((roi_val+1))

done < <(tail -n +2 $file)
rm *temp.nii.gz
