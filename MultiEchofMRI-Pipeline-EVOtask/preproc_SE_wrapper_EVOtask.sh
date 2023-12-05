#!/bin/bash
# CJL; (cjl2007@med.cornell.edu)
# HRB; (hob4003@med.cornell.edu)
# Task-Based fMRI Preprocessing Wrapper
# Updated 2023-12-05

StudyFolder=$1 # location of Subject folder
Subject=$2 # space delimited list of subject IDs
NTHREADS=$3 # set number of threads; larger values will reduce runtime (but also increase RAM usage)
StartSession=$4 # define the starting point
TaskName=$5 # name of task; should match subdir names and file prefixes (for EVO, should be 'floop' or 'adjective')

# Load modules
module load Connectome_Workbench/1.5.0/Connectome_Workbench
module load freesurfer/6.0.0
module load python-3.7.7-gcc-8.2.0-onbczx6
module load fsl/6.0.4
module load afni/afni
module load ants-2.4.0-gcc-8.2.0-ehibrhi
module load matlab/R2021a

# reformat subject folder path
if [ "${StudyFolder: -1}" = "/" ]; then
	StudyFolder=${StudyFolder%?};
fi

# define subject directory
Subdir="$StudyFolder"/"$Subject"

# define some directories containing custom matlab scripts and various atlas files
MEDIR="/athena/victorialab/scratch/hob4003/ME_Pipeline/MEF-P-HB/MultiEchofMRI-Pipeline"

# these variables should not be changed unless you have a very good reason
DOF=6 # this is the degrees of freedom (DOF) used for SBref --> T1w and EPI --> SBref coregistrations
AtlasTemplate="$MEDIR/res0urces/FSL/MNI152_T1_2mm.nii.gz" # define a lowres MNI template
AtlasSpace="T1w" # define either native space ("T1w") or MNI space ("MNINonlinear")

# set variable value that sets up environment
# source /software/spack/share/spack/setup-env.sh # TEST - did not change parallel error in func_preproc_coreg.sh

EnvironmentScript="/athena/victorialab/scratch/hob4003/ME_Pipeline/Hb_HCP_master/Examples/Scripts/SetUpHCPPipeline.sh" # Pipeline environment script
source ${EnvironmentScript}	# Set up pipeline environment variables and software

echo -e "\nMulti-Echo Preprocessing Pipeline for Subject $Subject...\n"

# Create output directory
if [ ! -d "$StudyFolder"/"$Subject"/func/"$TaskName" ]; then
	mkdir "$StudyFolder"/"$Subject"/func/"$TaskName"
fi

# (1) Process all field maps & create an average image for cases where scan-specific maps are unavailable
echo -e "\nProcessing the Field Maps\n"
"$MEDIR"/func_preproc_fm_EVOtask.sh "$MEDIR" "$Subject" "$StudyFolder" "$NTHREADS" "$StartSession" "$TaskName"

# ––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––
# leave commented out - this is redundant with last code block in func_preproc_fm.sh
# echo -e "\n Post Processing the Field Maps"

# "$MEDIR"/post_func_preproc_fm.sh "$MEDIR" "$Subject" "$StudyFolder" "$NTHREADS" "$StartSession"
# ––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––

# (2) Create an avg. sbref image and co-register that image & all individual SBrefs to the T1w image
echo -e "\nCoregistering SBrefs to the Anatomical Image\n"
"$MEDIR"/func_preproc_coreg_EVOtask.sh "$MEDIR" "$Subject" "$StudyFolder" "$AtlasTemplate" "$DOF" "$NTHREADS" "$StartSession" "$TaskName"

# (3) Correct func images for slice time differences and head motion
echo -e "\nCorrecting for Slice Time Differences, Head Motion, & Spatial Distortion\n"
"$MEDIR"/preproc_headmotion_EVOtask.sh "$MEDIR" "$Subject" "$StudyFolder" "$AtlasTemplate" "$DOF" "$NTHREADS" "$StartSession" "$TaskName"

# (4) Functional post-processing (motion QA)
echo -e "\nFunctional Post-Processing Motion QA for Subject $Subject...\n"
"$MEDIR"/post_func_preproc_headmotion_EVOtask.sh "$MEDIR" "$Subject" "$StudyFolder" "$AtlasTemplate" "$DOF" "$NTHREADS" "$StartSession"

echo -e "\nFunctional pre-processing for subject $Subject "$TaskName" done.\n" 