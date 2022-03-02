#!/bin/bash



# ------------------------- Helper function -----------------------------------
help()
{
  echo
	echo "Anatomical registration to NMT space using AFNI's @animal_warper."
	echo
	echo "USAGE: $(basename $0) <-S site_directory> <-s subject_id> [options]";
	echo
	echo "MNADATORY INPUTS:"
	echo "-S: /path/to/site-directory"
	echo "-s: subject id. Ex. sub-032202"
	echo
	echo "OPTIONAL INPUTS"
	echo "-h: print help"
	echo "-o: Output directory. DEFAULT: site/data_aw. If the output directory \
  doesn't exist, the script will create one. The script also creates a folder \
  inside of the output directory named as subject id where all the \
  @animal_warper outputs will be saved."
	echo  "-r: NMT_v2 path. DEFAULT:\
  /misc/hahn2/alfonso/atlases_and_templates/MNI152_T1_2mm_template1.0_SSW.nii.gz.\
Inside of this folder a NMT*SS.nii.gz and a NMT*_brainmask.nii.gz must exist."
	echo "-b: Use a biased field corrected anatomical volume. It has to have a N4\
identifier. EX. site-ion/sub-032202/anat/sub-032202_T1_N4.nii.gz. Use ANTS' \
N4BiasFieldCorrection  function to get one. THIS OPTION DOESN'T NEED AN ARGUMENT."
	echo
	echo "EX: use biased field corrected T1 volume of sub-032202 inside site-ion."
	echo "$(basename $0) -S site-ion -s sub-032202 -b"
	echo
}

# --------------------------- Set Reference template --------------------------
export GZIP=-9
basedir=$PWD
ref_template=/misc/hahn2/alfonso/atlases_and_templates/\
MNI152_T1_2mm_template1.0_SSW.nii.gz

bfc=0

# ------ Enable some optional options for the script --------------------------
while getopts "S:s:h:r:o:b" opt; do
	case ${opt} in
		S) site=${OPTARG};;
		s) s=${OPTARG};;
		r) ref_template=${OPTARG};;
		o) outdir=${OPTARG};;
		h) help
		   exit
		   ;;
		b) bfc=1;;
		\?) help
	            exit
		    ;;
	esac
done

# ------- Make sure to provide aruguments for the function --------------------

if [ "$#" -eq 0 ]; then help; exit 0; fi

# ------ Control for N4BiasFieldCorrection option -----------------------------

if [ $bfc -eq 0 ]
then
	s_anat=$(find $site -type f \( -name "${s}*T1*nii*" -not -name "*N4*" \))
else
	s_anat=$(find $site -type f -name "${s}*N4*nii*")
fi

# --------------- set output directory ----------------------------------------

if [ -z $outdir ]
then
outdir=$site/data_ssw
fi
sswarper_file=$(which @SSwarper)

#---------------- make sure that some files and directories exist -------------

echo -e "\e[0;31m"
if [ ! -f $ref_template ]; then echo "No reference $ref_template found."
exit 1; fi

if [ ! -d $site ]; then echo "No site with name $site found.";
exit 1; fi
if [ ! -d $site/$s ]; then echo "No subject with id $s found in $site."
exit 1; fi
if [ -z "$s_anat" ]; then echo "Couldn't found an anatomical volume for $s.";
exit 1; fi
# SSwarper file
if [ -z $sswarper_file ]; then
echo "Couldn't found @SSwarper script"
exit 1
fi

# Antspath
if [ -z $ANTSPATH ]; then
echo "Couldn't found ANTS PATH script"
exit 1
fi

# outdir
if [ ! -d $outdir/${s} ]; then mkdir -p $outdir/${s} ; fi


echo -e "\e[0m"

# --------------------- start biasfield correction ----------------------------

if [ $bfc -eq 0 ]
then
bfc_anat=$(echo $s_anat | sed 's/.nii.gz/_N4.nii.gz/g')

N4BiasFieldCorrection -v -i $s_anat -o $bfc_anat

s_anat=$(echo $bfc_anat)

fi

# ----------------- Now run @SSwarper script ----------------------------------

@SSwarper	\
-input $s_anat	\
-odir ${outdir}/${s}	\
-subid ${s}	\
-base $ref_template		\
-giant_move		\
-echo			\
-verb |& tee ${outdir}/${s}/${s}_sswarper.logs


# --------- compress *.nii files ----------------------------------------------

cd ${outdir}/${s}
gzip *.nii
cd $basedir

# ------keep a record of where the script was run -----------------------------
echo -e "\e[0;33m"
echo THIS SCRIPT FOR SUBJECT ${s} WAS EXECUTED IN HOST: $(hostname). \
RELATED IP ADRESS IS: $(hostname -I | awk '{print $1}') \
>> ${outdir}/${s}/${s}_sswarper.logs

echo -e "\e[0m"

exit 0
