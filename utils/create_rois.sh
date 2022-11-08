#!/bin/bash

# HELP FUNCTION
help ()
{
	echo " 
	`basename "$0"` <label_table.txt> <outdir> [atlas_dir]				
	"

	Create a single ROI.BRIK file with the rois specified in label_table.txt
}

if [ $# -eq 0 ]; then help; exit 0; fi

set -veu

file=$1 # roi table
outdir=$2
atlas_dir=$3

if [ $# -lt 3 ]; then
		atlas_dir=/misc/tezca/reduardo/resources/atlases_and_templates/NMT_v2.0_sym/NMT_v2.0_sym_05mm
fi

# Empty BRIK files to save everything
3dTcat $atlas_dir/CHARM_in_NMT*.nii.gz'[0]' -prefix $outdir/tmp.dummy
3dcalc -a $outdir/tmp.dummy+tlrc -expr "a*0" -prefix $outdir/tmp.left
3dcopy $outdir/tmp.left+tlrc $outdir/tmp.right


# Create file to save centers of mass of each ROI
touch $outdir/cmass_L.txt
touch $outdir/cmass_R.txt
touch $outdir/labeltable.txt

left_value=1
right_value=2

while read line
do
	atlas_name=`echo $line | awk '{print $1}'`	
	roi_val=`echo $line | awk '{print $2}'`	
	roi_id=`echo $line | awk '{print $3}'`	
	atlas_num=`echo $line | awk '{print $NF}'`
	atlas_num=`echo "$atlas_num-1" | bc`

	if [ $atlas_name == CHARM ]; then
			atlas=$atlas_dir/CHARM_in_NMT_v2.0_sym_05mm.nii.gz
			gm_atlas=$atlas_dir/NMT*GM_cortical_mask.nii.gz
	elif [ $atlas_name == SARM ]; then
			atlas=$atlas_dir/SARM_in_NMT_v2.0_sym_05mm.nii.gz
			gm_atlas=$atlas_dir/SARM*subcortical_mask.nii.gz
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

	# Set value value according to atlas
	3dcalc -a $outdir/tmp.${roi_id}_L+tlrc -expr "a * $left_value" -overwrite -prefix $outdir/tmp.${roi_id}_L
	3dcalc -a $outdir/tmp.${roi_id}_R+tlrc -expr "a * $right_value" -overwrite -prefix $outdir/tmp.${roi_id}_R

	# Add ROI to one single file 
	3dcalc -a $outdir/tmp.left+tlrc -b $outdir/tmp.${roi_id}_L+tlrc -expr 'a+b' -overwrite -prefix $outdir/tmp.left
	3dcalc -a $outdir/tmp.right+tlrc -b $outdir/tmp.${roi_id}_R+tlrc -expr 'a+b' -overwrite -prefix $outdir/tmp.right

	# Update labeltable
	printf "%s\t%s\n%s\t%s\n" "${roi_id}_left ${left_value}" >> $outdir/labeltable.txt
	printf "%s\t%s\n%s\t%s\n" "${roi_id}_right ${right_value}" >> $outdir/labeltable.txt


	# Update roi values
	left_value=$(echo "$left_value + 2" | bc)
	right_value=$(echo "$right_value + 2" | bc)


done < <(cat $file)

3dcopy $outdir/tmp.left+tlrc $outdir/ROIS_left
3dcopy $outdir/tmp.right+tlrc $outdir/ROIS_right

3dcalc -a $outdir/ROIS_left+tlrc -b $outdir/ROIS_right+tlrc -expr 'a+b' -prefix $outdir/ROIS_LR


# Add labels
@MakeLabelTable -labeltable $outdir/labeltable -lab_file $outdir/labeltable.txt 1 2
3drefit -labeltable $outdir/labeltable.niml.lt $outdir/ROIS_left+tlrc
3drefit -labeltable $outdir/labeltable.niml.lt $outdir/ROIS_right+tlrc
3drefit -labeltable $outdir/labeltable.niml.lt $outdir/ROIS_right+tlrc


rm $outdir/tmp.*
