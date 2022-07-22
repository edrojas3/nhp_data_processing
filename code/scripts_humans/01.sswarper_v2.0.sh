!/bin/bash

# ----------------------SCRIPT INFO ----------------------#
# Author: Alfonso Fajardo (https://github.com/alffajardo) #
# Version: 2.0                                            # 
# Date: 2022-22-07                                        #
# USAGE: ./01.sswarper_v2.0.sh [FLAGS]     #
# ------------------------------------------------------- #



# -----------------helper function---------------------------------------------------------

export OMP_NUM_THREADS=4
help(){
echo -e "\e[0;33m"
 echo " USAGE: $0 [flags]"
 echo
 echo " COMPULSORY ARGUMENTS:" 
 echo " -S: Site. Path to BIDS (or bids-like) data directory. Ex. '/home/alfonso/site-HCP100'."
 echo " -s: Subject-id. Subject to preprocess with this script . Ex 'sub-001'." 
 echo
 echo " OPTIONAL ARGUMENTS:"
 echo " -o: Ouput directory. Default is '<Site>/data_SSW'." 
 echo " -r: Provide the path to the template. Dafault is MNI152_2009_template_SSW.nii.gz"
 echo



echo -e "\e[0m"
}

# display the help option when no arguments are provided

if [ $# -eq 0 ] ; then
help
exit 0
fi

# ------------------------------------------------------------------------------------------

# Case optional flags
optstring=":S:s:o:r:h"

while getopts $optstring options ; do

    case $options in
        S) site=${OPTARG}
        ;;
        s) subject_id=${OPTARG}
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

# ------------------ -----Configure optional arguments -------------------------------------------------------------------------

# output directory 
if [ -z $output_dir ]; then
output_dir=${site}/data_SSW

fi
mkdir -p $output_dir/${subject_id}

# reference template

if [ -z $ref_template ]; then
  ref_template="/AFNI/abin/MNI152_2009_template_SSW.nii.gz"
else
    if [ ! -f $ref_template ]; then
     echo -e "\e[0;31mERROR: Reference template $ref_template not found.\e[0m"
        exit 1
    fi
fi

# -------------------------------- Search for anatomicals ---------------------------------------

s_anat=$(find ${site}/${subject_id} -name "${subject_id}*T1w.nii.gz")

if [ -z $s_anat ]; then 
echo "Couldn't found an anatomical volume for $s.";
exit 1 
fi

# --------------------------------------- Print basic info----------------------------------

echo
echo -e "   \e[6;36mStarting Script Execution:\e[0m"
echo -e "\e[3;36m"
echo "  ++ OMP_NUM_THREADS: $OMP_NUM_THREADS "
echo "  ++ Site: $site"
echo "  ++ Subject ID: $subject_id"
echo "  ++ Reference template: $ref_template"
echo "  ++ Output Directory: ${output_dir}/${subject_id}"
echo "  ++  T1w file: $(basename $s_anat)."
echo
echo -e "\e[0m"


# ----------------- Now run @SSwarper script ----------------------------------

@SSwarper	\
-input $s_anat	\
-odir ${output_dir}/${subject_id}	\
-subid ${subject_id}	\
-base $ref_template		\
-giant_move		\
-echo			\
-verb |& tee ${output_dir}/${subject_id}/${subject_id}_sswarper.logs

# --------- compress *.nii files ----------------------------------------------

cd ${output_dir}/${subject_id}
gzip *.nii
cd $basedir

# ----------------------------------------script summary--------------------------

echo " SUMMARY:::::::::::::::::::::::::::::::::::::::::::::
        ++ OMP_NUM_THREADS: $OMP_NUM_THREADS 
        ++ Site: $site 
        ++ Subject ID: $subject_id
        ++ Reference template: $ref_template
        ++ Output Directory: ${output_dir}/${subject_id}
        ++ T1w file: $(basename $s_anat).
        ++ Executed on: $(hostname -i) 
        ++Date: $(date)

:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::" >> ${output_dir}/${subject_id}/${subject_id}_sswarper.logs



exit