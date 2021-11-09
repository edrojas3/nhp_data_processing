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
container=/misc/purcell/alfonso/tmp/container/afni.sif

while getopts "s:t:o:w:v:c:" opt; do
	case ${opt} in
		s ) seed=${OPTARG};;	
		t ) target=${OPTARG};;
		o ) outdir=${OPTARG};;
		w ) awdir=${OPTARG};;
		v ) apvoxdir=${OPTARG};;
		c ) container=${OPTARG}
	esac	
done

# POSITIONAL ARGUMENTS
site=${@:$OPTIND:1}
subj=${@:$OPTIND+1:1}


# CHECK INPUT FILES AND DIRECTORIES
if [ -z ${seed+x} ] || [ -z ${target+x} ] || [ $# -lt 3 ]; then
	help
fi

# SEED MASK. If not specified the code will try to use a subject brain mask
if [ -z ${seed+x} ]
then
	# brain seeds
	echo "Subject brain seeds will be used ..."
	seedsvol=$site/data_aw/$subj/*nsu_mask.nii.gz
	
	if [ ! -f $seeds ]
	then
		echo  "Brain seeds NOT found. I'll create one."
		fslmaths $site/data_aw/$subj/*nsu.nii.gz -bin $site/data_aw/$subj/${subj}_anat_warp2std_nsu_mask.nii.gz
	else
		echo "Brain seeds found."
	fi
else
	seedsvol=$seed.nii.gz
	seedstsv=$seed.tsv

	if [ ! -f $seedsvol -o ! -f $seedstsv ]; then
		echo "Seeds files not found."
		exit 0
	fi
fi

if [ ! -f $container ]; then echo "Container not found. Specify container path with '-c' option."; exit ; fi

test ! -d $outdir/$subj && mkdir -p $outdir/$subj

# CONFOUND REGRESSORS
echo "Check for confounds txt file..."
if [ ! -f $outdir/$subj/confounds.txt ]
then
	echo "Confound regressors not found..."
	nhp-chmx_get_confounds.sh $site $subj $outdir
else
	echo "Confounds file found."
fi

targetsvol=$target.nii.gz
targetstsv=$target.tsv
targets_n=$(tail $targetstsv -n +2 | wc -l)

#epi=$site/data_apv/$subj/${subj}.results/errts.$subj.tproject+tlrc.nii.gz
#
#if [ -f $epi ]
#then
#	# resample mask and targets volumes
#	echo "Resampling seeds and targets to subject's epi."
#	singularity exec -B /misc:/misc --cleanenv $container 3dresample -input $seedsvol -master $epi -prefix $outdir/${subj}/seeds_in_${subj}_epi.nii.gz
#	singularity exec -B /misc:/misc --cleanenv $container 3dresample -input $targetsvol -master $epi -prefix $outdir/${subj}/targets_in_${subj}_epi.nii.gz
#
#	cp $targetstsv $outdir/$subj/targets.tsv
#	cp $seedstsv $outdir/$subj/seeds.tsv
#	
#	if [ ! -d $outdir/${subj}/corr_files ]; then mkdir $outdir/${subj}/corr_files; fi
#
#	echo "SBCA for all targets..." 
#	for n in $(seq 1 $targets_n)
#	do
#		echo "sbca for targets $n of $targets_n..."
#		index=$(cat $targetstsv | awk -v idx="$n" '$1 == idx' | awk '{print $1}')
#		nhp-chmx_mask_from_roi_index.sh $outdir/${subj}/targets_in_${subj}_epi.nii.gz $index $outdir/${subj}/target_mask	
#		
#		fsl_sbca -i $epi \
#			-s $outdir/${subj}/seeds_in_${subj}_epi.nii.gz \
#			-t $outdir/${subj}/target_mask.nii.gz \
#			-o $outdir/${subj}/corr_files/target_${n} \
#			--conf=$outdir/${subj}/confounds.txt 
#	
#		rm $outdir/${subj}/target_mask*nii.gz
#	done
#
#	echo DONE
#else
#	echo "Couldn't find epi."
#	echo "epi set at $epi"
#	
#fi	
	
# corrtable.txt
#nhp-chmx_corrtable.sh $outdir $subj 

# spider plots
test ! -d $outdir/$subj/spiderplots && mkdir $outdir/$subj/spiderplots
#
nhp-chmx_spiderplots_from_corrtable.R $outdir/$subj/corrtable.tsv $outdir/$subj/spiderplots
