#!/bin/bash
help(){
echo
echo "USAGE: $(basename $0) -S site -s sub-id [options]"
echo
echo "Creates a confound.csv file with the eigen timeseries of CSF, white matter, and motion parameters to use in fsl_sbca."
echo
echo "MANDATORY INPUTS:"
echo "-S: full path to site directory (ex. /home/someone/mri/data/site-ecnu)"
echo "-s: ex. sub-032202"
echo 
echo "OPTIONS"
echo "-o: output directory, default = site/sbca"
echo "-w: animal_warper directory, defaulte = site/data_aw"
echo "-v: afni_proc.py directory, default = site/data_ap_vox"
echo "-c: afni container directory, default = /misc/purcell/alfonso/tmp/container/afni.sif"
echo "-h: print this help"
echo
echo "Output:"
echo "-confounds.txt: tab separated file with 8 columns, each one with the eigen timeseries of:"
echo "* 1. CSF"
echo "* 2. White matter"
echo "* 3 to 8: motion parameters"
echo
echo "CONSIDER THAT:"
echo "The script segments CSF and WM from the subject anatomical volume registered in template and skull stripped. "
}

container=/misc/purcell/alfonso/tmp/container/afni.sif

while getopts "S:s:o:w:v:c:h:" opt; do
	case ${opt} in
		S) site=${OPTARG};;
		s) subj=${OPTARG};;
		o) outdir=${OPTARG};;
		w) aw=${OPTARG};;
		v) apv=${OPTARG};;
		c) container=${OPTARG};;
		h) help
	           exit;;
		\?) help
		    exit;;
    	esac
done
 

if [ $# -lt 3 ]; then help; exit 1; fi

if [ -z $aw ]; then aw=$site/data_aw; fi
if [ -z $apv ]; then apv=$site/data_ap_vox; fi
if [ -z $outdir ]; then outdir=$site/sbca; fi

echo "+ Getting confounds file for $subj in $(echo $site | rev | cut -d/ -f1 | rev)"

test ! -d $outdir && mkdir -p $outdir/$subj

aw=$aw/$subj
apv=$apv/$subj/$subj.results
outdir=$outdir/$subj

if [ ! -d $aw ] || [ ! -d $apv ]; then
	echo "No animal_warper or ap_vox directory found. They are currently set at:"
	echo "animal_warper: $aw"
	echo "ap_vox: $apv"
fi

epi=$apv/errts.${subj}.tproject+tlrc.nii.gz

if [ ! -f $epi ]; then
	singularity exec -B /misc:/misc --cleanenv $container 3dAFNItoNIFTI -prefix $epi $apv/errts.${subj}.tproject+tlrc.
fi

# resample tissue to subject epi
echo "+ Tissue masks"

echo "++ Segmenting..."
fast -o $outdir/$subj $aw/${subj}_anat_warp2std_nsu.nii.gz

echo "++ Creating CSF and WM masks..."
singularity exec -B /misc:/misc --cleanenv $container 3dresample -input $outdir/*pve_0*.nii.gz -master $epi -prefix $outdir/pve_0_in_${subj}.nii.gz
fslmaths $outdir/pve_0_in_${subj}.nii.gz -thr 0.5 $outdir/csf_in_${subj}_epi
fslmaths $outdir/csf_in_${subj}_epi.nii.gz -bin $outdir/csf_in_${subj}_mask
fslmaths $outdir/csf_in_${subj}_epi.nii.gz -ero $outdir/csf_in_${subj}_mask_ero
 
singularity exec -B /misc:/misc --cleanenv $container 3dresample -input $outdir/*pve_2*.nii.gz -master $epi -prefix $outdir/pve_2_in_${subj}.nii.gz
fslmaths $outdir/pve_2_in_${subj}.nii.gz -thr 0.5 $outdir/wm_in_${subj}_epi
fslmaths $outdir/wm_in_${subj}_epi.nii.gz -bin $outdir/wm_in_${subj}_mask
fslmaths $outdir/wm_in_${subj}_epi.nii.gz -ero $outdir/wm_in_${subj}_mask_ero

csf=$outdir/csf_in_${subj}_mask_ero.nii.gz
wm=$outdir/wm_in_${subj}_mask_ero.nii.gz

echo "+ Tissue to $subj epi..."
wm_nmt=$aw/NMT_WM.nii.gz
csf_nmt=$aw/NMT_VENT.nii.gz

singularity exec -B /misc:/misc --cleanenv $container 3dresample -input $csf_nmt -master $epi -prefix $outdir/CSF_in_${subj}_epi.nii.gz
singularity exec -B /misc:/misc --cleanenv $container 3dresample -input $wm_nmt -master $epi -prefix $outdir/WM_in_${subj}_epi.nii.gz

csf=$outdir/CSF_in_${subj}_epi.nii.gz
wm=$outdir/WM_in_${subj}_epi.nii.gz

# tissue eigen time series
echo "++ Calculating tissue eigen timeseries"
echo "+++ CSF"
fslmeants -i $epi --eig -m $csf > $outdir/CSF_eigts.txt
echo  "+++ WM"
fslmeants -i $epi --eig -m $wm > $outdir/WM_eigts.txt

# paste txt tissue and motion files to creat confound file
echo "++ Creating file with tissue timeseries and motion parameters"
motion=$apv/dfile_rall.1D
cp $motion $outdir/motion_params.txt

# join files to create confounds.txt file
echo Joining files
paste -d '\t' $outdir/CSF_eigts.txt $outdir/WM_eigts.txt $outdir/motion_params.txt > $outdir/confounds_temp.txt 

echo Setting tab as separator
sed -i 's/ /\t/g' $outdir/confounds_temp.txt

echo "Getting rid of extra tabs"
tr -s '\t' '\t' < $outdir/confounds_temp.txt > $outdir/confounds.tsv 

echo "Deleting empty lines if needed"
sed -i '/^[[:space:]]*$/d' $outdir/confounds.tsv

rm $outdir/confounds_temp.txt

echo "+ DONE"


