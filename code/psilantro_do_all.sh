#!/bin/bash

help ()
{
	echo "\"User friendly\" script for non-human primate anatomical registration, functional preprocessing, and ROI connectivity."
	echo
	echo "USAGE: $(basename $0) -i <directory/with/subjects> [-o|-s|-b|-w|-p|-P|-a|-m|-h]"
	echo
	echo "The script performs a functional connectivity processing sequence, or a set of substeps. Except for bias field correction, everything is done inside a container (/misc/purcell/alfonso/tmp/container/afni.sif). An error will occur with printing the correlation matrices because matplotlib.pyplot."
	echo 
	echo "INPUTS:"
	echo "-i: directory with subjects. Ex. $HOME/primeDE/site-ecnu"
	echo
	echo "-o: prefix for the output directories. data_ is default. The script will assign an automated suffix for each step: aw for animal warper registration, ap for afni_proc.py EPI preprocessing, pp for post-processing/correlation matrices. This means that data_aw will be the output directory with all the anatomical registration files. Also, all the output directories will be inside the directory specified with the -i option."
	echo
	echo "-s: specify a single subject. Ex. sub-032212. It has to be a directory within the directory specified with the -i option."
	echo
	echo "-b: perform ANTs N4BiasFieldCorrection and use the output for anatomical registration. If there are more than one anatomical volume, the script will perform the bias field correction on every anatomical it finds."
	echo
       	echo "-w: perform anatomical registration with @animal_warper" 
	echo
	echo "-p: perform EPI preprocessing with afni_proc.py. Needs an existing @animal_warper output directory."
	echo
	echo "-P: get correlation matrices. Needs an existing afni_proc.py output directory."
	echo
	echo "-a: performs the whole processing sequence. Equivalent to -wpP."
	echo
	echo "-m: set main directory. HOME directory is default. This directory is binded to the container /home directory."
	echo
	echo "-c: set container path. Default: /misc/purcell/alfonso/tmp/container/afni.sif "
	echo
	echo "-h: print this help"
	echo
	echo "Examples:"
	echo
	echo "Do the whole processing (-a) with all the subjects of the ecnu data set (-i):"
	echo "$(basename $0) -i $HOME/data/primeDE/site-ecnu -a"
	echo
	echo "Do bias field correction (-b) and only do anatomical registration and epi preprocessing (-wp):"
	echo "$(basename $0) -i $HOME/data/primeDE/site-ecnu -b -wp" 
	echo 
	echo "Get the epi post-processing (-P) using only subject sub-032212:"
	echo "$(basename $0) -i $HOME/data/primeDE/site-ecnu -s sub-032212 -P"
	echo
}
# TO DO:
# 1. Add a test command to check if the directory of the previous step exists.
# 2. Add to animal_proc.tcsh an -a flag option to turn on all processing steps
# 3. Long getopts 
#
# NOTES:
# For some reason, giving a list of subjects won't work. So, is either one subject or the whole directory. My impression is that this problem would be easier to solve in bash, but to translate everything from tcsh to bash sounds like work...

# Defaults
maindir=$HOME
subj_list=0
PREFIX=data_
container=/misc/purcell/alfonso/tmp/container/afni.sif
BFC=0
aw=0
ap=0
av=0
pp=0


while getopts "bi:o:s:m:c:awpvPh" opt; do
	case ${opt} in
		b) BFC=1;; # ANTs bias field correction
		i) DIR=${OPTARG};; # dir with subjects
		s) all_subj=${OPTARG} # specify subject
		   subj_list=1
		   ;;
		a) aw=1
		   ap=1
		   av=1
		   pp=1
		   ;;
		w) aw=1;; # run animal warper
		p) ap=1;; # run afni_proc.py
		v) av=1;; # run afni_proc.py for sbca
		P) pp=1;; # run post processing
		m) maindir=${OPTARG};; # sort of home directory
		o) PREFIX=${OPTARG};; # prefix of output directories
		c) container=${OPTARG};;
		h) help
		   exit
		   ;;
		\?) help	
		   exit
		   ;;
	esac
done


if [ $subj_list -eq 1 ]; then
	subj_paths=${all_subj}
	for sub in "${!subj_paths[@]}"; do
		subj_paths[$sub]=$DIR/${subj_paths[$sub]}
	done
else
	subj_paths=($(find $DIR -maxdepth 1 -type d -name "sub*" | sort))
fi

# Bias field correction with ANTs
if [ $BFC -eq 1 ]; then 
	echo "++ Bias Field Correction..."
	for sub in "${subj_paths[@]}"; do 
		anat_subj=$(find $sub -type f -name "sub*T1w*.nii.gz" | grep -v N4)
		anat_n=$(echo $anat_subj | awk '{print NF}')
		for anat in $(seq 1 $anat_n); do 
			a=$(echo $anat_subj | awk '{print $'$anat'}')
			anat_dir=$(dirname ${a})
	     		anat_base=$(basename ${a} | cut -d . -f 1)
	     		anat_N4=${anat_dir}/${anat_base}_N4.nii.gz
			if [ ! -f $anat_N4 ]; then
	    			N4BiasFieldCorrection -v -i $anat_subj -o $anat_N4
			fi
		done
	done
fi

## Animal warper, afni_proc.py, and post-processing within container

# look for animal_proc.tcsh command inside $maindir
animal_proc=$(find $maindir -type f -name animal_proc.tcsh) # loog for animal_proc.tcsh command inside $maindir

echo "Entering singularity..."
# run everything inside container
if [ $subj_list -eq 1 ]; then
	singularity exec -B /misc:/misc -B $maindir:/home --cleanenv $container $animal_proc -i $DIR -s ${all_subj} -o $PREFIX -b $BFC -aw $aw -ap $ap -apv $av -pp $pp
else
	singularity exec -B /misc:/misc -B $maindir:/home --cleanenv $container $animal_proc -i $DIR -o $PREFIX -b $BFC -aw $aw -ap $ap -apv $av -pp $pp
fi

