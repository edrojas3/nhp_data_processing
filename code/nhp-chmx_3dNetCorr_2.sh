#!/bin/bash

nc1=$1
outdir=$2

rois=($(find $nc1 -type f -name "*Z*.BRIK" | awk -F + '{print $1}' | awk -F _ '{print $NF}' | sort -u))

if [ ! -d $out ]; then mkdir -p $outdir; fi

for roi in ${rois[@]}; do
		left_corrfiles=($(find $nc1/*/*left* -type f -name "*Z*$roi*.BRIK"))
		right_corrfiles=($(find $nc1/*/*right* -type f -name "*Z*$roi*.BRIK"))

		3dttest++                                 \
				-prefix $outdir/${roi}_left_nc_wb \
				-setA ${left_corrfiles[@]} 

		3dttest++                                  \
				-prefix $outdir/${roi}_right_nc_wb \
				-setA ${right_corrfiles[@]} 
done
