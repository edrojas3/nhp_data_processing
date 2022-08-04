#!/bin/bash

sub=$1

sitedir=$MACADATA/site-ucdavis
outdir=/misc/fourier/reduardo/site-ucdavis/align_test/$sub
container=/misc/purcell/alfonso/tmp/container/afni.sif

 if [ ! -d $outdir ]; then mkdir -p $outdir; fi

anatnii=$sitedir/data_aw/$sub/${sub}_anat_nsu.nii.gz
epinii=$sitedir/$sub/*/func/*bold_unwarped.nii.gz

3dcopy $anatnii $outdir/${sub}_anat_nsu
anatbrik=$outdir/${sub}_anat_nsu+orig

3dTcat -prefix $outdir/${sub}_epi ${epinii}'[5]'
epibrik=$outdir/${sub}_epi+orig

cd $outdir
align_epi_anat.py \
		-anat2epi \
		-anat ${sub}_anat_nsu+orig \
		-epi ${sub}_epi+orig \
		-epi_base 0 \
		-epi_strip 3dAutomask \
		-anat_has_skull no \
		-giant_move \
		-cmass cmass \
		-feature_size 0.5 \
		-volreg off -tshift off \
		-cost lpc \
		-multi_cost lpc+ZZ mi nmi lpa ls

cd $sitedir
