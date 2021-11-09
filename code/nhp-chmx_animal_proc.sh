#!/bin/tcsh -f

# USAGE: nhp-chmx_animal_proc.tcsh <-i directory/with/subject> [-o|-s|-r|-b|-h]

# -o: output directory
# -s: string with subjects to preproces (ex: 'sub-1 sub-2 sub-5')
# -r: directory with template and atlas. DEFAULT: $HOME/mri/resources/atlases_and_templates/NMT_v2.0_sym/NMT_v2.0_sym_05mm
# -b: ANTs bias field correction. Looks for N4 suffix in subjects anat folder. Default=0. 
# -h: display this help

# The script is inspirated by (ie. copy-pasted) nhp-chmx_do_all.tcsh file available with @INSTALL_MACAQUE_DEMO in afni.

# The script is meant to be run inside a container with AFNI and @animal_warper. There is one inside Don Clusterio at: /mis/purcell/alfonso/tmp/container/afni.sif. Be sure to bind (ie. mount) the directory with the atlas/templates and subjects to the home directory.

# DEFAULTS

OUTPREFIX=data_
REFDIR=/misc/tezca/reduardo/resources/atlases_and_templates/NMT_v2.0_sym/NMT_v2.0_sym_05mm
subj_list=0
BFC=0
AW=0
AP=0
APV=0
PP=0

# GETOPTS
while getopts ""
nargs=`echo $#argv`
foreach n ( `seq 1 2 $nargs` )
		@ val=$n + 1
		switch ( $argv[$n] )
			case -b:
				 BFC=$argv[$val]
				breaksw
			case -i:
				 INPUTDIR=$argv[$val] 
	 			breaksw 
			case -o:
				 OUTPREFIX=$argv[$val] 
				breaksw
			case -r:
				 REFDIR=$argv[$val]
				breaksw
			case -s:
				 all_subj=`echo $argv[$val]`
				 subj_list=1
				breaksw
			case -aw:
				 AW=$argv[$val]
				breaksw
			case -ap:
				 AP=$argv[$val]
				breaksw
			case -apv:
				 APV=$argv[$val]
				breaksw
			case -pp:
				 PP=$argv[$val]
				breaksw
		endsw
end

################################################################# 

# Setting logical values to 0 (FALSE) or 1 (TRUE)

# Use ANTs Bias Field Correction
if ( $BFC > 1 ) then
	 BFC=1
else if ( $BFC < 0 ) then
	 BFC=0
endif

# Animal Warper regitration
if ( $AW > 1 ) then
	 AW=1
else if ( $AW < 0 ) then
	 AW=0
endif

# Afni_proc.py EPI pre-processing
if ( $AP > 1 ) then
	 AP=1
else if ( $AP < 0 ) then
	 AP=0
endif

if ( $APV > 1 ) then
	 AP=1
else if ( $APV < 0 ) then
	 AP=0
endif

# ROI correlation
if ( $PP > 1 ) then
	 PP=1
else if ( $PP < 0 ) then
	 PP=0
endif

################################################################# 


# Input and output directiores
 dir_basic =$INPUTDIR   	
 dir_aw=$dir_basic/${OUTPREFIX}aw       # AW output
 dir_ap=$dir_basic/${OUTPREFIX}ap
 dir_apv=$dir_basic/${OUTPREFIX}apv
 dir_pp=$dir_basic/${OUTPREFIX}pp

# The template + atlas data; more follower datas could be input.
# Abbreviations are defined for each d, to simplify naming of files
 refdir   =$REFDIR
 refvol   =`\ls ${refdir}/NMT*_SS.nii.gz`
 refvol_ab=NMT2
 refatl   =`\ls ${refdir}/CHARM*.nii.gz \
                     ${refdir}/D99*.nii.gz`
 refatl_ab=( CHARM D99 )
 refseg   =`\ls ${refdir}/NMT*_segmentation*.nii.gz  \
                     ${refdir}/supplemental_masks/NMT*_ventricles*.nii.gz`
 refseg_ab=( SEG VENT )
 refmask  =`\ls ${refdir}/NMT*_brainmask*.gz`
 refmask_ab=MASK


### user's could  this environment variable here or in the own
### ~/.*rc files: useful if one has multiple CPUs/threads on the OS.
# env OMP_NUM_THREADS 12
# -----------------------------------------------------------------

# get list of subj to process
if ( $subj_list == 0  ) then 
	echo  $dir_basic
	cd ${dir_basic} 
	 all_subj=`find . -maxdepth 1 -type d -name "sub*" | cut -b3- | sort`
	echo "++ Found these ${#all_subj} subj:"
	echo "     ${all_subj}"
	cd -
endif

# -----------------------------------------------------------------

# animal_warper for skullstripping and nonlinear warp estimation
if ( $AW == 1 ) then
	 dir_aw=$dir_basic/${OUTPREFIX}aw       # AW output
	echo " ++ start warping"
	foreach subj ( ${all_subj} )
	   
	    # get first anat out of any possible ones in basic subj dir--
	    # but there is only one anat per subj here
	    if ( $BFC == 1 ) then
		  all_anat=`find ${dir_basic}/${subj} -type f -name "sub*N4*nii*" | sort `
	    else
	   	  all_anat=`find ${dir_basic}/${subj} -type f -name "sub*T1w*nii*" | sort `
	    endif

	     anat_subj="${all_anat[1]}"
	    echo "++ Found anat:"
	    echo "     ${anat_subj}"
	
	     odir_aw=${dir_aw}/${subj}
	    mkdir -p ${odir_aw}
	
	    @animal_warper                          \
	        -echo                               \
	        -input            ${anat_subj}      \
	        -input_abbrev     ${subj}_anat      \
	        -base             ${refvol}         \
	        -base_abbrev      ${refvol_ab}      \
	        -atlas_followers  ${refatl}         \
	        -atlas_abbrevs    ${refatl_ab}      \
	        -seg_followers    ${refseg}         \
	        -seg_abbrevs      ${refseg_ab}      \
	        -skullstrip       ${refmask}        \
	        -outdir           ${odir_aw}        \
	        -ok_to_exist                        \
	        |& tee ${odir_aw}/o.aw_${subj}.txt
	end
	echo "++ Done with aligning anatomical with template"
endif

	
	
# -----------------------------------------------------------------

if ( $AP == 1 ) then
	    
	foreach subj ( ${all_subj} )
	    
	    # get all EPI runs per subj, in the order of acquisition--- there
	    # are only 2 runs per subj here
	    cd ${dir_basic}/${subj}
	    #     all_epi=`find . -type f -name "*boldnii.gz" | grep -v "motioncorrection" | sort`
	     all_epi=`find . -type f -name "*bold.nii.gz" | sort`
	
	    cd -
	    echo "++ Found EPIs:"
	    echo "     ${all_epi}"
	
	    # need each EPI file to have path attached
	     subj_epi=( )
	    foreach ee ( ${all_epi} )
	         subj_epi=( ${subj_epi} ${dir_basic}/${subj}/${ee} )
	    end
	
	     odir_aw=${dir_aw}/${subj}
	     odir_ap=${dir_ap}/${subj}
	    mkdir -p ${odir_ap}
	
	    # Using the lpa+zz cost func for some macaques who have MION;
	    # lpc+zz for the others
	
	    # Using "-giant_move" in align epi anat, because of large rot diff
	    # between anat and EPI. 
	
	    # The feature_size=0.5 appears to be very important for a few
	    # macaques for EPI-anat alignment;  helps minorly for all.
	
	    # The "-anat_uniform_method none" greatly helped the alignment in
	    # one or two cases, due to the inhomogeneity of brightness in both
	    # the EPI and anatomicals (in many cases, it doesn't make much of
	    # a difference, maybe helps slightly)
	
	    # Choosing *not* to bandpass (keep degrees of freedom).
	
	    # For @radial_correlate: use a radius scaled down from size used
	    # on human brain vol.
	
	    # Specifying output spatial resolution (1.25 mm iso) explicitly,
	    # because the input datas have differing spatial res -- and so
	    # would likely have differing 'default' output spatial res, too,
	    # otherwise.
	
	     d_subj_anat=`\ls ${odir_aw}/${subj}*_ns.* | grep -v "_warp2std"`
	
	    #    if ( "${subj}" == "sub-01" || "${subj}" == "sub-02" || \
	    #         "${subj}" == "sub-03" ) then
	    #          cost_a2e="lpa+zz"
	    #    else
	    #         cost_a2e="lpc+zz"
	    #    endif
	
	     cost_a2e="lpc+zz"
	
	    afni_proc.py                                                              \
	        -subj_id                 ${subj}                                      \
	        -script                  ${odir_ap}/proc.$subj -scr_overwrite         \
	        -out_dir                 ${odir_ap}/${subj}.results                   \
	        -blocks tshift align tlrc volreg mask scale regress                   \
	        -ds                   ${subj_epi}                                  \
	        -copy_anat               "${d_subj_anat}"                          \
	        -anat_has_skull          no                                           \
	        -anat_uniform_method     none                                         \
	        -radial_correlate_blocks tcat volreg                                  \
	        -radial_correlate_opts   -sphere_rad 14                               \
	        -tcat_remove_first_trs   2                                            \
	        -volreg_align_to         MIN_OUTLIER                                  \
	        -volreg_align_e2a                                                     \
	        -volreg_tlrc_warp                                                     \
	        -volreg_warp_dxyz        1.25                                         \
	        -align_opts_aea          -cost ${cost_a2e} -giant_move                \
	                                 -cmass cmass -feature_size 0.5               \
	        -tlrc_base               ${refvol}                                    \
	        -tlrc_NL_warp                                                         \
	        -tlrc_NL_warped_ds                                                 \
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
endif	
# -----------------------------------------------------------------

if ( $APV == 1 ) then
	foreach subj ( ${all_subj} )
	    
	    # get all EPI runs per subj, in the order of acquisition--- there
	    # are only 2 runs per subj here
	    cd ${dir_basic}/${subj}
	    # all_epi=`find . -type f -name "sub*task-rest*run-*nii*" | sort`
	     all_epi=`find . -type f -name "*bold.nii.gz" | sort`

	    cd -
	    echo "++ Found EPIs:"
	    echo "     ${all_epi}"
	
	    # need each EPI file to have path attached
	     subj_epi=( )
	    foreach ee ( ${all_epi} )
	         subj_epi=( ${subj_epi} ${dir_basic}/${subj}/${ee} )
	    end
	
	     odir_aw=${dir_aw}/${subj}
	    # Note this is in the 'vox' one
	     odir_ap=${dir_apv}/${subj}
	    mkdir -p ${odir_ap}
	
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
	    # because the input datas have differing spatial res -- and so
	    # would likely have differing 'default' output spatial res, too,
	    # otherwise.
	
	    # get some tissue maps that are native space for anaticor (use the
	    # final, modally smoothed ones); need to extra WM from segmentation
	     d_subj_anat=`\ls ${odir_aw}/${subj}*_ns.* | grep -v "_warp2std"`
	
             cost_a2e="lpc+zz"
	
	    afni_proc.py                                                              \
	        -subj_id                 ${subj}                                      \
	        -script                  ${odir_ap}/proc.$subj -scr_overwrite         \
	        -out_dir                 ${odir_ap}/${subj}.results                   \
	        -blocks tshift align tlrc volreg blur mask scale regress              \
	        -ds                   ${subj_epi}                                  \
	        -copy_anat               "${d_subj_anat}"                          \
	        -anat_has_skull          no                                           \
	        -anat_uniform_method     none                                         \
	        -radial_correlate_blocks tcat volreg                                  \
	        -radial_correlate_opts   -sphere_rad 14                               \
	        -tcat_remove_first_trs   2                                            \
	        -volreg_align_to         MIN_OUTLIER                                  \
	        -volreg_align_e2a                                                     \
	        -volreg_tlrc_warp                                                     \
	        -volreg_warp_dxyz        1.25                                         \
	        -blur_size                3.0                                         \
	        -align_opts_aea          -cost ${cost_a2e} -giant_move                \
	                                 -cmass cmass -feature_size 0.5               \
	        -tlrc_base               ${refvol}                                    \
	        -tlrc_NL_warp                                                         \
	        -tlrc_NL_warped_ds                                                 \
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
endif

# -----------------------------------------------------------------

# 'Postprocessing' after the AP preproc for ROI-based analysis; here,
# just func correlation matrices
if ( $PP == 1 ) then

	foreach subj ( ${all_subj} )
	    
	    # ${dir_ap} is for ROI-based analysis
	     odir_apr=${dir_ap}/${subj}/${subj}.results # has AP results
	     odir_pp =${dir_pp}/${subj}                 # for postproc
	    mkdir -p ${odir_pp}
	
	    # should just be one time series of residuals
	     errts   =`ls ${dir_ap}/${subj}/${subj}.results/errts*HEAD`
	
	    # resample each standard space atlas to final EPI resolution
	    foreach ff ( ${refatl} ) 
	
	        # uppermost brick index in atlas d
	         nvi    =`3dinfo -nvi ${ff}`
	
	         opref  =${subj}_epi_`basename ${ff}`
	         epi_atl=${odir_pp}/${opref}

	        3dresample -echo_edu                      \
	            -overwrite                            \
	            -input         "${ff}"                \
	            -rmode          NN                    \
	            -master         ${errts}              \
	            -prefix         ${epi_atl}
	
	        # reattach any labels/atlases
	        3drefit -copytables "${ff}" ${epi_atl}
	        3drefit -cmap INT_CMAP      ${epi_atl}
	
	         ooo    =`3dinfo -prefix_noext ${epi_atl}`
	         onet   =${odir_pp}/${ooo}

	        3dNetCorr -echo_edu                         \
	            -overwrite                              \
	            -fish_z                                 \
	            -in   ${errts}                       \
	            -in_rois ${epi_atl}                     \
	            -prefix  ${onet}
	
	        foreach ii ( `seq 0 1 ${nvi}` )
	             iii  =`printf "%03d" ${ii}`
	             netcc=${onet}_${iii}.netcc
	
	            fat_mat2d_plot.py                  \
	                -input  ${netcc}               \
	                -pars   'CC'                   \
	                -vmin  -0.8                    \
	                -vmax   0.8                    \
	                -cbar   'RdBu_r'               \
	                -dpi    100                    \
	                -ftype  svg   
	
	        end
	    end
	end
	
endif	
	
