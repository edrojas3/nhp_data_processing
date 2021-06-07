#!/bin/tcsh -f

# DEFAULTS
set OUTPUTDIR = ap_out
set REFDIR = $HOME/atlases_and_templates/NMT_v2.0_sym/NMT_v2.0_sym_05mm
set subj_list = 0

# GETOPTS
set nargs = `echo $#argv`

foreach n ( `seq 1 2 $nargs` )
	@ val=$n + 1
	switch ( $argv[$n] )
		case -i:
			set INPUTDIR = $argv[$val]
			breaksw
		case -o:
			set OUTPUTDIR = $argv[$val]
			breaksw
		case -s:
			set all_subj = `echo $argv[$v]`
			set subj_list = 1
			breaksw	
		case -r:
			set REFDIR = $argv[$val]
			breaksw
	endsw
end


if ( $subj_list == 0  ) then 
	cd ${INPUTDIR} 
	set all_subj = `find . -maxdepth 1 -type d -name "sub*" | cut -b3- | sort`
	echo "++ Found these ${#all_subj} subj:"
	echo "     ${all_subj}"
	cd -
endif

foreach subj ( ${all_subj} )
    
    # get all EPI runs per subj, in the order of acquisition--- there
    # are only 2 runs per subj here
    cd ${INPUTDIR}/${subj}
    set all_epi = `find . -type f -name "sub*task-rest*run-*nii*" | sort`
    cd -
    echo "++ Found EPIs:"
    echo "     ${all_epi}"

    # need each EPI file to have path attached
    set subj_epi = ( )
    foreach ee ( ${all_epi} )
        set subj_epi = ( ${subj_epi} ${INPUTDIR}/${subj}/${ee} )
    end

    set odir_aw = ${dir_aw}/${subj}
    # Note this is in the 'vox' one
    set odir_ap = ${dir_ap_vox}/${subj}
    \mkdir -p ${odir_ap}

    # lpa+zz cost func for some macaques who have MION; lpc+zz for the
    # others

    # The "-anat_uniform_method none" greatly helps the alignment in
    # one or two cases, due to the inhomogeneity of brightness in both
    # the EPI and anatomicals (in many cases, it doesn't make much of
    # a difference, maybe helps slightly)

    # using "-giant_move" in align epi anat, because of large rot diff
    # between anat and EPI (different session anat)

    # choosing *not* to bandpass (keep degrees of freedom)

    # for @radial_correlate: use a radius scaled down from size used
    # on human brain vol

    # specifying output spatial resolution (1.25 mm iso) explicitly,
    # because the input datasets have differing spatial res -- and so
    # would likely have differing 'default' output spatial res, too,
    # otherwise.

    # get some tissue maps that are native space for anaticor (use the
    # final, modally smoothed ones); need to extra WM from segmentation
    set dset_subj_anat = `\ls ${odir_aw}/${subj}*_ns.* | grep -v "_warp2std"`

    if ( "${subj}" == "sub-01" || "${subj}" == "sub-02" || \
         "${subj}" == "sub-03" ) then
         set cost_a2e = "lpa+zz"
    else
        set cost_a2e = "lpc+zz"
    endif

    afni_proc.py                                                              \
        -subj_id                 ${subj}                                      \
        -script                  ${odir_ap}/proc.$subj -scr_overwrite         \
        -out_dir                 ${odir_ap}/${subj}.results                   \
        -blocks tshift align tlrc volreg blur mask scale regress              \
        -dsets                   ${subj_epi}                                  \
        -copy_anat               "${dset_subj_anat}"                          \
        -anat_has_skull          no                                           \
        -anat_uniform_method     none                                         \
        -radial_correlate_blocks tcat volreg                                  \
        -radial_correlate_opts   -sphere_rad 14                               \
        -tcat_remove_first_trs   2                                            \
        -volreg_align_to         MIN_OUTLIER                                  \
        -volreg_align_e2a                                                     \
        -volreg_tlrc_warp                                                     \
        -volreg_warp_dxyz        1.25                                         \
        -blur_size                2.0                                         \
        -align_opts_aea          -cost ${cost_a2e} -giant_move                \
                                 -cmass cmass -feature_size 0.5               \
        -tlrc_base               ${refvol}                                    \
        -tlrc_NL_warp                                                         \
        -tlrc_NL_warped_dsets                                                 \
            ${odir_aw}/${subj}*_warp2std_nsu.nii.gz                           \
            ${odir_aw}/${subj}*_composite_linear_to_template.1D               \
            ${odir_aw}/${subj}*_shft_WARP.nii.gz                              \
        -regress_motion_per_run                                               \
        -regress_apply_mot_types  demean deriv                                \
        -regress_censor_motion    0.10                                        \
        -regress_censor_outliers  0.02                                        \
        -regress_est_blur_errts                                               \
        -regress_est_blur_epits                                               \
        -regress_run_clustsim     no                                          \
        -html_review_style        pythonic                                    \
        -execute

end

echo "\n\n++ DONE.\n\n"

