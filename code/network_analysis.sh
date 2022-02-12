#!/bin/bash

if [ $# -eq 0 ]
then
       	echo "USAGE: $(basename $0) <-S site_directory> <-s subject_id> <-r roi3dvolume.nii.gz> <-n roinames.txt>";
	exit 0
	
fi


# INPUTS
while getopts "S:s:r:o:n:w:p:" opt; do
	case ${opt} in
		S) site=${OPTARG};;
		s) sub=${OPTARG};;
		r) roi=${OPTARG};;
		o) outdir=${OPTARG};;
		w) awdir=${OPTARG};;
		p) apvoxdir=${OPTARG};;
		n) roinames=${OPTARG};;
	esac
done

# SET IMPORTANT VARIABLES

## Directories with previous preprocessing results
[ -z $awdir ] && awdir=$site/data_aw
[ -z $apvoxdir ] && apvoxdir=$site/data_ap

## Set output directory
[ -z $outdir ] && outdir=$site/network_analysis
[ ! -d $outdir/$sub ] &&  mkdir -p $outdir/$sub

########## SINGLE SUBJECT NETWORK ANALYSIS ###################

# TRANSFORM ROI FILE TO SUBJECT EPI

## get preprocessed epi from afni_proc analysis
epi=$(find $apvoxdir/$sub -type f -name "errts.*nii.gz")
cp $epi $outdir/$sub/${sub}_epi.nii.gz

## use 3dresample to transform roi-3d volume in standard space 2 epi space and save it in outdir
cp $roi $outdir/$sub/rois_in_NMT.nii.gz
3dresample -input $outdir/$sub/rois_in_NMT.nii.gz \
	-master $epi \
	-prefix $outdir/$sub/rois_in_epi.nii.gz

# GET EIGEN TIMESERIES FOR EACH ROI IN ROI-3D VOLUME
nhp-chmx_eigts_from_roi.sh $epi $outdir/$sub/rois_in_epi.nii.gz $outdir/$sub/eigts.tsv $roinames


# SINGLE SUBJECT CORRELATION ANALYSIS: PARTIAL CORRELATION

## Confound regressors
echo "Check for confounds txt file..."
if [ ! -f $outdir/confounds.txt ]
then
	echo "Confound regressors not found..."
	nhp-chmx_get_confounds.sh -S $site -s $sub -o $outdir -w $awdir -v $apvoxdir
else
	echo "Confounds file found."
fi

## Partial correlation

# group level

# network plot


