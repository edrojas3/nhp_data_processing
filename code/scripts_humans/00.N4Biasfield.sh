#!/bin/bash

# USAGE Compute biasfield  N4 biasfield correction in T1w

# Compulsory arguements:

# $1: PATH to site. EX ${HOME}/site-HCP100
# $2 subject id to preprocess

#
Site=$1
subj=$2

# Evaluate if N4BiasFieldCorrection script exists

if [ ! -f "$(which N4BiasFieldCorrection)" ]; then
    echo -e "\e[3;31mError: N4BiasFieldCorrection not found.\e[0m"
    exit 1
fi



# evaluate the number of arguments
if [ $# -lt 2 ]; then
 echo -e  "\e[3;31mError: Insufficient number arguments.\e[0m"
 echo -e "\e[3;97mPlease run "bash 00.N4Biasfield.sh PATH/TO/SITE SUBJECT-ID\e[0m""
    exit 1
fi

# Evalute if site and subject exist

if [ ! -d ${Site}/${subj} ]; then
    echo -e  "\e[3;31mError: Directory ${Site}/${subj} not found\e[0m"
    exit 1
fi

# set the path to T1w file

T1w_file=$(find $Site/${subj} -type f -name "${subj}*T1w.nii.gz")
output_file=$(echo $T1w_file | sed 's/.nii.gz/_N4.nii.gz/g')

## ---- Run N4BiasField Correction





    N4BiasFieldCorrection -v -i $T1w_file -o $output_file

echo ++DONE!

exit 0




