#!/bin/bash

help(){
echo
echo "USAGE: $(basename "$0") roi_3dvol.nii.gz file.tsv datadir output"
echo
echo "Uses fslmeants to create a tsv file with the mean timeseries of each roi per column."
echo
echo "Mandatory inputs:"
echo "-roi_3dvol.nii.gz: 3D NIFTI containing different ROIs" 
echo "-file.tsv: tab separated file where:"
echo "   	- 1st column has the index (value of each ROI)"
echo "   	- 3d column has the name of the brain region of each ROI"
echo "-datadir: path to the directory of the database (ex. /path/to/site-ecnu). Inside this directory a data_apv' must exist. This folder must have subfolders for each subject (ex. sub-032202 sub-032203) containig the preprocessed epi images. The name of the epi images have the format: epi_sub-032202.nii.gz. If you want to change it edit the 'epi' variable in the code." 
echo "-output: name of the tsv file to save the timeseries. The code creates a folder called corr_roiVStargets inside $datadir"
echo
echo "+++ NOTE: uses nhp-chmx_mask_from_roi_index.sh script +++"
}

if [ $# -lt 4 ]; then help; exit 1; fi

# Inputs
niifile=$1 # roi 3dvolume
txtfile=$2 # textfile with index values and region name
datadir=$3 # database folder (ex. site-ion)
outfile=$4 # name of output file with time series

# get neccessary info from txtfile
index=($(cat $txtfile | awk '{print $1}'))
targets=($(cat $txtfile | awk '{print $3}' | sed 1d))

n=$((${#index[@]}-1)) # number of rois
subj=($(find $datadir -maxdepth 1 -type d -name "sub*" | awk -F/ '{print $NF}')) # subjects inside datadir
outdir_main=corr_roiVStargets # set main output directory

test ! -d $datadir/$outdir_main && mkdir $datadir/$outdir_main # check if output dir exists

# loop through subjects
for s in ${subj[@]}
do
	echo "# Processing subject $s..."

	outsub=$datadir/$outdir_main/$s

	test ! -d $outsub && mkdir $outsub

	epi=$datadir/data_apv/$s/epi_${s}.nii.gz

	out_ts=$outsub/$outfile.tsv
	touch $out_ts
	
	# loop through rois
	for r in $(seq 1 $n)
	do
		echo "+++ Time series of ${targets[$r]} ($r/$n) "
		
		# temporal mask with current roi
		mask_from_roi_index.sh $niifile ${index[$r]} $outsub/temp_mask
		fslmaths $outsub/temp_mask.nii.gz -bin $outsub/temp_mask.nii.gz

		# roi 2 epi
		3dresample -input $outsub/temp_mask.nii.gz \
			-prefix $outsub/temp_mask_to_epi.nii.gz \
			-master $epi	

		# time series
		fslmeants -i $epi \
			-m $outsub/temp_mask_to_epi.nii.gz \
			-o $outsub/temp_meants.txt

		# save to file
		if [ $r -eq 1 ]
		then
			mv $outsub/temp_meants.txt $out_ts 
		else
			cp $out_ts $out_ts.copy
			paste $out_ts.copy $outsub/temp_meants.txt > $out_ts
			rm $out_ts.copy	
		fi

		rm $outsub/temp*
		
	done

	# add region names as column names 
	cp $out_ts $out_ts.copy
	rm $out_ts
	( IFS=$'\t'; echo "${targets[*]}"; cat $out_ts.copy ) > $out_ts
	rm $out_ts.copy

	echo "# time series of $s done..."

	
done

