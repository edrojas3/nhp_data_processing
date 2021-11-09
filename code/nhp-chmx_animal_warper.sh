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
	echo "-o: Output directory. DEFAULT: data_aw. If the output directory doesn't exist, the script will create one. The script also creates a folder inside of the output directory named as subject id where all the @animal_warper outputs will be saved." 
	echo  "-r: NMT_v2 path. DEFAULT:/misc/tezca/reduardo/resources/atlases_and_templates/NMT_v2.0_sym/NMT_v2.0_sym_05mm. Inside of this folder a NMT*SS.nii.gz and a NMT*_brainmask.nii.gz must exist." 
	echo "-c: AFNI container directory. DEFAULT:/misc/purcell/alfonso/tmp/container/afni.sif."
	echo "-b: Use a biased field corrected anatomical volume. It has to have a N4 identifier. EX. site-ion/sub-032202/anat/sub-032202_T1_N4.nii.gz. Use ANTS' N4BiasFieldCorrection  function to get one. THIS OPTION DOESN'T NEED AN ARGUMENT."	
	echo
	echo "EX: use biased field corrected T1 volume of sub-032202 inside site-ion."
	echo "$(basename $0) -S site-ion -s sub-032202 -b"
	echo 
}

# Defaults
refdir=/misc/tezca/reduardo/resources/atlases_and_templates/NMT_v2.0_sym/NMT_v2.0_sym_05mm
outdir=data_aw
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

if [ $bfc -eq 0 ]; then
	s_anat=$(find $site -type f \( -name "${s}*T1*nii*" -not -name "*N4*" \))
else

	s_anat=$(find $site -type f -name "${s}*N4*nii*")
fi


# Check for stuff
if [ ! -d $ref ]; then echo "No reference $ref found." ; exit 1; fi
if [ ! -d $site ]; then echo "No site with name $site found."; exit 1; fi
if [ ! -d $site/$s ]; then echo "No subject with id $s found in $site."; exit 1; fi
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
