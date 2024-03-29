#!/bin/bash

# SET VARIABLES
sub=sub-032125
cost_func=nmi


# DEFAULTS
# important directories
site=/misc/hahn2/alfonso/primates/monkeys/data/site-ucdavis
data_aw=$site/data_aw/$sub
refdir=/misc/hahn2/reduardo/atlases_and_templates/NMT_v2.0_sym/NMT_v2.0_sym_05mm
container=/misc/purcell/alfonso/tmp/container/afni.sif
outdir=/misc/tezca/reduardo/data/site-ucdavis/data_ap/$sub

# input data
sub_epi=$site/$sub/ses-001/func/${sub}_ses-001_task-resting_run-1_bold.nii.gz
sub_epirev=$site/$sub/ses-001/func/${sub}_ses-001_task-resting_acq-RevPol_run-1_bold.nii.gz
sub_anat=$site/$data_aw/$sub/${sub}_anat_nsu.nii.gz
refvol=$refdir/NMT*_SS.nii.gz

# ----------------- afni_proc.py -----------------
if [ ! -d $outdir ]; then mkdir -p $outdir; fi

echo "Enter the singularity..."
echo "Preprocessing witn afni_proc.py"
singularity exec -B /misc:/misc --cleanenv $container afni_proc.py \
	-subj_id $sub \
	-script $outdir/proc.$sub -scr_overwrite \
	-out_dir $outdir/${sub}.results \
	-blocks despike tshift align tlrc volreg blur mask scale regress \
	-dsets $sub_epi\
	-blip_forward_dset $sub_epi \
	-blip_reverse_dset $sub_epirev \
	-copy_anat "${sub_anat}" \
	-anat_has_skull no \
	-anat_uniform_method none \
	-radial_correlate_blocks tcat volreg \
	-radial_correlate_opts -sphere_rad 14 \
	-tcat_remove_first_trs 2 \
	-volreg_align_to MIN_OUTLIER \
	-volreg_align_e2a \
	-volreg_tlrc_warp \
	-volreg_warp_dxyz 1.25 \
	-align_opts_aea -cost ${cost_func} \
	                -cmass cmass -feature_size 0.5 \
	-tlrc_base ${refvol} \
	-tlrc_NL_warp \
	-tlrc_NL_warped_dsets \
	    ${data_aw}/${sub}*_warp2std_nsu.nii.gz \
	    ${data_aw}/${sub}*_composite_linear_to_template.1D \
	    ${data_aw}/${sub}*_shft_WARP.nii.gz \
	-mask_epi_anat yes \
	-regress_motion_per_run \
	-regress_apply_mot_types demean deriv \
	-regress_censor_motion 0.30 \
	-regress_censor_outliers 0.05 \
	-regress_est_blur_errts \
	-regress_est_blur_epits \
	-regress_run_clustsim no \
	-html_review_style pythonic \
	-execute

echo "Done."
