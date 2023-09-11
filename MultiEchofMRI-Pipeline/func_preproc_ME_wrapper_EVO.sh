#!/bin/bash
# Chuck Lynch, Hussain Bukhari, Holland Brown
# Updated 2023-09-11

# Functional Preprocessing Wrapper (2nd of 3 wrappers): field map preprocessing, coregistration, slice-time and motion correction,
# spatial distortion correction, and motion QA

# About this fork:
	# changed to handle double-echo (magnitude and phase) field maps optionally (prev version only for spin-echo FMs)
	# debugged matlab script calls (prev version ran into permissions errors in some environments)
	# added flexibility for different json formats in matlab scripts
	# added scripts (rorden_get_slice_times.m, edit_jsons.sh) to calculate missing slice timing info and edit json format/parameter names for Philips datasets

#–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––

StudyFolder=$1 # location of Subject folder
Subject=$2 # space delimited list of subject IDs
NTHREADS=$3 # set number of threads; larger values will reduce runtime (but also increase RAM usage)
StartSession=$4 # define the starting point

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

echo -e "\nMulti-Echo Preprocessing & Denoising Pipeline for Subject $Subject...\n"

# process all field maps & create an average image for cases where scan-specific maps are unavailable
echo -e "\nProcessing the Field Maps\n"
#"$MEDIR"/func_preproc_fm_EVO_NKI.sh "$MEDIR" "$Subject" "$StudyFolder" "$NTHREADS" "$StartSession" # skips BET for magnitude FMs (already done for NKI FMs)
"$MEDIR"/func_preproc_fm_EVO_UW.sh "$MEDIR" "$Subject" "$StudyFolder" "$NTHREADS" "$StartSession" # includes BET for magnitude FMs (not already done for UW FMs)

# create an avg. sbref image and co-register that image & all individual SBrefs to the T1w image
echo -e "\nCoregistering SBrefs to the Anatomical Image for Subject $Subject...\n\n"
"$MEDIR"/func_preproc_coreg_EVO.sh "$MEDIR" "$Subject" "$StudyFolder" "$AtlasTemplate" "$DOF" "$NTHREADS" "$StartSession"

# correct func images for slice time differences and head motion
echo -e "\nCorrecting for Slice Time Differences, Head Motion, & Spatial Distortion for Subject $Subject...\n\n"
"$MEDIR"/func_preproc_headmotion_EVO.sh "$MEDIR" "$Subject" "$StudyFolder" "$AtlasTemplate" "$DOF" "$NTHREADS" "$StartSession"

# functional post-processing (motion QA)
echo -e "\nFunctional Post-Processing for Subject $Subject...\n"
"$MEDIR"/post_func_preproc_headmotion_EVO.sh "$MEDIR" "$Subject" "$StudyFolder" "$AtlasTemplate" "$DOF" "$NTHREADS" "$StartSession"

echo -e "\nFunctional pre-processing for subject $Subject done.\n" 