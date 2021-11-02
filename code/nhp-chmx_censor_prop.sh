#!/bin/bash

help()
{
	echo 
	echo "Prints proportion of censored volumes by enorm or outlier count."
	echo
	echo "USAGE: nhp-chmx_censor_prop.sh -s SUBJECTID -d APDIR -t METRIC [-T]"
	echo 
	echo "Inputs:"
	echo "-s: subject id. Ex. 032212"
	echo "-d: afni_proc.py output directory of the subject specified in -s. Ex. ~/primeDE/site-ecnu/data_02_ap "
	echo "-t: type of metric. Choose between 'enorm' or 'outliers'"
	echo "-T: if selected a table will be printed with counts of ok volumes and censored volumes for both metrics."
	echo
}

if [ "$#" -lt 1 ]; then help; exit; fi

table=0
while getopts "d:s:t:hT" opt; do
	case ${opt} in
		d) apdir=$OPTARG;;
		s) sub=$OPTARG;;
		t) type=$OPTARG;;
		T) table=1;;
		h) help
		   exit
	           ;;	   
	       \?) help
		   exit
		   ;;
	esac
done

# Censor metrics
enorm=$apdir/${sub}/${sub}.results/motion_${sub}_enorm.1D
enorm_c=$apdir/${sub}/${sub}.results/motion_${sub}_censor.1D

outlier=$apdir/${sub}/${sub}.results/outcount.r01.1D
outlier_c=$apdir/${sub}/${sub}.results/outcount_${sub}_censor.1D

## stats
total_vols=$(cat $enorm | wc -l)

### enorm
not_censored=$(paste -sd+ $enorm_c | bc)
p_not_censored=$(bc <<< "scale=2; $not_censored/$total_vols")
censored=$(( $total_vols - $not_censored ))
p_censored=$(bc <<< "scale=2; $censored/$total_vols")

if [ "$type" = enorm ]; then
	echo $p_censored 
fi


if [ "$table" -eq 1 ]; then
	if [ -f "motion_stats.txt" ]; then rm motion_stats.txt; fi
	echo "Metric,OK,Censored,p_Censored" >> motion_stats.txt
	echo "enorm,$not_censored,$censored,$p_censored" >> motion_stats.txt
fi

### outlier counts
not_censored=$(paste -sd+ $outlier_c | bc)
p_not_censored=$(bc <<< "scale=2; $not_censored/$total_vols")
censored=$(( $total_vols - $not_censored ))
p_censored=$(bc <<< "scale=2; $censored/$total_vols")

if [ "$type" = outliers ]; then
	echo $p_censored 
fi

if [ "$table" -eq 1 ]; then
	echo "outliers,$not_censored,$censored,$p_censored" >> motion_stats.txt
	cat motion_stats.txt | column -s, -t
	rm motion_stats.txt
fi

#
##
### graph 
##
##graph=motion_plots.png
##1dplot.py -sepscl -boxplot_on -reverse_order -infiles $enorm $outcount -censor_files $outcensor $enorm_censor -censor_hline 0.1 0.02 -ylabels enorm outliers -xlabel  "vols" -title "Motion and outlier plots" -prefix  $graph
### rm motion_censor.1D
##
###clear
##
##echo " "
##echo " "
##cat motion_stats.txt | column -s, -t
##
###rm motion_stats.txt
##
##aiv $graph 
