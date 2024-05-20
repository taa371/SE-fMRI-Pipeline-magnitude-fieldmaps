# Liston-Laboratory-MultiEchofMRI-Pipeline
Repository for "Rapid precision mapping of individuals using multi-echo fMRI" ; Lynch et al. 2020 Cell Reports.

This pipeline was designed to process longitudinal multi-echo fMRI data. It calls scripts developed by the Human Connectome Project (for preprocessing of high resolution anatomical images and the generation of cortical surfaces) and Tedana (for signal-decay based denoising). 

Important Note: Code and instructions for use will be updated on a rolling basis to ensure generalizability of code to other computing environments.

Instructions for use: Data must be organized in the expected manner (see "ExampleDataOrganization" folder). Some images must also be accompanied by .json files (which can be produced by dicom conversion programs; e.g., "dcm2niix"). The .json files will be used at various points in the functional pipeline to obtain information needed for preprocessing (echo spacing, total readout time, slice time information, etc.) and denoising (echo times, etc.). 

Required Software
- Matab
- Freesurfer 
- FSL
- Connectome Workbench 
- ANTS
- Tedana
- GNU

## Step 1: Change all relevant paths in the FreeSurfer environment set up script /SetupHCPPipelinesScript.sh
    - see FreeSurfer pipelines documentation for more information (https://github.com/Washington-University/HCPpipelines)
    - NOTE: this script is sourced in the anatomical, functional and denoising wrappers

## Step 2: Anatomical Pipeline
    - set up general variables
        - in script to submit cluster jobs, define study folder, subject ID, TE, magnitude fieldmap name, phase fieldmap name, number of cluster cores, and readout distortion correction
        - set path to /SetupHCPPipelinesScript.sh (variable: "EnvironmentScript")

####    (A) Pre-FreeSurfer Pipeline
        - paths to templates (likely don't need to change; paths are set during /SetupHCPPipelinesScript.sh script)
        - structural scan settings
            - check JSON files or scan protocol docs to make sure DICOM field and unwarping direction are correct
            - brain size should typically be between 150 and 170 mm; choose 170 and decrease size + re-run if brain appears warped at end
            - set path to FNIRT config file (something like /T1_2_MNI152_2mm.cnf)
        - set gradient distortion coefficients if using spin echo fieldmaps (set to "NONE" for EVO study because fieldmaps were not spin-echo)

####    (B) FreeSurfer Pipeline
        - 

####    (C) Post-FreeSurfer Pipeline



## Step 3: Functional Pipeline

####    (A) Pre-FreeSurfer Pipeline


## Step 4: Denoising Pipeline
