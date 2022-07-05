#!/bin/bash

# Notes: Script created with the purpuse of skullstrip functional images and warp then to standard 
# space.
# Make sure to run the 00.N4Biasfield.sh script first




# ------------------------- Helper function -----------------------------------
help()
{
  echo
	echo "Anatomical registratio"
	echo
	echo "USAGE: $(basename $0) <-S site_directory> <-s subject_id> [options]";
	echo
	echo "Compulsory arguments:"
	echo "-S: /path/to/site-directory"
	echo "-s: subject id. Ex. sub-032202"
	echo
	echo "OPTIONAL INPUTS"
	echo "-h: print help"
	echo "-o: Output directory. DEFAULT: site/data_SSW. If the output directory \
  doesn't exist, the script will create one. The script also creates a folder \
  inside of the output directory named as subject id where all the \
  @SSwarper outputs will be saved."

}

# Limit the maximum number of CPU threads by setting this variable.

export OMP_NUM_THREADS=4

# --------------------------- Set Reference template and some variables --------------------------

export GZIP=-9
export basedir=$PWD
export ref_template=/AFNI/abin/MNI152_2009_template_SSW.nii.gz
export sswarper_file=$(which @SSwarper)

# ------ Enable some optional options for the script --------------------------
while getopts "S:s:h:r:o" opt; do
	case ${opt} in
		S) site=${OPTARG};;
		s) s=${OPTARG};;
		r) ref_template=${OPTARG};;
		o) outdir=${OPTARG};;
		h) help
		   exit
		   ;;
		\?) help
	            exit
		    ;;
	esac
done

# ------- Make sure to provide arGUuments for the function --------------------

if [ "$#" -eq 0 ]; then help; exit 0; fi

# ------ Find N4BiasField Correction output    -----------------------------
	s_anat=$(find $site -type f -name "${s}*N4*nii*"
# --------------- set output directory ----------------------------------------

if [ -z $outdir ]
then
outdir=$site/data_SSW/${s}
mkdir -p $outdir
fi
)

#---------------- make sure that some files and directories exist -------------

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

# ----------------- Now run @SSwarper script ----------------------------------

@SSwarper	\
-input $s_anat	\
-odir ${outdir}/${s}	\
-subid ${s}	\
-base $ref_template		\
-giant_move		\
-echo			\
-verb |& tee ${outdir}/data_SSW/${s}/${s}_sswarper.logs


# --------- compress *.nii files ----------------------------------------------

cd ${outdir}/data_SSW/${s}
gzip *.nii
cd $basedir

# ------keep a record of where the script was run -----------------------------
echo -e "\e[0;33m"
echo THIS SCRIPT FOR SUBJECT ${s} WAS EXECUTED IN HOST: $(hostname). \
RELATED IP ADRESS IS: $(hostname -I | awk '{print $1}') \
>> ${outdir}/data_SSW/${s}/${s}_sswarper.logs

echo -e "\e[0m"

exit 0
