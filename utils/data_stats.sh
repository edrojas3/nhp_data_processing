#!/bin/bash

site=$1

printf "%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n" \
	sub-id ses run img dim1 dim2 dim3 pixdim1 pixdim2 pixdim3 \
		> $site/T1_info.txt

t1s=($(find $site/sub-* -type f -name "*T1w.nii.gz" | sort -V))
for ii in ${t1s[@]}
do
	fname=$(echo $ii | awk -F/ '{print $NF}')
	sub=$( echo $fname | cut -d_ -f1)
	ses=$( echo $fname | cut -d_ -f2)
	run=$( echo $fname | cut -d_ -f3)
	img=$( echo $fname | cut -d_ -f4 | cut -d. -f1)

	info=$(fslinfo $ii)
	dim1=$(echo $info | cut -d " " -f4)
	dim2=$(echo $info | cut -d " " -f6)
	dim3=$(echo $info | cut -d " " -f8)
	pixdim1=$(echo $info | cut -d " " -f14)
	pixdim2=$(echo $info | cut -d " " -f16)
	pixdim3=$(echo $info | cut -d " " -f18)

	printf "%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n" \
		$sub $ses $run $img $dim1 $dim2 $dim3 $pixdim1 $pixdim2 $pixdim3\
		>> $site/T1_info.txt

done

printf "%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n" \
	sub ses run img \
       	dim1 dim2 dim3 nvols \
	pixdim1 pixdim2 pixdim3 TR \
	> $site/bold_info.txt

t2s=($(find $site/sub-* -type f -name "*bold.nii.gz" | sort -V))
for ii in ${t2s[@]}
do
	fname=$(echo $ii | awk -F/ '{print $NF}')
	sub=$( echo $fname | cut -d_ -f1)
	ses=$( echo $fname | cut -d_ -f2)
	run=$( echo $fname | cut -d_ -f3)
	img=$( echo $fname | cut -d_ -f4 | cut -d. -f1)

	info=$(fslinfo $ii)
	dim1=$(echo $info | cut -d " " -f4)
	dim2=$(echo $info | cut -d " " -f6)
	dim3=$(echo $info | cut -d " " -f8)
	nvols=$(echo $info | cut -d " " -f10)
	pixdim1=$(echo $info | cut -d " " -f14)
	pixdim2=$(echo $info | cut -d " " -f16)
	pixdim3=$(echo $info | cut -d " " -f18)
	TR=$(echo $info | cut -d " " -f20)


	printf "%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n" \
		$sub $ses $run $img \
	       	$dim1 $dim2 $dim3 $nvols \
		$pixdim1 $pixdim2 $pixdim3 $TR \
		>> $site/bold_info.txt

done

