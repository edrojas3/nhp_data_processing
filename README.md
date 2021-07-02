# <u>**NHP-MXCH  project**</u>
![](https://github.com/edrojas3/nhp_data_processing/blob/main/media/monkey3.png)

### *Project Description:*

This repository is intended to serve as a container for code, analyses and results of the Mexican-Chinese non-human primate collaboration. Till now, the main goal of this project is to carry out comparisons of Fronto-Striatal network connectivity (functional and structural) between **macaques** (data obtained from the [PRIME-DE](https://fcon_1000.projects.nitrc.org/indi/indiPRIME.html) dataset) and **humans**  (data obtained from the [HCP](http://www.humanconnectomeproject.org/) or [ENIGMA](http://enigma.ini.usc.edu/)).

### *Usage:* 

- scripts and code (till now): [afni](https://github.com/edrojas3/nhp_data_processing/tree/main/afni) folder. 

### *Project administrators:*

- Sze Chai Kwok, PhD - **Principal Investigator**
- Eduardo A. Garza-Villarreal, PhD - **Principal Investigator**
- Eduardo Rojas-Hortelano, MSc, PhD candidate - **Research Assistant**
- Alfonso Fajardo-Valdez, MSc - **Research Assistant**



##  **Resting-State preprocessing  pipeline for macaques**

In this section  we will use the subject `sub-032125` of the site-ucdavis data available in the PRIME-DE website. To process the  images we are currently using  tools from  [ANTs](https://stnava.github.io/ANTs/), [AFNI](https://afni.nimh.nih.gov/pub/dist/doc/htmldoc/index.html) and [FSL](https://fsl.fmrib.ox.ac.uk/fsl/fslwiki)

### <u>T1 weighted sequence preprocessing</u>

1. Some images need to be cropped to keep only skull and brain. Open the image with your favorite viewer and  choose the  the  slice (z axis coordinate ) from which you want to cut. Then simply use `fslroi` tool: `fslroi <input> <output> <xmin> <xsize> <ymin> <ysize> <zmin> <zsize>`

   **Example:**

    ```fslroi sub-032125_ses-001_run-1_T1w.nii.gz  sub-032125_ses-001_run-1_T1w_cropped.nii.gz 0 480 0 512 246 200```

   ![](https://github.com/edrojas3/nhp_data_processing/blob/main/media/cropping.png)

