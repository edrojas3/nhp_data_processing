#!/bin/bash
help(){
echo
echo "USAGE: $(basename $0) site subject-id output_directory"
echo
echo "Creates a confound.csv file with the eigen timeseries of CSF, white matter, and motion parameters to use in fsl_sbca."
echo
echo "Inputs:"
echo "-site: full path to site directory (ex. /home/someone/mri/data/site-ecnu)"
echo "-subject-id: ex. sub-032202"
echo "-output-directory: subfolder within site-directory to save the outputs. If it doesn't exist, the script will create it along with a subject-id subfolder."
echo 
echo "Output:"
echo "-confounds.txt: tab separated file with 8 columns, each one with the eigen timeseries of:"
echo "* 1. CSF"
echo "* 2. White matter"
echo "* 3 to 8: motion parameters"
echo
echo "CONSIDER THAT:"
echo "The script segments CSF and WM from the subject anatomical volume registered in template and skull stripped. "
echo "The script assumes that within the site directory a subfolder called data_apv exists. It takes the epi and motion parameter files (dfile_rall.1D) from this folder."
}


if [ $# -lt 3 ]; then help; exit 1; fi

site=$1
subj=$2
outdir=$3/$subj

echo "+ Getting confounds file for $subj in $(echo $site | rev | cut -d/ -f1 | rev)"

# Tissue regressors

test ! -d $outdir && mkdir -p $outdir

aw=$site/data_aw/$subj
apv=$site/data_apv/$subj/$subj.results
epi=$apv/errts.${subj}.tproject+tlrc.nii.gz

test ! -f $epi && 3dAFNItoNIFTI -prefix $epi $apv/errts.${subj}.tproject+tlrc.

# resample tissue to subject epi
echo "+ Tissue masks"

echo "++ Segmenting..."
fast -o $outdir $aw/$subj/${subj}_anat_warp2std_nsu.nii.gz

echo "++ Creating CSF and WM masks..."
fslmaths $outdir/*pve_0*.nii.gz -thr 0.5 $outdir/csf_in_${subj}_epi
fslmaths $outdir/csf_in_${subj}_epi.nii.gz -bin $outdir/csf_in_${subj}_mask
 
fslmaths $outdir/*pve_2*.nii.gz -thr 0.5 $outdir/wm_in_${subj}_epi
fslmaths $outdir/wm_in_${subj}_epi.nii.gz -bin $outdir/wm_in_${subj}_mask

csf=$outdir/csf_in_${subj}_mask.nii.gz
wm=$outdir/wm_in_${subj}_mask.nii.gz

# tissue eigen time series
echo "++ Calculating tissue eigen timeseries"
echo "+++ CSF"
fslmeants -i $epi --eig -m $csf -o $outdir/CSF_eigts.txt
echo  "+++ WM"
fslmeants -i $epi --eig -m $wm -o $outdir/WM_eigts.txt

# paste txt tissue and motion files to creat confound file
echo "++ Creating file with tissue timeseries and motion parameters"
motion=$apv/dfile_rall.1D
cp $motion $apv/motion_params.txt
mv $apv/motion_params.txt $outdir

# join files to create confoundsjls

paste $outdir/CSF_eigts.txt $outdir/WM_eigts.txt $outdir/motion_params.txt | sed -e 's/ \{2,\}/\t/g' > $outdir/confounds.txt 


echo "+ DONE"


