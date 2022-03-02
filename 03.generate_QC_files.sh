#!/bin/bash

# --------------------------- Description -------------------------------------

# -------------Create a helper function ---------------------------------------
help ()
{
	echo
       	echo "Functional preprocessing with afni_proc.py WITHOUT VOXEL SMOOTHING.\
				If you like it smooth, try nhp-chmx_afni_proc_ap_vox.sh"
       	echo
       	echo "USAGE: $(basename $0) <-S site_directory> <-s subject_id> [options]";
       	echo
       	echo "MNADATORY INPUTS:"
       	echo "-S: /path/to/site-directory"
       	echo "-s: subject id. Ex. sub-032202"
       	echo
       	echo "OPTIONAL INPUTS"
       	echo "-h: print help"
	echo "-w: path to animal_warper results directory. Default = site/data_aw"
       	echo "-o: Output directory. DEFAULT: site/data_ap. If the output directory\
				doesn't exist, the script will create one. The script also creates a folder\
				inside of the output directory named as the subject id. All the afni_proc.py outputs will be saved in this data_ap/sub-id path."
       	echo  "-r: NMT_v2 path. DEFAULT:/misc/tezca/reduardo/resources/atlases_and_templates/NMT_v2.0_sym/NMT_v2.0_sym_05mm. Inside of this folder a NMT*SS.nii.gz must exxist."
       	echo "-c: AFNI container directory. DEFAULT:/misc/purcell/alfonso/tmp/container/afni.sif."
       	echo
       	echo "EXample: use afni_proc.py to preprocess the functional data of sub-032202 of site-blah and save the output in another folder/data_ap."
       	echo "$(basename $0) -S site-blah -s sub-032202 -w site-blah/data_aw -o other_folder/data_ap"
       	echo
	echo NOTES
	echo "- The script takes all the functional images in path/to/site/sub-id/ses*/func/*bold.nii.gz"
	echo "- The cost function is fixed a lpc+zz option."

}

# ------------------------------- Compulsory arguments ------------------------
#

# Compulsory postional arguments:												\
# $S: PATH TO DIR WICH PREPROCESSED SUBJECTS site											\
# : PROC.PY suffix diractory name (a string inside each subject dir where the afny.proc.py outputs can be found		\
# for example rest-fmri_proc03.results	or 	rest-fmri_proc04.results							\
# $3: OUTPUT NAME FOR RESULTING TABLE	\


# ------------------------- Case options --------------------------------------

while getopts "S:s:r:o:w:mh" opt; do
	case ${opt} in
		S) site=${OPTARG};;
                h) help
                   exit
                   ;;
                \?) help
                    exit

    esac
done

# ---------------------check that afni script exists---------------------------
gen_ss_review=$(which  gen_ss_review_table.py)

if [ -z  $gen_ss_review ]
	then
		echo -e "\e[0;31mNo gen_ss_review_table.py script found!!!\e[0m"
		exit 0

fi


# ------------------------------ set directories-------------------------------


basedir=$PWD

if  [ ! -d ${site}/data_ap ]; then
echo -e "\e[0;31mSite Directory Not Found. Make sure that 'data_ap' \
Directory Exists.\e[0m"
exit 0
fi

	cd $site/data_ap

	mkdir -p ../QC
# --------------------- Found subjects on dir ---------------------------------

subjects=$(ls -d */ | grep sub- | cut -d '/' -f 1 )
subjects=$(echo $subjects)
echo
echo -e "\e[1;97mThe following subjects were found:\e[0m"\
 "\e[3;97m$subjects\e[0m"
echo
 echo -e "\e[0;33mSearching for QC html reports..."
echo ...
echo ...
echo ...
echo -e "\e[0m"



# -------find QC directories  per subject -------------------------------------
for s in $subjects
do
	cd $s
	rundirs=$(ls  -d */ | grep results |   cut -d '/' -f 1)

echo "Subject $s has $(echo $rundirs | wc -w) preprocessed run(s).\
 I will try to extract metrics to generate $(echo $rundirs | wc -w) QC file(s)."

#  ----------------- extract qc report for each run --------------------------

run_index=0

for run in $rundirs
do
let "run_index= $run_index + 1"

qc_file=$(find $run -maxdepth 1 -name "out.ss*txt")

# make sure that qc file exist before coping it

if  ! [ -z $qc_file ]; then

cp $qc_file ../../QC/tmp.run0${run_index}.${s}.txt

fi

#  echo $run_index

done

cd ..

done

# -------- change directory to QC files ---------------------------------------
cd ../QC

# ------ identify unique runs--------------------------------------------------

site_name=$(basename $site)


unique_runs=$( ls *txt | cut -d '.' -f 2 | uniq)

for r in $unique_runs
do

files=$(ls *tmp*.txt | grep $r)

# generate first QC file
gen_ss_review_table.py -write_table tmp_${r}_tmp01.tsv -infiles  $files \
-overwrite -show_infiles -showlabs

# Generate second QC file

 cat tmp_${r}_tmp01.tsv | sed 's/,/ /g' | sed 's/\t/,/g' > tmp_${r}_tmp02.csv

 nl=$(cat tmp_${r}_tmp02.csv| wc -l)
 max=$(echo "$(($nl -2))")

# generate thirth qc file

echo Index,Site > tmp_${r}_tmp03.csv
echo 0,${site_name} >> tmp_${r}_tmp03.csv

for s in $(seq $max)
do
echo ${s},${site_name} >> tmp_${r}_tmp03.csv
done

paste -d ',' tmp_${r}_tmp03.csv tmp_${r}_tmp02.csv > QC_${site_name}_${r}.csv



done

rm tmp*

clear

echo "++++ DONE!!!!!!!!!"
cd $basedir
