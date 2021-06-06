#!/bin/tcsh -f

# USAGE: aw.tcsh <-i directory/with/subject> [-o|-s|-r|-h]

# -o: output directory
# -s: string with subjects to preproces (ex: 'sub-1 sub-2 sub-5')
# -r: directory with template and atlas. DEFAULT: $HOME/atlases_and_templates/NMT_v2.0_sym/NMT_v2.0_sym_05mm
# -h: display this help

# The script is inspirated by (ie. copy-pasted) do_all.tcsh file available with @INSTALL_MACAQUE_DEMO in afni.

# The script is meant to be run inside a container with AFNI and @animal_warper. There is one inside Don Clusterio at: /mis/purcell/alfonso/tmp/container/afni.sif. Be sure to bind (ie. mount) the directory with the atlas/templates and subjects to the home directory.

# DEFAULTS
set OUTDIR = aw_out
set REFDIR = $HOME/atlases_and_templates/NMT_v2.0_sym/NMT_v2.0_sym_05mm
set subj_list = 0

# ARGUMENTS
set nargs = `echo $#argv`
foreach n ( `seq 1 2 $nargs` )
		@ val=$n + 1
		switch ( $argv[$n] )
			case -o:
				set OUTDIR = $argv[$val] 
				breaksw
			case -i:
				set INPUTDIR = $argv[$val] 
	 			breaksw 
			case -s:
				set all_subj = `echo $argv[$val]`
				set subj_list = 1
				breaksw
			case -r:
				set REFDIR = $argv[$val]
				breaksw
			case -h:
				help
				exit
				breaksw
		endsw
end

# Input and output directiores
set dir_basic  = $INPUTDIR   	
set dir_aw     = $OUTDIR       # AW output

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

# get list of subj to process
if ( $subj_list == 0  ) then 
	cd ${dir_basic} 
	set all_subj = `find . -maxdepth 1 -type d -name "sub*" | cut -b3- | sort`
	echo "++ Found these ${#all_subj} subj:"
	echo "     ${all_subj}"
	cd -
endif
# -----------------------------------------------------------------

# animal_warper for skullstripping and nonlinear warp estimation

foreach subj ( ${all_subj} )
   
    # get first anat out of any possible ones in basic subj dir--
    # but there is only one anat per subj here
    cd ${dir_basic}/${subj}
    set all_anat = `find . -type f -name "sub*T1w*nii*"`
    cd -
    set anat_subj = "${dir_basic}/${subj}/${all_anat[1]}"
    echo "++ Found anat:"
    echo "     ${anat_subj}"

    set odir_aw = ${dir_aw}/${subj}
    \mkdir -p ${odir_aw}

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


# -----------------------------------------------------------------

