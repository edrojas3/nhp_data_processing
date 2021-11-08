# <ins> **NHP-MXCH  project** </ins>
![](https://github.com/edrojas3/nhp_data_processing/blob/main/media/monkey3.png)

### *Project administrators:*

- Alfonso Fajardo-Valdez, MSc - **Research Assistant**
- Eduardo Rojas-Hortelano, MSc, PhD candidate - **Research Assistant**
- Sze Chai Kwok, PhD - **Principal Investigator**
- Eduardo A. Garza-Villarreal, PhD - **Principal Investigator**

### *Project Description:*

This repository is intended to serve as a container for code, analyses and results of the Mexican-Chinese non-human primate collaboration. Till now, the main goal of this project is to carry out comparisons of Fronto-Striatal network connectivity (functional and structural) between **macaques** (data obtained from the [PRIME-DE](https://fcon_1000.projects.nitrc.org/indi/indiPRIME.html) dataset) and **humans**  (data obtained from the [HCP](http://www.humanconnectomeproject.org/) or [ENIGMA](http://enigma.ini.usc.edu/)).

### *Usage:* 

- scripts and code (till now): [code](https://github.com/edrojas3/nhp_data_processing/tree/main/code) folder. 


# Image pre-processing steps
##  **Resting-State preprocessing  pipeline for macaques**

In this section  we will use the subject `sub-032125` of the site-ucdavis data available at the PRIME-DE website. To process the  images we are currently using  tools from  [ANTs](https://stnava.github.io/ANTs/), [AFNI](https://afni.nimh.nih.gov/pub/dist/doc/htmldoc/index.html) and [FSL](https://fsl.fmrib.ox.ac.uk/fsl/fslwiki)

### <ins> T1 weighted sequence preprocessing </ins>

1. **Cropping (FSL)** : Open the image with your favorite viewer and  choose the  the  slice (z axis coordinate ) from which you want to cut. Then simply use `fslroi` tool: `fslroi <input> <output> <xmin> <xsize> <ymin> <ysize> <zmin> <zsize>`

   **Example:**

    ```fslroi sub-032125_ses-001_run-1_T1w.nii.gz  sub-032125_ses-001_run-1_T1w_cropped.nii.gz 0 480 0 512 246 200```

   ![](https://github.com/edrojas3/nhp_data_processing/blob/main/media/cropping.png)

2. **Bias Field Correction (ANTs):** Use `N4BiasFieldCorrection -i <NIFTI image> - o <ouput_N4.nii.gz> `

   **Example:** ```N4BiasFieldCorrection  -v -i sub-032125_ses-001_run-1_T1w_cropped.nii.gz -o sub-032125_ses-001_run-1_T1w_cropped_n4.nii.gz```

3. **Animal Warper (AFNI):** Performs non-linear registration from subject to standard space. It was the best option among other "available" pipelines like PREEMACS or cvet-macaque.
   **Basic usage**: `@animal_warper -input <anatomical image> -base <standard volume> -outdir <anatomical image registered to standard>`
 
4. **Functional preprocessing:** we used `afni_proc.py` for basic preprocessing steps:
    - align slices to the beginning of TR
    - registration to anatomical space
    - spatial blurring: 3mm of FWHM filter

# **Seed based correlation analysis (SBCA)**
We used SBCA to obtain the connectivity profiles of the regions of the reward network (targets). The connectivity profiles are the partial correlations between the eigen timeseries of each target and every seed. The eigen timeseries of the white matter (WM), cerebro-spinal fluid (CSF), and 6 motion parameteres were used as confound variables. The regions identified as seeds are homologus regions between humans and macaques.

For the group analysis a linear model was created for each target to obtain the z-values of the parameter estimates for each seed. Putting it in R terminology lm(rvalues ~ seed).

## Targets and Seeds
The targets are the regions of the reward network we're interested in, and the seeds are the homologus regions between macaques and humans. A detailed table of coordinates is inside the `files` directory of this repository, as well as the 3dvolumes containing the roi's. For macaques, each roi is a cube of 3 x 3 x 3 mm. In very medial regions, like the ventral striatum, there was ovelap between the bilateral cubes. In these cases the overlap was deleted.
  - targets (bilateral):
    - vmpfc: BAs 10, 32, 25
    - anterior insula
    - basal ganglia structures: dorsal striatum, accumbens, putamen, globus pallidus, amygdala, caudate
    - hippocampus
  - seeds:
    - area 9/46
    - area 44
    - sma
    - area 8
    - m1
    - s1
    - parietal operculum
    - anterior inferior parietal sulcus
    - posterior inferior parietal lobule   
    - area 23ab
    - retrosplenial cortex
    - perirhinal cortex
    - temporal pole
    - ventral striatum
    - caudate head
    - putamen
    - hippocampus
    - amygdala
    - hypothalamus
    - vta

The script `nhp-chmx_sbca.sh` can be used to perform the complete analysis.

## Getting the confounds (WM and CSF)
CODE:`nhp-chmx_get_confounds.sh`
- fsl's `fast` to make a tissue segmentation of the WM and CSF from the subject's T1
- AFNI's `3drsample` to transform the segmenation images to the subject's epi.
- `fslmaths` to create a binary mask of each tissue
- `fslmeants` with `--eig` option to get the eigen timeseries of each tissue.
- Copy of the dfile_rall.1D file from `@animal_warper` output to get the motion parameters
- Joins everything in one text file called `confounds.txt`

## SBCA for every target
CODE: part of `nhp-chmx_sbca.sh`
- AFNI's`3dresample` to take the 3d nii files of the targets and seeds and into the subject's epi
- `nhp-chmx_mask_from_roi_index.sh` to extract a single target 
- `fsl_sbca` to obtain the partial correlations between each single target and every seed. The `confounds.txt` (see **Getting confounds**) of each subject was used as input for the `--conf` option.
  - `fsl_sbca` takes the eigen timeseries of the target as default, and calculates the partial correlation for every single voxel in the seeds mask. 
- The ouputs are 3dvolumnes, 1 for each target, and are located in a directory called `corr_files` inside the sbca/sub-id directory
- `nhp-chmx_get_corrtable.sh` takes the target-seed sbca result, obtains the best correlated voxel for each seed, and place it in a table. 

## **Spider plots:** 
The results of the sbca are represented with spider plots which show the correlation of a single target with every seed. 
- `nhp-chmx_spiderplots_from_corrtable.R` takes the `corrtable.tsv` of each subject and saves a png with the spider plot for each target.

## Group analysis
- `nhp-chmx_get_group_zvals_table.R` joins the corrtables of every subject and performs a linear model to obtain a parameter estimate and z-value of each seed.

   

   

