#!/bin/bash

set -v

file=$1
outdir=$2


atlas_dir=/misc/tezca/reduardo/resources/atlases_and_templates/NMT_v2.0_sym/NMT_v2.0_sym_05mm
srad=3

# Empty BRIK files to save everything
3dTcat $atlas_dir/CHARM_in_NMT*.nii.gz'[0]' -prefix $outdir/tmp.dummy
3dcalc -a $outdir/tmp.dummy+tlrc -expr "a*0" -prefix $outdir/tmp.left
3dcopy $outdir/tmp.left+tlrc $outdir/tmp.right

# Create file to save centers of mass of each ROI
touch $outdir/cmass_L.txt
touch $outdir/cmass_R.txt

while read line
do
	atlas_name=`echo $line | awk '{print $1}'`	
	roi_val=`echo $line | awk '{print $2}'`	
	roi_id=`echo $line | awk '{print $3}'`	
	atlas_num=`echo $line | awk '{print $NF}'`
	atlas_num=`echo "$atlas_num-1" | bc`

	if [ $atlas_name == CHARM ]; then
			atlas=$atlas_dir/CHARM_in_NMT*
			gm_atlas=$atlas_dir/NMT*GM_cortical_mask.nii.gz
			srad=3
	elif [ $atlas_name == SARM ]; then
			atlas=$atlas_dir/SARM_in_NMT*
			gm_atlas=$atlas_dir/SARM*subcortical_mask.nii.gz
			srad=2
	else
			echo "No atlas found."
			exit 1
	fi

	# Extract region from atlas and create mask
	roi_cmd="3dcalc -a ${atlas}'[$atlas_num]''<$roi_id>' -expr a -prefix $outdir/tmp.${roi_id}_LR"
	eval $roi_cmd
	3dcalc -a $outdir/tmp.${roi_id}_LR+tlrc -expr 'ispositive(a)' -overwrite -prefix $outdir/tmp.${roi_id}_LR

	# Separate by hemisphere
	3dcalc -a $outdir/tmp.${roi_id}_LR+tlrc -b $atlas_dir/supplemental_masks/NMT*_LH_mask.nii.gz -expr 'a*b' -prefix $outdir/tmp.${roi_id}_L
	3dcalc -a $outdir/tmp.${roi_id}_LR+tlrc -b $atlas_dir/supplemental_masks/NMT*_RH_mask.nii.gz -expr 'a*b' -prefix $outdir/tmp.${roi_id}_R

	# Get centers of mass
	3dCM -Dcent -local_ijk $outdir/tmp.${roi_id}_L+tlrc > $outdir/tmp.CM_${roi_id}_L.1D
	3dCM -Dcent -local_ijk $outdir/tmp.${roi_id}_R+tlrc > $outdir/tmp.CM_${roi_id}_R.1D

	echo "$roi_id `cat $outdir/tmp.CM_${roi_id}_L.1D`" >> $outdir/cmass_L.txt 
	echo "$roi_id `cat $outdir/tmp.CM_${roi_id}_R.1D`" >> $outdir/cmass_R.txt 

	# Create spherical rois centered at center of gravity
	3dUndump -prefix $outdir/tmp.${roi_id}_L_sphere -master $outdir/tmp.${roi_id}_L+tlrc -srad $srad -ijk $outdir/tmp.CM_${roi_id}_L.1D
	3dUndump -prefix $outdir/tmp.${roi_id}_R_sphere -master $outdir/tmp.${roi_id}_R+tlrc -srad $srad -ijk $outdir/tmp.CM_${roi_id}_R.1D

	# Delete overlap with other hemisphere
#	3dcalc -a $outdir/tmp.${roi_id}_L_sphere+tlrc -b $atlas_dir/supplemental_masks/NMT*_LH_mask.nii.gz -expr 'a*b' -overwrite -prefix $outdir/tmp.${roi_id}_L_sphere
#	3dcalc -a $outdir/tmp.${roi_id}_R_sphere+tlrc -b $atlas_dir/supplemental_masks/NMT*_RH_mask.nii.gz -expr 'a*b' -overwrite -prefix $outdir/tmp.${roi_id}_R_sphere

	# Set value of sphere to value according to atlas
	3dcalc -a $outdir/tmp.${roi_id}_L_sphere+tlrc -expr "a * $roi_val" -overwrite -prefix $outdir/tmp.${roi_id}_L_sphere
	3dcalc -a $outdir/tmp.${roi_id}_R_sphere+tlrc -expr "a * $roi_val" -overwrite -prefix $outdir/tmp.${roi_id}_R_sphere

    # Eliminate WM portions in ROI
    3dcalc -a $outdir/tmp.${roi_id}_L_sphere+tlrc -b $outdir/tmp.${roi_id}_L+tlrc -expr 'a*b' -overwrite -prefix $outdir/tmp.${roi_id}_L_sphere+tlrc
    3dcalc -a $outdir/tmp.${roi_id}_R_sphere+tlrc -b $outdir/tmp.${roi_id}_R+tlrc -expr 'a*b' -overwrite -prefix $outdir/tmp.${roi_id}_R_sphere+tlrc

	# Add ROI to one single file 
	3dcalc -a $outdir/tmp.left+tlrc -b $outdir/tmp.${roi_id}_L_sphere+tlrc -expr 'a+b' -overwrite -prefix $outdir/tmp.left
	3dcalc -a $outdir/tmp.right+tlrc -b $outdir/tmp.${roi_id}_R_sphere+tlrc -expr 'a+b' -overwrite -prefix $outdir/tmp.right

done < <(cat $file)

3dcopy $outdir/tmp.left+tlrc $outdir/ROIS_left
3dcopy $outdir/tmp.right+tlrc $outdir/ROIS_right


# Add labels
@MakeLabelTable -labeltable $outdir/rois_label-table -lab_file $file 2 1
3drefit -labeltable $outdir/rois_label-table* $outdir/ROIS_left+tlrc
3drefit -labeltable $outdir/rois_label-table* $outdir/ROIS_right+tlrc

rm $outdir/tmp.*
