#!/bin/bash

help(){
	echo
	echo "$(basename "$0") <-S site> <-s sub-id> <-d seed_base> <-t target_base> [-o outdir | -w awdir | -v apvoxdir | -c containerdir]"
	echo
	echo "Performs seed-based correlation analysis including: tissue segmentation (csf and wm), fsl_sbca, and spiderplots"
	echo
	echo "MANDATORY INPUTS:"
	echo "-S: site directory"
	echo "-s: sub-id"
	echo "-d: seed_base name for the seeds tsv and nii file. Example: path/to/repo/files/Neubert_seeds_in_NMT"
	echo "-t: seed_base name for the targets nii file. Example: path/to/repo/files/targets_in_NMT.nii.gz"
	echo
	echo "OPTIONAL INPUTS"
	echo "-o: output directory. Default site/sbca"
	echo "-f: targets_in_NMT.tsv file. Default same/path/as/targets_nii_file/targets_in_NMT.tsv"
	echo "-w: animal_warper results directory. Default: site/data_aw"
	echo "-v: afni_proc.py results directory. Default: site/data_ap_vox"
	echo "-c: container directory. Default: /misc/purcell/alfonso/tmp/container/afni.sif"
	echo

	exit 0
}

# FLAG OPTIONS

## defaults
container=/misc/purcell/alfonso/tmp/container/afni.sif

while getopts "S:s:d:t:o:f:w:v:c:" opt; do
	case ${opt} in
		S) site=${OPTARG};;
		s) subj=${OPTARG};;
		d ) seed=${OPTARG};;	
		t ) target=${OPTARG};;
		o ) outdir=${OPTARG};;
		f) file=${OPTARG};;
		w ) awdir=${OPTARG};;
		v ) apvoxdir=${OPTARG};;
		c ) container=${OPTARG}
	esac	
done


# CHECK INPUT FILES AND DIRECTORIES
if [ -z ${seed+x} ] || [ -z ${target+x} ] || [ $# -eq 0 ]; then
	help
fi

if [ -z $awdir ]; then awdir=$site/data_aw; fi
if [ -z $apvoxdir ]; then apvoxdir=$site/data_ap_vox; fi
if [ -z $outdir ]; then outdir=$site/sbca; fi

if [ ! -d $outdir/$subj ]; then mkdir -p $outdir/$subj; fi

seedsvol=$seed.nii.gz
seedstsv=$seed.tsv

if [ -z ${file+x} ]
then
	file=${target%/*}/targets_in_NMT.tsv
fi

if [ ! -f $seedsvol -o ! -f $seedstsv ]; then
	echo "Seeds files not found."
	exit 0
fi

if [ ! -f $container ]; then echo "Container not found. Specify container path with '-c' option."; exit ; fi

test ! -d $outdir/$subj && mkdir -p $outdir/$subj

# CONFOUND REGRESSORS
echo "Check for confounds txt file..."
if [ ! -f $outdir/$subj/confounds.txt ]
then
	echo "Confound regressors not found..."
	nhp-chmx_get_confounds.sh -S $site -s $subj -o $outdir -w $awdir -v $apvoxdir
else
	echo "Confounds file found."
fi

targetsvol=$target
targetstsv=$file
targets_n=$(tail $targetstsv -n +2 | wc -l)

epi=$apvoxdir/$subj/${subj}.results/errts.$subj.tproject+tlrc.nii.gz

if [ -f $epi ]
then
	# resample mask and targets volumes
	echo "Resampling seeds and targets to subject's epi."
	singularity exec -B /misc:/misc --cleanenv $container 3dresample -input $seedsvol -master $epi -prefix $outdir/${subj}/seeds_in_${subj}_epi.nii.gz
	singularity exec -B /misc:/misc --cleanenv $container 3dresample -input $targetsvol -master $epi -prefix $outdir/${subj}/targets_in_${subj}_epi.nii.gz
	
	# copy targets and seeds tsv files tu subject output dir
	cp $targetstsv $outdir/$subj/targets.tsv
	cp $seedstsv $outdir/$subj/seeds.tsv
	
	if [ ! -d $outdir/${subj}/corr_files ]; then mkdir $outdir/${subj}/corr_files; fi

	# SBCA
	echo "SBCA for all targets..." 
	for n in $(seq 1 $targets_n)
	do
		echo "sbca for targets $n of $targets_n..."
		index=$(cat $targetstsv | awk -v idx="$n" '$1 == idx' | awk '{print $1}')
		nhp-chmx_mask_from_roi_index.sh $outdir/${subj}/targets_in_${subj}_epi.nii.gz $index $outdir/${subj}/target_mask	
		
		fsl_sbca -i $epi \
			-s $outdir/${subj}/seeds_in_${subj}_epi.nii.gz \
			-t $outdir/${subj}/target_mask.nii.gz \
			-o $outdir/${subj}/corr_files/target_${n} \
			--conf=$outdir/${subj}/confounds.txt 
	
		rm $outdir/${subj}/target_mask*nii.gz
	done

	echo DONE
else
	echo "Couldn't find epi."
	echo "epi set at $epi"
	
fi	
	
# Table with the max target-seed rvalue
nhp-chmx_corrtable.sh $outdir $subj 

# spider plots
test ! -d $outdir/$subj/spiderplots && mkdir $outdir/$subj/spiderplots
nhp-chmx_spiderplots_from_corrtable.R $outdir/$subj/corrtable.tsv $outdir/$subj/spiderplots





