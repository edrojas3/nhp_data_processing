#!/bin/bash

if [[ $# -ne 2 ]]
then
	echo "USAGE: $(basename $0) site-name sub-id"
	exit 0
fi

site=$1
sub=$2

epis=($(find $site/$sub -type f -name "*bold.nii.gz"))

for e in ${epis[@]}
do
	dirname=$(dirname $e)
	filename=$(basename $e | awk -F. '{print $1}')
	fslmaths $e -Tmean $dirname/${filename}_tmean.nii.gz

	#### Remove skull with FSL's bet ####

	#bet $dirname/${filename}_tmean.nii.gz $dirname/${filename}_tmean_bet.nii.gz
	#fslmaths $dirname/${filename}_tmean_bet.nii.gz -bin $dirname/${filename}_bet_brainmask.nii.gz
	#fslmaths $e -mul $dirname/${filename}_bet_brainmask.nii.gz $dirname/${filename}_bet.nii.gz


	#### Remove skull with AFNI's 3dSkullStrip
	3dSkullStrip -input $dirname/${filename}_tmean.nii.gz \
		-surface_coil \
		-monkey \
		-prefix $dirname/${filename}_tmean_SS.nii.gz \
		-shrink_fac 0.2  

	fslmaths $dirname/${filename}_tmean_SS.nii.gz -bin $dirname/${filename}_SS_brainmask.nii.gz
	fslmaths $e -mul $dirname/${filename}_SS_brainmask.nii.gz $dirname/${filename}_SS.nii.gz
done











	


