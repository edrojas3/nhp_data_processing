
# Defaults
refdir=/misc/tezca/reduardo/resources/atlases_and_templates/NMT_v2.0_sym/NMT_v2.0_sym_05mm
outdir=data_aw
bfc=0
container=/misc/purcell/alfonso/tmp/container/afni.sif

while getopts "S:s:r:o:c:b" opt; do
	case ${opt} in
		S) site=${OPTARG};;
		s) s=${OPTARG};;
		r) refdir=${OPTARG};;
		o) outdir=${OPTARG};;
		c) container=${OPTARG};;
		b) bfc=1
	esac
done

if [ $bfc -eq 0 ]; then
	s_anat=$(find $site -type f \( -name "${s}*T1*nii*" -not -name "*N4*" \))
else

	s_anat=$(find $site -type f -name "${s}*N4*nii*")
fi


# Check for stuff
if [ ! -d $ref ]; then echo "No reference $ref found." ; exit 1; fi
if [ ! -d $site ]; then echo "No site with name $site found."; exit 1; fi
if [ ! -d $s ]; then echo "No subject with id $s found."; exit 1; fi
if [ -z "$s_anat" ]; then echo "Couldn't found an anatomical volumen for $s."; exit 1; fi

if [ ! -d $outdir ]; then mkdir $outdir; fi

refvol=$refdir/NMT*_SS.nii.gz
refvol_ab=NMT2
refseg=($refdir/NMT*_segmentation*.nii.gz $refdir/supplemental_masks/NMT*_ventricles*.nii.gz)
refseg_ab=(SEG VENT)
refmask=$refdir/NMT*_brainmask.nii.gz
refmask_ab=MASK
	
singularity exec -B /misc:/misc --cleanenv $container @animal_warper \
	-echo \
	-input ${s_anat} \
	-input_abbrev ${s}_anat \
	-base ${refvol} \
	-base_abbrev ${refvol_ab} \
	-seg_abbrevs ${refseg_ab} \
	-skullstrip  ${refmask} \
	-outdir ${outdir} \
	-ok_to_exist                   
