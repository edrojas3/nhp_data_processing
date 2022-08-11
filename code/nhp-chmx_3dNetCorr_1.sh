#!/bin/bash

# ----------------- CHANGE SHELL OPTIONS -----------------
#set -v


# ----------------- CONTROL VARIABLES -----------------
site=$1
subj=$2

data_ap=$site/data_ap/$subj/$subj.results
outdir=$site/connectivity/netcorr_1/${subj}_netcorr
roidir=/misc/tezca/reduardo/data/rois

#data_ap=~/mri/tezca/data/site-ucdavis/data_ap/$subj/$subj.results
#outdir=~/mri/tezca/data/site-ucdavis/connectivity/$subj
#roidir=~/mri/tezca/data/rois


# ----------------- COPY NECESSARY FILES TO OUTPUT DIRECTORY -----------------

## anatomical in standard space
3dcopy $data_ap/${subj}_anat_warp2std_nsu+tlrc $outdir/${subj}_anat_warp2std_nsu

## epi in standard space
3dcopy $data_ap/errts.${subj}.tproject+tlrc $outdir/errts.${subj}.tproject

## ROIs in standard space
3dcopy $roidir/nmt_rois/ROIS_left+tlrc $outdir/ROIS_left
3dcopy $roidir/nmt_rois/ROIS_right+tlrc $outdir/ROIS_right

# ----------------- RESAMPLE ROIs IMAGES TO EPI RESOLUTION -----------------
# Resample ROIs
3dresample -master $outdir/errts.${subj}.tproject+tlrc \
		-prefix $outdir/ROIS_left2epi                  \
		-input $outdir/ROIS_left+tlrc

3dresample -master $outdir/errts.${subj}.tproject+tlrc \
		-prefix $outdir/ROIS_right2epi                 \
		-input $outdir/ROIS_right+tlrc

# Copy labels
3drefit -copytables $outdir/ROIS_left+tlrc $outdir/ROIS_left2epi+tlrc
3drefit -copytables $outdir/ROIS_right+tlrc $outdir/ROIS_right2epi+tlrc

# Set label values to integers
3drefit -cmap INT_CMAP $outdir/ROIS_left2epi+tlrc
3drefit -cmap INT_CMAP $outdir/ROIS_right2epi+tlrc

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
rois=($outdir/ROIS_left2epi+tlrc $outdir/ROIS_right2epi+tlrc)
c=1
for roi in ${rois[@]}; do
		if [ $c -eq 1 ]; then hem=left; else hem=right; fi
		3dNetCorr -echo_edu                                         \
				-overwrite                                          \
				-prefix $outdir/netcorr_$hem                        \
				-fish_z                                             \
				-inset $outdir/errts.${subj}.tproject.masked+tlrc   \
				-in_rois $roi                                       \
				-ts_wb_corr                                         \
				-ts_wb_Z                                            \
				-ts_wb_strlabel

		c=$(($c+1))
done

