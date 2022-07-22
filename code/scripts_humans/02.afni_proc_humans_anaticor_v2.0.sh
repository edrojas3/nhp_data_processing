#!/bin/bash

# ----------------------SCRIPT INFO ----------------------#
# Author: Alfonso Fajardo (https://github.com/alffajardo) #
# Version: 2.0                                            # 
# Date: 2022-21-07                                        #
# USAGE: ./02.afni_proc_humans_anaticor_v2.sh [FLAGS]     #
# ------------------------------------------------------- #



# -----------------helper function---------------------------------------------------------

export OMP_NUM_THREADS=4 
help(){
echo -e "\e[0;33m"
 echo " USAGE: $0 [flags]"
 echo
 echo " IMPORTANT: Before running this script preprocess anatomical T1w files with @SSwarper."
 echo
 echo " COMPULSORY ARGUMENTS:" 
 echo " -S: Site. Path to BIDS (or bids-like) data directory. Ex. '/home/alfonso/site-HCP100'."
 echo " -s: Subject-id. Subject to preprocess with this script . Ex 'sub-001'." 
 echo
 echo " OPTIONAL ARGUMENTS:"
 echo " -v: Ventricle mask. If you are not running the script inside our container you must provide the path to the ventricle mask"
 echo " -o: Ouput directory. Default is '<Site>/data_ap'." 
 echo " -w: Path to @SSwarper outputs folder. Default is '<Site>/data_SSW/<Subject-id>'."
 echo " -r: Provide the path to the template. Dafault is MNI152_2009_template.nii.gz"
 echo

echo -e "\e[0m"

}

# display the help option when no arguments are displayed

if [ $# -eq 0 ] ; then
help
exit 0
fi

# ------------------------------------------------------------------------------------------

# Case optional flags
optstring=":S:s:v:w:o:r:h"

while getopts $optstring options ; do

    case $options in
        S) site=${OPTARG}
        ;;
        s) subject_id=${OPTARG}
        ;;
        v) ventricle_mask=${OPTARG}
        ;;
        w) ssw_dir=${OPTARG}
        ;;
        o) output_dir=${OPTARG}
        ;; 
        r) ref_template=${OPTARG}
        ;;

        h) help
           exit 0 
        ;;
        ?) 
        echo 
        echo -e "\e[0;31mERROR: Invalid option -${OPTARG}\e[0m"
        exit 1 
        ;;
    esac

done

#----------------- Test validity of arguments Compulsory arguments -----------------------------------------------------

# Site 
if [ ! -d $site ] || [ -z $site ]; then
echo -e "\e[0;31mERROR: Site $site doesn't exists.\e[0m"
exit 1 
fi

# subject id 
if [ ! -d $site/$subject_id ] || [ -z $subject_id ] ; then
echo -e "\e[0;31mERROR: Subject $subject_id not found.\e[0m"
exit 1 
else
subject_id=$(echo $subject_id | cut -d '/' -f 1 )
fi

# ventricle mask 
if [ -z $ventricle_mask ] ; then
    ventricle_mask="/AFNI/abin/MNI152_T1_2mm_ventricle_mask.nii.gz"    
fi

if [ ! -f $ventricle_mask ]; then
echo -e "\e[0;31mERROR: Ventricle mask not found.\e[0m"
exit 1 
fi



# ------------------ -----Configure optional arguments -------------------------------------------------------------------------
# SSwarper files


if [ -z $ssw_dir ] ; then
    ssw_dir=${site}/data_SSW/${subject_id}
fi
# Asses if sswarper files folder exists
if [ ! -d $ssw_dir ] ; then 
        echo -e "\e[0;31mERROR: @SSwarper outputs directory $ssw_dir was not found.\e[0m"
        exit 1
fi
# Asses if sswarper  files exists

ssw_files=$(ls $ssw_dir | grep anatQQ | grep -v jpg)

if [  -z $ssw_files ] ; then 
        echo -e "\e[0;31mERROR: No valid @SSwarper files were found in $ssw_dir.\e[0m"
        exit 1
fi


# output directory 
if [ -z $output_dir ]; then
output_dir=${site}/data_ap/anaticor

fi
mkdir -p $output_dir/${subject_id}

# reference template

if [ -z $ref_template ]; then
  ref_template="MNI152_2009_template.nii.gz"
else
    if [ ! -f $ref_template ]; then
     echo -e "\e[0;31mERROR: Reference template $ref_template not found.\e[0m"
        exit 1
    fi
fi

# Search for ecoplanar (functional images)

s_epi=$(find $site/$subject_id -type f -name "${subject_id}*bold.nii.gz" | sort -V )

if [ -z $s_epi ]; then
echo -e "\e[0;31mERROR: No epis found.\e[0m"
        exit 1
fi




echo
echo -e "   \e[6;36mStarting Script Execution:\e[0m"
echo -e "\e[3;36m"
echo "  ++ OMP_NUM_THREADS: $OMP_NUM_THREADS "
echo "  ++ Site: $site"
echo "  ++ Subject ID: $subject_id"
echo "  ++ Ventricle mask: $ventricle_mask"
echo "  ++ @SSwarper directory: $ssw_dir"
echo "  ++ @SSwarper files: $ssw_files"
echo
echo "  ++ Reference template: $ref_template"
echo "  ++ Output Directory: $output_dir/${subject_id}"
echo "  ++ Epi dataset(s): $s_epi."
echo
echo -e "\e[0m"
sleep 5s

# -------------------------- Program starts here ---------------------------------------
basedir=$PWD
cost_func='lpc+ZZ'

# --------------------------- Set some variables --------------------------------------------

# start segmentation of images
if [ ! -f $ssw_dir/Classes.nii.gz ]; then
echo "  ++ Starting Tissue Segmentation of anatomical file ..."

cd $ssw_dir

3dSeg  -anat anatSS.${subject_id}.nii.gz -mask AUTO \
       -classes 'CSF ; GM ; WM' \
       -bias_fwhm 25 -mixfrac UNI -main_N 5 \
       -blur_meth BFT
    
    # Convert to Nifti
    echo Converting output to NIFTI
    3dAFNItoNIFTI -prefix Classes.nii.gz Segsy/Classes+orig.BRIK.gz

    # Extract white matter and csf mask 

    # CSF 
    3dcalc -a Classes.nii.gz -prefix anatSS.${subject_id}.CSF.nii.gz -expr "within(a,1,1)"
    # WM
    3dcalc -a Classes.nii.gz -prefix anatSS.${subject_id}.WM.nii.gz -expr "within(a,3,3)"


    # rm Segsy directory
    rm -rf Segsy
    
    cd $basedir
fi

# ----------------------------- Preprocessing Script ------------------------------------------
sleep 5s
echo -e  "  \e[6;36m+Creating Preprocessing script...\e[0m"
echo 
afni_proc.py	\
  -subj_id ${subject_id}	\
  -script ${output_dir}/${subject_id}/proc_${subject_id}.tsch \
  -scr_overwrite	\
  -remove_preproc_files \
  -out_dir ${output_dir}/${subject_id}/${subject_id}.results	\
  -dsets ${s_epi[@]}	\
  -tcat_remove_first_trs 4 \
  -blocks  despike align tlrc volreg mask scale regress	\
  -radial_correlate_blocks tcat volreg	\
  -copy_anat ${ssw_dir}/anatSS.${subject_id}.nii.gz	\
  -anat_has_skull no	\
  -anat_uniform_method none \
  -align_opts_aea -cost $cost_func -giant_move -check_flip -cmass cmass	\
  -volreg_align_to MIN_OUTLIER	\
  -volreg_align_e2a	\
  -volreg_tlrc_warp	\
  -volreg_warp_dxyz 2.0 	\
	-mask_import Tvent_Mask $ventricle_mask \
    -anat_follower_ROI WM_Mask epi ${ssw_dir}/anatSS.${subject_id}.WM.nii.gz  \
	-anat_follower_ROI CSF_Mask epi ${ssw_dir}/anatSS.${subject_id}.CSF.nii.gz \
    -mask_intersect Svent_Mask Tvent_Mask CSF_Mask \
	-mask_union Svent_WM_Mask Svent_Mask WM_Mask   \
    -anat_follower_erode WM_Mask CSF_Mask \
        -tlrc_base $ref_template	\
        -tlrc_NL_warp 	\
        -tlrc_NL_warped_dsets	\
 	${ssw_dir}/anatQQ.${subject_id}.nii.gz			\
 	 ${ssw_dir}/anatQQ.${subject_id}.aff12.1D			\
 	 ${ssw_dir}/anatQQ.${subject_id}_WARP.nii.gz			\
	 -mask_epi_anat yes	\
  	-regress_motion_per_run \
	-regress_ROI_PC_per_run Svent_Mask 3 \
	-regress_ROI_PC_per_run WM_Mask 3 \
	-regress_make_corr_vols WM_Mask Svent_WM_Mask \
	-regress_anaticor_fast \
    -regress_anaticor_label Svent_WM_Mask \
  	-regress_apply_mot_types demean deriv	\
  	-regress_censor_motion 0.3						\
  	-regress_censor_outliers 0.1						\
  	-regress_est_blur_epits						\
  	-regress_run_clustsim yes	\
  	-regress_est_blur_errts 	\
	-html_review_style pythonic 	\
	-execute

# 
echo


# convert preprocessed file to Nifti

epi_preproc=$(find ${output_dir}/${subject_id} -name "errts*HEAD"  )
epi_nifti=$(basename $epi_preproc | sed "s/.HEAD/.nii.gz/g")

if [ -f $epi_preproc ]
3dAFNItoNIFTI -prefix $epi_nifti $epi_preproc

fi
# remove 
if [ -f $epi_nifti ]; then
 rm $(find ${output_dir}/${subject_id} -name "errts*HEAD")
 rm $(find ${output_dir}/${subject_id} -name "errts*BRIK")
fi

echo "  ++DONE: Preprecessing was executed in $(hostname -I)"

exit 0
