#!/bin/tcsh -f

# USAGE: animal_proc.tcsh <-i directory/with/subject> [-o|-s|-r|-b|-h]

# -o: output directory
# -s: string with subjects to preproces (ex: 'sub-1 sub-2 sub-5')
# -r: directory with template and atlas. DEFAULT: $HOME/mri/resources/atlases_and_templates/NMT_v2.0_sym/NMT_v2.0_sym_05mm
# -b: ANTs bias field correction. Default = 1. 
# -h: display this help

# The script is inspirated by (ie. copy-pasted) do_all.tcsh file available with @INSTALL_MACAQUE_DEMO in afni.

# The script is meant to be run inside a container with AFNI and @animal_warper. There is one inside Don Clusterio at: /mis/purcell/alfonso/tmp/container/afni.sif. Be sure to bind (ie. mount) the directory with the atlas/templates and subjects to the home directory.

# DEFAULTS

set OUTPREFIX = data_
set REFDIR = /misc/tezca/reduardo/resources/atlases_and_templates/NMT_v2.0_sym/NMT_v2.0_sym_05mm
set subj_list = 0
set BFC = 1
set AW = 1
set AP = 0
set PP = 0
# GETOPTS
set nargs = `echo $#argv`
foreach n ( `seq 1 2 $nargs` )
		@ val=$n + 1
		switch ( $argv[$n] )
			case -b:
				set BFC = $argv[$val]
				breaksw
			case -i:
				set INPUTDIR = $argv[$val] 
	 			breaksw 
			case -o:
				set OUTPREFIX = $argv[$val] 
				breaksw
			case -r:
				set REFDIR = $argv[$val]
				breaksw
			case -s:
				set all_subj = `echo $argv[$val]`
				set subj_list = 1
				breaksw
			case -aw:
				set AW = $argv[$val]
				breaksw
			case -ap:
				set AP = $argv[$val]
				breaksw
			case -pp:
				set PP = $argv[$val]
				breaksw
		endsw
end

################################################################# 

# Setting logical values to 0 (FALSE) or 1 (TRUE)

# Use ANTs Bias Field Correction
if ( $BFC > 1 ) then
	set BFC = 1
else if ( $BFC < 0 ) then
	set BFC = 0
endif

# Animal Warper regitration
if ( $AW > 1 ) then
	set AW = 1
else if ( $AW < 0 ) then
	set AW = 0
endif

# Afni_proc.py EPI pre-processing
if ( $AP > 1 ) then
	set AP = 1
else if ( $AP < 0 ) then
	set AP = 0
endif

# ROI correlation
if ( $PP > 1 ) then
	set PP = 1
else if ( $PP < 0 ) then
	set PP = 0
endif

################################################################# 

# Input and output directiores
set dir_basic  = $INPUTDIR   	
set dir_aw = $dir_basic/${OUTPREFIX}aw       # AW output
set dir_ap = $dir_basic/${OUTPREFIX}ap
set dir_pp = $dir_basic/${OUTPREFIX}pp

# The template + atlas data; more follower datasets could be input.
# Abbreviations are defined for each dset, to simplify naming of files
set refdir    = $REFDIR
set refvol    = `\ls ${refdir}/NMT*_SS.nii.gz`
set refvol_ab = NMT2
set refatl    = `\ls ${refdir}/CHARM*.nii.gz \
                     ${refdir}/D99*.nii.gz`
set refatl_ab = ( CHARM D99 )
set refseg    = `\ls ${refdir}/NMT*_segmentation*.nii.gz  \
                     ${refdir}/supplemental_masks/NMT*_ventricles*.nii.gz`
set refseg_ab = ( SEG VENT )
set refmask   = `\ls ${refdir}/NMT*_brainmask*.gz`
set refmask_ab = MASK


### user's could set this environment variable here or in the own
### ~/.*rc files: useful if one has multiple CPUs/threads on the OS.
# setenv OMP_NUM_THREADS 12

# -----------------------------------------------------------------

echo "++ ${all_subj} has been specified."
# get list of subj to process
if ( $subj_list == 0  ) then 
	echo  $dir_basic
	cd ${dir_basic} 
	set all_subj = `find . -maxdepth 1 -type d -name "sub*" | cut -b3- | sort`
	echo "++ Found these ${#all_subj} subj:"
	echo "     ${all_subj}"
	cd -
endif

# -----------------------------------------------------------------

# animal_warper for skullstripping and nonlinear warp estimation
if ( $AW == 1 ) then
	set dir_aw = $dir_basic/${OUTPREFIX}aw       # AW output
	echo " ++ start warping"
	foreach subj ( ${all_subj} )
	   
	    # get first anat out of any possible ones in basic subj dir--
	    # but there is only one anat per subj here
	    if ( $BFC == 1 ) then
		 set all_anat = `find ${dir_basic}/${subj} -type f -name "sub*N4*nii*" `
	    else
	   	 set all_anat = `find ${dir_basic}/${subj} -type f -name "sub*T1w*nii*" `
	    endif
	
	    set anat_subj = "${all_anat[1]}"
	    echo "++ Found anat:"
	    echo "     ${anat_subj}"
	
	    set odir_aw = ${dir_aw}/${subj}
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
	    #    set all_epi = `find . -type f -name "*boldnii.gz" | grep -v "motioncorrection" | sort`
	    set all_epi = `find . -type f -name "*bold.nii.gz" | sort`
	
	    cd -
	    echo "++ Found EPIs:"
	    echo "     ${all_epi}"
	
	    # need each EPI file to have path attached
	    set subj_epi = ( )
	    foreach ee ( ${all_epi} )
	        set subj_epi = ( ${subj_epi} ${dir_basic}/${subj}/${ee} )
	    end
	
	    set odir_aw = ${dir_aw}/${subj}
	    set odir_ap = ${dir_ap}/${subj}
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
	    # because the input datasets have differing spatial res -- and so
	    # would likely have differing 'default' output spatial res, too,
	    # otherwise.
	
	    set dset_subj_anat = `\ls ${odir_aw}/${subj}*_ns.* | grep -v "_warp2std"`
	
	    #    if ( "${subj}" == "sub-01" || "${subj}" == "sub-02" || \
	    #         "${subj}" == "sub-03" ) then
	    #         set cost_a2e = "lpa+zz"
	    #    else
	    #        set cost_a2e = "lpc+zz"
	    #    endif
	
	    set cost_a2e = "lpc+zz"
	
	    afni_proc.py                                                              \
	        -subj_id                 ${subj}                                      \
	        -script                  ${odir_ap}/proc.$subj -scr_overwrite         \
	        -out_dir                 ${odir_ap}/${subj}.results                   \
	        -blocks tshift align tlrc volreg mask scale regress                   \
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
endif	
# -----------------------------------------------------------------

# 'Postprocessing' after the AP preproc for ROI-based analysis; here,
# just func correlation matrices
if ( $PP == 1 ) then

	foreach subj ( ${all_subj} )
	    
	    # ${dir_ap} is for ROI-based analysis
	    set odir_apr = ${dir_ap}/${subj}/${subj}.results # has AP results
	    set odir_pp  = ${dir_pp}/${subj}                 # for postproc
	    mkdir -p ${odir_pp}
	
	    # should just be one time series of residuals
	    set errts    = `ls ${dir_ap}/${subj}/${subj}.results/errts*HEAD`
	
	    # resample each standard space atlas to final EPI resolution
	    foreach ff ( ${refatl} ) 
	
	        # uppermost brick index in atlas dset
	        set nvi     = `3dinfo -nvi ${ff}`
	
	        set opref   = ${subj}_epi_`basename ${ff}`
	        set epi_atl = ${odir_pp}/${opref}
	
	        3dresample -echo_edu                      \
	            -overwrite                            \
	            -input         "${ff}"                \
	            -rmode          NN                    \
	            -master         ${errts}              \
	            -prefix         ${epi_atl}
	
	        # reattach any labels/atlases
	        3drefit -copytables "${ff}" ${epi_atl}
	        3drefit -cmap INT_CMAP      ${epi_atl}
	
	        set ooo     = `3dinfo -prefix_noext ${epi_atl}`
	        set onet    = ${odir_pp}/${ooo}
	
	        3dNetCorr -echo_edu                         \
	            -overwrite                              \
	            -fish_z                                 \
	            -inset   ${errts}                       \
	            -in_rois ${epi_atl}                     \
	            -prefix  ${onet}
	
	        foreach ii ( `seq 0 1 ${nvi}` )
	            set iii   = `printf "%03d" ${ii}`
	            set netcc = ${onet}_${iii}.netcc
	
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
	
