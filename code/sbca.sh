#!/bin/bash

# all brain sbca with different sources

site=$1
subj=$2
source=$3
outdir=$site/$4/$subj
mask=$5

echo $#
echo $1
echo $2
echo $3
echo $4
exit 0

# MASK
if [ $# -lt 5 ]
then
	# brain mask
	echo "Subject brain mask will be used ..."
	mask=$site/data_aw/$subj/*nsu_mask.nii.gz
	
	if [ ! -f $mask ]
	then
		echo  "Brain mask NOT found. I'll create one."
		fslmaths $site/data_aw/$subj/*nsu.nii.gz -bin $site/data_aw/$subj/${subj}_anat_warp2std_nsu_mask.nii.gz
	else
		echo "Brain mask found."
	fi
else
	if [ -f $mask ]
	then
		echo "$(basename $mask) will be used"
	else
		echo "$mask not found."
	       	exit 0
	fi
fi

# CONFOUND REGRESSORS
echo "Check for confounds txt file..."
if [ ! -f $outdir/confounds.txt ]
then
	echo "Confound regressors not found..."
	get_confounds.sh $site $subj $4
else
	echo "Confounds file found."
fi

source_n=$(fslstats $source -R | awk '{print $2}' | cut -d. -f1)
epi=$site/data_apv/$subj/${subj}.results/errts.$subj.tproject+tlrc.nii.gz

if [ -f $epi ]
then
	# resample mask and source volumes
	echo "Resample brain mask and source file to subject's epi."
	3dresample -in $mask -master $epi -prefix $outdir/mask_in_${subj}_epi.nii.gz
	3dresample -in $source -master $epi -prefix $outdir/source_in_${subj}_epi.nii.gz
	
	if [ ! -d $outdir/corr_files ]; then mkdir $outdir/corr_files; fi

	echo "SBCA for all rois in source volume..." 
	for n in $(seq 1 $source_n)
	do
		echo "sbca for source $n of $source_n..."
		mask_from_roi_index.sh $outdir/source_in_${subj}_epi.nii.gz $n $outdir/source_mask	
		
		fsl_sbca -i $epi \
			-s $outdir/mask_in_${subj}_epi.nii.gz \
			-t $outdir/source_mask.nii.gz \
			-o $outdir/corr_files/source_${n} \
			--conf=$outdir/confounds.txt 
	
		rm $outdir/source_mask*nii.gz
	done

	echo DONE
else
	echo "Couldn't find epi."
	echo "epi set at $epi"
	
fi	
	
	
	
