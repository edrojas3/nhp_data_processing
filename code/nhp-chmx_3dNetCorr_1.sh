#!/bin/bash

set -veu
# ----------------- HELP FUNCTION -----------------
help (){

echo "

USAGE: $(basename $0) <site-id> <sub-id>

$(basename $0) uses AFNI's 3dNetCorr to calculate ROI-wise correlation and. 

INPUT ARGUEMENTS:
-site-id: path/to/site-id
-sub-id: sub-id

Inside site-id directory a data_ap directory must exists (afni_proc.py output). $(basename $0) takes from here the epi and anatomical data in standard space

From the time being, $(basename $0) takes the ROI file(s) from a fixed directory. If you want to change the directory and roi files' names, look for the respective variables in the 'CONTROL VARIABLES' section. I hope to eventually change this to a more flexible wat to specify these things.

The ROI files must have one volume with all the ROIs in it. Each ROI is identified with an integer and with a label (presumably with the abbreviation of the brain region). If the ROI file you want to use doesn't have these characteristics, probably the script named 'create_roi_file.sh' in the 'utils' directory of this repository might help. But BEWARE! By the time and date this help was written it was still not commented! 

ERH, 12.08.2022
		"
}

if [ $# -eq 0 ]; then help; exit 0; fi

# ----------------- CHANGE SHELL OPTIONS -----------------
set -v


# ----------------- CONTROL VARIABLES -----------------
site=$1
subj=$2

data_ap=$site/data_ap/$subj/$subj.results
outdir=$site/connectivity/netcorr_1/${subj}_netcorr
roifile=/misc/tezca/reduardo/data/rois/addiction_rois/ROIS_LR+tlrc

#data_ap=~/mri/tezca/data/site-ucdavis/data_ap/$subj/$subj.results
#outdir=~/mri/tezca/data/site-ucdavis/connectivity/$subj
#roidir=~/mri/tezca/data/rois


if [ ! -d $outdir ]; then
		mkdir -p $outdir
fi
# ----------------- COPY NECESSARY FILES TO OUTPUT DIRECTORY -----------------

## anatomical in standard space
3dcopy $data_ap/${subj}_anat_warp2std_nsu+tlrc $outdir/${subj}_anat_warp2std_nsu

## epi in standard space
3dcopy $data_ap/errts.${subj}.tproject+tlrc $outdir/errts.${subj}.tproject

## ROIs in standard space
3dcopy $roifile $outdir/ROIS_LR

# ----------------- RESAMPLE ROIs IMAGES TO EPI RESOLUTION -----------------
# Resample ROIs
3dresample -master $outdir/errts.${subj}.tproject+tlrc \
		-prefix $outdir/ROIS_LR2epi                  \
		-input $outdir/ROIS_LR+tlrc

# Copy labels
3drefit -copytables $outdir/ROIS_LR+tlrc $outdir/ROIS_LR2epi+tlrc

# Set label values to integers
3drefit -cmap INT_CMAP $outdir/ROIS_LR2epi+tlrc

# ----------------- MASK EPI -----------------
# Mask from anatomical volume
3dcalc -a $outdir/${subj}_anat_warp2std_nsu+tlrc            \
		-expr 'ispositive(a)'                               \
		-prefix $outdir/${subj}_anat_warp2std_brainmask

# Resample mask from anatomical to EPI resolution
3dresample -master $outdir/errts.${subj}.tproject+tlrc      \
		-input $outdir/${subj}_anat_warp2std_brainmask+tlrc \
		-prefix $outdir/${subj}_anat_warp2std_brainmask2epi

# Mask EPI 
3dcalc -a $outdir/${subj}_anat_warp2std_brainmask2epi+tlrc \
		-b $outdir/errts.${subj}.tproject+tlrc             \
		-expr 'a*b'                                        \
		-prefix $outdir/errts.${subj}.tproject.masked

# Extract an example volume from EPI for visualization purposes
3dTcat $outdir/errts.${subj}.tproject.masked+tlrc'[10]'    \
		-prefix $outdir/errts.${subj}.tproject.examp


# ----------------- CORRELATION ANALYSIS FOR EVERY ROI IN ROI VOLUME -----------------
rois=$outdir/ROIS_LR2epi+tlrc
3dNetCorr -echo_edu                                         \
		-overwrite                                          \
		-prefix $outdir/netcorr_                            \
		-fish_z                                             \
		-inset $outdir/errts.${subj}.tproject.masked+tlrc   \
		-in_rois $rois                                       \
		-ts_out												\
		-ts_wb_corr                                         \
		-ts_wb_Z                                            \
		-ts_wb_strlabel										\
		-push_thru_many_zeros

fat_mat2d_plot.py 	\
		-input $outdir/netcorr__000.netcc \
		-pars 'CC'						  \
		-vmin -0.8 \
		-vmax 0.8 \
		-prefix $outdir/CC_mat
