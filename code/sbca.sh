#!/bin/bash

help(){
	echo
	echo "$(basename "$0") <-s seed_base -t target_base -o outputdir> [-w awdir | -v apvoxdir] <site subject>" 
	echo
	exit 0
}

# FLAG OPTIONS

## defaults
awdir=data_aw
apvoxdir=data_apv

while getopts "s:t:o:w:v:" opt; do
	case ${opt} in
		s ) seed=${OPTARG};;	
		t ) target=${OPTARG};;
		o ) outdir=${OPTARG}/$subj;;
		w ) awdir=${OPTARG};;
		v ) apvoxdir=${OPTARG};;
	esac	
done

# POSITIONAL ARGUMENTS
site=${@:$OPTIND:1}
subj=${@:$OPTIND+1:1}
outdir=$(echo $(echo $outdir)$(echo $subj))

if [ -z ${seed+x} ] || [ -z ${target+x} ] || [ $# -lt 3 ]; then
	help
fi

# SEED MASK. If not specified the code will try to use a subject brain mask
#if [ -z ${seed+x} ]
#then
#	# brain seeds
#	echo "Subject brain seeds will be used ..."
#	seedsvol=$site/data_aw/$subj/*nsu_mask.nii.gz
#	
#	if [ ! -f $seeds ]
#	then
#		echo  "Brain seeds NOT found. I'll create one."
#		fslmaths $site/data_aw/$subj/*nsu.nii.gz -bin $site/data_aw/$subj/${subj}_anat_warp2std_nsu_mask.nii.gz
#	else
#		echo "Brain seeds found."
#	fi
#else
	seedsvol=$seeds.nii.gz
	seedstsv=$seeds.tsv
#
#	if [ ! -f $seedsvol -o ! -f $seedstsv ]; then
#		echo "Seeds files not found."
#		exit 0
#	fi
#fi
#

# CONFOUND REGRESSORS

#echo "Check for confounds txt file..."
#if [ ! -f $outdir/confounds.txt ]
#then
#	echo "Confound regressors not found..."
#	get_confounds.sh $site $subj $4
#else
#	echo "Confounds file found."
#fi

#targets_n=$(fslstats $targets -R | awk '{print $2}' | cut -d. -f1)
targetsvol=$targets.nii.gz
targetstsv=$targets.tsv
targets_n=$(tail $targetstsv -n +2 | wc -l)

epi=$site/data_apv/$subj/${subj}.results/errts.$subj.tproject+tlrc.nii.gz

if [ -f $epi ]
then
	# resample mask and targets volumes
	#echo "Resampling seeds and targets to subject's epi."
	#3dresample -in $seeds -master $epi -prefix $outdir/seeds_in_${subj}_epi.nii.gz
	#3dresample -in $targets -master $epi -prefix $outdir/targets_in_${subj}_epi.nii.gz
	
	if [ ! -d $outdir/corr_files ]; then mkdir $outdir/corr_files; fi

	echo "SBCA for all targets..." 
	for n in $(seq 1 $targets_n)
	do
		echo "sbca for targets $n of $targets_n..."
		index=$(cat $targetstsv | awk -v idx="$n" '$1 == idx' | awk '{print $1}')
		mask_from_roi_index.sh $outdir/targets_in_${subj}_epi.nii.gz $index $outdir/target_mask	
		
		fsl_sbca -i $epi \
			-s $outdir/seeds_in_${subj}_epi.nii.gz \
			-t $outdir/target_mask.nii.gz \
			-o $outdir/corr_files/target_${n} \
			--conf=$outdir/confounds.txt 
	
		rm $outdir/target_mask*nii.gz
	done

	echo DONE
else
	echo "Couldn't find epi."
	echo "epi set at $epi"
	
fi	
	
	
