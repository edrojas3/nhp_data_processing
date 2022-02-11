#!/bin/bash

if [ $# -eq 0 ]
then
       	echo "USAGE: $(basename $0) <-S site_directory> <-s subject_id> <-r roi3dvolume>";
	exit 0
	
fi

# inputs
while getopts "S:s:r:o:w:" opt; do
	case ${opt} in
		S) site=${OPTARG};;
		s) sub=${OPTARG};;
		r) roi=${OPTARG};;
		o) outdir=${OPTARG};;
	esac
done

if [ -z $outdir ]; then outdir=$site/network_analysis/$sub; fi
if [ -z $data_aw ]; then data_aw=$site/data_ap; fi

# TRANSFORM ROI FILE TO SUBJECT EPI

## get preprocessed epi from afni_proc analysis
epi=$(find $data_aw/$sub -type f -name "errts.*nii.gz")

## use 3dresample to transform roi in standard space 2 epi and save it in outdir
cp $roi $outdir/rois_in_NMT.nii.gz
3dresample -input $outdir/rois_in_NMT.nii.gz \
       	-master $epi -prefix \
	$outdir/rois_in_epi.nii.gz

# GET EIGEN TIMESERIES FOR EACH ROI IN ROI 3D VOLUME
nhp-chmx_eigts_from_roi.sh $epi $outdir/rois_in_NMT.nii.gz

# single subject Correlation analysis

# group level

# network plot


