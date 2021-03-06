#!/bin/bash

# --------------------------- Create a helper function ------------------------

help ()
{
	echo
       	echo "Functional preprocessing with afni_proc.py WITHOUT VOXEL SMOOTHING.\
				If you like it smooth, try nhp-chmx_afni_proc_ap_vox.sh"
       	echo
       	echo "USAGE: $(basename $0) <-S site_directory> <-s subject_id> [options]";
       	echo
       	echo "MNADATORY INPUTS:"
       	echo "-S: /path/to/site-directory"
       	echo "-s: subject id. Ex. sub-032202"
       	echo
       	echo "OPTIONAL INPUTS"
       	echo "-h: print help"
	echo "-w: path to animal_warper results directory. Default = site/data_aw"
       	echo "-o: Output directory. DEFAULT: site/data_ap. If the output directory\
				doesn't exist, the script will create one. The script also creates a folder\
				inside of the output directory named as the subject id. All the afni_proc.py outputs will be saved in this data_ap/anaticor/sub-id path."
       	echo  "-r: Template DEFAULT:/misc/tezca/reduardo/resources/atlases_and_templates/NMT_v2.0_sym/NMT_v2.0_sym_05mm. Inside of this folder a NMT*SS.nii.gz must exxist."
       	echo "-c: AFNI container directory. DEFAULT:/misc/purcell/alfonso/tmp/container/afni.sif."
       	echo
       	echo "EXample: use afni_proc.py to preprocess the functional data of sub-032202 of site-blah and save the output in another folder/data_ap."
       	echo "$(basename $0) -S site-blah -s sub-032202 -w site-blah/data_aw -o other_folder/data_ap"
       	echo
	echo NOTES
	echo "- The script takes all the functional images in path/to/site/sub-id/ses*/func/*bold.nii.gz"
	echo "- The cost function is fixed a lpc+zz option."

}



# ----- make sure that arguments were provided for the script -----------------
if [ $# -eq 0 ]
then
echo -e "\e[1;31m No arguments provided\e[0m"
help
exit 0
fi


# -------------- Define some varibables ---------------------------------------

cost_func='lpc+ZZ'
basedir=${PWD}
export OMP_NUM_THREADS=4
# -------------- case options ------------------------------------------------

while getopts "S:s:r:o:w:vh" opt; do
	case ${opt} in
		S) site=${OPTARG};;
    s) s=${OPTARG};;
    r) ref_template=${OPTARG};;
    o) outdir=${OPTARG};;
	w) data_SSW=${OPTARG};;
	v) ventricle_mask=${OPTARG};;
                h) help
                   exit
                   ;;
                \?) help
                    exit

    esac
done



#------- Find images and check that all variables are set correctly -----------
export GZIP=-9
# DEFAULT FOR SS WARPER R INPUTS AND OUTPUT DIRECTORY
if [ -z $data_SSW ]
then
data_SSW=${site}/data_SSW
fi

# output directory.
if [ -z $outdir ]
then
outdir=$site
fi

# Define reference template
if [ -z  $ref_template ]
then
ref_template=/AFNI/abin/MNI152_2009_template.nii.gz
fi

# Ventricles mask 

if [ -z $ventricle_mask ]
then
ventricle_mask=/AFNI/abin/MNI152_T1_2mm_ventricle_mask.nii.gz
fi

echo "Checking if everything is in it's right place"
s_epi=$(find $site/$s -type f -name "*bold.nii.gz" | sort -V )
# s_anat=$(ls $data_SSW/${s}/anatQQ.sub-* | grep -v "_warp2std")

if [ -z "$(find $data_SSW/${s} -name "anatQQ*")" ]
then
	echo -e "\e[0;31mERROR: No anatomical preprocessed sswarper files were in\
	 ${data_SSW}.Run SSwarper first or specify sswarper files path with the -w Flag.\e[0m"
 exit 1
fi

# --------------------- Prepare for the battle --------------------------------

 mkdir -p $outdir/data_ap/anaticor/${s}
 cd $outdir/data_ap/anaticor/${s}

	echo -e  "\e[0;32mCreating Preprocessing script\e[0m"

  afni_proc.py	\
  -subj_id ${s}	\
  -script ${outdir}/data_ap/anaticor/${s}/proc_${s}.tsch \
  -scr_overwrite	\
  -remove_preproc_files \
  -out_dir ${outdir}/data_ap/anaticor/${s}/${s}.results		\
  -dsets ${s_epi[@]}	\
  -tcat_remove_first_trs 4						\
  -blocks  despike align tlrc volreg mask scale regress	\
  -radial_correlate_blocks tcat volreg	\
  -copy_anat ${data_SSW}/${s}/anatSS.${s}.nii.gz	\
  -anat_has_skull no	\
  -align_opts_aea -cost $cost_func -giant_move -check_flip -cmass cmass	\
  -volreg_align_to MIN_OUTLIER	\
  -volreg_align_e2a	\
  -volreg_tlrc_warp	\
  -volreg_warp_dxyz 2.0 	\
	-mask_segment_anat yes \
	-mask_segment_erode yes  \
	-mask_import Tvent $ventricle_mask \
	-mask_intersect Svent CSFe Tvent \
  -tlrc_base $ref_template	\
  -tlrc_NL_warp 	\
  -tlrc_NL_warped_dsets	\
 	 ${data_SSW}/${s}/anatQQ.${s}.nii.gz			\
 	 ${data_SSW}/${s}/anatQQ.${s}.aff12.1D			\
 	 ${data_SSW}/${s}/anatQQ.${s}_WARP.nii.gz			\
	 -mask_epi_anat yes	\
  	-regress_motion_per_run						\
	-regress_ROI_PC_per_run Svent 3 \
	-regress_ROI_PC_per_run WMe 3 \
	-regress_make_corr_vols WMe Svent \
	-regress_anaticor_fast \
  	-regress_apply_mot_types demean deriv	\
  	-regress_censor_motion 0.3						\
  	-regress_censor_outliers 0.1						\
  	-regress_est_blur_epits						\
  	-regress_run_clustsim yes	\
  	-regress_est_blur_errts 	\
	-html_review_style pythonic 	\
	-execute


	echo "Done..."

errts_file=$(find ${outdir}/data_ap/anaticor/${s}/${s}.results -type f -name "errts*HEAD")

if ! [ -z $errts_file ]
then
echo "Converting errts.$s.tproject+tlrc to NIFTI because who uses BRIK?"
3dAFNItoNIFTI -prefix ${outdir}/data_ap/anaticor/${s}/${s}.results/errts.${s}.anaticor.\
tproject+tlrc.nii.gz $errts_file
rm $errts_file
fi
# Execute quality control scripts
cd ${outdir}/data_ap/anaticor/${s}/${s}.results

# Convert masks to Nifti
for f in *mask*HEAD
do
3dAFNItoNIFTI $f
done
gzip *.nii

cd $basedir

 	
 	duration=$SECONDS
 	echo "$(($duration / 60)) minutes and $(($duration % 60)) seconds elapsed."

cd $basedir
exit 0
