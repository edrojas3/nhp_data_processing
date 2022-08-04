#!/bin/bash

help ()
{
	echo
	echo Gets the eigen timeseries of all indexed rois in a 3d volume.
	echo USAGE: $(basename $0) epi.nii.gz roi.nii.gz [out.txt] [roinames.txt]
	echo
	echo Default output = ./eigts.tsv
	echo
}


epi=$1
roi=$2
out=$3
roinames=$4

id=$(echo $epi | awk -F/ '{print $NF}' | awk -F. '{print $2}')

echo check inputs
if [ $# -lt 2 ]; then help; exit 0; fi

echo out default
test -z $out && out=eigts.tsv

nroi=$(fslstats $roi -P 100 | cut -d. -f1)
echo $nroi rois found

echo creating out file
touch $out

echo getting eigen timeseries
for n in $(seq 1 $nroi)
do
	out_temp=${id}_out_temp_$n.txt
	nhp-chmx_mask_from_roi_index.sh $roi $n ${id}_mask_temp.nii.gz

	echo timeseries for roi $n
	fslmeants -i $epi -m ${id}_mask_temp.nii.gz --eig > $out_temp
done

outfiles=$(ls ${id}_out_temp* | sort -V)
paste $outfiles > ${id}_out_temp.txt

if [ $# -eq 4 ]
then
	namearray=($(cat $roinames))
	(IFS=$'\t'; echo "${namearray[*]}"; cat ${id}_out_temp.txt) > $out
else
	mv ${id}_out_temp.txt $out
fi


sed -i -e '/^[[:space:]]*$/d' $out

rm ${id}_out_temp*.txt 
rm ${id}_*temp.nii.gz

