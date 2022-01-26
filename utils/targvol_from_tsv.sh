#!/bin/bash

file=$1
outfile=$2


atlasdir=$NMTDIR

outfile=$(echo $outfile | cut -d. -f1)
echo $outfile
fslmaths $NMT -mul 0 $outfile
lh_mask=$NMTDIR/supplemental_masks/NMT_v2.0_sym_05mm_L_mask.nii.gz
rh_mask=$NMTDIR/supplemental_masks/NMT_v2.0_sym_05mm_R_mask.nii.gz

while read line
do
	atlas=$(echo $line | awk '{print $2}')
	if [ "$atlas" == "NA" ]; then continue; fi 

	outval=$(echo $line | awk '{print $1}')
	atlas_num=$(echo $line | awk '{print $3}')
	atlas_val=$(echo $line | awk '{print $4}')
	region=$(echo $line | awk '{print $6}')

	atlas_file=$NMTDIR/supplemental_$atlas/${atlas}_${atlas_num}_in_NMT_v2.0_sym_05mm.nii.gz
	hem=$(echo $region | cut -d. -f1)
	
	echo "Extracting $region from NMT..."
	nhp-chmx_mask_from_roi_index.sh $atlas_file $atlas_val ${region}_tmp.nii.gz

	if [ "$hem" == "L" ]
	then
		fslmaths ${region}_tmp.nii.gz -mul $lh_mask ${region}_tmp_hem.nii.gz
	else
		fslmaths ${region}_tmp.nii.gz -mul $rh_mask ${region}_tmp_hem.nii.gz
	fi

	fslmaths ${region}_tmp_hem.nii.gz -ero ${region}_tmp_hem_ero.nii.gz
	fslmaths ${region}_tmp_hem_ero.nii.gz -bin ${region}_tmp_hem_ero.nii.gz

	fslmaths ${region}_tmp_hem_ero.nii.gz -mul $outval ${region}_tmp_targval.nii.gz

	fslmaths $outfile.nii.gz -add ${region}_tmp_targval.nii.gz $outfile.nii.gz 

	rm *tmp*.nii.gz

	echo "Done."


done < <(tail -n +2 $file)
