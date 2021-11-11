#!/bin/bash

help ()
{
	echo 
       	echo "Functional preprocessing with afni_proc.py WITH VOXEL SMOOTHING. If you don't like it smooth, try nhp-chmx_afni_proc_ap.sh"
       	echo
       	echo "USAGE: $(basename $0) <-S site_directory> <-s subject_id> [options]";
       	echo 
       	echo "MNADATORY INPUTS:"
       	echo "-S: /path/to/site-directory"
       	echo "-s: subject id. Ex. sub-032202"
       	echo 
       	echo "OPTIONAL INPUTS"
       	echo "-h: print help"
       	echo "-o: Output directory. DEFAULT: site/data_ap. If the output directory doesn't exist, the script will create one. The script also creates a folder inside of the output directory named as the subject id. All the afni_proc.py outputs will be saved in this data_ap/sub-id path." 
       	echo  "-r: NMT_v2 path. DEFAULT:/misc/tezca/reduardo/resources/atlases_and_templates/NMT_v2.0_sym/NMT_v2.0_sym_05mm. Inside of this folder a NMT*SS.nii.gz must exxist."
       	echo "-c: AFNI container directory. DEFAULT:/misc/purcell/alfonso/tmp/container/afni.sif."
       	echo
       	echo "EXample: use afni_proc.py to preprocess the functional data of sub-032202 of site-blah and save the output in another folder/data_ap."
       	echo "$(basename $0) -S site-blah -s sub-032202 -w site-blah/data_aw -o other_folder/data_ap"
       	echo 
	echo NOTES:
	echo "- The script takes all the functional images in path/to/site/sub-id/ses*/func/*bold.nii.gz"
	echo "- The cost function is fixed at lpc+zz option."

}

# SOME DEFAULTS
refdir=/misc/tezca/reduardo/resources/atlases_and_templates/NMT_v2.0_sym/NMT_v2.0_sym_05mm
container=/misc/purcell/alfonso/tmp/container/afni.sif
cost_func='lpc+zz'

# OPTIONS
while getopts "S:s:r:o:c:w:h" opt; do
	case ${opt} in
		S) site=${OPTARG};;
                s) s=${OPTARG};;
                r) refdir=${OPTARG};;
                o) outdir=${OPTARG};;
                c) container=${OPTARG};;
		w) data_aw=${OPTARG};;
                h) help
                   exit
                   ;;
                \?) help
                    exit
                    ;;
    esac
done


if [ "$#" -lt 2 ]; then help; exit 0; fi

# DEFAULTS FOR ANIMAL_WARPER INPUTS AND OUTPUT DIRECTORY
if [ -z $data_aw ]; then data_aw=$site/data_aw; fi
if [-z $outdir ]; then outdir=$site/data_ap_vox; fi

echo "Checking if everything is in it's right place"

if [ ! -d $refdir ]; then echo "No reference $ref found." ; exit 1; fi
if [ ! -d $site ]; then echo "No site with name $site found."; exit 1; fi
if [ ! -d $site/$s ]; then echo "No subject with id $s found in $site."; exit 1; fi
if [ ! -d $data_aw ]; then echo "No folder $data_aw for @animal_warper output found for $s"; exit 1; fi

refvol=$refdir/NMT*_SS.nii.gz
s_epi=($(find $site/$s -type f -name "*bold.nii.gz" | sort))
s_anat=$(ls $data_aw/${s}/*_ns.* | grep -v "_warp2std")

if [ -z $s_anat ]; then echo "No $s anatomical volume found."; exit 1; fi
if [ -z $s_epi ]; then echo "No functional data found."; exit 1; fi

if [ ! -d $outdir/$s ]; then mkdir -p $outdir/$s; fi

echo "Enter the singularity..."
echo "Preprocessing witn afni_proc.py"
singularity exec -B /misc:/misc --cleanenv $container afni_proc.py \
	-subj_id                 ${s}                                      \
	-script                  $outdir/$s/proc.$s -scr_overwrite         \
	-out_dir                 $outdir/$s/${s}.results                   \
	-blocks tshift align tlrc volreg blur mask scale regress              \
	-dsets                   $site/$s/*/func/*bold.nii.gz                                  \
	-copy_anat               "${s_anat}"                          \
	-anat_has_skull          no                                           \
	-anat_uniform_method     none                                         \
	-radial_correlate_blocks tcat volreg                                  \
	-radial_correlate_opts   -sphere_rad 14                               \
	-tcat_remove_first_trs   2                                            \
	-volreg_align_to         MIN_OUTLIER                                  \
	-volreg_align_e2a                                                     \
	-volreg_tlrc_warp                                                     \
	-volreg_warp_dxyz        1.25                                         \
	-blur_size 3.0 \
	-align_opts_aea          -cost ${cost_func} -giant_move                \
	                         -cmass cmass -feature_size 0.5               \
	-tlrc_base               ${refvol}                                    \
	-tlrc_NL_warp                                                         \
	-tlrc_NL_warped_dsets                                                 \
	    ${data_aw}/$s/${s}*_warp2std_nsu.nii.gz                           \
	    ${data_aw}/$s/${s}*_composite_linear_to_template.1D               \
	    ${data_aw}/$s/${s}*_shft_WARP.nii.gz                              \
	-regress_motion_per_run                                               \
	-regress_apply_mot_types  demean deriv                                \
	-regress_censor_motion    0.10                                        \
	-regress_censor_outliers  0.02                                        \
	-regress_est_blur_errts                                               \
	-regress_est_blur_epits                                               \
	-regress_run_clustsim     no                                          \
	-html_review_style        pythonic                                    \
	-execute

echo "Done..."

echo "Converting errts.$s.tproject+tlrc to NIFTI because who uses BRIK?"
singularity exec -B /misc:/misc --cleanenv $container 3dAFNItoNIFTI \
	-prefix $outdir/$s/$s.results/errts.$s.tproject+tlrc.nii.gz \
	$outdir/$s/$s.results/errts.$s.tproject+tlrc.

echo "This is the end my friend."
