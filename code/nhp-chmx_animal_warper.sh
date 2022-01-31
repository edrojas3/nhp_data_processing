# Help function
help()
{
	echo
	echo "Anatomical registration to NMT space using AFNI's @animal_warper."
	echo
	echo "USAGE: $(basename $0) <-S site_directory> <-s subject_id> [options]";
	echo
	echo "MNADATORY INPUTS:"
	echo "-S: /path/to/site-directory"
	echo "-s: subject id. Ex. sub-032202"
	echo
	echo "OPTIONAL INPUTS"
	echo "-h: print help"
	echo "-o: Output directory. DEFAULT: site/data_aw. If the output directory doesn't exist, the script will create one. The script also creates a folder inside of the output directory named as subject id where all the @animal_warper outputs will be saved."
	echo  "-r: NMT_v2 path. DEFAULT:/misc/tezca/reduardo/resources/atlases_and_templates/NMT_v2.0_sym/NMT_v2.0_sym_05mm. Inside of this folder a NMT*SS.nii.gz and a NMT*_brainmask.nii.gz must exist."
	echo "-c: AFNI container directory. DEFAULT:/misc/purcell/alfonso/tmp/container/afni.sif."
	echo "-b: Use a biased field corrected anatomical volume. It has to have a N4 identifier. EX. site-ion/sub-032202/anat/sub-032202_T1_N4.nii.gz. Use ANTS' N4BiasFieldCorrection  function to get one. THIS OPTION DOESN'T NEED AN ARGUMENT."
	echo
	echo "EX: use biased field corrected T1 volume of sub-032202 inside site-ion."
	echo "$(basename $0) -S site-ion -s sub-032202 -b"
	echo
}

# Defaults
refdir=/misc/hahn2/reduardo/atlases_and_templates/NMT_v2.0_sym/NMT_v2.0_sym_05mm
bfc=0
container=/misc/purcell/alfonso/tmp/container/afni.sif

while getopts "S:s:h:r:o:c:b" opt; do
	case ${opt} in
		S) site=${OPTARG};;
		s) s=${OPTARG};;
		r) refdir=${OPTARG};;
		o) outdir=${OPTARG};;
		c) container=${OPTARG};;
		h) help
		   exit
		   ;;
		b) bfc=1;;
		\?) help
	            exit
		    ;;
	esac
done

if [ "$#" -eq 0 ]; then help; exit 0; fi

if [ $bfc -eq 0 ]; then
	s_anat=$(find $site -type f \( -name "${s}*T1*nii*" -not -name "*N4*" \))
else

	s_anat=$(find $site -type f -name "${s}*N4*nii*")
fi

if [ -z $outdir ]; then outdir=$site/data_aw; fi

# Check for stuff
if [ ! -d $ref ]; then echo "No reference $ref found." ; exit 1; fi
if [ ! -d $site ]; then echo "No site with name $site found."; exit 1; fi
if [ ! -d $site/$s ]; then echo "No subject with id $s found in $site."; exit 1; fi
if [ -z "$s_anat" ]; then echo "Couldn't found an anatomical volume for $s."; exit 1; fi

if [ ! -d $outdir/$s ]; then mkdir -p $outdir/$s; fi

# copy wm and ventricle mask
cp $refdir/NMT_WM.nii.gz $outdir/$s
cp $refdir/NMT_VENT.nii.gz $outdir/$s

refvol=$refdir/NMT*_SS.nii.gz
#refvol_ab=NMT2
#refseg=($refdir/NMT*_segmentation*.nii.gz $refdir/supplemental_masks/NMT*_ventricles*.nii.gz)
#refseg_ab=(SEG VENT)
refmask=$refdir/NMT*_brainmask.nii.gz
refmask_ab=MASK

singularity exec -B /misc:/misc --cleanenv $container @animal_warper \
	-echo \
	-no_surfaces \
	-input ${s_anat} \
	-input_abbrev ${s}_anat \
	-base ${refvol} \
	-base_abbrev NMT \
	-atlas_followers ${refdir}/CHARM*.nii.gz ${refdir}/D99*.nii.gz \
	-atlas_abbrevs CHARM D99 \
	-seg_followers $refdir/NMT*_segmentation*.nii.gz $refdir/NMT*_ventricles*.nii.gz \
	-seg_abbrevs SEG VENT \
	-skullstrip  ${refmask} \
	-outdir $outdir/$s \
	-ok_to_exist
