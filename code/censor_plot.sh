#!/bin/bash

help()
{
	echo
	echo Plots motion metric as time series highlighting the censored volumes.
	echo
	echo USAGE: censor_plot.sh -s SUBJECTID -d APDIR -t METRIC
	echo
	echo INPUTS:
	echo "-s: subject id. Ex. 032212"
	echo "-d: afni_proc.py output directory of the subject specified in -s. Ex. ~/primeDE/site-ecnu/data_02_ap "
	echo "-t: type of metric. Choose between 'enorm' or 'outliers'"
	echo
}

if [ "$#" -lt 1 ]; then help; exit; fi

while getopts "s:d:t:h" opt; do
	case ${opt} in
		s) sub=$OPTARG;;
		d) apdir=$OPTARG;;
		t) type=$OPTARG;;
		h) help
			exit
			;;
	       \?) help
		       exit
		       ;;
       esac
done

# Censor metrics
if [ "$type" = enorm ]; then
	metric=$apdir/${sub}/${sub}.results/motion_${sub}_enorm.1D
	cfile=$apdir/${sub}/${sub}.results/motion_${sub}_censor.1D
elif [ "$type" = outliers ]; then
	metric=$apdir/${sub}/${sub}.results/outcount.r01.1D
	cfile=$apdir/${sub}/${sub}.results/outcount_${sub}_censor.1D
else
	echo "Wrong type of metric. Your choices are 'enorm' or 'outliers'"
	exit 1
fi
	
1dplot -censor $cfile -xlabel volumes -ylabel $type $metric 

