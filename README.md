# NHP-MXCH  project

*Project Description:*

This repository is intended to serve as a container for code, analyses and results of the Mexican-Chinese non-human primate collaboration. Till now, the main goal of this project is to carry out comparisons of Fronto-Striatal network connectivity (functional and structural) between **macaques** (data obtained from the [PRIME-DE](https://fcon_1000.projects.nitrc.org/indi/indiPRIME.html) dataset) and **humans**  (data obtained from the [HCP](http://www.humanconnectomeproject.org/) or [ENIGMA](http://enigma.ini.usc.edu/)).

*Usage:* 

- scripts and code (till now): [afni](https://github.com/edrojas3/nhp_data_processing/tree/main/afni) folder. 

*Project administrators:*

- Sze Chai Kwok, PhD - **Principal Investigator**
- Eduardo A. Garza-Villarreal, PhD - **Principal Investigator**
- Eduardo Rojas-Hortelano, MSc, PhD candidate - **Research Assistant**
- Alfonso Fajardo-Valdez, MSc - **Research Assistant**



##  **Resting-State preprocessing  pipeline for macaques**

In this section  we will use the subject `sub-032125` of the site-ucdavis data available in the PRIME-DE website. To process the  images we are currently using  tools from  [ANTs](https://stnava.github.io/ANTs/), [AFNI](https://afni.nimh.nih.gov/pub/dist/doc/htmldoc/index.html) and [FSL](https://fsl.fmrib.ox.ac.uk/fsl/fslwiki)

### T1 weighted sequence preprocessing 

