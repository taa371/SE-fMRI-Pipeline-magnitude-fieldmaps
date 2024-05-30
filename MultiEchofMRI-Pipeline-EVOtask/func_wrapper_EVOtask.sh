#!/bin/bash
# Charles Lynch, Holland Brown
# Task-Based fMRI Preprocessing Wrapper
# Updated 2023-12-11

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
AtlasTemplate="$MEDIR/res0urces/FSL/MNI152_T1_2mm.nii.gz" # define a low-res MNI template
AtlasSpace="T1w" # define either native space ("T1w") or MNI space ("MNINonlinear") -> this variable isn't used (?)

# Set up pipeline environment variables and software
EnvironmentScript="/athena/victorialab/scratch/hob4003/ME_Pipeline/Hb_HCP_master/Examples/Scripts/SetUpHCPPipeline.sh"
source ${EnvironmentScript}

echo -e "\n----------------------------------------------------"
echo -e "$Subject $TaskName Multi-Echo Preprocessing Pipeline"
echo -e "----------------------------------------------------\n"

# Create output directories
if [ ! -d "$StudyFolder/$Subject/func/$TaskName" ]; then
	mkdir "$StudyFolder"/"$Subject"/func/"$TaskName"
fi

# (1) Process all field maps & create an average image for cases where scan-specific maps are unavailable
echo -e "\n--------------------------------------------"
echo -e "$Subject $TaskName Processing the Field Maps"
echo -e "--------------------------------------------\n"
"$MEDIR"/func_fieldmaps_EVOtask.sh "$MEDIR" "$Subject" "$StudyFolder" "$NTHREADS" "$StartSession" "$TaskName"

# (2) Create an avg SBref image; co-register that image & all individual SBrefs to the T1w image
echo -e "\n---------------------------------------------------------------"
echo -e "$Subject $TaskName Coregistering SBrefs to the Anatomical Image"
echo -e "---------------------------------------------------------------\n"
"$MEDIR"/func_coreg_EVOtask.sh "$MEDIR" "$Subject" "$StudyFolder" "$AtlasTemplate" "$DOF" "$NTHREADS" "$StartSession" "$TaskName"

# (3) Correct func images for slice-time differences & head motion; motion QA
echo -e "\n-------------------------------------------------------------------------------------------"
echo -e "$Subject $TaskName Correcting for Slice Time Differences, Head Motion, & Spatial Distortion"
echo -e "-------------------------------------------------------------------------------------------\n"
"$MEDIR"/func_headmotion_EVOtask.sh "$MEDIR" "$Subject" "$StudyFolder" "$AtlasTemplate" "$DOF" "$NTHREADS" "$StartSession" "$TaskName"

if [ -d "$StudyFolder/$Subject/workspace" ]; then
	rm -rf "$StudyFolder"/"$Subject"/workspace
fi

echo -e "\n-----------------------------------------------------"
echo -e "$Subject $TaskName Functional Pre-Processing COMPLETE"
echo -e "-----------------------------------------------------\n"
