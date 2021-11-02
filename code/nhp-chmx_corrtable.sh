#!/bin/bash

help(){
	echo 
	echo "Extracts the voxel of max correlation for each seed."
	echo
	echo "USAGE: $(basename "$0") <sbcadir> <subject> [outfile.tsv]"
	echo
	echo "sbcadir: directory where sbca results are located. Ex. path/to/site-ecnu/sbca"
	echo "subject: subject id. Ex. sub-032202"
	echo "outfile.tsv: name of output file. Default: path/to/sbcadir/corrtable.tsv"
	echo
}

if [ $# -lt 2 ]; then
	help
       	exit 0
fi

sbcadir=$1
subj=$2
out=$3

workdir=$sbcadir/$subj

corrdir=$workdir/corr_files

targetstxt=$workdir/targets.tsv
targets=($(find $corrdir -maxdepth 1 -type f -name "target*_corr.nii.gz" | sort -V))

seedstxt=$workdir/seeds.tsv
seeds=$workdir/seeds_in_${subj}_epi.nii.gz
seeds_index=($(tail $seedstxt -n +2 | awk '{print $1}'))

if [ $# -lt 3 ]; then
	out=$workdir/corrtable.tsv
fi
touch $out.temp

echo "Correlation tables for $subj..."

for t in ${targets[@]}
do

	target_index=$(basename $t | cut -d_ -f2)

	echo "Processing target $target_index of ${#targets[@]}"

	for s in ${seeds_index[@]}
	do
		nhp-chmx_mask_from_roi_index.sh $seeds $s $workdir/seed_mask_temp
		fslmaths $t -mul $workdir/seed_mask_temp.nii.gz $workdir/target_corr_temp

		# LOCATION OF MAX CORR VOXEL

		## Scale image to obtain the voxel location of  max corr value.
	        ## Necessary 'cause tha max corr value can be less than 0.
		minval=$(fslstats $workdir/target_corr_temp.nii.gz -P 0)	
		minval_sign=$(echo $minval | cut -d. -f1 | sed -e 's/0/1/')
		if [ $minval_sign -lt 0 ]; then
			fslmaths $workdir/target_corr_temp.nii.gz -add ${minval#-} $workdir/target_corr_scaled_temp
		else
			fslmaths $workdir/target_corr_temp.nii.gz -sub ${minval} $workdir/target_corr_scaled_temp
		fi

		## reset voxels outside mask to 0		
		fslmaths $workdir/target_corr_scaled_temp.nii.gz -mul $workdir/seed_mask_temp.nii.gz $workdir/target_corr_scaled_temp.nii.gz 
		maxval=$(fslstats $workdir/target_corr_scaled_temp.nii.gz -P 100)
		fslmaths $workdir/target_corr_scaled_temp.nii.gz -div $maxval $workdir/target_corr_scaled_temp.nii.gz

		## voxel location
		vox=$(fslstats $workdir/target_corr_scaled_temp.nii.gz -x) # coordinates of max value

		# CORR VAL
		maxval=$(fslstats $workdir/target_corr_temp.nii.gz -P 100)
		
		# TARGET AND SEED NAME
		targetname=$(cat $targetstxt | awk -v ti="$target_index" '$1 == ti' | awk '{print $3}')
		seedname=$(cat $seedstxt | awk -v si="$s" '$1 == si' | awk '{print $3}')

		echo $maxval   $vox

		# ADD TO TABLE
		printf "%s\t%s\t%s\t%s\n" \
			"$targetname" \
		       "$seedname" \
		       "$maxval" \
		      " $(echo $vox | sed -e 's/ /,/g' -e 's/,$//')" >> $out.temp

	done
done

# ADD COLUMN NAMES
colnames=(target seed rval voxel)
(IFS=$'\t'; echo "${colnames[*]}"; cat $out.temp) > $out

rm $workdir/*temp.nii.gz $out.temp 

